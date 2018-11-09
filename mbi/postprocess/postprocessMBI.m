function [markersFinal,markersInitial,imputedFrames,remainingBadFrames] = postprocessMBI(dataPath,varargin)
%postprocessMBI - Postprocess MBI marker predictions. 
%
% Syntax: [markersFinal,markersInitial,imputedFrames,remainingBadFrames] = postprocessMBI(dataPath);
%         [markersFinal,markersInitial,imputedFrames,remainingBadFrames] = postprocessMBI(dataPath, smoothingWindow);
%         [markersFinal,markersInitial,imputedFrames,remainingBadFrames] = postprocessMBI(dataPath, smoothingWindow, badFrameThreshold);
%         [markersFinal,markersInitial,imputedFrames,remainingBadFrames] = postprocessMBI(dataPath,
%         smoothingWindow, badFrameThreshold, badFrameSurround);
% 
% Inputs:
%    dataPath - Path to a .mat, .h5, or .hdf5 file created by 
%               impute_markers.py or merge.py. 
%
% Optional Inputs: 
%    smoothingWindow - Number of frames to use in median smoothing. Default
%    5.
% 
%    badFrameThreshold - Threshold at which to trigger a bad frame. 
%                        Default 1. Metric is the z-scored energy of 
%                        jerk. For use in getRemainingBadFrames.m
% 
%    badFrameSurround - Number of surrounding frames to flag in the event of a
%                       trigger. Default 150. For use in 
%                       getRemainingBadFrames.m
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
% October 2018; Last revision: 7-November-2018

%------------- BEGIN CODE --------------

% Preamble
numvarargs = length(varargin);
if numvarargs > 3
    error('myfuns:somefun2Alt:TooManyInputs', ...
        'Accepts at most 3 optional inputs');
end
optargs = {5,1,150};
optargs(1:numvarargs) = varargin;
[smoothingWindow,badFrameThreshold,badFrameSurround] = optargs{:};

% Load the data
[~,~,ext] = fileparts(dataPath);
switch lower(ext)
    case '.mat'
        load(dataPath,'markers','badFrames','preds');
    case {'.h5', '.hdf5'}
        markers = h5read(dataPath,'/markers')';
        preds = h5read(dataPath,'/preds')';
        badFrames = h5read(dataPath,'/badFrames')';
    otherwise
        error('Unexpected file extension: %s', ext);
end

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
for i = 1:size(badFrames,2)
    CC = bwconncomp(badFrames(:,i));
    markerIds = (i-1)*3 + (1:3);
    for j = 1:numel(CC.PixelIdxList)
        preds(CC.PixelIdxList{j},markerIds) =...
            smoothdata(preds(CC.PixelIdxList{j},markerIds),...
                       'movmedian',smoothingWindow);
    end
end

% Get the remaining bad frames
remainingBadFrames = getRemainingBadFrames(preds,badFrameThreshold,...
                                           badFrameSurround);
remainingBadFrames(find(badFrames(:,4))) = true;

% Return
imputedFrames = badFrames;
markersFinal = preds;
markersInitial = markers; 
end