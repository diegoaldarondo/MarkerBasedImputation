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

%% Construct the rat
rat = Animal('path',imputationPath,'skeleton',skeleton);

%% Postprocess
rat.postProcess();

%% View the rat
markersets = {'aligned','imputed'};
rat.movie(markersets);