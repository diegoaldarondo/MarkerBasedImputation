%% Analyze gaps and bad frames before and after MBI imputation.
% Produces six figures:
% 1. Fraction imputed frames per marker
% 2. Fraction imputed moving frames per marker
% 3. Fraction remaining bad frames per marker
% 4. Fraction remaining bad moving frames per marker
% 5. Before/After imputation comparison
% 6. Before/After imputation comparison moving
% Diego Aldarondo 12 3 18

% Required toolboxes
addpath(genpath('C:/code/Olveczky/MarkerBasedImputation/mbi'))
addpath(genpath('C:\code\Olveczky\OlveczkyToolbox\classes'))
addpath(genpath('C:/code/talmos-toolbox'))

% Set the output path for .png figures. 
exportPath = 'C:\code\Olveczky\MotionAnalysis\viz\LabMeeting12_10_18\badFramesAnalysis\';

%% Pathing
imputationPaths = {'Y:/Diego/data/JDM25/20170916/predictions/thresh_5/fullDay_model_ensemble.h5',...
         'Y:/Diego/data/JDM25/20170917/predictions/fullDay_model_ensemble.h5',...
         'Y:/Diego/data/JDM27/20171208/predictions/thresh_5/fullDay_model_ensemble.h5',...
         'Y:/Diego/data/JDM27/20171207/predictions/fullDay_model_ensemble.h5',...
         'Y:/Diego/data/JDM31_imputation_test/predictions/strideTest_thresh_5/fullDay_model_ensemble.h5',...
         'Y:/Diego/data/JDM32/20171023/predictions/thresh_5/fullDay_model_ensemble.h5',...
         'Y:/Diego/data/JDM32/20171024/predictions/fullDay_model_ensemble.h5',...
         'Y:/Diego/data/JDM33/20171124/predictions/thresh_5/fullDay_model_ensemble.h5',...
         'Y:/Diego/data/JDM33/20171125/predictions/fullDay_model_ensemble.h5'};
datasetPaths = {'Y:/Diego/data/JDM25/20170916/JDM25_fullDay.h5',...
         'Y:/Diego/data/JDM25/20170917/dataset.h5',...
         'Y:/Diego/data/JDM27/20171208/JDM27_fullDay.h5',...
         'Y:/Diego/data/JDM27/20171207/dataset.h5',...
         'Y:/Diego/data/JDM31_imputation_test/JDM31_fullDay.h5',...
         'Y:\Diego\data\JDM32\20171023\JDM32_fullDay.h5',...
         'Y:\Diego\data\JDM32\20171024\dataset.h5',...
         'Y:\Diego\data\JDM33\20171124\JDM33_fullDay.h5',...
         'Y:\Diego\data\JDM33\20171125\dataset.h5'};
names = {'JDM25','JDM25','JDM27','JDM27','JDM31','JDM32','JDM32','JDM33','JDM33'};

% Restrict the data to a subset with good tracking. 
filesToUse = [1 2 5 8 9];
imputationPaths = imputationPaths(filesToUse);
datasetPaths = datasetPaths(filesToUse);
names = names(filesToUse);
 
%% Loading data
% Preimputation bad frames
BF = cell(numel(datasetPaths),1);
for i = 1:numel(datasetPaths)
    BF{i} = logical(h5read(datasetPaths{i},'/bad_frames'));
end

% Moving frames
movingFrames = cell(numel(datasetPaths),1);
for i = 1:numel(datasetPaths)
    movingFrames{i} = logical(h5read(datasetPaths{i},'/move_frames'));
end

% Moving fast frames
movingFastFrames = cell(numel(datasetPaths),1);
for i = 1:numel(datasetPaths)
    movingFastFrames{i} = logical(h5read(datasetPaths{i},'/move_frames_fast'));
end

% Get imputedFrames, finalBadFrames, and badSpines
[finalBadFrames,imputedFrames,badSpines] = deal(cell(numel(imputationPaths),1));
parfor i = 1:numel(imputationPaths)
    tic
    [markersFinal,markersInitial,imputedFrames{i},~] = postprocessMBI(imputationPaths{i});
    finalBadFrames{i} = isnan(markersFinal);
    badSpines{i} = applySpineDistThreshold(markersInitial);
    disp(toc);
end

% Skeleton
skeleton = load('Y:/Diego/data/skeleton.mat');
skeleton = skeleton.skeleton;
%%
for i = 1:numel(badSpines)
    badSpines{i} = imdilate(badSpines{i},strel('square',30));
end

%% Compute imputation gap lengths
lengths = cell(numel(datasetPaths),1);
for i = 1:numel(lengths)
    CC = bwconncomp(BF{i}(:,11));
    lengths{i} = cellfun(@(X) numel(X),CC.PixelIdxList);
end

%% Look at distribution of imputation gap lengths
figure;addToolbarExplorationButtons(gcf);
hold on; set(gcf,'color','w');
for i = 1:numel(datasetPaths)
    histogram(lengths{i}(lengths{i}<100),99,'Normalization','Probability');
end
legend(names)

