%% Look at OOB error 

imputationPath = 'Y:\Diego\data\JDM25_caff_imputation_test\predictions\strideTest_thresh_5\fullDay_model_ensemble.h5';
nFrames = 100000;
nMarkers = 60;
nMembers = 10;
memberPredsF = h5read(imputationPath,'/member_predsF',[1 1 1],[nMarkers nFrames nMembers]);
memberPredsR = h5read(imputationPath,'/member_predsR',[1 1 1],[nMarkers nFrames nMembers]);

%% Nan out the frames in which there was no imputation, and compute the std. 
memberPredsF(memberPredsF == 0) = nan;
memberPredsR(memberPredsR == 0) = nan;
mpfStd = nanstd(memberPredsF,[],3);
mprStd = nanstd(memberPredsR,[],3);

%% Look at the stds over time for the forward and reverse predictions
close all
figure; hold on; 
cLimVal = .1;
subplot(1,2,1);
imagesc(mpfStd); 
caxis([0 cLimVal]);
title(sprintf('Forward std'));

subplot(1,2,2);
imagesc(mprStd); 
caxis([0 cLimVal]);
title(sprintf('Reverse std'));

%% Look at the vector sum of both. 