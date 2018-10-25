import numpy as np
import h5py
import os
from time import time
import re
import shutil
import inspect
import datetime
from subprocess import check_call
from skimage import measure
from scipy.io import loadmat, savemat
from scipy import stats
import matplotlib.pyplot as plt
import clize
import keras
import tensorflow as tf
from utils import CausalAtrousConvolution1D
from keras.callbacks import ReduceLROnPlateau, ModelCheckpoint, LambdaCallback
from keras import backend as K
from keras.models import Model, load_model, save_model
from keras.layers import Input, Conv1D, Dense, Dropout, Lambda, Permute, LSTM, Average, concatenate, Layer, multiply
from keras.optimizers import Adam
from utils import create_run_folders

## Make an ensemble
def ensemble(models, model_input, return_member_data):
    """
    Build an ensemble of models that output the median of all members. Does not compile the ensemble.
    :param models: List of keras models to include in the ensemble. Currently requires the same output shape.
    :param model_input: Input shape of the members. Used for building the ensemble.
    :param return_member_data: If True, model will have two outputs: the ensemble prediction and all member predictions.
                               Otherwise, the model will output only the ensemble predictions.
    """
    def ens_median(x):
        import tensorflow as tf # This is needed to load the model in the future.
        return tf.contrib.distributions.percentile(x,50,axis=1)
    def pad(x):
        return(x[:,None,:])

    # Get outputs from the ensemble models, compute the median, and fix the shape.
    outputs = [model(model_input) for model in models]
    member_predictions = concatenate(outputs,axis = 1)
    ensemble_prediction = Lambda(ens_median)(member_predictions)
    ensemble_prediction = Lambda(pad)(ensemble_prediction)

    # Return model. No compilation is necessary since there are no additional trainable parameters.
    if return_member_data:
        model = Model(model_input, outputs=[ensemble_prediction,member_predictions], name='ensemble')
    else:
        model = Model(model_input, ensemble_prediction, name='ensemble')
    return model

def build_ensemble(base_output_path,
    *models_in_ensemble,
    return_member_data = True,
    run_name=None,
    clean=False):
    """
    Build an ensemble of models for marker prediction
    :param base_output_path: Path to base models directory
    :param models_in_ensemble: List of all of the models to be included in the build_ensemble
    :param return_member_data: If True, model will have two outputs: the ensemble prediction and all member predictions.
    :param run_name: Name of the model run
    :param clean: If True, deletes the contents of the run output path
    """

    # Load all of the models to be used as members of the ensemble
    models = [None]*len(models_in_ensemble)
    for i in range(len(models_in_ensemble)):
        models[i] = load_model(os.path.join(base_output_path, models_in_ensemble[i]))
        models[i].name = 'model_%d' % (i)

    # Build the ensemble
    ensemble_input = Input(batch_shape=models[0].input_shape)
    model_ensemble = ensemble(models,ensemble_input,return_member_data)

    # Build ensemble folder name if needed
    if run_name == None:
        run_name = "model_ensemble"
    print("run_name:", run_name)

    # Initialize run directories
    print('Building run folders')
    run_path = create_run_folders(run_name, base_path=base_output_path, clean=clean)

    # Convert list of models to objects for .mat saving
    model_paths = np.empty((len(models_in_ensemble),), dtype=np.object)
    for i in range(len(models_in_ensemble)):
        model_paths[i] = models_in_ensemble[i]

    # Save the training information in a mat file.
    print('Saving training info')
    savemat(os.path.join(run_path, "training_info.mat"),
            {"base_output_path": base_output_path, "run_name": run_name, "return_member_data": return_member_data,
             "clean": clean,"model_paths":model_paths,"n_members":len(models_in_ensemble)})

    print('Saving model ensemble')
    model_ensemble.save(os.path.join(run_path, "final_model.h5"))

if __name__ == "__main__":
    # Wrapper for running from commandline
    clize.run(build_ensemble)
