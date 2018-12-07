%% Analyze synthetic gap experiments
% Creates figures:
% 1. Median error at midpoint. 
exportPath = 'C:\code\Olveczky\MotionAnalysis\viz\LabMeeting12_10_18\SyntheticGaps\';

%% Pathing and loading data
errorPath = 'Y:\Diego\data\JDM25_caff_imputation_test\models\strideTest\model_ensemble\viz\JDM25_analyze\errors.mat';
errors = load(errorPath);
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
export_fig([exportPath 'medianErrorAtMidpoint.png']);