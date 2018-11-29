paths = {'Y:/Diego/data/JDM25/20170916/JDM25_fullDay.h5',...
         'Y:/Diego/data/JDM27/20171208/JDM27_fullDay.h5',...
         'Y:/Diego/data/JDM31_imputation_test/JDM31_fullDay.h5',...
         'Y:\Diego\data\JDM32\20171023\JDM32_fullDay.h5',...
         'Y:\Diego\data\JDM33\20171124\JDM33_fullDay.h5'};
         
BF = cell(numel(paths),1);
for i = 1:numel(paths)
    BF{i} = h5read(paths{i},'/bad_frames');
end
% BF27 = h5read('Y:/Diego/data/JDM27/20171208/JDM27_fullDay.h5','/bad_frames');
% BF25 = h5read('Y:/Diego/data/JDM25/20170916/JDM25_fullDay.h5','/bad_frames');

%%
% [lengths27, lengths25] = deal(cell(size(BF25,2),1));
% for i = 1:size(BF25,2)
%     CC = bwconncomp(BF25(:,i));
%     lengths25{i} = cellfun(@(X) numel(X),CC.PixelIdxList);
%     CC = bwconncomp(BF27(:,i));
%     lengths27{i} = cellfun(@(X) numel(X),CC.PixelIdxList);
% end
% lengths25 = cat(2,lengths25{[11 15]});
% lengths27 = cat(2,lengths27{[11 15]});


lengths = cell(numel(paths),1);
for i = 1:numel(lengths)
    CC = bwconncomp(BF{i}(:,11));
    lengths{i} = cellfun(@(X) numel(X),CC.PixelIdxList);
end
% lengths25 = cat(2,lengths25{[11 15]});
% lengths27 = cat(2,lengths27{[11 15]});
%%
% figure;addToolbarExplorationButtons(gcf);
% hold on;
% histogram(lengths25(lengths25<100),99,'Normalization','Probability');
% histogram(lengths27(lengths27<100),99,'Normalization','Probability');

figure;addToolbarExplorationButtons(gcf);
hold on;
for i = 1:numel(paths)
    histogram(lengths{i}(lengths{i}<100),99,'Normalization','Probability');
end
legend({'JDM25','JDM27','JDM31','JDM32','JDM33'})
%%

% [N25,~] =histcounts(lengths25,max(lengths25));
% [N27,~] =histcounts(lengths27,max(lengths27));
% figure; hold on; 
% plot(cumsum(N25)./sum(N25));
% plot(cumsum(N27)./sum(N27));
% plot(cumsum(N25));
% plot(cumsum(N27));

figure; addToolbarExplorationButtons(gcf); 
hold on; 
for i = 1:numel(paths)
    [N,~] =histcounts(lengths{i},max(lengths{i}));
    % plot(cumsum(N)./sum(N));
    plot(cumsum(N));
end

legend({'JDM25','JDM27','JDM31','JDM32','JDM33'})
xlabel('Bad Frames gap length');
ylabel('Frequency');
