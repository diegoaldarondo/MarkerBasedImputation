function badFrames = applySpineDistThreshold(preds,varargin)
%applySpineDistThreshold - Detect the remaining bad frames given marker predictions.
%
% Syntax: badFrames = applySpineDistThreshold(preds);
%         badFrames = applySpineDistThreshold(preds,distThresh);
%
% Inputs:
%    preds - numFrames x numMarkers matrix of marker predictions.
%
% Optional Inputs:
%    distThresh - dist threshold above which to trigger
%                    bad frame. Default 60
%
% Outputs:
%    badFrames - numFrames x 1 dimensional logical vector denoting the bad
%    frames
%
% Example:
%    applySpineDistThreshold(preds);
%    applySpineDistThreshold(preds,distThresh);
%
% Author: Diego Aldarondo
% Work address
% email: diegoaldarondo@g.harvard.edu
% NOvember 2018; Last revision: 28-November-2018

%------------- BEGIN CODE --------------

% Preamble
numvarargs = length(varargin);
if numvarargs > 1
    error('myfuns:somefun2Alt:TooManyInputs', ...
        'Accepts at most 1 optional inputs');
end
optargs = {60};
optargs(1:numvarargs) = varargin;
distThresh = optargs{:};

%TODO: Skeletonize
mIds = 10:15;

% Get the spine markers
spineMarkers = preds(:,mIds);
M1 = spineMarkers(:,1:3);
M2 = spineMarkers(:,4:6);

% Compute the distance. 
spineDistance = sqrt(sum((M1 - M2).^2,2));

% Threshold
badFrames = (spineDistance > distThresh);
end