classdef Animal < matlab.mixin.SetGet
    % Animal   Animal class for marker tracking analysis
    % This class encapsulates data required to analyze MotionCapture data
    % in animals.
    %
    % Rat Properties:
    %    path - filepath or condition of animal
    %    skeleton - graph describing animal skeleton and markers
    %    markers - global marker positions of the animal
    %    alignedMarkers - aligned marker positions relative to midline
    %    imputedMarkers - imputed aligned marker positions
    %    badFrames - logical matrix denoting the time of bad frames for
    %                 all markers
    %    embedFrames - frames for which there exists embeddings
    %    embed - embedding points
    %    h - handles to Animal child graphics objects
    %    hlink - linking instructions for vizualizations
    %    remainingBadFrames - frames that are still bad after imputation.
    %
    % myClass Methods:
    %    Animal - constructor
    %    stackedplot - plot marker traces for given indices
    %    compareTraces - plot marker traces for imputed and non-imputed
    %    getNodes - returns marker names
    %    getSegmentJoints - return segment indices
    %    getSegmentColors - return segment colors
    %    setSegmentColors - set segment colors
    %    movie - interactive marker movie
    %    writeMovie - write movie to a save file
    properties (Access = private)
        loadingFieldNames = {'markers','preds','badFrames'};
    end
    
    properties (Access = public)
        path
        fps = 60;
        skeleton
        markers
        embed
        embedFrames
        alignedMarkers
        imputedMarkers
        badFrames
        remainingBadFrames
        hlink
        h
    end
    
    methods
        
        % Constructor
        function obj = Animal(varargin)
            %Animal - construct an Animal Object
            %
            %   Syntax: animal = Animal(varargin);
            %
            %   Optional Inputs: 
            %       path - Path to an imputation file. Will load included
            %              data automatically.
            %       fps - frame rate 
            %       skeleton - animal skeleton
            %       markers - global marker set
            %       alignedMarkers - aligned marker set
            %       imputedMarkers - imputed marker set
            %       embed - behavioral embedding
            %       embedFrames - frames that have been embedded
            %       badFrames - improperly tracked frames
            %       remainingBadFrames - remaining bad frames after
            %                            imputation
            %       hlink - chart linking function 
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            if ~isempty(obj.path)
                % Load the data
                [~,~,ext] = fileparts(obj.path);
                switch lower(ext)
                    case '.mat'
                        temp = load(obj.path, obj.loadingFieldNames{:});
                        obj.alignedMarkers =...
                            temp.(obj.loadingFieldNames{1});
                        obj.imputedMarkers =...
                            temp.(obj.loadingFieldNames{2});
                        obj.badFrames = temp.(obj.loadingFieldNames{3});
                        clear temp;
                    case {'.h5', '.hdf5'}
                        obj.alignedMarkers = h5read(obj.path,...
                            ['/' obj.loadingFieldNames{1}])';
                        obj.imputedMarkers = h5read(obj.path,...
                            ['/' obj.loadingFieldNames{2}])';
                        obj.badFrames = h5read(obj.path,...
                            ['/' obj.loadingFieldNames{3}])';
                    otherwise
                        error('Unexpected file extension: %s', ext);
                end
            end
            if isempty(obj.skeleton)
               skeletonPath = 'Y:\Diego\data\skeleton.mat';
               temp = load(skeletonPath);
               obj.skeleton = temp.skeleton;
            end
        end
        
        % Build stackedplot of marker trajectories
        function stackedplot(obj, markerset, frameIds, varargin)
            switch markerset
                case 'aligned'
                    x = array2table(obj.alignedMarkers(frameIds,:));
                case 'imputed'
                    x = array2table(obj.imputedMarkers(frameIds,:));
                case 'global'
                    x = array2table(obj.markers(frameIds,:));
                otherwise
                    error(['Improper markerset. Must be aligned, ' ...
                        'imputed, or global.']);
            end
            stackedplot(x,varargin{:});
        end
        
        function f = compareTraces(obj, frameIds, markerIds, varargin)
            %compareTraces plot aligned and imputed marker traces together
            %
            %   Syntax: Animal.compareTraces(frameIds,markerIds);
            %           compareTraces(Animal,frameIds,markerIds);
            %
            %           Animal.compareTraces(Animal,frameIds,markerIds,...
            %               interTraceSpacing,barHeight,offset,colors);
            %   Inputs: frameIds - Frames to plot
            %           markerIds - Markers to plot (3d marker dimension)
            %
            %   Optional: interTraceSpacing - distance between middle of
            %             traces
            %             barHeight - height of bars denoting bad frames
            %             colors - Nx3 matrix of rgb color values. N must
            %             equal numel(markerIds).
            numvarargs = length(varargin);
            if numvarargs > 4
                error('myfuns:somefun2Alt:TooManyInputs', ...
                    'Accepts at most 4 optional inputs');
            end
            optargs = {150,150,20,[]};
            optargs(1:numvarargs) = varargin;
            [interTraceSpacing, barHeight, offset,c] = optargs{:};
            
            % Organize the necessary data
            numTraces = numel(markerIds);
            X = obj.alignedMarkers(frameIds,markerIds);
            Y = obj.imputedMarkers(frameIds,markerIds);
            markerIds3D = ceil(markerIds/3);
            BF = obj.badFrames(frameIds,markerIds3D);
            
            midlines =...
                ((numTraces-1)*interTraceSpacing):-interTraceSpacing:0;
            barEdges = midlines-round(barHeight/2);
            map = @(X,n,target) [linspace(X(1),target(1),n)',...
                linspace(X(2),target(2),n)',...
                linspace(X(3),target(3),n)'];
            nColorsInMap = 7;
            target = [.7 .7 .7];
            if isempty(c)
                c = lines(numTraces);
            end
            
            % Allocate figure
            f = gcf; set(f,'color','w'); hold on;
            addToolbarExplorationButtons;
            for i = 1:numTraces
                imputeBlocks = bwconncomp(BF(:,i) | any(isnan(X(:,i)),2));
                Pix = imputeBlocks.PixelIdxList;
                for j = 1:numel(Pix)
                    pos = [Pix{j}(1)/obj.fps,...
                        barEdges(i),...
                        numel(Pix{j})/obj.fps,...
                        barHeight];
                    rectangle('Position',pos,'FaceColor',[1 1 1].*.9,...
                        'EdgeColor','none')
                end
                
                medX = nanmedian(X(:,i));
                medY = nanmedian(Y(:,i));
                cmap = map(c(i,:),nColorsInMap,target);
                plot((1:numel(frameIds))/obj.fps,...
                    X(:,i) - medX + midlines(i) + offset/2,...
                    'color',cmap(1,:),'LineWidth',2)
                plot((1:numel(frameIds))/obj.fps,...
                    Y(:,i) - medY + midlines(i) - offset/2,...
                    'color',cmap(5,:),'LineWidth',2)
            end
            xlabel('Time (s)');
            yticks(midlines(end:-1:1))
            nodes = obj.getNodes;
            labels = cell(numTraces,1);
            dim = {'_z','_x','_y'};
%             dim = {'_{z_{vel}}','_{x_{vel}}','_{y_{vel}}'};
            
            for i = 1:numTraces
                labels{i} = [nodes{markerIds3D(i)}...
                    dim{mod(markerIds(i),3)+1}];
            end
            yticklabels(labels(end:-1:1));
            set(gca,'box','off');
            axis tight
        end
        
        % Get the node names
        function nodes = getNodes(obj)
            nodes = obj.skeleton.nodes;
        end
        
        % Get the joint indices of the node names
        function joints_idx = getSegmentJoints(obj)
            joints_idx = obj.skeleton.segments.joints_idx;
        end
        
        % Get the segment colors
        function colors = getSegmentColors(obj)
            colors = obj.skeleton.segments.color;
        end
        
        % Set the segment colors.
        function obj = setSegmentColors(obj, colors)
            obj.skeleton.segments.color = colors;
        end
        
        function obj = postProcess(obj,varargin)
            %postprocessMBI - Postprocess MBI marker predictions.
            %
            % Syntax: Animal.postProcess();
            %         Animal.postProcess(smoothingWindow,
            %                            badFrameThreshold,
            %                            badFrameSurround);
            %
            % Optional Inputs:
            %    smoothingWindow - Number of frames to use in median 
            %                       smoothing. Default 5.
            %
            %    badFrameThreshold - Threshold at which to trigger a bad
            %                        frame. Default 1. Metric is the 
            %                        z-scored energy of jerk. For use in 
            %                        getRemainingBadFrames.m
            %
            %    badFrameSurround - Number of surrounding frames to flag 
            %                       in the event of a trigger. 
            %                       Default 150. For use in
            %                       getRemainingBadFrames.m
            numvarargs = length(varargin);
            if numvarargs > 3
                error('myfuns:somefun2Alt:TooManyInputs', ...
                    'Accepts at most 3 optional inputs');
            end
            optargs = {5,1,150};
            optargs(1:numvarargs) = varargin;
            [smoothingWindow,badFrameThreshold,badFrameSurround] =...
                optargs{:};
            
            % Add nans for the portions of the markers that were incorrect
            obj.alignedMarkers(logical(repelem(obj.badFrames,1,3))) = nan;
            for i = 1:size(obj.alignedMarkers,2)
                % Nan values were previously assigned the mean for ease
                % of imputation.
                % Reassign to nans, except for SpineM
                if i >= 13 || i <= 15
                    continue;
                end
                marker = obj.alignedMarkers(:,i);
                marker(marker == mode(marker)) = nan;
                obj.alignedMarkers(:,i) = marker;
            end
            
            % Smooth the predicitons
            padding = smoothingWindow;
            for i = 1:size(obj.badFrames,2)
                CC = bwconncomp(obj.badFrames(:,i));
                markerIds = (i-1)*3 + (1:3);
                for j = 1:numel(CC.PixelIdxList)
                    frameIds = CC.PixelIdxList{j};
                    frameIds = ...
                        (frameIds(1) - padding):(frameIds(end) + padding);
                    frameIds = frameIds((frameIds > 0)...
                        & (frameIds < size(obj.imputedMarkers,1)));
                    obj.imputedMarkers(frameIds,markerIds) =...
                        smoothdata(obj.imputedMarkers(frameIds,markerIds),...
                        'movmedian',smoothingWindow);
                end
            end
            
            % Get the remaining bad frames
            jerkBadFrames = applyJerkThreshold(obj.imputedMarkers,...
                badFrameThreshold, badFrameSurround);            
            headBadFrames = applyHeadPdistThreshold(obj.imputedMarkers);
            spineBadFrames = applySpineDistThreshold(obj.imputedMarkers);
            
            % Set the remainingBadFrames to the union of metrics
            obj.remainingBadFrames = ...
                jerkBadFrames | headBadFrames | spineBadFrames;
            
            % Redundant check of spineF. Consider revising. 
            obj.remainingBadFrames(find(obj.badFrames(:,...
                contains(obj.getNodes,{'SpineF'})))) = true;
            
            % Set the head markers to nan for the headBadFrames, and
            % everything to nan for the spineBadFrames and jerkBadFrames
            mIds = repelem(contains(obj.getNodes,{'Head'}),3,1);
            obj.imputedMarkers(headBadFrames,mIds) = nan;
            obj.imputedMarkers(jerkBadFrames | spineBadFrames,:) = nan;
        end
        
        function h = movie(obj,markerset,varargin)
            %movie - view interactive animations
            %
            %   Syntax: Animal.movie(markerset);
            %
            %   Inputs: markerset - can be 'aligned','imputed','global',
            %           'embed', or a cell array of these four options.
            %           varargin - arguments to MarkerMovie constructor.
            %
            %   Notes: Markersets will appear side by side in the order
            %   given with appropriate titles above. movie supports any
            %   number of markersets.
            if isstring(markerset) || ischar(markerset)
                markerset = {markerset};
            end
          
            if ~isempty(varargin)
                frameIds = varargin{1};
                varargin(1) = [];
            else
                frameIds = 1:size(obj.imputedMarkers,1);
            end
            
            % For each element in markerset, plot the appropriate chart
            numComparisons = numel(markerset);
            [x,positions,h,titles] = deal(cell(numComparisons,1));
            isMM = contains(markerset,{'aligned','imputed','global'});
            for i = 1:numComparisons
                % Calculate the position in which to put the chart
                left = (i-1)*(1/numComparisons);
                bottom = 0;
                width = (1/numComparisons);
                height = 1;
                positions{i} = [left bottom width height];
                
                % Handle each type of chart appropriately
                switch markerset{i}
                    case 'aligned'
                        x{i} = obj.alignedMarkers(frameIds,:);
                        titles{i} = 'Aligned unimputed';
                    case 'imputed'
                        x{i} = obj.imputedMarkers(frameIds,:);
                        titles{i} = 'Aligned imputed';
                    case 'global'
                        x{i} = obj.markers(frameIds,:);
                        titles{i} = 'Global';
                    case 'embed'
                        h{i} = EmbeddingAnimator('embed',obj.embed,...
                            'embedFrames',obj.embedFrames,...
                            'nFrames',size(obj.imputedMarkers,1),...
                            'AxesPosition',positions{i},...
                            'animal',obj);
                    otherwise
                        error(['Improper markerset. Must be aligned, ' ...
                            'imputed, global, or embed.']);
                end              
                if isMM(i)
                    h{i} = MarkerAnimator('markers',x{i},...
                        'skeleton',obj.skeleton,...
                        'AxesPosition',positions{i},...
                        'movieTitle',titles{i},...
                        varargin{:});
                end
            end
            
            % Set the figure keypress function to iterate through all
            % charts' keypress functions.
            set(h{1}.Parent,'WindowKeyPressFcn',...
                @(src,event) Animator.runAll(h,src,event));

            % Link the axes of the MarkerAnimator objects
            obj.hlink = linkprop(h{1}.Parent.Children(isMM(end:-1:1)),...
                {'CameraPosition','CameraUpVector'});
            obj.h = h;
        end
        
        function V = writeMovie(obj,markerset,frameIds,savePath,varargin)
            %writeMovie - write a MarkerMovie
            %
            %   Syntax: Animal.writeMovie(markerset,frameIds,savePath);
            %
            %   Inputs: markerset - can be 'aligned','imputed','global',
            %           'embed', or a cell array of these three options.
            %           frameIds - frames to write
            %           savePath - path to save movie
            %           varargin - arguments to write_frames.m.
            %
            %   Required .m files: write_frames.m
            mm = movie(obj,markerset,frameIds);
            if numel(mm) == 1; mm = {mm}; end
            
            fig = mm{1}.Parent;
            V = cell(numel(frameIds),1);
            tic
            for i = 1:numel(frameIds)
                for j = 1:numel(mm)
                    mm{j}.frame = i;
                end
                F = getframe(fig);
                V{i} = F.cdata;
                if i == 100
                    rate = 100/(toc);
                    fprintf('Estimated time remaining: %f seconds\n',...
                        numel(frameIds)/rate)
                end
            end
            V = cat(4,V{:});
            fprintf('Writing movie to: %s\n', savePath);
            write_frames(V,savePath,varargin{:});
        end
    end
end