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

import keras
import keras.losses
from keras.callbacks import ReduceLROnPlateau, ModelCheckpoint, LambdaCallback
from keras import backend as K
from keras.models import Model, load_model
from keras.layers import Input, Conv1D, Dense, Dropout, Lambda, Permute, LSTM
from keras.optimizers import Adam
from keras.utils import multi_gpu_model
from keras.layers.convolutional import Conv1D
from keras.utils.conv_utils import conv_output_length
import tensorflow as tf

def load_dataset(data_path):
    """
    Load marker, marker_means, marker_stds, and bad_frames from the .h5 dataset

    Inputs:
    data_path - path to .h5 file

    Outputs:
    markers - Z-scored marker trajectories over time.
    marker_means - Mean of markers in real world coordinates
    marker_stds - Std of markers in real world coordinates
    bad_frames - Logical or integer matrix denoting frames in which there were marker errors. Same size as markers.
                 0 when marker j is a good recording at frame i, 1 otherwise.
    """
    # data_path = '/n/holylfs02/LABS/olveczky_lab/Diego/data/TCNData/JDM32_20180924T170909.h5'
    # data_path = '/n/holylfs02/LABS/olveczky_lab/Diego/data/TCNData/Traces_20180918T154235.h5'
    # data_path = '/n/holylfs02/LABS/olveczky_lab/Diego/data/TCNData/TCN_20180905T134346.h5'
    f = h5py.File(data_path, 'r')
    markers = np.array(f['markers'][:]).T
    marker_means = np.array(f['marker_means'][:]).T
    marker_stds = np.array(f['marker_stds'][:]).T
    bad_frames = np.array(f['bad_frames'][:]).T

    return markers, marker_means, marker_stds, bad_frames

def get_ids(bad_frames, input_length, output_length, only_good_inputs = False, only_good_outputs = False):
    """
    Get the sequences of indices to use for network training.

    Inputs:
    bad_frames - Logical or integer matrix denoting frames in which there were marker errors. Same size as markers.
                 0 when marker j is a good recording at frame i, 1 otherwise.
    input_length - Number of frames to input to the model.
    output_length - Number of frames the model will attempt to predict.

    Optional:
    only_good_inputs - Only return samples in which there are no bad frames in the input sequence. Default: False
    only_good_outputs - Only return samples in which there are no bad frames in the output sequence. Default: False

    Outputs:
    input_ids - N x input_length integer matrix of input ids.
    output_ids - N x output_length integer matrix of output ids.

    """
    # Find all of the good frames
    n_bad_markers = np.sum(bad_frames,1)
    good_frames = np.where(n_bad_markers == 0)[0]
    good_frames = good_frames[(good_frames > input_length) & (good_frames < (bad_frames.shape[0]-output_length))]

    # Save the preceding input_length ids before that frame
    input_ids = np.zeros([good_frames.shape[0],input_length],'int32')
    output_ids = np.zeros([good_frames.shape[0],output_length],'int32')

    for i in range(input_ids.shape[0]):
        input_ids[i,:] = range(good_frames[i]-input_length,good_frames[i])
        output_ids[i,:] = range(good_frames[i],good_frames[i]+output_length)

    # Remove all samples that have bad frames in the input
    if only_good_inputs:
        n_bad_markers_all = n_bad_markers[input_ids];
        is_bad_input = n_bad_markers_all != 0
        is_bad_sample = np.any(is_bad_input,axis=1)
        input_ids = input_ids[~is_bad_sample,:]
        output_ids = output_ids[~is_bad_sample,:]

    # Remove all samples that have bad frames in the output
    if only_good_outputs:
        n_bad_markers_all = n_bad_markers[output_ids];
        is_bad_output = n_bad_markers_all != 0
        is_bad_sample = np.any(is_bad_output,axis=1)
        input_ids = input_ids[~is_bad_sample,:]
        output_ids = output_ids[~is_bad_sample,:]

    return input_ids, output_ids

def asymmetric_temporal_padding(x, left_pad=1, right_pad=1):
    '''Pad the middle dimension of a 3D tensor
    with "left_pad" zeros left and "right_pad" right.
    '''
    pattern = [[0, 0], [left_pad, right_pad], [0, 0]]
    return tf.pad(x, pattern)


def categorical_mean_squared_error(y_true, y_pred):
    """MSE for categorical variables."""
    return K.mean(K.square(K.argmax(y_true, axis=-1) -
                           K.argmax(y_pred, axis=-1)))


class CausalAtrousConvolution1D(Conv1D):
    def __init__(self, filters, kernel_size, init='glorot_uniform', activation=None,
                 padding='valid', strides=1, dilation_rate=1, bias_regularizer=None,
                 activity_regularizer=None, kernel_constraint=None, bias_constraint=None, use_bias=True, causal=False, **kwargs):
        super(CausalAtrousConvolution1D, self).__init__(filters,
                                                        kernel_size=kernel_size,
                                                        strides=strides,
                                                        padding=padding,
                                                        dilation_rate=dilation_rate,
                                                        activation=activation,
                                                        use_bias=use_bias,
                                                        kernel_initializer=init,
                                                        activity_regularizer=activity_regularizer,
                                                        bias_regularizer=bias_regularizer,
                                                        kernel_constraint=kernel_constraint,
                                                        bias_constraint=bias_constraint,
                                                        **kwargs)

        self.causal = causal
        if self.causal and padding != 'valid':
            raise ValueError("Causal mode dictates border_mode=valid.")

    def compute_output_shape(self, input_shape):
        input_length = input_shape[1]

        if self.causal:
            input_length += self.dilation_rate[0] * (self.kernel_size[0] - 1)

        length = conv_output_length(input_length,
                                    self.kernel_size[0],
                                    self.padding,
                                    self.strides[0],
                                    dilation=self.dilation_rate[0])

        return (input_shape[0], length, self.filters)

    def call(self, x):
        if self.causal:
            x = asymmetric_temporal_padding(x, self.dilation_rate[0] * (self.kernel_size[0] - 1), 0)
        return super(CausalAtrousConvolution1D, self).call(x)
