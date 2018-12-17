%% Analyze embeddings
embeddingPath = 'Y:\Diego\data\JDM25\20170916\analysisstructs\analysisstruct.mat';
exportPath = 'C:\code\Olveczky\MotionAnalysis\viz\LabMeeting12_10_18\EmbeddingAnalysis\';

temp = load(embeddingPath,'zValues','condition_inds','frames_with_good_tracking');
nEmbeds = numel(temp.frames_with_good_tracking);
[embedFrames,embed] = deal(cell(nEmbeds,1));
for i = 1:nEmbeds
    embedFrames{i} = round(temp.frames_with_good_tracking{i}/5);
    embed{i} = temp.zValues(temp.condition_inds==i,:); 
end
%% Find Frames that are in one embedding but not another. 
framesToNearestMatchImp = zeros(size(embedFrames{2}));
framesToNearestMatchOrig = zeros(size(embedFrames{1}));
for i = 1:numel(embedFrames{2})
    dist = min(abs(embedFrames{1}-embedFrames{2}(i)));
    framesToNearestMatchImp(i) = dist;
end
for i = 1:numel(embedFrames{1})
    dist = min(abs(embedFrames{2}-embedFrames{1}(i)));
    framesToNearestMatchOrig(i) = dist; 
end
%% Count those frames
thresh = 9;
framesOnlyInImp = framesToNearestMatchImp>thresh;
framesOnlyInOrig = framesToNearestMatchOrig>thresh;
nFramesOnlyInImp = sum(framesOnlyInImp);
nFramesOnlyInOrig = sum(framesOnlyInOrig);
uniqueFrames = {framesOnlyInOrig,framesOnlyInImp};

%% Scatter embedding 
figure(1); set(gcf,'color','w');
mSize = 1;
for i = 1:numel(embed)
    scatter(embed{i}(:,1),embed{i}(:,2),mSize,'.')
    hold on;
end
xlabel('T-sne 1')
ylabel('T-sne 2')
legend({'Unimputed','Imputed'})
set(gcf,'color','w');
set(gca,'Box','off');
export_fig([exportPath 'tSneAllFrames.png'],'-r2000')

%% Scatter embedding matched frames
figure(1); set(gcf,'color','w');
mSize = 1;
for i = 1:numel(embed)
    scatter(embed{i}(~uniqueFrames{i},1),embed{i}(~uniqueFrames{i},2),mSize,'.')
    hold on;
end
xlabel('T-sne 1')
ylabel('T-sne 2')
legend({'Unimputed','Imputed'})
set(gcf,'color','w');
set(gca,'Box','off');
export_fig([exportPath 'tSneSharedFrames.png'],'-r2000')

%% Scatter embedding unmatched frames
figure(2); hold on; 
for i = 1:numel(embed)
    scatter(embed{i}(uniqueFrames{i},1),embed{i}(uniqueFrames{i},2),mSize,'.');
end
xlabel('T-sne 1')
ylabel('T-sne 2')
legend({'Unimputed','Imputed'})
set(gcf,'color','w');
set(gca,'Box','off');
export_fig([exportPath 'tSneUniqueFrames.png'],'-r2000')

%% Bar graph number of frames added
figure(3); 
b = bar([numel(embedFrames{1}) numel(embedFrames{2})]);
ylabel('Number of embedded frames');
xticklabels({'Unimputed','Imputed'});
fontsize(16)
set(gcf,'color','w');
set(gca,'Box','off');
export_fig([exportPath 'numberOfFrames.png'])
