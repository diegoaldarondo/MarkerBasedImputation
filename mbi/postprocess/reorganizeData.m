function reorganizeData(originalDirectory,imputationPath,copyOriginal)
%reorganizeData - Reorganize data files to fit Jesse's file structure.
%Finds the .mat files comprising the imputation, postprocesses the
%imputation data, and for each .mat file, saves a new v7.3 matfile containing
%the original information and imputed data reformatted to match the
%original structure. 
%
% Syntax: reorganizeData(originalDirectory,imputationPath,copy_original);
% 
% Inputs: originalDirectory - Path to directory containing original datasets.
%         Path to imputation file. 
%         imputationPath - Path to the imputation .h5 file.  
%         copyOriginal - Boolean determining whether or not to copy the
%         contents of the original mocap struct. 
%
% Notes: The new .mat file shares the same name as its original, but with
%        '_imputed' appended to the end of the file name. 
%
%        The new fields added to the .mat files are:
%        imputed_markers - Upsampled with linear interpolation
%        imputed_bad_frames_agg - Upsampled with repetition
%        remaining_bad_frames - Upsampled with repetition
%        
% Other m-files required: postprocessMBI.m, getRemainingBadFrames.m,
% diffpad.m
% 
% Author: Diego Aldarondo
% Work address
% email: diegoaldarondo@g.harvard.edu
% November 2018; Last revision: 12-November-2018
%------------- BEGIN CODE --------------
%% Get the original dataset paths
d = dir([originalDirectory '\*nolj.mat']);
out = regexp(cell2mat(regexp([d.name],'[0-9]*_nolj.mat','match')),...
             '[0-9]*','match');
id = zeros(size(out));
for i = 1:numel(out)
    id(i) = str2num(out{i});
end
[~,B] = sort(id);
mocap_paths = fullfile({d(B).folder},{d(B).name});

%% Get postprocessing data
fprintf('Postprocessing data\n')
[markersFinal,~,imputedFrames,remainingBadFrames] = postprocessMBI(imputationPath);

%% Put the appropriate chunk in the correct file. 
totalFramesRead = 1;
stride = 5;
for i = 1:numel(mocap_paths)
    fprintf('Reformatting %s\n',mocap_paths{i})
    mocap = load(mocap_paths{i});
    
    [numFrames, numMarkers] = size(struct2array(mocap.markers_preproc));
    imputed_markers = markersFinal(totalFramesRead:(totalFramesRead + round((numFrames/stride))-1),:);
    imputed_frames = imputedFrames(totalFramesRead:(totalFramesRead + round((numFrames/stride))-1),:);
    remaining_bad_frames = remainingBadFrames(totalFramesRead:(totalFramesRead + (numFrames/stride)-1));
    
    upsampled_imputed_frames = cell(size(imputed_frames,2));
    upsampled_imputed_markers = cell(size(imputed_frames,2));
    
    % Upsample...
    for j = 1:numMarkers
        upsampled_imputed_markers{j} = interp(imputed_markers(:,j),stride);
    end
    for j = 1:size(imputed_frames,2)
        upsampled_imputed_frames{j} = repelem(imputed_frames(:,j),stride,1);
    end
    imputed_markers = cat(2,upsampled_imputed_markers{:});
    imputed_frames = cat(2,upsampled_imputed_frames{:});
    
    % Copy the markernames in case user does not want to copy the original
    % and clear the mocap struct if that is the case. 
    markernames = mocap.markernames;
    if ~copyOriginal
        clear mocap
    end
    
    % Add the new data to the structure
    mocap.remaining_bad_frames = repelem(remaining_bad_frames,stride,1);
    
    % Reformat to Jesse's structures. 
    for j = 1:numel(markernames)
        mocap.imputed_markers.(markernames{j}) =...
            imputed_markers(:,(j-1)*3 + (1:3));
        mocap.imputed_bad_frames_agg{j} = find(imputed_frames(:,j));
    end
    
    % Save out 
    savePath = [mocap_paths{i}(1:end-4)  '_imputed.mat'];
    save(savePath,'-struct','mocap','-v7.3');
    totalFramesRead = totalFramesRead + round(numFrames/stride);
end