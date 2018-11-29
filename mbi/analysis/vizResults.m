% Vizualize results
% Demonstrates how to use Animal class to view marker imputations
% Diego Aldarondo
%% Pathing
addpath(genpath('C:\code\Olveczky\OlveczkyToolbox'))
addpath(genpath('C:/code/talmos-toolbox'))
addpath(genpath('C:/code/Olveczky/MarkerBasedImputation/mbi'))

% imputationPath = 'Y:\Diego\data\JDM25_caff_imputation_test\predictions\diffThreshTest\fullDay_model_ensemble.h5';
% imputationPath = 'Y:\Diego\data\JDM31_imputation_test\predictions\strideTest_thresh_5\fullDay_model_ensemble.h5';
imputationPath = 'Y:\Diego\data\JDM33\20171124\predictions\thresh_5\fullDay_model_ensemble.h5';

% embeddingPath = 'Y:\Diego\data\JDM25_caff_imputation_test\analysisstructs\analysisstruct.mat';
% temp = load(embeddingPath,'zValues','condition_inds','frames_with_good_tracking');
% embedFrames = round(temp.frames_with_good_tracking{2}/5);
% embed = temp.zValues(temp.condition_inds==2,:);

%% Construct the rat
% rat = Animal('path',imputationPath,'skeleton',skeleton,'embed',embed,'embedFrames',embedFrames);
rat = Animal('path',imputationPath);

%% Postprocess
rat.postProcess();

%% View trajectories of markers
close all;
frameIds = 100000:102500;
markerIds = find(repelem(contains(skeleton.nodes,{'Arm','Elbow'}),3,1));
rat.compareTraces(frameIds,markerIds);

%% View the rat and embedding simultaneously
% close all;
figure; 
% markersets = {'aligned','imputed','embed'};
markersets = {'aligned','imputed'};
% markersets = {'aligned','imputed','global'};
h = rat.movie(markersets);

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
frameIds = [98931:103931];
savePath = 'C:\code\Olveczky\MotionAnalysis\viz\videos\fullDay_waveNet_thresh_5_.mp4';
rat.writeMovie(markersets,frameIds,savePath,'FPS',60);