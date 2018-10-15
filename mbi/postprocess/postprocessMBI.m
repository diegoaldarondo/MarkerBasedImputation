function [markersFinal,markersInitial,remainingBadFrames] = postprocessMBI(dataPath,varargin)
%postprocessMBI - Postprocess MBI marker predictions. 
%
% Syntax: [markersFinal,markersInitial] = postprocessMBI(dataPath);
%         [markersFinal,markersInitial] = postprocessMBI(dataPath, smoothingWindow);
%         [markersFinal,markersInitial] = postprocessMBI(dataPath, smoothingWindow, badFrameThreshold);
%         [markersFinal,markersInitial] = postprocessMBI(dataPath,
%         smoothingWindow, badFrameThreshold, badFrameSurround);
% 
% Inputs:
%    dataPath - Path to a .mat file created by impute_markers.py. 
%
% Optional Inputs: 
%    smoothingWindow - Number of frames to use in median smoothing. Default
%    5.
% 
%    badFrameThreshold - Threshold at which to trigger a bad frame. Default 0.6. 
%    Metric is the z-scored energy of jerk. For use in getRemainingBadFrames.m
% 
%    badFrameSurround - Number of surrounding frames to flag in the event of a
%    trigger. Default 150. For use in getRemainingBadFrames.m
% 
% Outputs:
%    markersFinal - Postprocessed marker positions. numFrames x numMarkers
%    markersInitial - Initial marker positions. numFrames x numMarkers
%    remainingBadFrames - remainingBadFrames after prediction. numFrames x
%    1
% 
% Example: 
%    [markersFinal,markersInitial,remainingBadFrames] = postprocessMBI(dataPath);
%    [markersFinal,markersInitial,remainingBadFrames] = postprocessMBI(dataPath,5);
%    [markersFinal,markersInitial,remainingBadFrames] = postprocessMBI(dataPath,5,.6);
%    [markersFinal,markersInitial,remainingBadFrames] = postprocessMBI(dataPath,5,.6,150);
% 
% Other m-files required: getRemainingBadFrames.m
%
% Author: Diego Aldarondo
% Work address
% email: diegoaldarondo@g.harvard.edu
% October 2018; Last revision: 15-October-2018

%------------- BEGIN CODE --------------

% Preamble
numvarargs = length(varargin);
if numvarargs > 3
    error('myfuns:somefun2Alt:TooManyInputs', ...
        'Accepts at most 3 optional inputs');
end
optargs = {5,.6,150};
optargs(1:numvarargs) = varargin;
[smoothingWindow,badFrameThreshold,badFrameSurround] = optargs{:};

% Load the data
load(dataPath,'markers','badFrames','preds');

% Add nans for the portions of the markers that were incorrect 
markers(logical(repelem(badFrames,1,3))) = nan;
for i = 1:size(markers,2)
    % Nan values were previously assigned the mean for ease of imputation.
    % Reassign to nans, except for SpineM
    if i >= 13 || i <= 15
        continue;
    end
    marker = markers(:,i);
    marker(marker == mode(marker)) = nan;
    markers(:,i) = marker;
end

% Smooth the predicitons
preds = smoothdata(preds,'movmedian',smoothingWindow);

% Get the remaining bad frames
remainingBadFrames = getRemainingBadFrames(preds,badFrameThreshold,badFrameSurround);

% Return markers
markersFinal = preds;
markersInitial = markers; 
end