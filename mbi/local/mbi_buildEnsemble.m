function mbi_buildEnsemble(ensembleBasePath,models_in_ensemble,varargin)
%mbi_buildEnsemble - Wrapper for build_ensemble.py to evaluate locally from matlab command line.  
%
% Syntax: mbi_buildEnsemble(ensembleBasePath,models);
%         mbi_buildEnsemble(ensembleBasePath,'Name','Value',...);
%
% Inputs:
%    ensembleBasePath - Base path in which to save ensemble. 
%    models_in_ensemble - Cell array of model paths to include in ensemble.  
%
% Optional Name-Value Pairs:
%
%    Only accepts chars and does not check inputs. 
%
%    return_member_data: If True, model will have two outputs: the ensemble 
%                        prediction and all member predictions.
%                        Please use 'True' or 'False' instead of true or false.
%                        Default 'True'
%    run_name: Name of the model run
%    clean: If True, deletes the contents of the run output path
%
% Example: 
%    mbi_buildEnsemble(ensembleBasePath,models);
%    mbi_buildEnsemble(ensembleBasePath,models,'return_member_data','True');
%
% Author: Diego Aldarondo
% Work address: 
% email: diegoaldarondo@g.harvard.edu
% October 2018; Last revision: 18-October-2018

%------------- BEGIN CODE --------------
%% Parse inputs
p = inputParser;
validFilePath = @(x) (ischar(x) || isstring(x)) && (exist(x,'file') == 2);
validModelPaths = @(x) ~any(~(iscell(x) & cellfun(validFilePath,x))); 
addRequired(p,'ensembleBasePath',validFilePath);
addRequired(p,'models_in_ensemble',validModelPaths);
params = {'return_member_data','run_name','clean'};
for i = 1:numel(params)
    addParameter(p,params{i},'',@ischar)
end
parse(p,ensembleBasePath,models_in_ensemble,varargin{:});

%% Get optional parameters
specifiedParams = structfun(@(X) ~isempty(X), p.Results);
paramList = fieldnames(p.Results);
specifiedParams = paramList(specifiedParams);
specifiedParams(strcmp(specifiedParams,'ensembleBasePath')) = [];
specifiedParams(strcmp(specifiedParams,'models_in_ensemble')) = [];

%% Tokenize
commandTokens = cell(size(specifiedParams));
for i = 1:numel(specifiedParams)
    commandTokens{i} = [' --' strrep(specifiedParams{i},'_','-') '="' p.Results.(specifiedParams{i}) '"'];
end

%% Add spaces for command
for i = 1:numel(models_in_ensemble)
    models_in_ensemble{i} = [models_in_ensemble{i} ' '];
end

%% Build the command
command = ['python build_ensemble.py ' ensembleBasePath ' ' cat(2,models_in_ensemble{:}) cat(2,commandTokens{:})];

%% Execute
system(command)
end