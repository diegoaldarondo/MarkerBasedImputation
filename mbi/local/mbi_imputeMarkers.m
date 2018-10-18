function mbi_imputeMarkers(modelPath,dataPath,varargin)
%mbi_imputeMarkers - Wrapper for impute_markers.py to evaluate locally from matlab command line.  
%
% Syntax: mbi_imputeMarkers(dataPath);
%         mbi_imputeMarkers(dataPath,'Name','Value',...);
%
% Inputs:
%    modelPath - Path to model to use for prediction. 
%    dataPath  - Path to an HDF5 file with marker data. 
%
% Optional Name-Value Pairs:
%
%    Only accepts chars and does not check inputs. 
%
%	 save_path: Path to .mat file where predictions will be saved.
%	 start_frame: Frame at which to begin imputation.
%	 n_frames: Number of frames to impute.
%	 stride: stride length between frames for faster imputation. Default 1.
%	 error_diff_thresh: Z-scored difference threshold marking suspicious frames
%
% Not implemented: 
%    markers_to_fix: Markers for which to override suspicious MoCap measurements
% 
% Example: 
%    mbi_imputeMarkers(dataPath);
%    mbi_imputeMarkers(dataPath,'save_path','mySavePath','stride','5');
%
%
% Author: Diego Aldarondo
% Work address: 
% email: diegoaldarondo@g.harvard.edu
% October 2018; Last revision: 18-October-2018

%------------- BEGIN CODE --------------
%% Parse inputs
p = inputParser;
validFilePath = @(x) (ischar(x) || isstring(x)) && (exist(x,'file') == 2);
addRequired(p,'modelPath',validFilePath);
addRequired(p,'dataPath',validFilePath);
params = {'save_path','start_frame','n_frames','stride','error_diff_thresh'};
for i = 1:numel(params)
    addParameter(p,params{i},'',@ischar)
end
parse(p,modelPath,dataPath,varargin{:});

%% Get optional parameters
specifiedParams = structfun(@(X) ~isempty(X), p.Results);
paramList = fieldnames(p.Results);
specifiedParams = paramList(specifiedParams);
specifiedParams(strcmp(specifiedParams,'dataPath')) = [];
specifiedParams(strcmp(specifiedParams,'modelPath')) = [];

%% Tokenize
commandTokens = cell(size(specifiedParams));
for i = 1:numel(specifiedParams)
    commandTokens{i} = [' --' strrep(specifiedParams{i},'_','-') '="' p.Results.(specifiedParams{i}) '"'];
end

%% Build the command
command = ['python impute_markers.py ' modelPath ' ' dataPath cat(2,commandTokens{:})];

%% Execute
system(command)
end