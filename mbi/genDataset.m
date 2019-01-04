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
% October 2018; Last revision: 26-November-2018

%------------- BEGIN CODE --------------

%% Load the Data
% Variables to look for. 
vars = {'markers_aligned_preproc','bad_frames_agg','move_frames',...
        'move_frames_fast'};

mocapData = cell(numel(mocapPaths),1);
parfor i = 1:numel(mocapPaths)
    lastwarn('') % Clear last warning message
    fprintf('Loading file %d\n',i)
    mocapData{i} = load(mocapPaths{i},vars{:});
    [warnMsg, warnId] = lastwarn;
    % Handle warnings if the fields dont exist
    if ~isempty(warnMsg)
        try
            % Try to see if the struct is nested
            temp = load(mocapPaths{i});
            temp = temp.mocap_struct;
            for j = 1:numel(vars)
                mocapData{i}.(vars{j}) = temp.(vars{j});
            end
        catch
            % Otherwise forget about that file and move on. 
            mocapData{i} = [];
            mocapPaths{i} = [];
        end
    end
end
mocapData(cellfun(@isempty, mocapData)) = [];
mocapPaths(cellfun(@isempty, mocapPaths)) = [];

%% Extract the aligned markers
[markers, bad_frames, move_frames, move_frames_fast] = deal(cell(numel(mocapPaths),1));
for i = 1:numel(mocapPaths)
    fprintf('Processing file %d\n',i)
    
    % These catch statements may be unneccessary. Check.  
    try
        markers{i} = struct2array(mocapData{i}.markers_aligned_preproc);
        bad_frames{i} = false(size(markers{i},1), size(markers{i},2)./3);

        % Express bad_frames as a logical matrix rather than integer indexing.
        for j = 1:numel(mocapData{i}.bad_frames_agg)
            bad_frames{i}(mocapData{i}.bad_frames_agg{j},j) = true;
        end
        
        move_frames{i} = false(size(markers{i},1), 1);
        move_frames_fast{i} = false(size(markers{i},1), 1);
        move_frames{i}(mocapData{i}.move_frames,:) = true;
        move_frames_fast{i}(mocapData{i}.move_frames_fast,:) = true;
    catch
        markers{i} = struct2array(mocapData(i).markers_aligned_preproc);
        bad_frames{i} = false(size(markers{i},1), size(markers{i},2)./3);

        % Express bad_frames as a logical matrix rather than integer indexing.
        for j = 1:numel(mocapData(i).bad_frames_agg)
            bad_frames{i}(mocapData(i).bad_frames_agg{j},j) = true;
        end
        
        move_frames{i} = false(size(markers{i},1), 1);
        move_frames_fast{i} = false(size(markers{i},1), 1);
        move_frames{i}(mocapData(i).move_frames,:) = true;
        move_frames_fast{i}(mocapData(i).move_frames_fast,:) = true;
    end
    mocapData{i} = [];
end

% Concatenate all data
markers = cat(1, markers{:});
bad_frames = uint8(cat(1,bad_frames{:}));
move_frames = uint8(cat(1,move_frames{:}));
move_frames_fast = uint8(cat(1,move_frames_fast{:}));

% If there exists only a single elbow/arm marker, treat both as bad.
larm = [11 12];
rarm = [15 16];
new_bad_frames = bad_frames;
new_bad_frames(:,larm) = repmat(any(bad_frames(:,larm),2),1,2);
new_bad_frames(:,rarm) = repmat(any(bad_frames(:,rarm),2),1,2);
bad_frames = new_bad_frames;

%% Put in some values for the nans
% (Otherwise the model will fail if nans aren't accounted for in
% badFrames, which happens in some datasets). These are taken out later.  
markers(logical(repelem(bad_frames,1,3))) = nan;
marker_means = nanmean(markers,1);
marker_stds = nanstd(markers,1);
for i = 1:size(markers,2)
    markers(isnan(markers(:,i)),i) = marker_means(i);
end

%% Normalize the values across time.
markers = (markers-marker_means)./marker_stds;
markers(isnan(markers)) = 0;

%% Save the files used to a mat file within the base directory
fn = fileparts(savePath);
save(fullfile(fn,'mocapPaths.mat'),'mocapPaths');

%% Save the data to an h5 file
compressionLevel = 9; % GZIP compression 0-9: 9 is max
h5save(savePath,markers,'markers','ChunkSize',[1000 60],'Deflate',compressionLevel)
h5save(savePath,bad_frames,'bad_frames','ChunkSize',[1000 20],'Deflate',compressionLevel)
h5save(savePath,marker_means,'marker_means')
h5save(savePath,marker_stds,'marker_stds')
h5save(savePath,move_frames,'move_frames')
h5save(savePath,move_frames_fast,'move_frames_fast')
end
