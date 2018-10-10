import numpy as np
import h5py
import os
from time import time
from scipy.io import loadmat, savemat
import re
import shutil
import inspect
import datetime
import clize
from subprocess import check_call
from skimage import measure
from scipy.io import loadmat, savemat
from scipy import stats

import keras
from keras.callbacks import ReduceLROnPlateau, ModelCheckpoint, LambdaCallback
from keras import backend as K
from keras.models import Model, load_model
from keras.layers import Input, Conv1D, Dense, Dropout, Lambda, Permute, LSTM
from keras.optimizers import Adam


def sigmoid(x,x_0,k):
    return 1 / (1 + np.exp(-k*(x-x_0)))

def predict_markers(model, X, bad_frames, markers_to_fix = None, error_diff_thresh = .25):
    """
    Imputes the position of missing markers.
    :param model: model to use for prediction
    :param X: marker data (n_frames x n_markers)
    :param bad_frames: logical matrix of shape == X.shape where 0 denotes a tracked frame and 1 denotes a dropped frame
    :param fix_errors: boolean vector of length n_markers. True if you wish to override marker on frames further than error_diff_thresh from the previous prediction.
    :param error_diff_thresh: z-scored distance at which predictions override marker measurements.
    :return: preds, bad_frames
    """
    # Get the input lengths and find the first instance of all good frames.
    input_length = model.input.shape.as_list()[1]
    bad_frames = np.repeat(bad_frames,3,axis=1) > .5
    num_bad_markers = np.sum(bad_frames,axis=1)
    startpoint = 0
    for i in range(X.shape[0]):
        if np.any(num_bad_markers[startpoint:(startpoint+input_length)]):
            startpoint += startpoint
        else:
            break

    # See whether you should fix errors
    fix_errors = np.any(markers_to_fix);

    # Reshape and get the starting seed.
    X = X[None,...]
    X_start = X[:,startpoint:(startpoint+input_length),:]

    # Preallocate
    preds = np.zeros((X.shape))
    pred = np.zeros((1,1,X.shape[2]))

    # At each step, generate a prediction, replace the predictions of markers
    # you do not want to predict with the ground truth, and append the
    # resulting vector to the end of the next input chunk.
    for i in range(startpoint,X.shape[1]-input_length-startpoint):
        if np.mod(i,10000) == 0:
            print('Predicting frame: ',i)
        next_frame_id = (startpoint+input_length)+i

        # If there is a marker prediction that is greater than the difference
        # threshold above, mark it as a bad frame.
        # These are likely just jumps or identity swaps from MoCap that were
        # not picked up by preprocessing.
        if fix_errors:
            errors = np.squeeze(np.abs((pred[:,0,:] - X[:,next_frame_id,:])) > error_diff_thresh)
            errors[~markers_to_fix] = False
            bad_frames[next_frame_id,errors] = True
        if np.any(bad_frames[next_frame_id,:]):
            pred = model.predict(X_start)
#             pred = pred[:,np.newaxis,:]
        # Only use the predictions for the bad markers. Take the predictions
        # and append to the end of X_start for future prediction.
        pred[:,0,~bad_frames[next_frame_id,:]] = X[:,next_frame_id,~bad_frames[next_frame_id,:]]
        preds[:,next_frame_id,:] = np.squeeze(pred)
        X_start = np.concatenate((X_start[:,1:,:], pred),axis = 1)
    return np.squeeze(preds), bad_frames

