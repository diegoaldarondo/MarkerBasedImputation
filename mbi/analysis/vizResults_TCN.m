%% Vizualize marker predictions
addpath(genpath('C:/code/talmos-toolbox'))
clear all;
% predPath = 'Y:\\Diego\code\TCN\predictions3.mat';
% predPath = 'Y:\\Diego\code\TCN\predictions2_thresh_.25_JDM32_18_09_25_16_15_17_input_9_output_1.mat';
predPath = 'Y:/Diego/data/JDM25_caff_imputation_test/predictions/model_ensemble_02_stride_5_18_10_13.mat'; % (start_frame, n_frames);
load(predPath)
%%
% no_movement = diffpad(markers)==0;
% no_movement(:,10:15) = false;
% markers(no_movement) = nan;
markers(logical(repelem(badFrames,1,3))) = nan;
for i = 1:size(markers,2)
    if i >= 13 || i <= 15
        continue;
    end
    marker = markers(:,i);
    marker(marker == mode(marker)) = nan;
    markers(:,i) = marker;
end
%%

% diffPreds = diffpad(preds);
% bounds = prctile(diffPreds,[5 95]);
% boundMean = nanmean(diffPreds(diffPreds > bounds(1,:) & diffPreds < bounds(2,:)));
% boundStd = nanstd(diffPreds(diffPreds > bounds(1,:) & diffPreds < bounds(2,:)));
% zdiffPreds = (diffPreds - boundMean)./boundStd;
% % zdiffPreds = zscore(diffpad(preds));
% preds(abs(diffpad(preds)) > 3) = markers(abs(diffpad(preds)) > 3);
markerLims = [-150 150];
preds(isnan(preds)) = markers(isnan(preds));
preds(preds < markerLims(1) | preds > markerLims(2)) = markers(preds < markerLims(1) | preds > markerLims(2));
preds = smoothdata(preds,'movmedian',5);
%%  Load the skeleton and recolor
addpath(genpath('C:\\code\talmos-toolbox'));
labelPath = 'Y:\Diego\leap\data\leapMarkerTest\markerTest_camera3.labels.mat';
temp = load(labelPath);

colors = [1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0];
for i = 1:numel(temp.skeleton.segments.color)
    segments = string(temp.skeleton.segments.joints{i});
    if any(contains(segments,'Head'))
       temp.skeleton.segments.color{i} = colors(1,:);
    elseif any(contains(segments,{'Shoulder','Elbow','Arm','Forepaw'}) & contains(segments,'L'))
       temp.skeleton.segments.color{i} = colors(3,:);
    elseif any(contains(segments,{'Hip','Knee','Shin','Hindpaw'}) & contains(segments,'L'))
       temp.skeleton.segments.color{i} = colors(4,:);
    elseif any(contains(segments,{'Shoulder','Elbow','Arm','Forepaw'}) & contains(segments,'R'))
       temp.skeleton.segments.color{i} = colors(5,:);
    elseif any(contains(segments,{'Hip','Knee','Shin','Hindpaw'}) & contains(segments,'R'))
       temp.skeleton.segments.color{i} = colors(6,:);
    elseif any(contains(segments,{'Spine','Offset'}))
       temp.skeleton.segments.color{i} = colors(2,:);
    end
end

skeleton = temp.skeleton;
segments = temp.skeleton.segments;

%% Get the bad frames into a nice vector for framewise vizualization
[BF,PBF] = deal(zeros(size(badFrames,2),1,1,size(badFrames,1)));
postBadFrames = getRemainingBadFrames(preds);
for i = 1:size(BF,1)
    BF(i,:,:,:) = badFrames(:,i);
    PBF(i,:,:,:) = postBadFrames;
end

%% Scatter post prediction markers in interactive animation
close all
lim = [-150 150];
f = figure; hold on;
ax1 = gca;
camPosition = [1.5901e+03 -1.7910e+03 1.0068e+03];
set(ax1,'xlim',lim,'ylim',lim,'zlim',lim,'color','k','CameraPosition',camPosition) 
h = plot_joints_single_3d(ax1,preds(1,:),segments);
vplay(BF,{@(~,idx) update_joints_single_3d(h,preds(idx,:),segments)})

