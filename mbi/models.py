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
from keras import layers
from keras.layers import Input, Conv1D, Dense, Dropout, Lambda, Permute, LSTM
from keras.optimizers import Adam
from keras.regularizers import l2
from keras.utils import multi_gpu_model
from utils import load_dataset, get_ids, CausalAtrousConvolution1D, asymmetric_temporal_padding, categorical_mean_squared_error

def wave_net(lossfunc,lr,input_length,output_length,n_markers,n_filters,filter_width,layers_per_level,n_dilations,print_summary = False):

#     n_markers = 60
#     n_filters = 512
#     filter_width = 2
#     layers_per_level = 3;

    # Set the dilations
    if n_dilations is None:
        n_dilations = np.int32(np.floor(np.log2(input_length)))
    else:
        n_dilations = int(n_dilations)
    dilation_rates = [2**i for i in range(n_dilations)]

    # Specify the Input
    history_seq = Input(shape=(input_length,n_markers))
    x = history_seq

    # Dilated causal convolutions
    for dilation_rate in dilation_rates:
        for i in range(layers_per_level):
            x = Conv1D(filters=n_filters,
                       kernel_size=filter_width,
                       padding='causal',
                       dilation_rate=dilation_rate)(x)

    # Dense connections
    x = Dense(60)(x)
    x = Permute([2,1])(x)
    x = Dense(output_length)(x)
    x = Permute([2,1])(x)

    model = Model(history_seq, x)
    model.compile(optimizer=Adam(lr=lr), loss=lossfunc, metrics=['mse'])
    if print_summary:
        model.summary()

    return model

def wave_net_res_skip(lossfunc, lr, input_length, n_filters, n_markers, n_dilations, layers_per_level, filter_width, use_skip_connections=True,
                learn_all_outputs = False, use_bias = True, res_l2 = .01, final_l2 = .01, print_summary=False):
    # def residual_block(x):
    #     original_x = x
    #     # TODO: Look up the implementation details for layers_per_level and n_dilations
    #     # Note: The AtrousConvolution1D with the 'causal' flag is implemented in github.com/basveeling/keras#@wavenet.
    #     tanh_out = CausalAtrousConvolution1D(n_filters, filter_width, dilation_rate=2 ** i, padding='valid', causal=True,
    #                                          use_bias=use_bias,
    #                                          name='dilated_conv_%d_tanh_s%d' % (2 ** i, s), activation='tanh',
    #                                          kernel_regularizer=l2(res_l2))(x)
    #     sigm_out = CausalAtrousConvolution1D(n_filters, filter_width, dilation_rate=2 ** i, padding='valid', causal=True,
    #                                          use_bias=use_bias,
    #                                          name='dilated_conv_%d_sigm_s%d' % (2 ** i, s), activation='sigmoid',
    #                                          kernel_regularizer=l2(res_l2))(x)
    #     x = layers.Multiply(name='gated_activation_%d_s%d' % (i, s))([tanh_out, sigm_out])
    #
    #     res_x = layers.Convolution1D(n_filters, 1, padding='same', use_bias=use_bias,
    #                                  kernel_regularizer=l2(res_l2))(x)
    #     skip_x = layers.Convolution1D(n_filters, 1, padding='same', use_bias=use_bias,
    #                                   kernel_regularizer=l2(res_l2))(x)
    #     res_x = layers.Add()([original_x, res_x])
    #     return res_x, skip_x

    def residual_block(x):
        original_x = x
        # TODO: Look up the implementation details for layers_per_level and n_dilations
        x = Conv1D(filters=n_filters,
                   kernel_size=filter_width,
                   padding='causal', name='dilated_conv_%d_s%d_01' % (2 ** i, s),
                   dilation_rate=2**i)(x)
        res_x = Conv1D(filters=n_filters,
                   kernel_size=filter_width,
                   padding='causal', name='dilated_conv_%d_s%d_02' % (2 ** i, s),
                   dilation_rate=2**i)(x)
        res_x = Conv1D(filters=n_filters,
                   kernel_size=filter_width,
                   padding='causal', name='dilated_conv_%d_s%d_03' % (2 ** i, s),
                   dilation_rate=2**i)(res_x)
        skip_x = Conv1D(n_filters, 1, padding='same', use_bias=use_bias, kernel_regularizer=l2(res_l2))(x)
        res_x = layers.Add()([original_x, res_x])
        return res_x, skip_x
    # Set the dilations
    if n_dilations is None:
        n_dilations = np.int32(np.floor(np.log2(input_length)))
    else:
        n_dilations = int(n_dilations)
    input = Input(shape=(input_length, n_markers), name='input_part')
    out = input
    skip_connections = []
    out = Conv1D(n_filters, filter_width,
                            dilation_rate=1,
                            padding='causal',
                            name='initial_causal_conv'
                            )(out)
    # for s in range(layers_per_level):
    #     for i in range(0, n_dilations + 1):
    #         out, skip_out = residual_block(out)
    #         skip_connections.append(skip_out)
    for i in range(0, n_dilations + 1):
        for s in range(layers_per_level):
            out, skip_out = residual_block(out)
            skip_connections.append(skip_out)

    # if use_skip_connections:
        # out = layers.Add()(skip_connections)
    # out = layers.Activation('relu')(out)
    # out = layers.Convolution1D(n_markers, 1, padding='same',
    #                            kernel_regularizer=l2(final_l2))(out)
    # out = layers.Activation('relu')(out)
    # out = layers.Convolution1D(n_markers, 1, padding='same')(out)
    out = Dense(n_markers)(out)
    out = Permute([2,1])(out)
    out = Dense(1)(out)
    out = Permute([2,1])(out)

    if not learn_all_outputs:
        # raise DeprecationWarning('Learning on just all outputs is wasteful, now learning only inside receptive field.')
        out = layers.Lambda(lambda x: x[:, -1, :], output_shape=(out._keras_shape[-1],))(
            out)  # Based on gif in deepmind blog: take last output?

    # out = layers.Activation('softmax', name="output_softmax")(out)
    model = Model(input, out)
    model.compile(optimizer=Adam(lr=lr), loss=lossfunc, metrics=['mse'])
    if print_summary:
        model.summary()
    # receptive_field, receptive_field_ms = compute_receptive_field()

    # _log.info('Receptive Field: %d (%dms)' % (receptive_field, int(receptive_field_ms)))
    return model