%% Look at cumulative distribution of gap-frames
figure; addToolbarExplorationButtons(gcf); 
hold on; set(gcf,'color','w');
% colors = parula(numel(paths));
colors = [1 0 0; 1 0 0; 0 1 0; 0 1 0; 0 0 1; 1 1 0; 1 1 0; 0 1 1; 0 1 1];

% colors = parula(numel(paths));
for i = 1:numel(datasetPaths)
    [N,edges] =histcounts(lengths{i},max(lengths{i}));
    % plot(cumsum(N)./sum(N));
    plot(cumsum(N.*round(edges(1:end-1)))./size(BF{i},1),'color',colors(i,:),'LineWidth',2);
end

legend(names)
% legend(paths);
xlabel('Bad Frames gap length');
ylabel('Fraction of total number of frames');
xlim([0 20]);

%% Look at the percentage imputed frames per marker for all frames
pctBadFramesPre = zeros(numel(imputedFrames),size(imputedFrames{1},2));
for iDay = 1:numel(imputedFrames)
    nFrames = size(imputedFrames{iDay},1);
    for jMarker = 1:size(imputedFrames{iDay},2)
        pctBadFramesPre(iDay,jMarker) = sum(imputedFrames{iDay}(:,jMarker))./nFrames;
    end
end

%% Look at the percentage imputed frames per marker for moving frames
pctBadFramesPreMoving = zeros(numel(imputedFrames),size(imputedFrames{1},2));
for iDay = 1:numel(imputedFrames)
    moving = movingFrames{iDay}(1:5:end) & ~badSpines{iDay};
    nFrames = sum(moving);
    for jMarker = 1:size(imputedFrames{iDay},2)
        pctBadFramesPreMoving(iDay,jMarker) = sum(imputedFrames{iDay}(moving,jMarker))./nFrames;
    end
end

%% Look at the percentage remainingBadFrames per marker for all frames
nMarkers = size(imputedFrames{1},2);
pctRemainingBadFrames = zeros(numel(finalBadFrames),nMarkers);
for iDay = 1:numel(finalBadFrames)
    nFrames = size(finalBadFrames{iDay},1);
    for jMarker = 1:nMarkers
        marker3dBadFrames = any(finalBadFrames{iDay}(:,(jMarker-1)*3 + (1:3)),2);
        pctRemainingBadFrames(iDay,jMarker) = sum(marker3dBadFrames)./nFrames;
    end
end

%% Look at the percentage remainingBadFrames per marker for moving frames
nMarkers = size(imputedFrames{1},2);
pctRemainingBadFramesMoving = zeros(numel(finalBadFrames),nMarkers);
for iDay = 1:numel(finalBadFrames)
    moving = movingFrames{iDay}(1:5:end) & ~badSpines{iDay};
    nFrames = sum(moving);
    for jMarker = 1:nMarkers
        marker3dBadFrames = ...
            any(finalBadFrames{iDay}(:,(jMarker-1)*3 + (1:3)),2);
        pctRemainingBadFramesMoving(iDay,jMarker) = ...
            sum(marker3dBadFrames(moving))./nFrames;
    end
end