%% Scatter pre and post prediction markers in interactive animation
close all
% Set figure parameters
f = figure; set(f,'color','k');
ax1 = axes('Position',[0 0 .5 1]); hold on;
ax2 = axes('Position',[.5 0 .5 1]); hold on;
lim = [-150 150];
camPosition = [1.5901e+03 -1.7910e+03 1.0068e+03];
set(ax1,'xlim',lim,'ylim',lim,'zlim',lim,'color','k','CameraPosition',camPosition) 
set(ax2,'xlim',lim,'ylim',lim,'zlim',lim,'color','k','CameraPosition',camPosition) 
title(ax1, 'Pre-Prediction','Color','w','Position',[0,0,150]); 
title(ax2, 'Post-Prediction','Color','w','Position',[0,0,150]); 
hlink = linkprop([ax1,ax2],{'CameraPosition','CameraUpVector'});

% Build the arrays of graphics handles
h1 = plot_joints_single_3d(ax1,markers(1,:),segments);
h2 = plot_joints_single_3d(ax2,preds(1,:),segments);

vplay(PBF,{@(~,idx) update_joints_single_3d(h1,markers(idx,:),segments)
    ,@(~,idx) update_joints_single_3d(h2,preds(idx,:),segments)})

%% Build a video
close all
f = figure; set(f,'color','k','Visible','on');
ax1 = axes('Position',[0 0 .5 1]); hold on;
ax2 = axes('Position',[.5 0 .5 1]); hold on;
lim = [-150 150];
camPosition = [1.5901e+03 -1.7910e+03 1.0068e+03];
set(ax1,'xlim',lim,'ylim',lim,'zlim',lim,'color','k','CameraPosition',camPosition) 
set(ax2,'xlim',lim,'ylim',lim,'zlim',lim,'color','k','CameraPosition',camPosition) 
title(ax1, 'Pre-Prediction','Color','w','Position',[0,0,lim(2)]); 
title(ax2, 'Post-Prediction','Color','w','Position',[0,0,lim(2)]); 
hlink = linkprop([ax1,ax2],{'CameraPosition','CameraUpVector'}); 

% Build the array of function handles
h1 = plot_joints_single_3d(ax1,markers(1,:),segments);
h2 = plot_joints_single_3d(ax2,preds(1,:),segments);

% Reorder the line precedence so that head > body > everything else
colors = {h1(:).Color};
uistack(h1(cellfun(@(X) sum((X == [0 1 0])) == 3,colors)),'top')
uistack(h1(cellfun(@(X) sum((X == [1 1 0])) == 3,colors)),'top')
colors = {h2(:).Color};
uistack(h2(cellfun(@(X) sum((X == [0 1 0])) == 3,colors)),'top')
uistack(h2(cellfun(@(X) sum((X == [1 1 0])) == 3,colors)),'top')

% Cycle through subsampled frames within a framespan and capture the figure
framespan = 50000; % 50k takes about 9 minutes to build w/ 4 workers. 
subsample_rate = 10;
V = cell1(framespan/subsample_rate);
% You can do parfor, but it messes with line precedence
for i = 1:framespan/subsample_rate
    % Update new frame
    update_joints_single_3d(h1,markers(i*subsample_rate,:),segments);
    update_joints_single_3d(h2,preds(i*subsample_rate,:),segments);
    
    % Collect and save the frame
    F = getframe(f);
    V{i} = F.cdata;
    disp(i*10)
end
V = cat(4,V{:});
%% Write video to file
savePath = 'C:\code\Olveczky\MotionAnalysis\viz\videos\TCN_predictions2_thresh_.25_JDM32_18_09_25_16_15_17_input_9_output_1.mp4';
write_frames(V,savePath,'FPS',30);

%% Build a video with specific frames
close all
f = figure; set(f,'color','k','Visible','on');
ax1 = axes('Position',[0 0 .5 1]); hold on;
ax2 = axes('Position',[.5 0 .5 1]); hold on;
lim = [-150 150];
camPosition = [1.5901e+03 -1.7910e+03 1.0068e+03];
set(ax1,'xlim',lim,'ylim',lim,'zlim',lim,'color','k','CameraPosition',camPosition) 
set(ax2,'xlim',lim,'ylim',lim,'zlim',lim,'color','k','CameraPosition',camPosition) 
title(ax1, 'Pre-Prediction','Color','w','Position',[0,0,lim(2)]); 
title(ax2, 'Post-Prediction','Color','w','Position',[0,0,lim(2)]); 
hlink = linkprop([ax1,ax2],{'CameraPosition','CameraUpVector'}); 

