import numpy as np
import h5py
import os
from time import time
from scipy.io import loadmat, savemat
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
def ensemble(models, model_input):
    def ens_median(x):
        import tensorflow as tf # This is needed to load the model in the future.
        return tf.contrib.distributions.percentile(x,50,axis=1)
    def pad(x):
        return(x[:,None,:])

    # Get outputs from the ensemble models, compute the median, and fix the shape.
    outputs = [model(model_input) for model in models]
    y = concatenate(outputs,axis = 1)
    y = Lambda(ens_median)(y)
    y = Lambda(pad)(y)

    # Return model. No compilation is necessary since there are no additional trainable parameters.
    model = Model(model_input, y, name='ensemble')
    return model

def build_ensemble(base_output_path,*models_in_ensemble,run_name=None,clean=False):
    # base_output_path ='/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models'
    # models_in_ensemble = ['JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_09/best_model.h5',
    #                       'JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_08/best_model.h5',
    #                       'JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_07/best_model.h5',
    #                       'JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_06/best_model.h5',
    #                       'JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_05/best_model.h5',
    #                       'JDM25_20181002T180653-wave_net_epochs=50_input_9_output_1_06/best_model.h5']

    models = [None]*len(models_in_ensemble)
    for i in range(len(models_in_ensemble)):
        models[i] = load_model(base_output_path + '/' + models_in_ensemble[i])
        models[i].name = 'model_%d' % (i)

    model_ensemble = ensemble(models,Input(batch_shape=models[0].input_shape))

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
            {"base_output_path": base_output_path, "run_name": run_name,
             "clean": clean,"model_paths":model_paths})

    print('Saving model ensemble')
    model_ensemble.save(os.path.join(run_path, "final_model.h5"))

if __name__ == "__main__":
    # Wrapper for running from commandline
    clize.run(build_ensemble)