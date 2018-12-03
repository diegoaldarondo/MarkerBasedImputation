%% Vizualize marker predictions
% Generates summary statistics for model performance relative to initial
% markers. 
% Diego Aldarondo 2018 10 10
clear all;
addpath(genpath('C:/code/talmos-toolbox'))
predPath = 'Y:/Diego/data/JDM25_caff_imputation_test/predictions/model_ensemble_02_stride_5_18_10_13.mat'; % (start_frame, n_frames);
load(predPath)

% Smooth
preds = smoothdata(preds,'movmedian',5);

% Nan out the Bad Frames in Orig. markers
% markers(logical(repelem(badFrames,1,3))) = nan;

% Nan out the mode, which was a placeholder for previous nans. 
for i = 1:size(markers,2)
    % Don't do this for Spine M, since its always 0
    if i <= 15 || i >= 13
        continue;
    end
    marker = markers(:,i);
    marker(marker == mode(marker)) = nan;
    markers(:,i) = marker;
end

%% Look at the distribution of marker speeds. 
marker_diff = abs(diffpad(markers,1));
pred_diff = abs(diffpad(preds,1));

% Total per-frame movement over time. 
figure; hold on;
plot(sum(marker_diff,2));
plot(sum(pred_diff ,2));

% Distribution of total per-frame movement
figure; hold on; 
histogram(log(nansum(marker_diff,2)),'Normalization','probability','DisplayStyle','stairs');
histogram(log(nansum(pred_diff ,2)),'Normalization','probability','DisplayStyle','stairs');

% Distribution of total single-marker per-frame movement
figure; hold on; 
histogram(log(marker_diff(:)),'Normalization','probability','DisplayStyle','stairs')
histogram(log(pred_diff(:)),'Normalization','probability','DisplayStyle','stairs')

% % Distribution of single-marker per-frame movement
% figure; hold on; 
% markerId = 10;
% % histogram(log(marker_diff(:,markerId)))
% [counts,edges] = histcounts(log(marker_diff(:,markerId)));
% histogram('BinEdges',edges,'BinCounts',counts,'Normalization','probability','DisplayStyle','stairs')
% histogram(log(pred_diff(:,markerId)),edges,'Normalization','probability','DisplayStyle','stairs')

%% Analyze jumps above threshold. 
movement_thresh = 1;
marker_mean = nanmean(markers,1);
marker_std = nanstd(markers,1);
zmarkers = zscore(markers,1);
zpreds = (preds-marker_mean)./marker_std;
zmarkers_diff = diffpad(zmarkers);
zpreds_diff = diffpad(zpreds);
markers_jumps = zmarkers_diff > movement_thresh;
preds_jumps = zpreds_diff > movement_thresh;

%% Look at the number of 3d jumps for each marker. 
[markers3d_jumps,preds3d_jumps] = deal(false(size(markers,1),size(markers,2)/3));
for i = 1:size(markers,2)
    markers3d_jumps(markers_jumps(:,i),ceil(i/3)) = true;
    preds3d_jumps(preds_jumps(:,i),ceil(i/3)) = true;
end
figure; hold on;
bar(sum(markers3d_jumps),'FaceAlpha',.7);
bar(sum(preds3d_jumps),'FaceAlpha',.7);
xlabel('Marker ID')
ylabel('Number of Jumps')
figure;
bar(1-sum(preds3d_jumps)./sum(markers3d_jumps));
xlabel('Marker ID')
ylabel('Fraction Fixed')
figure;
bar(sum(markers3d_jumps) - sum(preds3d_jumps));
xlabel('Marker ID')
ylabel('Difference between markers and preds')

%% Make a confusion matrix for these jumps. 
figure; 
X = markers3d_jumps(:)';
Y = preds3d_jumps(:)';
% markerId = 12;
% X = markers3d_jumps(:,markerId)';
% Y = preds3d_jumps(:,markerId)';

