function badFrames = applyHeadPdistThreshold(preds,varargin)
%applyHeadPdistThreshold - Detect the remaining bad frames given marker predictions. 
%
% Syntax: badFrames = applyHeadPdistThreshold(preds);
%         badFrames = applyHeadPdistThreshold(preds,lowHeadThresh,highHeadThresh);
%
% Inputs:
%    preds - numFrames x numMarkers matrix of marker predictions.
%
% Optional Inputs:
%    lowHeadThresh - sum of head pdist threshold below which to trigger
%                    bad frame. Default 75 
%    lowHeadThresh - sum of head pdist threshold above which to trigger
%                    bad frame. Default 100 
% Outputs:
%    badFrames - numFrames x 1 dimensional logical vector denoting the bad 
%    frames 
% 
% Example: 
%    applyHeadPdistThreshold(preds);
%    applyHeadPdistThreshold(preds,lowHeadThresh);
%    applyHeadPdistThreshold(preds,lowHeadThresh,highHeadThresh);
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
optargs = {75 100};
optargs(1:numvarargs) = varargin;
[lowHeadThresh, highHeadThresh] = optargs{:};

% TODO: skeletonize.
mIds = 1:9;

% Get the head markers
headMarkers = preds(:,mIds);
M1 = headMarkers(:,1:3);
M2 = headMarkers(:,4:6);
M3 = headMarkers(:,7:9);

% compute the sum of pairwise distances at each frame
D12 = sqrt(sum((M1 - M2).^2,2));
D13 = sqrt(sum((M1 - M3).^2,2));
D23 = sqrt(sum((M2 - M3).^2,2));
headDistance = D12 + D13 + D23;

% Threshold
badFrames = (headDistance < lowHeadThresh) |...
    (headDistance > highHeadThresh);
end