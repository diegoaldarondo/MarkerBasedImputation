import os
import numpy as np
import h5py
from time import time
from scipy.io import loadmat, savemat
import re
import shutil
import inspect
import datetime
from subprocess import check_call
import clize
import matplotlib.pyplot as plt
import keras
import keras.losses
from keras.callbacks import ReduceLROnPlateau, ModelCheckpoint, LambdaCallback
from keras import backend as K
import tensorflow as tf
from keras.models import Model, load_model
from keras.layers import Input, Conv1D, Dense, Dropout, Lambda, Permute, LSTM
from keras.optimizers import Adam
from keras.utils import multi_gpu_model
from utils import load_dataset, get_ids, CausalAtrousConvolution1D, asymmetric_temporal_padding, categorical_mean_squared_error
import models

def plot_history(history, save_path=None, show_figure=False):
    """ Plots the training history. """

    loss = [x["loss"] for x in history]
    val_loss = [x["val_loss"] for x in history]

    plt.figure(figsize=(8,4))
    plt.plot(loss)
    plt.plot(val_loss)
    plt.semilogy()
    plt.grid()
    plt.xlabel("Epochs")
    plt.ylabel("Loss")
    plt.legend(["Training", "Validation"])

    if save_path is not None:
        plt.savefig(save_path)
    if show_figure:
        plt.show()
    else:
        plt.close()

class LossHistory(keras.callbacks.Callback):
    def __init__(self, run_path):
        super().__init__()
        self.run_path = run_path

    def on_train_begin(self, logs={}):
        self.history = []

    def on_epoch_end(self, batch, logs={}):
        # Append to log list
        self.history.append(logs.copy())

        # Save history so far to MAT file
        savemat(os.path.join(self.run_path, "history.mat"),
                {k: [x[k] for x in self.history] for k in self.history[0].keys()})

        # Plot graph
        # plot_history(self.history, save_path=os.path.join(self.run_path, "history.png"))

def create_model(net_name, **kwargs):
    """ Wrapper for initializing a network for training. """

    compile_model = dict(
        wave_net=models.wave_net,
        lstm_model=models.lstm_model,
        wave_net_res_skip=models.wave_net_res_skip
        ).get(net_name)
    if compile_model == None:
        return None

    return compile_model(**kwargs)

def create_run_folders(run_name, base_path="models", clean=False):
    """ Creates subfolders necessary for outputs of training. """

    def is_empty_run(run_path):
        weights_path = os.path.join(run_path, "weights")
        has_weights_folder = os.path.exists(weights_path)
        return not has_weights_folder or len(os.listdir(weights_path)) == 0

    run_path = os.path.join(base_path, run_name)

    if not clean:
        initial_run_path = run_path
        i = 1
        while os.path.exists(run_path): #and not is_empty_run(run_path):
            run_path = "%s_%02d" % (initial_run_path, i)
            i += 1

    if os.path.exists(run_path):
        shutil.rmtree(run_path)

    os.makedirs(run_path)
    os.makedirs(os.path.join(run_path, "weights"))
    os.makedirs(os.path.join(run_path, "viz"))
    print("Created folder:", run_path)

    return run_path