p = plotconfusion(X,Y);
p.CurrentAxes.XLabel.String = 'Pre-prediction';
p.CurrentAxes.YLabel.String = 'Post-prediction';
p.CurrentAxes.XTickLabel = {'Non-Jump','Jump',''};
p.CurrentAxes.YTickLabel = p.CurrentAxes.XTickLabel;

% This is the 2018b way to do this, but I like how the old way looks more. 
% figure; hold off;
% C = confusionmat(X,Y);
% cm = confusionchart(C,{'Non-Jumps','Jumps'});
% cm.RowSummary = 'row-normalized';
% cm.ColumnSummary = 'column-normalized';
% cm.YLabel = 'Post-Prediction';
% cm.XLabel = 'Pre-Prediction';

precision = sum(X & Y)/(sum(X & Y) + sum(~X & Y));
recall = sum(X & Y)/(sum(X & Y) + sum(X & ~Y));
F1 = 2*(precision*recall)./(precision+recall);
fprintf('Corrected F1: %f\n',1-F1)

%% Loop through movement_thresholds and calculate the corrected F1 at each 

% Params
thresholds = 0:.1:2;
markers_fixed = [11,12,15:20];
F1Scores = zeros(numel(thresholds),numel(markers_fixed)+1);

% Get the differences between each frame
marker_mean = mean(markers,1);
marker_std = std(markers,1);
zmarkers = zscore(markers,1);
zpreds = (preds-marker_mean)./marker_std;
zmarkers_diff = abs(diffpad(zmarkers));
zpreds_diff = abs(diffpad(zpreds));

% Helpful function for F1 calculation. 
andnansum = @(X,Y) nansum(X & Y,1);

% For each threshold, find the jumps below that threshold in preds and
% markers and calculate the F1
for t = 1:numel(thresholds)
    disp(t)
    % Find Jumps
    movement_thresh = thresholds(t);
    markers_jumps = zmarkers_diff >= movement_thresh;
    preds_jumps = zpreds_diff >= movement_thresh;

    % Express in 3d markers
    [markers3d_jumps,preds3d_jumps] = deal(false(size(markers,1),size(markers,2)/3));
    for i = 1:size(markers,2)
        markers3d_jumps(markers_jumps(:,i),ceil(i/3)) = true;
        preds3d_jumps(preds_jumps(:,i),ceil(i/3)) = true;
    end
    
    % F1 for each of the fixed markers separately
    X = markers3d_jumps(:,markers_fixed);
    Y = preds3d_jumps(:,markers_fixed);
    precision = andnansum(X,Y)./(andnansum(X,Y) + andnansum(~X,Y));
    recall = andnansum(X,Y)./(andnansum(X,Y) + andnansum(X,~Y));
    F1 = 2*(precision.*recall)./(precision+recall);
    F1Scores(t,1:end-1) = 1-F1;
    
    % F1 for all the fixed markers at once.
    X = X(:);
    Y = Y(:);
    precision = andnansum(X,Y)./(andnansum(X,Y) + andnansum(~X,Y));
    recall = andnansum(X,Y)./(andnansum(X,Y) + andnansum(X,~Y));
    F1 = 2*(precision.*recall)./(precision+recall);
    F1Scores(t,end) = 1-F1;
end

%% Plot corrected F1 as a function of jump threshold
figure; hold on;
c = [repelem(lines(2),4,1);zeros(1,3)];
p = cell(size(c,1),1);
for i = 1:size(F1Scores,2)   
    p{i} = plot(thresholds, F1Scores(:,i),'LineWidth',3,'Color',c(i,:));
end
ylabel('Corrected F1','FontSize',16)
xlabel('Jump Threshold (\sigma)','FontSize',16)
legend([p{[1,5,end]}],{'Arms','Legs','Total'})

%% Redo Jesse's bad frames analysis
% velThresh = 23; % mm/s in 3d
thresholds = 0:40;
markers_fixed = [11,12,15:20];
get3DVel = @(X) sqrt(sum(diffpad(X).^2,2));
numMarkers = (size(markers,2)/3);
[markers_vel,preds_vel] = deal(zeros(size(markers,1),numMarkers));
for i = 1:numMarkers
    mIds = (i-1)*3 + (1:3);
    markers_vel(:,i) = get3DVel(markers(:,mIds));
    preds_vel(:,i) = get3DVel(preds(:,mIds));