%% Plot percentage imputed frames per marker for all frames. 
figure(1); hold on; set(gcf,'color','w');
bar(mean(pctBadFramesPre));
errorbar(mean(pctBadFramesPre),std(pctBadFramesPre)./sqrt(numel(imputedFrames)),'k.');
mSize=15;
p = plot(pctBadFramesPre','.','MarkerSize',mSize);
colors = parula(numel(datasetPaths));
cellfun(@(X,c) set(X,'Color',c), num2cell(p),num2cell(colors,2));
% legend(p,{'JDM25','JDM25','JDM27','JDM27','JDM31','JDM32','JDM32','JDM33','JDM33'})
legend(p,names)
ylabel('Fraction of imputed frames');
xticks(1:size(imputedFrames{1},2))
xticklabels(skeleton.nodes)
xtickangle(45)
title('Fraction imputed frames');
% export_fig([exportPath 'imputedFramesAllFrames.png'])

%% Plot percentage imputed frames per marker for moving frames. 
figure(2); hold on; set(gcf,'color','w');
bar(mean(pctBadFramesPreMoving));
errorbar(mean(pctBadFramesPreMoving),std(pctBadFramesPreMoving)./sqrt(numel(imputedFrames)),'k.');
mSize=15;
p = plot(pctBadFramesPreMoving','.','MarkerSize',mSize);
colors = parula(numel(datasetPaths));
cellfun(@(X,c) set(X,'Color',c),num2cell(p),num2cell(colors,2));
legend(p,names)
ylabel('Fraction of imputed frames');
xticks(1:size(BF{1},2))
xticklabels(skeleton.nodes)
xtickangle(45)
title('Fraction imputed moving frames');
% export_fig([exportPath 'imputedFramesMovingFrames.png'])

%% Plot percentage remainingBadFrames per marker for all frames. 
figure(3); hold on; set(gcf,'color','w');
bar(mean(pctRemainingBadFrames)*100);
errorbar(mean(pctRemainingBadFrames)*100,std(pctRemainingBadFrames)./sqrt(numel(finalBadFrames))*100,'k.');
mSize=15;
p = plot(pctRemainingBadFrames'*100,'.','MarkerSize',mSize);
colors = parula(numel(datasetPaths));
cellfun(@(X,c) set(X,'Color',c),num2cell(p),num2cell(colors,2));
legend(p,names)
ylabel('Percentage of remaining bad frames');
xticks(1:size(imputedFrames{1},2))
xticklabels(skeleton.nodes)
xtickangle(45)
title('Percentage of remaining bad frames');
% export_fig([exportPath 'remainingBadFrames.png'])

%% Plot percentage remainingBadFrames per marker for moving frames. 
figure(4); hold on; set(gcf,'color','w');
bar(mean(pctRemainingBadFramesMoving)*100);
errorbar(mean(pctRemainingBadFramesMoving)*100,std(pctRemainingBadFramesMoving)./sqrt(numel(finalBadFrames))*100,'k.');
mSize=15;
p = plot(pctRemainingBadFramesMoving'*100,'.','MarkerSize',mSize);
colors = parula(numel(datasetPaths));
cellfun(@(X,c) set(X,'Color',c),num2cell(p),num2cell(colors,2));
legend(p,names)
ylabel('Percentage of remaining bad frames');
xticks(1:size(imputedFrames{1},2))
xticklabels(skeleton.nodes)
xtickangle(45)
title('Percentage of remaining bad moving frames');
% export_fig([exportPath 'remainingMovingFrames.png'])

%% Compare the percentage of bad frames before and after. 
figure(5); hold on; set(gcf,'color','w','pos',[488, 195, 688, 567]);
totalImputationBadFrames = zeros(size(finalBadFrames));
totalRemainingBadFrames = zeros(size(finalBadFrames));
for i = 1:numel(finalBadFrames)
    totalImputationBadFrames(i) = sum(any(imputedFrames{i},2))./size(imputedFrames{i},1);
    totalRemainingBadFrames(i) = sum(any(finalBadFrames{i},2))./size(finalBadFrames{i},1);
end
markerMeans = [mean(pctBadFramesPre)' , mean(pctRemainingBadFrames)']*100;
totals = mean([totalImputationBadFrames totalRemainingBadFrames]*100);
markerSEM = [std(pctBadFramesPre)' , std(pctRemainingBadFrames)']*100./numel(imputedFrames);
totalsSEM = mean([totalImputationBadFrames totalRemainingBadFrames]*100./numel(imputedFrames));
X = [markerMeans; totals];
SEM = [markerSEM; totalsSEM];
b = bar(X);
nbars=size(X,2);
ngroups=size(X,1);
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    % Calculate center of each bar
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x,X(:,i), SEM(:,i), 'k', 'linestyle', 'none');
end
ylabel('Average percentage of bad frames per rat');
L = legend({'Pre imputation','Post Imputation'},'Position',[0.6133 0.8187 0.1956 0.0616]);
labels = skeleton.nodes;
labels{end+1} = 'Total';
xticks(1:numel(labels))
xticklabels(labels)
xtickangle(45)
title('Percentage of remaining bad frames');
% export_fig([exportPath 'beforeAndAfterAll.png'])

%% Compare the percentage of bad frames while moving before and after.
figure(6); hold on; set(gcf,'color','w','pos',[488, 195, 688, 567]);
totalImputationBadFramesMoving = zeros(size(finalBadFrames));
totalRemainingBadFramesMoving = zeros(size(finalBadFrames));
for i = 1:numel(finalBadFrames)
    moving = movingFrames{i}(1:5:end) & ~badSpines{i};
    totalImputationBadFramesMoving(i) = sum(any(imputedFrames{i}(moving,:),2))./sum(moving);
    totalRemainingBadFramesMoving(i) = sum(any(finalBadFrames{i}(moving,:),2))./sum(moving);
end
markerMeans = [mean(pctBadFramesPreMoving)' , mean(pctRemainingBadFramesMoving)']*100;
totals = mean([totalImputationBadFramesMoving totalRemainingBadFramesMoving]*100);
markerSEM = [std(pctBadFramesPreMoving)' , std(pctRemainingBadFramesMoving)']*100./numel(imputedFrames);
totalsSEM = mean([totalImputationBadFramesMoving totalRemainingBadFramesMoving]*100./numel(imputedFrames));
X = [markerMeans; totals];
SEM = [markerSEM; totalsSEM];
b = bar(X);
nbars=size(X,2);
ngroups=size(X,1);
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    % Calculate center of each bar
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x,X(:,i), SEM(:,i), 'k', 'linestyle', 'none');
end
ylabel('Average percentage of bad frames per rat');
L = legend({'Pre imputation','Post Imputation'},'Position',[0.6133 0.8187 0.1956 0.0616]);
labels = skeleton.nodes;
labels{end+1} = 'Total';
xticks(1:numel(labels))
xticklabels(labels)
xtickangle(45)
title('Percentage of remaining bad moving frames');
% export_fig([exportPath 'beforeAndAfterMoving.png'])