def train(data_path, *,
    gpu_id=0,
    base_output_path="models",
    run_name=None,
    data_name=None,
    net_name="wave_net",
    clean=False,
    input_length=9,
    output_length=1,
    n_markers=60,
    train_fraction=.85,
    val_fraction=0.15,
    n_filters=512,
    filter_width=2,
    layers_per_level=3,
    n_dilations=None,
    latent_dim=750,
    epochs=50,
    batch_size=1000,
    lossfunc='mean_squared_error',
    lr=1e-4,
    batches_per_epoch=0,
    val_batches_per_epoch=0,
    reduce_lr_factor=0.5,
    reduce_lr_patience=3,
    reduce_lr_min_delta=1e-5,
    reduce_lr_cooldown=0,
    reduce_lr_min_lr=1e-10,
    save_every_epoch=False
    ):

    """
    Trains the network and saves the intermediate results to an output directory.
    :param data_path: Path to an HDF5 file with box and confmaps datasets
    :param gpu_id: gpu to use for training.
    :param base_output_path: Path to folder in which the run data folder will be saved
    :param run_name: Name of the training run. If not specified, will be formatted according to other parameters.
    :param data_name: Name of the dataset for use in formatting run_name
    :param net_name: Name of the network for use in formatting run_name
    :param clean: If True, deletes the contents of the run output path
    :param input_length: Number of frames to input into model
    :param output_length: Number of frames model will attempt to predict
    :param n_markers: Number of markers to use
    :param train_fraction: Fraction of dataset to use as training
    :param val_fraction: Fraction of dataset to use as validation
    :param filter_width: Width of base convolution filter
    :param layers_per_level: Number of layers to use at each convolutional block
    :param n_dilations: Number of dilations for wavenet filters. (See models.wave_net)
    :param latent_dim: Number of latent dimensions (Currently just for LSTM)
    :param n_filters: Number of filters to use as baseline (see create_model)
    :param epochs: Number of epochs to train for
    :param batch_size: Number of samples per batch
    :param batches_per_epoch: Number of batches per epoch (validation is evaluated at the end of the epoch)
    :param val_batches_per_epoch: Number of batches for validation
    :param reduce_lr_factor: Factor to reduce the learning rate by (see ReduceLROnPlateau)
    :param reduce_lr_patience: How many epochs to wait before reduction (see ReduceLROnPlateau)
    :param reduce_lr_min_delta: Minimum change in error required before reducing LR (see ReduceLROnPlateau)
    :param reduce_lr_cooldown: How many epochs to wait after reduction before LR can be reduced again (see ReduceLROnPlateau)
    :param reduce_lr_min_lr: Minimum that the LR can be reduced down to (see ReduceLROnPlateau)
    :param save_every_epoch: Save weights at every epoch. If False, saves only initial, final and best weights.
    """

    # gpu_id_string = '%d' % (gpu_id)
    # os.environ["CUDA_VISIBLE_DEVICES"]=gpu_id_string
    # gpu_string = '/gpu:%d' % (gpu_id)
    # print('Using ' + gpu_string )
    # with tf.device(gpu_string):

    # TODO: Fix n_dilations default
    # Load Data
    print('Loading Data')
    markers, marker_means, marker_stds, bad_frames = load_dataset(data_path)

    # Get Ids
    print('Getting indices')
    [input_ids,target_ids] = get_ids(bad_frames,input_length,output_length,True,True)

    # Get the training, testing, and validation trajectories by indexing into the marker arrays
    n_train = np.int32(np.round(input_ids.shape[0]*train_fraction))
    n_val = np.int32(np.round(input_ids.shape[0]*val_fraction))
    X = markers[input_ids[:n_train,:],:]
    Y = markers[target_ids[:n_train,:],:]
    val_X = markers[input_ids[n_train:(n_train+n_val),:],:]
    val_Y = markers[target_ids[n_train:(n_train+n_val),:],:]
    test_X = markers[input_ids[(n_train+n_val):,:],:]
    test_Y = markers[target_ids[(n_train+n_val):,:],:]

    if (net_name == 'lstm_model') | (net_name == 'wave_net_res_skip'):
        Y = np.squeeze(Y)
        val_Y = np.squeeze(val_Y)
        test_Y = np.squeeze(test_Y)

    # Create network
    print('Compiling network')
    if isinstance(net_name, keras.models.Model):
        model = net_name
        net_name = model.name
    elif net_name == 'wave_net':
        model = create_model(net_name, lossfunc=lossfunc, lr=lr, input_length=input_length, output_length=output_length, n_markers=n_markers, n_filters=n_filters, filter_width=filter_width, layers_per_level=layers_per_level, n_dilations=n_dilations, print_summary=False)
    elif net_name == 'lstm_model':
        model = create_model(net_name, lossfunc=lossfunc, lr=lr, input_length=input_length, n_markers=n_markers, latent_dim=latent_dim, print_summary = False)
    elif net_name == 'wave_net_res_skip':
        model = create_model(net_name, lossfunc=lossfunc, lr=lr, input_length=input_length, n_markers=n_markers, n_filters=n_filters, filter_width=filter_width, layers_per_level=layers_per_level, n_dilations=n_dilations, print_summary=True)
    if model == None:
        print("Could not find model:", net_name)
        return

    # Build run name if needed
    if data_name == None:
        data_name = os.path.splitext(os.path.basename(data_path))[0]
    if run_name == None:
        run_name = "%s-%s_epochs=%d_input_%d_output_%d" % (data_name, net_name, epochs, input_length, output_length)
    print("data_name:", data_name)
    print("run_name:", run_name)


    # Initialize run directories
    print('Building run folders')
    run_path = create_run_folders(run_name, base_path=base_output_path, clean=clean)

    # Save the training information in a mat file.
    print('Saving training info')
    savemat(os.path.join(run_path, "training_info.mat"),
            {"data_path": data_path, "base_output_path": base_output_path, "run_name": run_name, "data_name": data_name,
             "net_name": net_name, "clean": clean, "input_length": input_length, "output_length": output_length,
             "n_filters": n_filters, "n_markers": n_markers, "epochs": epochs, "batch_size": batch_size, "train_fraction": train_fraction,
             "val_fraction": val_fraction, "filter_width": filter_width, "layers_per_level": layers_per_level, "n_dilations":n_dilations,
             "batches_per_epoch": batches_per_epoch, "val_batches_per_epoch": val_batches_per_epoch,
             "reduce_lr_factor": reduce_lr_factor, "reduce_lr_patience": reduce_lr_patience, "reduce_lr_min_delta": reduce_lr_min_delta,
             "reduce_lr_cooldown": reduce_lr_cooldown, "reduce_lr_min_lr": reduce_lr_min_lr, "save_every_epoch": save_every_epoch})

    # Save initial network
    print('Saving initial network')
    model.save(os.path.join(run_path, "initial_model.h5"))

    # Initialize training callbacks
    history_callback = LossHistory(run_path=run_path)
    reduce_lr_callback = ReduceLROnPlateau(monitor="val_loss", factor=reduce_lr_factor,
                                          patience=reduce_lr_patience, verbose=1, mode="auto",
                                          epsilon=reduce_lr_min_delta, cooldown=reduce_lr_cooldown,
                                          min_lr=reduce_lr_min_lr)
    if save_every_epoch:
        checkpointer = ModelCheckpoint(filepath=os.path.join(run_path, "weights/weights.{epoch:03d}-{val_loss:.9f}.h5"), verbose=1, save_best_only=False)
    else:
        checkpointer = ModelCheckpoint(filepath=os.path.join(run_path, "best_model.h5"), verbose=1, save_best_only=True)

    # Train!
    print('Training')
    t0_train = time()
    training = model.fit(X, Y,
                    batch_size=batch_size,
                    epochs=epochs,
                    verbose = 1,
                    validation_data = (val_X,val_Y),
                    callbacks=[history_callback,checkpointer,reduce_lr_callback])

    # Compute total elapsed time for training
    elapsed_train = time() - t0_train
    print("Total runtime: %.1f mins" % (elapsed_train / 60))

    # Save final model
    print('Saving final model')
    model.history = history_callback.history
    model.save(os.path.join(run_path, "final_model.h5"))


if __name__ == "__main__":
    # Wrapper for running from commandline
    clize.run(train)