def impute_markers(model_path, data_path, *,
    save_path = None,
    start_frame = None,
    n_frames = None,
    stride = 1,
    markers_to_fix = None,
    error_diff_thresh = .25,
    model = None):
    """
    Imputes the position of missing markers.
    :param model_path: Path to model to use for prediction.
    :param data_path: Path to marker and bad_frames data. Can be hdf5 or mat -v7.3.
    :param save_path: Path to .mat file where predictions will be saved.
    :param start_frame: Frame at which to begin imputation.
    :param n_frames: Number of frames to impute.
    :param stride: stride length between frames for faster imputation.
    :param markers_to_fix: Markers for which to override suspicious MoCap measurements
    :param error_diff_thresh: Z-scored difference threshold marking suspicious n_frames
    :param model: Model to be used in prediction. Overrides model_path.
    :return: preds
    """

    # Check data extensions
    filename, file_extension = os.path.splitext(data_path)
    accepted_extensions = {'.h5','.hdf5','.mat'}
    if file_extension not in accepted_extensions:
        raise ValueError('Improper extension: hdf5 or mat -v7.3 file required.')

    # Load data
    print('Loading data')
    f = h5py.File(data_path, 'r')
    if file_extension in {'.h5', '.hdf5'}:
        markers = np.array(f['markers'][:]).T
        marker_means = np.array(f['marker_means'][:]).T
        marker_stds = np.array(f['marker_stds'][:]).T
        bad_frames = np.array(f['bad_frames'][:]).T
    else:
        # Get the markers data from the struct
        dset = 'markers_aligned_preproc'
        marker_names = list(f[dset].keys())
        n_frames_tot = f[dset][marker_names[0]][:].T.shape[0]
        n_dims = f[dset][marker_names[0]][:].T.shape[1]

        markers = np.zeros((n_frames_tot,len(marker_names)*n_dims))
        for i in range(len(marker_names)):
            marker = f[dset][marker_names[i]][:].T
            for j in range(n_dims):
                markers[:,i*n_dims + j] = marker[:,j]

        print(markers.shape)

        # Z-score the marker data
        marker_means = np.mean(markers,axis=0)
        marker_means = marker_means[None,...]
        marker_stds = np.std(markers,axis=0)
        marker_stds = marker_stds[None,...]
        print(marker_means)
        print(marker_stds)
        markers = stats.zscore(markers)


        # Get the bad_frames data from the cell
        dset = 'bad_frames_agg'
        n_markers = f[dset][:].shape[0]
        bad_frames = np.zeros((markers.shape[0],n_markers))
        for i in range(n_markers):
            reference = f[dset][i][0]
            bad_frames[np.squeeze(f[reference][:]).astype('int32') - 1,i] = 1

    # Set number of frames to impute
    if n_frames is None:
        n_frames = markers.shape[0]
    if start_frame is None:
        start_frame = 0;
    print('Predicting %d frames starting at frame %d.' % (n_frames,start_frame))

    # Exceptions
    if n_frames > markers.shape[0]:
        raise ValueError('Improper n_frames to predict: likely asked to predict a greater number of frames than were available.')
    if (n_frames + start_frame) > markers.shape[0]:
        raise ValueError('start_frame + n_frames exceeds matrix dimensions.')
    if n_frames < 0:
        raise ValueError('Improper n_frames to predict: likely too few input frames.')
    if n_frames == 0:
        raise ValueError('Improper n_frames to predict: likely asked to predict zero frames.')

    markers = markers[start_frame:(start_frame + n_frames):stride,:]
    bad_frames = bad_frames[start_frame:(start_frame + n_frames):stride,:]

    # Load model
    if model is None:
        print('Loading model')
        model = load_model(model_path)

    # Set Markers to fix
    if markers_to_fix is None:
        markers_to_fix = np.zeros((markers.shape[1])) > 1
        # TODO: Automate this by including the skeleton.
        markers_to_fix[30:36] = True
        markers_to_fix[42:] = True

    # Forward Pass
    print('Imputing markers: forward pass')
    predsF,bad_framesF = predict_markers(model,markers,bad_frames, markers_to_fix = markers_to_fix, error_diff_thresh = error_diff_thresh)
    # Reverse Predict
    print('Imputing markers: reverse pass')
    predsR,bad_framesR = predict_markers(model,markers[::-1,:],bad_frames[::-1,:], markers_to_fix = markers_to_fix, error_diff_thresh = error_diff_thresh)

    # Convert to real world coordinates
    markers_world = np.zeros((markers.shape))
    predsF_world = np.zeros((predsF.shape))
    predsR_world = np.zeros((predsR.shape))
    for i in range(markers_world.shape[1]):
        markers_world[:,i] = markers[:,i]*marker_stds[0,i] + marker_means[0,i]
        predsF_world[:,i] = predsF[:,i]*marker_stds[0,i] + marker_means[0,i]
        predsR_world[:,i] = predsR[:,i]*marker_stds[0,i] + marker_means[0,i]

    predsR_world = predsR_world[::-1,:]
    bad_framesR = bad_framesR[::-1,:]

    # Get the frames that differ between bad_framesF and bad_framesR

    # This is not necessarily all of the error frames from multiple_predict_recording_with_replacement,
    # But if they overlap, we would just take the weighted average.
    errorsF = (bad_framesF) & ~(bad_framesR)
    errorsR = (bad_framesR) & ~(bad_framesF)
    for i in range(bad_frames.shape[1]):
        bad_frames[:,i] = np.any(bad_framesF[:,(i*3):(i*3)+3] & bad_framesR[:,(i*3):(i*3)+3],axis=1)


    # Compute the weighted average of the forward and reverse predictions using a logistic function
    print('Computing weighted average')
    preds_world = np.zeros(predsF_world.shape)
    for i in range(bad_frames.shape[1]*3):
        is_bad = bad_frames[:,np.floor(i/3).astype('int32')]
        CC = measure.label(is_bad,background = 0)
        num_CC = len(np.unique(CC))-1
        preds_world[:,i] = predsF_world[:,i]
        for j in range(num_CC):
            length_CC = np.sum(CC == (j+1))
            x_0 = np.round(length_CC/2)
            k = 1
            weightR = sigmoid(np.arange(length_CC),x_0,k)
            weightF = 1-weightR
            preds_world[CC == (j+1),i] = (predsF_world[CC == (j+1),i]*weightF) + (predsR_world[CC == (j+1),i]*weightR)

    # Save predictions to a matlab file.
    if save_path is not None:
        s = 'Saving to %s' % (save_path)
        print(s)
        savemat(save_path,{'preds':preds_world,'markers':markers_world,'badFrames':bad_frames})

    return preds_world

if __name__ == "__main__":
    # Wrapper for running from commandline
    clize.run(impute_markers)
