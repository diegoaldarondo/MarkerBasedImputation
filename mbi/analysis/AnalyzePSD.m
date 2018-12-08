%% AnalyzePSD - Analyze the power spectral density of the markers before and after imputation
%   Generates figures:
%   1. Power spectral density of markers before and after imputation in
%   decibels
%   2. Power spectral density of markers before and after imputation
%`  3. Power spectral density of unimputed markers in decibels
%   3. Power spectral density of unimputed markers
addpath(genpath('C:/code/talmos-toolbox'));
exportPath = 'C:\code\Olveczky\MotionAnalysis\viz\LabMeeting12_10_18\PowerSpectralDensity\';

%% Pathing 
imputationPath = 'Y:/Diego/data/JDM25/20170916/predictions/thresh_5/fullDay_model_ensemble.h5';
dataPath = 'Y:/Diego/data/JDM25/20170916/JDM25_fullDay.h5';

%% Load a section of data
% Define the start and stop parameters
startFrame = 1000000;
duration = 500000;
upsampleFactor=5;

% Load imputed traces
imputed = h5read(imputationPath,'/preds',[1 startFrame],[60 duration])';
temp = zeros(size(imputed,1)*upsampleFactor,size(imputed,2));

% Cubic interpolation
for i = 1:size(temp,2)
    temp(:,i) = interp1(1:duration,imputed(:,i),...
        linspace(1,duration,upsampleFactor*duration),'pchip');
end
imputed = temp; clear temp;

% Load the bad frames and upsample
badFrames = h5read(imputationPath,'/badFrames',...
    [1 startFrame],[20 duration])';
badFrames = logical(repelem(badFrames,upsampleFactor,3));

% Load the unimputed traces and convert to real world coordinates
unimputed = h5read(dataPath,'/markers',...
    [startFrame*upsampleFactor 1],[duration*upsampleFactor 60]);
marker_means = h5read(dataPath,'/marker_means');
marker_stds = h5read(dataPath,'/marker_means');
unimputed = (unimputed.*marker_stds) + marker_means;

% Replace the good frames with the true values at 300 Hz. 
imputed(~badFrames) = unimputed(~badFrames);

% Mean-centering
% for i = 1:size(imputed,2)
%     imputed(:,i) = imputed(:,i) - nanmean(imputed(:,i));
%     unimputed(:,i) = unimputed(:,i) - nanmean(unimputed(:,i));
% end

%% Calculate the power spectral density for each. 
nMarkers = size(imputed,2);
[psdImputed, fImputed, psdUnimputed, fUnimputed] = deal(cell(nMarkers,1));
Fs = 300;
parfor i = 1:nMarkers
    disp(i)
    [psdImputed{i},fImputed{i}] = pwelch(imputed(:,i),Fs);
    [psdUnimputed{i},fUnimputed{i}] = pwelch(unimputed(:,i),Fs);
end

%% plot the psds in decibel space
totalPsdImputed = cat(2,psdImputed{:});
totalPsdImputed = mean(totalPsdImputed,2);
totalPsdUnimputed = cat(2,psdUnimputed{:});
totalPsdUnimputed = mean(totalPsdUnimputed,2);

figure('pos',[488, 133, 891, 629]); hold on; set(gcf,'color','w');
start = 1;
factor = sum(sum(badFrames))/numel(imputed);
factor = (upsampleFactor - 1)*factor + 1;
smoothWidth = 7;
lineWidth = 2;
plot(fUnimputed{1}(start:end)*150/pi,...
    smoothdata(10*log10(totalPsdUnimputed(start:end)),...
               'movmean',smoothWidth),'LineWidth',lineWidth);
plot(fImputed{1}(start:end)*150/pi,...
    smoothdata(10*log10(totalPsdImputed(start:end)*factor),...
               'movmean',smoothWidth),'LineWidth',lineWidth);
xlabel('Frequency (Hz)')
ylabel('Average PSD (mm^{2}/Hz) dB')
line([30 30],get(gca,'YLim'),'LineStyle','--','Color','k')
legend({'Unimputed','Imputed'})
grid on;
fontsize(16)
set(gca,'Box','off')
export_fig([exportPath 'PSD_DB.png'])

%% plot the psds not in decibel space
figure('pos',[488, 133, 891, 629]); hold on; set(gcf,'color','w');
plot(fUnimputed{1}(start:end)*150/pi,...
    smoothdata(totalPsdUnimputed(start:end),...
               'movmean',smoothWidth),'LineWidth',lineWidth);
plot(fImputed{1}(start:end)*150/pi,...
    smoothdata(totalPsdImputed(start:end),...
               'movmean',smoothWidth),'LineWidth',lineWidth);
xlabel('Frequency (Hz)')
ylabel('Average PSD (mm^{2}/Hz)')
line([30 30],get(gca,'YLim'),'LineStyle','--','Color','k')
legend({'Unimputed','Imputed'})
grid on;
ylim([0 25]);
fontsize(16)
set(gca,'Box','off')
export_fig([exportPath 'PSD.png'])

%% plot the psds for only the original markers in decibel space
totalPsdImputed = cat(2,psdImputed{:});
totalPsdImputed = mean(totalPsdImputed,2);
totalPsdUnimputed = cat(2,psdUnimputed{:});
totalPsdUnimputed = mean(totalPsdUnimputed,2);

figure('pos',[488, 133, 891, 629]); hold on; set(gcf,'color','w');
start = 1;
factor = sum(sum(badFrames))/numel(imputed);
factor = (upsampleFactor - 1)*factor + 1;
plot(fUnimputed{1}(start:end)*150/pi,...
    smoothdata(10*log10(totalPsdUnimputed(start:end)),...
               'movmean',smoothWidth),'LineWidth',lineWidth);
xlabel('Frequency (Hz)')
ylabel('Average PSD (mm^{2}/Hz) dB')
line([30 30],get(gca,'YLim'),'LineStyle','--','Color','k')
grid on;
fontsize(16)
set(gca,'Box','off')
export_fig([exportPath 'PSD_Unimputed_DB.png'])

%% plot the psds for only the original markers not in decibel space
figure('pos',[488, 133, 891, 629]); hold on; set(gcf,'color','w');
plot(fUnimputed{1}(start:end)*150/pi,...
    smoothdata(totalPsdUnimputed(start:end),...
               'movmean',smoothWidth),'LineWidth',lineWidth);
xlabel('Frequency (Hz)')
ylabel('Average PSD (mm^{2}/Hz)')
line([30 30],get(gca,'YLim'),'LineStyle','--','Color','k')
grid on;
ylim([0 25]);
fontsize(16)
set(gca,'Box','off')
export_fig([exportPath 'PSD_Unimputed.png'])