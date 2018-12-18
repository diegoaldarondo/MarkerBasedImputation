%% Analyze synthetic gap experiments
% Creates figures:
% 1. Median error at midpoint. 
exportPath = 'C:\code\Olveczky\MotionAnalysis\viz\LabMeeting12_10_18\SyntheticGaps\';
addpath(genpath('C:/code/talmos-toolbox'))

%% Pathing and loading data
errorPath = 'Y:\Diego\data\JDM25_caff_imputation_test\models\strideTest\model_ensemble\viz\JDM25_analyze\errors.mat';
errors = load(errorPath,'delta_markers');
errors = errors.delta_markers;
skeleton = load('Y:\Diego\data\skeleton.mat');
skeleton = skeleton.skeleton;

%% Get the median error for the middle of the gap duration. 
medianError = cell(numel(errors),1);
for i = 1:numel(medianError)
    medianError{i} = squeeze(median(errors{i}));
    medianError{i} = medianError{i}(round(end/2),:);
end
medianError = cat(1,medianError{:})';

%% Make an image summarizing this data. 
figure(1); set(gcf,'color','w','pos',[437, 102, 764, 581]); 
[~,B] = sort(medianError(:,end));
imagesc(medianError(B,:));
yticks(1:size(medianError,1));
yticklabels(skeleton.nodes(B));
xticks(1:10);
xticklabels(10:10:100)
xlabel('Gap length (frames)')
c = colorbar;
c.Label.String = 'Median error (mm)';
fontsize(16)
set(gca,'Box','off')
% export_fig([exportPath 'medianErrorAtMidpoint.png']);

%% Cumulative error
markerIds = {contains(skeleton.nodes,'Head'),...
             contains(skeleton.nodes,{'Arm','Elbow','Shoulder'}),...
             contains(skeleton.nodes,{'SpineF','SpineL','Offset'}),...
             contains(skeleton.nodes,{'Shin','Knee','Hip'}),...
             ~contains(skeleton.nodes,'SpineM')};
         
thresholds = 0:.1:10;
for iLength = 1:numel(errors)
    pctBelowThresh = zeros(numel(markerIds),numel(thresholds));
    for i = 1:numel(markerIds)
        for j = 1:numel(thresholds)
            markerErrors = errors{iLength}(:,round(end/2),markerIds{i});
            pctBelowThresh(i,j) = sum(markerErrors(:) <= thresholds(j))./numel(markerErrors);
        end
    end
    figure; hold on; 
    plot(thresholds,pctBelowThresh','LineWidth',2)
    ylabel('Fraction below threshold')
    xlabel('Error threshold (mm)')
    legend({'Head','Forelimbs','Body','Hindlimbs','Total'},...
        'Position', [0.6477    0.3517    0.2418    0.3000])
    title(sprintf('Gap length: %d frames',size(errors{iLength},2)))
    fontsize(16)
    set(gca,'Box','off')
    set(gcf,'color','w')
    fn = sprintf('cumulativeErrorDistribution%d.png',size(errors{iLength},2));
    % export_fig([exportPath fn],'-r1500');
end

