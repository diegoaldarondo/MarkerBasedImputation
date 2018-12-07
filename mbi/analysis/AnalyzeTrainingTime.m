%% AnalyzeTrainingTime
% Creates figures:
% 1. MSE over Epochs
exportPath = 'C:\code\Olveczky\MotionAnalysis\viz\LabMeeting12_10_18\TrainingTime\';

%% Pathing
% modelPaths = {'Y:\Diego\data\JDM25\20170917\models',...
%              'Y:\Diego\data\JDM25\20170919\models'};
 modelPaths = {'Y:\Diego\data\JDM25\20170917\models'};
historyPaths = {};
for i = 1:numel(modelPaths)
    d = dir([modelPaths{i} '\*dataset*']);
    files = cell(numel(d),1);
    for j = 1:numel(d)
        files{j} = fullfile(d(j).folder,d(j).name);
    end
    historyPaths = cat(1,historyPaths,files{:});
end
historyPaths = cellfun(@(X) [X '\history.mat'],historyPaths,'uni',0);

%% Load the history
history = cell(size(historyPaths));
for i = 1:numel(historyPaths)
    history{i} = load(historyPaths{i});
end

%% Plot all of the histories
figure('pos',[488, 219, 680, 543]); hold on; set(gcf,'color','w');
colors = lines(2);
linewidth = 2;
for i = 1:numel(history)
    plot(history{i}.loss,'color',colors(1,:),'LineWidth',linewidth);
    plot(history{i}.val_loss,'color',colors(2,:),'LineWidth',linewidth);
end
xlabel('Number of epochs')
ylabel('MSE loss')
legend({'training set','validation set'});
fontsize(16)
export_fig([exportPath 'trainingTime.png'])