end

% left_elbow_X = 31;
% right_elbow_X = 43;
% left_arm_X = 34;
% right_arm_X = 46;
% 
% midline = mean([markers(:,left_elbow_X);markers(:,right_elbow_X)]);
% markers_L_arm_swap = abs(markers(:,left_elbow_X)-markers(:,right_elbow_X));

% preds_L_arm_swap = preds(:,left_elbow_X) < midline;
% 
% markers_LR_arm_swap = markers(:,left_elbow_X) < markers(:,right_elbow_X);
% preds_LR_arm_swap = preds(:,left_elbow_X) < preds(:,right_elbow_X);

F1Scores = zeros(numel(thresholds),numel(markers_fixed));
for v = 1:numel(thresholds)
    disp(v)
    velThresh = thresholds(v);
    markers_bad_frames = markers_vel >= velThresh;
    preds_bad_frames = preds_vel >= velThresh;
    
    X = markers_bad_frames(:,markers_fixed);
    Y = preds_bad_frames(:,markers_fixed);
    
    precision = sum(X & Y,1)./(sum(X & Y,1) + sum(~X & Y,1));
    recall = sum(X & Y,1)./(sum(X & Y,1) + sum(X & ~Y,1));
    F1 = 2*(precision.*recall)./(precision+recall);
    F1Scores(v,:) = 1-F1;
end

%% PCT bad frames as a function of gap length
[CC,lengths] = deal(cell(size(badFrames,2),1));
for i = 1:numel(CC)
   CC{i} = bwconncomp(badFrames(:,i));
   lengths{i} = cellfun(@numel,CC{i}.PixelIdxList);
end
lengths = cat(2,lengths{:});

thresholds = [0:max(lengths)];
numImputed = zeros(size(thresholds));
for i = 1:numel(thresholds)
    numImputed(i) = sum(lengths <= thresholds(i));
end

stride = 5;
figure; hold on;
plot(thresholds*stride, numImputed./numel(lengths),'LineWidth',3);
xlabel('Cutoff Length')
ylabel('Fraction of errors imputed')
set(gca,'XScale','log')


figure; hold on;
numAdditionalFramesPerThresh = diffpad(numImputed).*thresholds.*stride;
plot(thresholds*stride, cumsum(numAdditionalFramesPerThresh)./sum(lengths.*stride),'LineWidth',3);
xlabel('Cutoff Length')
ylabel('Fraction of marker-frames imputed')
set(gca,'XScale','log')

% figure; hold on;
% plot(thresholds*stride, numImputed,'LineWidth',3);
% xlabel('Cutoff Length')
% ylabel('Number Imputed')
% % set(gca,'XScale','log')

%% Find how many complete frames would be imputed at each threshold. 
CC_erode = CC;

thresholds = [0:512, 1000:500:40000];
numBFremaining = zeros(size(thresholds));
for i = 1:numel(thresholds)
    disp(i)
    for j = 1:numel(CC)
        marker = CC_erode{j};
        lengths = cellfun(@numel, marker.PixelIdxList);
        
        % Check to see if that was the last one in the CC
        marker.PixelIdxList(lengths <= thresholds(i)) = [];
        CC_erode{j} = marker;
    end
    
    % Find how many frames would still have an error
    BF = false(size(badFrames));
    for j = 1:size(BF,2)
        BF(cat(1,CC_erode{j}.PixelIdxList{:}),j) = true;
    end
    numBadMarkers = sum(BF,2);
    numBFremaining(i) = sum(any(numBadMarkers,2));
end

figure; hold on;
plot(thresholds*stride,1 - (numBFremaining./sum(any(badFrames,2))))
xlabel('Cutoff Threshold (frames)')
ylabel('Percentage of frames with bad markers imputed')