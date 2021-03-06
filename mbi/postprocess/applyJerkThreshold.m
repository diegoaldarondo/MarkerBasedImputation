function badFrames = applyJerkThreshold(preds,varargin)
%applyJerkThreshold - Detect the remaining bad frames given marker predictions. 
%
% Syntax: badFrames = applyJerkThreshold(preds);
%         badFrames = applyJerkThreshold(preds,threshold,surround);
%
% Inputs:
%    preds - numFrames x numMarkers matrix of marker predictions.
% 
% Optional Inputs:
%    threshold - Threshold at which to trigger a bad frame. Default 0.6. 
%    Metric is the z-scored energy of jerk (for now only of spineF).
% 
%    surround - Number of surrounding frames to flag in the event of a
%    trigger. Default 150.
%
% Outputs:
%    badFrames - numFrames x 1 dimensional logical vector denoting the bad 
%    frames 
% 
% Example: 
%    applyJerkThreshold(preds);
%    applyJerkThreshold(preds,threshold);
%    applyJerkThreshold(preds,threshold,surround);
%
% Other m-files required: diffpad.m
% 
% Author: Diego Aldarondo
% Work address
% email: diegoaldarondo@g.harvard.edu
% NOvember 2018; Last revision: 28-November-2018

%------------- BEGIN CODE --------------

% Preamble
numvarargs = length(varargin);
if numvarargs > 2
    error('myfuns:somefun2Alt:TooManyInputs', ...
        'Accepts at most 2 optional inputs');
end
optargs = {1 150};
optargs(1:numvarargs) = varargin;
[threshold, surround] = optargs{:};

% Calculate Jerk
jerk = diffpad(diffpad(diffpad(preds(:,[10,12]))));

% Get the z-score of total jerk energy
jerkEnergy = jerk.^2;
jerkEnergy = sum(jerkEnergy,2);
zJerkEnergy = zscore(jerkEnergy);

% maxFilter to also flag surrounding frames
zJerkEnergy = movmax(zJerkEnergy,surround);

% Find the bad frames
badFrames = zJerkEnergy>threshold;
end