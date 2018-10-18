function mbi_analyzePerformance(modelBasePath,dataPath,varargin)
%mbi_analyzePerformance - Wrapper for analyze_performance.py to run locally from matlab command line.  
%
% Syntax: mbi_analyzePerformance(dataPath);
%         mbi_analyzePerformance(dataPath,'Name','Value',...);
%
% Inputs:
%	 modelBasePath: Base path of model to be analyzed
%	 dataPath: Dataset to analyze
%
% Optional Name-Value Pairs:
%
%    Only accepts chars and does not check inputs.
% 
%	 model_name: Name of model to use within model_base_path
%	 default_input_length: Input length is determined by training_info.mat 
%                          in model_base_path. If this fails use default_input_length.
%	 testing_set_only: Use only samples from the model's testing set
%	 analyze_history: Make figure plotting training losses over time
%	 analyze_multi_prediction: Perform multiple prediction with replacement analysis
%	 load_training_info: Use training_info from model training.
%	 max_gap_length: Length of the longest gap to analyze during multipredict
%	 stride: Temporal downsampling rate
%	 skip: When calculating the error distribution over time, only take every
%          skip-th example trace to save time.
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
addRequired(p,'modelBasePath',validDatasetPath);
addRequired(p,'dataPath',validDatasetPath);
params = {'model_name','default_input_length','testing_set_only',...
          'analyze_history','analyze_multi_prediction','load_training_info',...
          'max_gap_length','stride','skip'};
for i = 1:numel(params)
    addParameter(p,params{i},'',@ischar)
end
parse(p,modelBasePath,dataPath,varargin{:});

%% Get optional parameters
specifiedParams = structfun(@(X) ~isempty(X), p.Results);
paramList = fieldnames(p.Results);
specifiedParams = paramList(specifiedParams);
specifiedParams(strcmp(specifiedParams,'dataPath')) = [];
specifiedParams(strcmp(specifiedParams,'modelBasePath')) = [];

%% Tokenize
commandTokens = cell(size(specifiedParams));
for i = 1:numel(specifiedParams)
    commandTokens{i} = [' --' strrep(specifiedParams{i},'_','-') '="' p.Results.(specifiedParams{i}) '"'];
end

%% Build the command
command = ['python analyze_performance.py ' modelBasePath ' ' dataPath cat(2,commandTokens{:})];

%% Execute
system(command)
end