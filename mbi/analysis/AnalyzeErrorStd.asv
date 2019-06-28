%% Analyze the relationship between member std and error. 
%
%
%   
%% Pathing
clear all;
errorPath = 'Y:\Diego\data\JDM25_caff_imputation_test\models\strideTest\model_ensemble\viz\JDM25_analyze\errors.mat';
skeletonPath = 'Y:\Diego\data\JDM25_caff_imputation_test\skeleton.mat';
datasetPath = 'Y:\Diego\data\JDM25_caff_imputation_test\JDM25_fullDay.h5';

%% Loading
errors = load(errorPath);
skeleton = load('Y:\Diego\data\JDM25_caff_imputation_test\skeleton.mat');
skeleton = skeleton.skeleton; 

markerMeans = h5read(datasetPath,'/marker_means');
markerStds = h5read(datasetPath,'/marker_stds');


%% Get data in the form of per-marker standardized 3d error.  
lengthGroup = 10;
delta = errors.delta_markers{lengthGroup};
member_stds = errors.member_stds{lengthGroup};
markerStds3d = zeros(size(delta,3),1);
predStds = zeros(size(delta));
for iMarker = 1:size(delta,3)
    mId = (iMarker-1)*3 + (1:3);
    markerStds3d(iMarker) = sqrt(sum(markerStds(mId).^2));
    predStds(:,:,iMarker) = sqrt(sum(member_stds(:,:,mId).^2,3)).*markerStds3d(iMarker);
%     delta(:,:,iMarker) = delta(:,:,iMarker)./markerStds3d(iMarker);
end
delta(isnan(delta)) = 0;

%% Scatter with fit line
figure; set(gcf, 'color','w');
mIds = contains(skeleton.nodes,{'Arm'});
% mIds = contains(skeleton.nodes,{'Arm','Elbow'});
X = predStds(:,:,mIds);
Y = delta(:,:,mIds);
% X = predStds(:);
% Y = delta(:);
% X = predStds(delta < 10);
% Y = delta(delta < 10);
mdl = fitlm(X(:),Y(:),'linear');
mdl.plot()
xlim([0 .25])
ylim([0 20])
xlabel('Member \sigma');
ylabel('Marker error (mm)');
%% Scatter
figure; set(gcf, 'color','w'); hold on; 
% mIds = contains(skeleton.nodes,{'Arm','Elbow','Shin','Hip','Knee'});
mIds = contains(skeleton.nodes,{'Arm'});

% mIds = contains(skeleton.nodes,{'Arm','Elbow'});
X = predStds(:,:,mIds);
Y = delta(:,:,mIds);
% X = predStds(:);
% Y = delta(:);
% X = predStds(delta < 10);
% Y = delta(delta < 10);
% mdl = fitlm(X(:),Y(:),'linear');
% mdl.plot()
xmax = 20;
ymax = 20;
scatter(X(:),Y(:),4,'.');
mdl = fitlm(X(:),Y(:),'linear');
plot([0 xmax], [mdl.Coefficients.Estimate(1) mdl.Coefficients.Estimate(2)*xmax],'r');
xlim([0 xmax])
ylim([0 ymax])
xlabel('Member \sigma (mm)');
ylabel('Marker error (mm)');

%% Average error as a function of std threshold
% mIds = contains(skeleton.nodes,{'Arm','Elbow','Shin','Hip','Knee'});
mIds = contains(skeleton.nodes,{'Arm'});

% mIds = contains(skeleton.nodes,{'Arm','Elbow'});
X = predStds(:,:,mIds);
Y = delta(:,:,mIds);
thresholds = 0:.005:.5;
[avgErrorsAbove,avgErrorsBelow] = deal(zeros(size(thresholds)));

for iThresh = 1:numel(thresholds)
    avgErrorsAbove(iThresh) = median(Y(X >= thresholds(iThresh)));
    avgErrorsBelow(iThresh) = median(Y(X <= thresholds(iThresh)));
end
figure; set(gcf, 'color','w'); hold on;
plot(thresholds,avgErrorsAbove,'LineWidth',2);
plot(thresholds,avgErrorsBelow,'LineWidth',2);
ylabel('Median error (mm)');
xlabel('Member \sigma threshold');
legend({'Above \sigma','Below \sigma'})

%% Divide member stds into bins, look at error within each bin. 
% mIds = contains(skeleton.nodes,{'Arm','Elbow','Shin','Hip','Knee'});
mIds = contains(skeleton.nodes,{'Arm'});

% mIds = contains(skeleton.nodes,{'Arm','Elbow'});
X = predStds(:,:,mIds);
Y = delta(:,:,mIds);
thresholds = 0:.01:.5;
avgErrors = zeros(size(thresholds,1)-1,1);

for iThresh = 1:numel(thresholds)-1
    avgErrors(iThresh) = median(Y(X >= thresholds(iThresh) & X < thresholds(iThresh+1)));
end
figure; set(gcf, 'color','w'); hold on;
plot(thresholds(1:end-1),avgErrors,'LineWidth',2);
ylabel('Median error (mm)');
xlabel('Member \sigma');
