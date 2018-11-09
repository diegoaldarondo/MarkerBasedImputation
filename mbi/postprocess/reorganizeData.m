function reorganizeData(originalDirectory,imputationPath)
%reorganizeData - Reorganize data files to fit Jesse's file structure.
%Finds the .mat files comprising the imputation, postprocesses the
%imputation data, and for each .mat file, saves a new v7.3 matfile containing
%the original information and imputed data reformatted to match the
%original structure. 
%
% Syntax: reorganizeData(originalDirectory,imputationPath);
% 
% Inputs: originalDirectory - Path to directory containing original datasets.
%         Path to imputation file. 
%         imputationPath - Path to the imputation .h5 file.  
%
% Notes: The new .mat file shares the same name as its original, but with
%        '_imputed' appended to the end of the file name. 
%
%        The new fields added to the .mat files are:
%        imputed_markers
%        imputed_bad_frames_agg
%        remaining_bad_frames
%        
% Other m-files required: postprocessMBI.m, getRemainingBadFrames.m,
% diffpad.m
% 
% Author: Diego Aldarondo
% Work address
% email: diegoaldarondo@g.harvard.edu
% November 2018; Last revision: 09-November-2018

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
[markersFinal,~,imputedFrames,remainingBadFrames] = postprocessMBI(imputationPath);

%% Put the appropriate chunk in the correct file. 
totalFramesRead = 1;
for i = 1:numel(mocap_paths)
    orig = load(mocap_paths{i});
    
    [numFrames, numMarkers] = size(struct2array(orig.markers_preproc));
    imputed_markers = markersFinal(totalFramesRead:(totalFramesRead + numFrames-1),:);
    imputed_frames = imputedFrames(totalFramesRead:(totalFramesRead + numFrames-1),:);
    remaining_bad_frames = remainingBadFrames(totalFramesRead:(totalFramesRead + numFrames-1));
    
    for j = 1:numel(orig.markernames)
        orig.imputed_markers.(orig.markernames{j}) = imputed_markers(:,(j-1)*3 + (1:3));
        orig.imputed_bad_frames_agg{j} = find(imputed_frames(:,j));
    end
    orig.remaining_bad_frames = remaining_bad_frames;
    
    savePath = [mocap_paths{i}(1:end-4)  '_imputed.mat'];
    save(savePath,'-struct','orig','-v7.3');
    totalFramesRead = totalFramesRead + numFrames;
end