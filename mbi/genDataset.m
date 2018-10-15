function genDataset(mocapPaths, savePath)
%genDataset - Generate an h5 dataset for MBI from MoCap structs. 
%
% Syntax: genDataset(mocapPaths, savePath)
%
% Inputs:
%    mocapPaths - Cell array of paths to mat files with mocap structs. 
%    savePath   - Output path for h5 file. 
%
% Example: 
%    mocapPaths = {'myMocapStruct1.mat','myMocapStruct2.mat'};
%    savePath = 'myDataset.h5';
%    genDataset(mocapPaths,savePath)
%
% Other m-files required: h5save.m
%
% Author: Diego Aldarondo
% Work address
% email: diegoaldarondo@g.harvard.edu
% October 2018; Last revision: 15-October-2018

%------------- BEGIN CODE --------------

%% Load the Data

mocap_data = cellfun(@(X) load(X), mocapPaths,'uni',0);

%% Extract the aligned markers
[markers, bad_frames] = deal(cell(numel(mocapPaths),1));
for i = 1:numel(mocapPaths)
    markers{i} = struct2array(mocap_data{i}.markers_aligned_preproc);
    bad_frames{i} = false(size(markers{i},1), size(markers{i},2)./3);
    
    % Express bad_frames as a logical matrix rather than integer indexing.
    for j = 1:numel(mocap_data{i}.bad_frames_agg)
        bad_frames{i}(mocap_data{i}.bad_frames_agg{j},j) = true;
    end
end

% Concatenate all data
markers = cat(1, markers{:});
marker_means = nanmean(markers,1);
marker_stds = nanstd(markers,1);
bad_frames = uint8(cat(1,bad_frames{:}));

%% Put in some values for the nans 
% (Otherwise the model will fail if nans aren't accounted for in 
%  badFrames, which happens in some datasets) 
for i = 1:size(markers,2)
    markers(isnan(markers(:,i)),i) = marker_means(i);
end

%% Normalize the values across time. 
markers = zscore(markers,1);

%% Save the data to an h5 file
h5save(savePath,markers,'markers')
h5save(savePath,bad_frames,'bad_frames')
h5save(savePath,marker_means,'marker_means')
h5save(savePath,marker_stds,'marker_stds')
end