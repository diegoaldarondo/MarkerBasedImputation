function mbi_trainNetwork(dataPath,varargin)
%mbi_trainNetwork - Wrapper for training.py to train locally from matlab command line.  
%
% Syntax: mbi_trainNetwork(dataPath);
%         mbi_trainNetwork(dataPath,'Name','Value',...);
%
% Inputs:
%    dataPath -  Path to an HDF5 file with marker data. 
%
% Optional Name-Value Pairs:
%
%    Only accepts chars and does not check inputs.
%
%    base_output_path: Path to folder in which the run data folder will be
%                      saved. Default 'models'
% 
%    run_name: Name of the training run. If not specified, will be
%              formatted according to other parameters. 
% 
%    data_name: Name of the dataset for use in formatting run_name
% 
%    net_name: Name of the network for use in formatting run_name. 
%              Can be 'wave_net', 'lstm_model', or 'wave_net_res_skip'. 
%              Default 'wave_net'. 
% 
%    clean: If True, deletes the contents of the run output path. Default
%           False
% 
%    input_length: Number of frames to input into model. Default 9
% 
%    output_length: Number of frames model will attempt to predict. Default 1
% 
%    n_markers: Number of markers to use. Default 60
% 
%    train_fraction: Fraction of dataset to use as training. Default .85
% 
%    val_fraction: Fraction of dataset to use as validation. Default .15
% 
%    filter_width: Width of base convolution filter. Default 2.
% 
%    layers_per_level: Number of layers to use at each convolutional block.
%                      Default 3.
% 
%    n_dilations: Number of dilations for wavenet filters. 
%                 (See models.wave_net)
% 
%    latent_dim: Number of latent dimensions in 'lstm_model'. Default 750
% 
%    n_filters: Number of filters to use as baseline (see create_model)
% 
%    epochs: Number of epochs to train for. Default 50
% 
%    batch_size: Number of samples per batch. Default 1000
% 
%    batches_per_epoch: Number of batches per epoch (validation is
%                       evaluated at the end of the epoch). Default 0.
% 
%    val_batches_per_epoch: Number of batches for validation. Default 0
% 
%    reduce_lr_factor: Factor to reduce the learning rate by (see ReduceLROnPlateau)
% 
%    reduce_lr_patience: How many epochs to wait before reduction (see ReduceLROnPlateau)
% 
%    reduce_lr_min_delta: Minimum change in error required before reducing LR (see ReduceLROnPlateau)
% 
%    reduce_lr_cooldown: How many epochs to wait after reduction before LR can be reduced again (see ReduceLROnPlateau)
% 
%    reduce_lr_min_lr: Minimum that the LR can be reduced down to (see ReduceLROnPlateau)
% 
%    save_every_epoch: Save weights at every epoch. If False, saves only initial, final and best weights.
%
% Example: 
%    mbi_trainNetwork(dataPath);
%    mbi_trainNetwork(dataPath,'input_length',16,'net_name','lstm_model');
%
%
% Author: Diego Aldarondo
% Work address: 
% email: diegoaldarondo@g.harvard.edu
% October 2018; Last revision: 18-October-2018

%------------- BEGIN CODE --------------
%% Parse inputs
p = inputParser;
validDatasetPath = @(x) (ischar(x) || isstring(x)) && (exist(x,'file') == 2);
addRequired(p,'dataPath',validDatasetPath);
params = {'base_output_path','run_name','data_name','net_name','clean','input_length',...
    'output_length','n_markers','train_fraction','val_fraction','filter_width',...
    'layers_per_level','n_dilations','latent_dim','n_filters','epochs','batch_size',...
    'batches_per_epoch','val_batches_per_epoch','reduce_lr_factor','reduce_lr_patience',...
    'reduce_lr_min_delta','reduce_lr_cooldown','reduce_lr_min_lr','save_every_epoch'};
for i = 1:numel(params)
    addParameter(p,params{i},'',@ischar)
end
parse(p,dataPath,varargin{:});

%% Get optional parameters
specifiedParams = structfun(@(X) ~isempty(X), p.Results);
paramList = fieldnames(p.Results);
specifiedParams = paramList(specifiedParams);
specifiedParams(strcmp(specifiedParams,'dataPath')) = [];

%% Tokenize
commandTokens = cell(size(specifiedParams));
for i = 1:numel(specifiedParams)
    commandTokens{i} = [' --' strrep(specifiedParams{i},'_','-') '="' p.Results.(specifiedParams{i}) '"'];
end

%% Build the command
command = ['python training.py ' dataPath cat(2,commandTokens{:})];

%% Execute
system(command)
end