% Vizualize results
%
% Diego Aldarondo
%% Pathing
addpath(genpath('C:\code\Olveczky\OlveczkyToolbox'))
addpath(genpath('C:/code/talmos-toolbox'))
addpath(genpath('C:/code/Olveczky/MarkerBasedImputation/mbi'))

imputationPath = 'Y:\Diego\data\JDM25_caff_imputation_test\predictions\diffThreshTest\fullDay_model_ensemble.h5';
skeletonPath = 'Y:\Diego\data\JDM25_caff_imputation_test\skeleton.mat';
load(skeletonPath);

embeddingPath = 'Y:\Diego\data\JDM25_caff_imputation_test\analysisstructs\analysisstruct.mat';
temp = load(embeddingPath,'zValues','condition_inds','frames_with_good_tracking');
embedFrames = round(temp.frames_with_good_tracking{2}/5);
embed = temp.zValues(temp.condition_inds==2,:);

%% Construct the rat
rat = Animal('path',imputationPath,'skeleton',skeleton,'embed',embed,'embedFrames',embedFrames);

%% Postprocess
rat.postProcess();

%% View the rat
markersets = {'aligned','imputed'};
rat.movie(markersets);

%% View the rat and the embedding simultaneously
markerset = {'aligned','imputed'};
rat.embedMovie(markerset)

%% Write a movie
frameIds = [98931:103931];
savePath = 'C:\code\Olveczky\MotionAnalysis\viz\videos\fullDay_waveNet_thresh_5.mp4';
rat.writeMovie(markersets,frameIds,savePath,'FPS',60);