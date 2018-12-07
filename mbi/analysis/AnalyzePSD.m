%% Load imputed and unimputed 


startFrame = 1000000;
duration = 50000;
upsampleFactor=5;
imputationPath = 'Y:/Diego/data/JDM25/20170916/predictions/thresh_5/fullDay_model_ensemble.h5';
imputed = h5read(imputationPath,'/preds',[1 startFrame],[60 duration])';
temp = zeros(size(imputed,1)*upsampleFactor,size(imputed,2));
for i = 1:size(temp,2)
    disp(i)
%     temp(:,i) = interp(imputed(:,i),upsampleFactor);
    temp(:,i) = interp1(1:duration,imputed(:,i),linspace(1,duration,5*duration),'pchip');
end
imputed = temp; clear temp;
badFrames = h5read(imputationPath,'/badFrames',[1 startFrame],[20 duration])';
badFrames = logical(repelem(badFrames,1,3));



dataPath = 'Y:/Diego/data/JDM25/20170916/JDM25_fullDay.h5';
unimputed = h5read(dataPath,'/markers',[startFrame*upsampleFactor 1],[duration*upsampleFactor 60]);
marker_means = h5read(dataPath,'/marker_means');
marker_stds = h5read(dataPath,'/marker_means');
unimputed = (unimputed.*marker_stds) + marker_means;


imputed(badFrames) = unimputed(badFrames);

% for i = 1:size(imputed,2)
%     imputed(:,i) = imputed(:,i) - nanmean(imputed(:,i));
%     unimputed(:,i) = unimputed(:,i) - nanmean(unimputed(:,i));
% end

%% Calculate the power spectral density for each. 
nMarkers = size(imputed,2);


[psdImputed, fImputed, psdUnimputed, fUnimputed] = deal(cell(nMarkers,1));
Fs = 300;
% Hs = spectrum.periodogram('Tukey');
parfor i = 1:nMarkers
    disp(i)
%     [psdImputed{i},fImputed{i}] = periodogram(imputed(:,i),rectwin(duration*upsampleFactor),duration*upsampleFactor,Fs,'psd');
%     [psdUnimputed{i},fUnimputed{i}] = periodogram(unimputed(:,i),rectwin(duration*upsampleFactor),duration*upsampleFactor,Fs,'psd');
%     [psdImputed{i},fImputed{i}] = periodogram(imputed(:,i),[],[],Fs,'psd');
%     [psdUnimputed{i},fUnimputed{i}] = periodogram(unimputed(:,i),[],[],Fs,'psd');
%     psdImputed{i} = psd(Hs,imputed(:,i),'Fs',Fs);
%     psdUnimputed{i} = psd(Hs,unimputed(:,i),'Fs',Fs);
    [psdImputed{i},fImputed{i}] = pwelch(imputed(:,i),Fs);
    [psdUnimputed{i},fUnimputed{i}] = pwelch(unimputed(:,i),Fs);
    
%     [psdUnimputed{i},fUnimputed{i}]
end
%% plot the psds
exportPath = 'C:\code\Olveczky\MotionAnalysis\viz\LabMeeting12_10_18\PowerSpectralDensity\'

totalPsdImputed = cat(2,psdImputed{:});
totalPsdImputed = mean(totalPsdImputed,2);

totalPsdUnimputed = cat(2,psdUnimputed{:});
totalPsdUnimputed = mean(totalPsdUnimputed,2);
% 
% figure; hold on;
% plot(fImputed{1},smoothdata(10*log10(psdImputed),'movmean',5));
% plot(fUnimputed{1},smoothdata(10*log10(psdUnimputed),'movmean',5));
% legend({'Imputed Downsampled','Unimputed'})

figure('pos',[488, 133, 891, 629]); hold on; set(gcf,'color','w');
start = 1;
plot(fImputed{1}(start:end)*150/pi,smoothdata(10*log10(totalPsdImputed(start:end)*upsampleFactor),'movmean',5));
plot(fUnimputed{1}(start:end)*150/pi,smoothdata(10*log10(totalPsdUnimputed(start:end)),'movmean',5));
% plot(fImputed{1}(start:end)*150/pi,10*log10(totalPsdImputed(start:end)*upsampleFactor),'LineWidth',2);
% plot(fUnimputed{1}(start:end)*150/pi,10*log10(totalPsdUnimputed(start:end)),'LineWidth',2);
% plot(fImputed{1}(start:end),10*log10(totalPsdImputed(start:end)*upsampleFactor),'LineWidth',2);
% plot(fUnimputed{1}(start:end),10*log10(totalPsdUnimputed(start:end)),'LineWidth',2);
xlabel('Frequency (Hz)')
ylabel('Average PSD (mm^{2}/Hz) dB')
line([30 30],get(gca,'YLim'),'LineStyle','--','Color','k')
legend({'Imputed','Unimputed'})
grid on;
fontsize(16)
% xlim([10 60])
% export_fig(exportPath,'PSD_DB.png')
%%
figure('pos',[488, 133, 891, 629]); hold on; set(gcf,'color','w');
plot(fImputed{1}(start:end)*150/pi,totalPsdImputed(start:end)*upsampleFactor,'LineWidth',2);
plot(fUnimputed{1}(start:end)*150/pi,totalPsdUnimputed(start:end),'LineWidth',2);
xlabel('Frequency (Hz)')
ylabel('Average PSD (mm^{2}/Hz)')
line([30 30],get(gca,'YLim'),'LineStyle','--','Color','k')
legend({'Imputed','Unimputed'})
grid on;
ylim([0 25]);
fontsize(16)
% export_fig(exportPath,'PSD.png')