%% Look at OOB error 
imputationPath = 'Y:\Diego\data\JDM31_imputation_test\predictions\strideTest_thresh_5\fullDay_model_ensemble.h5';
nFrames = 100000;
nMarkers = 60;
nMembers = 10;
memberPredsF = h5read(imputationPath,'/member_predsF',[1 1 1],[nMarkers nFrames nMembers]);
memberPredsR = h5read(imputationPath,'/member_predsR',[1 1 1],[nMarkers nFrames nMembers]);
% memberPredsF = h5read(imputationPath,'/member_predsF');
% memberPredsR = h5read(imputationPath,'/member_predsR');
skeletonPath = 'Y:\Diego\data\JDM25_caff_imputation_test\skeleton.mat';
load(skeletonPath);
%% Nan out the frames in which there was no imputation, and compute the std. 
memberPredsF(memberPredsF == 0) = nan;
memberPredsR(memberPredsR == 0) = nan;

notPredictedF = isnan(memberPredsF(:,:,1));
notPredictedR = isnan(memberPredsR(:,:,1));

for i = 1:size(notPredictedF,1)
    disp(i)
    memberPredsF(i,notPredictedF(i,:),:) = nan;
    memberPredsR(i,notPredictedR(i,:),:) = nan;
end

mpfStd = nanstd(memberPredsF,[],3);
mprStd = nanstd(memberPredsR,[],3);

%% Look at the stds over time for the forward and reverse predictions
% close all
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
totStd = mpfStd+mprStd;
% close all
figure;
cLimVal = .1;
imagesc(totStd); 
caxis([0 cLimVal]);
title(sprintf('reverse + forward std'));

%% Look at the cumulative distribution of total std as a function of std threshold
thresholds = 0:.05:200;
% thresholds = 0:.001:3;
fracBelow = zeros(size(thresholds));
total = nansum(totStd);
for i = 1:numel(thresholds)
    fracBelow(i) = (nansum(total <= thresholds(i)) - sum(total==0))./sum(total==0);
end
figure; 
plot(thresholds,fracBelow)
xlabel('Tot Std Threshold')
ylabel('Fraction imputed frames below threshold')

%% Look at the cumulative distribution of mean std as a function of std threshold
% thresholds = 0:.05:200;
thresholds = 0:.001:3;
fracBelow = zeros(size(thresholds));
total = nanmean(totStd);
for i = 1:numel(thresholds)
    fracBelow(i) = nansum(total <= thresholds(i))./sum(~isnan(total));
end
figure; 
plot(thresholds,fracBelow)
xlabel('Tot Std Threshold')
ylabel('Fraction imputed frames below threshold')

%% Look at the cumulative distribution of marker Std as a function of std threshold
% thresholds = 0:.05:200;
thresholds = 0:.001:3;
fracBelow = zeros(numel(thresholds),size(totStd,1));
for iMarker = 1:size(totStd,1)
    disp(iMarker)
    marker = totStd(iMarker,:);
    for iThresh = 1:numel(thresholds)
        fracBelow(iThresh,iMarker) = nansum(marker <= thresholds(iThresh))./sum(~isnan(marker));
    end
end
%%
headIds = repelem(contains(skeleton.nodes,{'Head'}),3,1);
bodyIds = repelem(contains(skeleton.nodes,{'Spine','Offset','Shoulder','Hip'}),3,1);
legIds = repelem(contains(skeleton.nodes,{'Knee','Shin'}),3,1);
armIds = repelem(contains(skeleton.nodes,{'Arm','Elbow'}),3,1);
colors = zeros(numel(skeleton.nodes)*3,3);
c = lines(4);
colors(headIds,:) = repelem(c(1,:),sum(headIds),1);
colors(bodyIds,:) = repelem(c(2,:),sum(bodyIds),1);
colors(legIds,:) = repelem(c(3,:),sum(legIds),1);
colors(armIds,:) = repelem(c(4,:),sum(armIds),1);

figure; 
p = plot(thresholds,fracBelow,'LineWidth',2);
for i = 1:numel(p)
    set(p(i), 'color', colors(i,:));  
end
xlabel('marker Std Threshold')
ylabel('Fraction imputed frames below threshold')
legend(p([find(headIds,1),find(bodyIds,1),find(legIds,1),find(armIds,1)]),{'Head','Body','Legs','Arms'})

%% Aggregate the total STD into a video
vid = reshape(totStd,60,1,[]);
vid(vid > .5) = .5;s

%%
% vplay(vid>=.25,{@(~,idx) set(h{1},'frame',idx)})
vplay(vid>=.25,{@(~,idx) set(h{1},'frame',idx),
                @(~,idx) set(h{2},'frame',idx)})
         