def lstm_model(lossfunc,lr,input_length,n_markers,latent_dim,print_summary = False):

    inputs1 = Input(shape = (input_length, n_markers))
    encoded1 = LSTM(latent_dim,return_sequences=True)(inputs1)
    encoded1 = LSTM(latent_dim,return_sequences=True)(encoded1)
    encoded1 = LSTM(latent_dim,return_sequences=False)(encoded1)
    encoded = Dense(n_markers)(encoded1)

    model = Model(inputs1, encoded)
    model.compile(optimizer=Adam(lr=lr), loss=lossfunc, metrics=['mse'])

    if print_summary:
        model.summary()

    return model

def conv_lstm(lossfunc,lr,input_length,output_length,n_markers,n_filters,filter_width,layers_per_level,n_dilations,latent_dim,print_summary = False):

#     n_markers = 60
#     n_filters = 512
#     filter_width = 2
#     layers_per_level = 3;

    # Set the dilations
    if n_dilations is None:
        n_dilations = np.int32(np.floor(np.log2(input_length)))
    else:
        n_dilations = int(n_dilations)
    dilation_rates = [2**i for i in range(n_dilations)]

    # Specify the Input
    history_seq = Input(shape=(input_length,n_markers))
    x = history_seq

    # Dilated causal convolutions
    for dilation_rate in dilation_rates:
        for i in range(layers_per_level):
            x = Conv1D(filters=n_filters,
                       kernel_size=filter_width,
                       padding='causal',
                       dilation_rate=dilation_rate)(x)

    encoded1 = LSTM(latent_dim,return_sequences=False)(x)

    # Dense connections
    x = Dense(60)(x)
    x = Permute([2,1])(x)
    x = Dense(output_length)(x)
    x = Permute([2,1])(x)

    model = Model(history_seq, x)
    model.compile(optimizer=Adam(lr=lr), loss=lossfunc, metrics=['mse'])
    if print_summary:
        model.summary()

    return model