% Build the array of function handles
h1 = plot_joints_single_3d(ax1,markers(1,:),segments);
h2 = plot_joints_single_3d(ax2,preds(1,:),segments);

% Reorder the line precedence so that head > body > everything else
colors = {h1(:).Color};
uistack(h1(cellfun(@(X) sum((X == [0 1 0])) == 3,colors)),'top')
uistack(h1(cellfun(@(X) sum((X == [1 1 0])) == 3,colors)),'top')
colors = {h2(:).Color};
uistack(h2(cellfun(@(X) sum((X == [0 1 0])) == 3,colors)),'top')
uistack(h2(cellfun(@(X) sum((X == [1 1 0])) == 3,colors)),'top')

% Cycle through subsampled frames within a framespan and capture the figure
startFrames = [18500; 32900; 91500];
clipLength = 1000;
subsample_rate = 5;
frames = reshape(([18500; 32900; 91500] + (0:subsample_rate:clipLength))',1,[]);

V = cell1(numel(frames));
% You can do parfor, but it messes with line precedence
for i = 1:numel(frames)
    if frames(i) == startFrames(1)
        set(ax1,'CameraPosition',1.0e+03 * [2.2894    0.9175    0.8167])
        set(ax2,'CameraPosition',1.0e+03 * [2.2894    0.9175    0.8167])
    end
    if frames(i) == startFrames(2)
        set(ax1,'CameraPosition',1.0e+03 * [1.3714   -2.0029    0.9260])
        set(ax2,'CameraPosition',1.0e+03 * [1.3714   -2.0029    0.9260])
    end
    if frames(i) == startFrames(3)
        set(ax1,'CameraPosition',1.0e+03 * [2.2894    0.9175    0.8167])
        set(ax2,'CameraPosition',1.0e+03 * [2.2894    0.9175    0.8167])
    end
    % Update new frame
    update_joints_single_3d(h1,markers(frames(i),:),segments);
    update_joints_single_3d(h2,preds(frames(i),:),segments);
    
    % Collect and save the frame
    F = getframe(f);
    V{i} = F.cdata;
end
V = cat(4,V{:});
%% Write video to file
savePath = 'C:\code\Olveczky\MotionAnalysis\viz\videos\TCN_predictions2_thresh_.25_JDM32_18_09_25_16_15_17_input_9_output_1_GoodExamples.mp4';
write_frames(V,savePath,'FPS',30);

% %% 
% [x,y,z] = sphere;
% radius = 3;
% x = x*radius;
% y = y*radius;
% z = z*radius;
% frame = 1;
% figure;
% ax1 = gca;
% lim = [-150 150];
% camPosition = [1.5901e+03 -1.7910e+03 1.0068e+03];
% 
% for i = 1:size(markers,2)/3
%     xid = (i-1)*3 + 1;
%     yid = (i-1)*3 + 2;
%     zid = (i-1)*3 + 3;
%     surf(x + markers(frame,xid),y + markers(frame,yid),z + markers(frame,zid),'FaceColor',[.5 .5 .5]); hold on;
% end
% set(ax1,'xlim',lim,'ylim',lim,'zlim',lim,'CameraPosition',camPosition) 
% 
% 
% 
% %%
% figure; hold on;
% count = 1;
% ax = cell(size(badFrames,2),1);
% for i = 1:size(badFrames,2)
%     ax{i} = subplot(4,5,count);
%     X = sqrt(sum(diff(markers(:,((i-1)*3 + (1:3))),1).^2,2)); histogram(X(X < 10));
%     histogram(X(X<5))
%     count = count + 1;
% end
% linkaxes([ax{:}], 'xy')
% 
% %%
% figure; hold on;
% count = 1;
% ax = cell(20,1);
% for i = 1:size(markers,2)
%     ax{i} = subplot(6,10,count);
%     X = diff(markers(:,i));
%     histogram(X(abs(X)<5),'Normalization','probability','DisplayStyle','stairs')
%     count = count + 1;
% end
% linkaxes([ax{:}], 'xy')