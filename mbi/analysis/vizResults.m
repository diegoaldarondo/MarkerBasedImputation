% Vizualize results
% Demonstrates how to use Animal class to view marker imputations
% Diego Aldarondo
%% Pathing
addpath(genpath('C:\code\Olveczky\OlveczkyToolbox'))
addpath(genpath('C:/code/talmos-toolbox'))
addpath(genpath('C:/code/Olveczky/MarkerBasedImputation/mbi'))

% imputationPath = 'Y:\Diego\data\JDM25_caff_imputation_test\predictions\diffThreshTest\fullDay_model_ensemble.h5';
% imputationPath = 'Y:\Diego\data\JDM31_imputation_test\predictions\strideTest_thresh_5\fullDay_model_ensemble.h5';
% imputationPath = 'Y:\Diego\data\JDM33\20171124\predictions\thresh_5\fullDay_model_ensemble.h5';
% imputationPath = 'Y:\Diego\data\JDM27\20171207\predictions\fullDay_model_ensemble.h5';
imputationPath = 'Y:/Diego/data/JDM25/20170919/predictions/fullDay_model_ensemble.h5';
% imputationPath = 'Y:/Diego/data/JDM25/20170916/predictions/thresh_5/fullDay_model_ensemble.h5';

% datasetPath = 'Y:/Diego/data/JDM33/20171125/dataset.h5';
% embeddingPath = 'Y:\Diego\data\JDM25\20170916\analysisstructs\analysisstruct.mat';
% 
% temp = load(embeddingPath,'zValues','condition_inds','frames_with_good_tracking');
% nEmbeds = numel(temp.frames_with_good_tracking);
% [embedFrames,embed] = deal(cell(nEmbeds,1));
% for i = 1:nEmbeds
%     embedFrames{i} = round(temp.frames_with_good_tracking{i}/5);
%     embed{i} = temp.zValues(temp.condition_inds==i,:); 
% end
%% Construct the rat
% rat = Animal('path',imputationPath,'embed',embed,'embedFrames',embedFrames);
rat = Animal('path',imputationPath);

%% Postprocess
% rat.postProcess(5,1,1);
rat.postProcess();

%% View trajectories of markers
close all;
frameIds = 100000:102500;
skeleton = load('Y:/Diego/data/skeleton.mat');
skeleton = skeleton.skeleton;
markerIds = find(repelem(contains(skeleton.nodes,{'Arm','Elbow'}),3,1));
rat.compareTraces(frameIds,markerIds);

%% View the rat and embedding simultaneously
% close all;
figure; 
markersets = {'aligned','imputed'};
% markersets = {'aligned','imputed'};
% markersets = {'aligned','imputed','global'};
h = rat.movie(markersets,[1 2]);

%% restrict the frames in the movie to a subset of the whole. 
cellfun(@(X) X.restrict(find(any(isnan(rat.imputedMarkers),2) & (movingFastFrames(1:5:end) & ~badSpines))),h);
% % cellfun(@(X) X.restrict(find(jerkBadFrames & ~spineBadFrames)),h);
% cellfun(@(X) X.restrict(find(jbf2 & ~spineBadFrames)),h);s

%% Find frames moving above a certain velocity threshold
velocity = nansum(diffpad(rat.imputedMarkers),2);
velThresh = [200 250];
% velocity = nanmedian(diffpad(rat.imputedMarkers),2);
% velThresh = [4 10];
fast_moving = (velocity>velThresh(1)) & (velocity<velThresh(2));
fast_moving = movmax(fast_moving,50);
fIds = find(fast_moving);
cellfun(@(X) X.restrict(fIds),h);

figure; 
mIds = contains(rat.getNodes,{'Arm','Elbow','Shin','Hip','Head'});
rat.compareTraces(fIds,find(repelem(mIds,3,1)));

%% Look at distances of head markers
mIds = repelem(contains(rat.getNodes,{'Head'}),3,1);
headMarkers = rat.imputedMarkers(:,mIds);
M1 = headMarkers(:,1:3);
M2 = headMarkers(:,4:6);
M3 = headMarkers(:,7:9);
D12 = sqrt(sum((M1 - M2).^2,2));
D13 = sqrt(sum((M1 - M3).^2,2));
D23 = sqrt(sum((M2 - M3).^2,2));
headDistance = D12 + D13 + D23;
headThresh = [80 100];
badHeads = (headDistance < headThresh(1)) | (headDistance > headThresh(2));
cellfun(@(X) X.restrict(find(badHeads)),h);

%% Write a movie
temp = ~any(isnan(rat.imputedMarkers),2);
startFrames = 77179;
duration = 2500;
frameIds = find(temp(startFrames:(startFrames+duration))) + startFrames;
savePath = 'C:\code\Olveczky\MotionAnalysis\viz\videos\JDM25_20170916_fullDay_waveNet_thresh_5_unnanned_30fps_walking.mp4';
rat.writeMovie(markersets,frameIds,savePath,'FPS',30);