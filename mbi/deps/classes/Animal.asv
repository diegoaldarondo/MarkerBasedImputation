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
        nFrames
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
        jerkBadFrames
        headBadFrames
        spineBadFrames
        hlink
        hlinkBrady
        h
        hBrady
        scope
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
            obj.nFrames = max([size(obj.imputedMarkers,1),...
                               size(obj.markers,1),...
                               size(obj.alignedMarkers,1)]);
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
%             X = diffpad(obj.alignedMarkers(frameIds,markerIds));
%             Y = diffpad(obj.imputedMarkers(frameIds,markerIds));
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
            target = [1 1 1].*.7;
            if isempty(c)
                c = lines(numTraces);
            end
            
            % Allocate figure
            f = gcf; set(f,'color','w'); hold on;
            addToolbarExplorationButtons;
            for i = 1:numTraces
                % Color the background gray where there was imputation
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
                
                % Plot the traces with an offset for the imputed and orig.
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
            optargs = {3,1,150};
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
%                     obj.imputedMarkers(frameIds,markerIds) =...
%                         smoothdata(obj.imputedMarkers(frameIds,markerIds),...
%                         'movmedian',smoothingWindow);
                    obj.imputedMarkers(frameIds,markerIds) =...
                        smoothdata(obj.imputedMarkers(frameIds,markerIds),...
                        'movmean',smoothingWindow);
                end
            end
            
            % Get the remaining bad frames
            obj.jerkBadFrames = applyJerkThreshold(obj.imputedMarkers,...
                badFrameThreshold, badFrameSurround);            
            obj.headBadFrames = applyHeadPdistThreshold(obj.imputedMarkers);
            obj.spineBadFrames = applySpineDistThreshold(obj.imputedMarkers);
            
            % Set the remainingBadFrames to the union of metrics
            obj.remainingBadFrames = ...
                obj.jerkBadFrames | obj.headBadFrames | obj.spineBadFrames;
            
            % Redundant check of spineF. Consider revising. 
            obj.remainingBadFrames(find(obj.badFrames(:,...
                contains(obj.getNodes,{'SpineF'})))) = true;
            
            % Set the head markers to nan for the headBadFrames, and
            % everything to nan for the spineBadFrames and jerkBadFrames
            mIds = repelem(contains(obj.getNodes,{'Head'}),3,1);
            obj.imputedMarkers(obj.headBadFrames,mIds) = nan;
            mIds = repelem(contains(obj.getNodes,{'SpineF'}),3,1);
            obj.imputedMarkers(obj.jerkBadFrames | obj.spineBadFrames,mIds) = nan;
            
%             velThresh = 23;
%             for i = 1:(size(obj.imputedMarkers,2)/3)
%                 mIds = (i-1)*3 + (1:3);
%                 vel = diffpad(obj.imputedMarkers(:,mIds));
%                 vel = sqrt(sum(vel.^2,2));
%                 obj.imputedMarkers(vel>velThresh,mIds) = nan;
%             end
        end
        
        function h = movie(obj,markerset,tiles,varargin)
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
                %TODO: fix this to work for any set. 
                frameIds = 1:obj.nFrames;
            end
            
            % For each element in markerset, plot the appropriate chart
            numComparisons = numel(markerset);
            [x,positions,h,titles] = deal(cell(numComparisons,1));
            isMM = contains(markerset,{'aligned','imputed','global'});
            embedCount = 1;
            if isempty(tiles)
                positions = Animal.linearPositions(numComparisons);
            elseif (numel(tiles) == 2) && isnumeric(tiles)
                positions = Animal.tilePositions(tiles(1),tiles(2));
            end
            
            for i = 1:numComparisons                
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
                        h{i} = EmbeddingAnimator('embed',obj.embed{embedCount},...
                            'embedFrames',obj.embedFrames{embedCount},...
                            'nFrames',size(obj.imputedMarkers,1),...
                            'AxesPosition',positions{i},...
                            'id', i,...
                            'animal',obj);
                        embedCount = embedCount + 1;
                    otherwise
                        error(['Improper markerset. Must be aligned, ' ...
                            'imputed, global, or embed.']);
                end              
                if isMM(i)
                    h{i} = MarkerAnimator('markers',x{i},...
                        'skeleton',obj.skeleton,...
                        'AxesPosition',positions{i},...
                        'movieTitle',titles{i},...
                        'id', i,...
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
            
            % Set axis colors and turn of axes
            for i = 1:numel(h{1}.Parent.Children)
                h{1}.Parent.Children(i).Color = [0 0 0];
                axis(h{1}.Parent.Children(i),'off');
            end
            obj.h = h;
        end
        
        function h = bradyMovie(obj,markerset,tiles,varargin)
            %bradyMovie - view interactive animations in a Brady Bunch
            %style
            %
            %   Syntax: Animal.bradyMovie(markerset,tiles);
            %           Animal.bradyMovie(markerset,tiles,plotSimple);
            %   
            %   Inputs: markerset - cell array of 'aligned' or 'imputed'
            %           tiles - shape of brady grid. e.g. [5,5]
            %   
            %   Optional Inputs: plotSimple - if true, plots everything in
            %                    white to speed up graphics. Colored 
            %                    according to animal skeleton otherwise
            
            % Check to see if simple plotting 
            if ~isempty(varargin)
                plotSimple = varargin{1};
            else
                plotSimple = false;
            end
            
            % Check to make sure markerset is in the right format
            if isstring(markerset) || ischar(markerset)
                markerset = {markerset};
            end
            
            % Get the indices based on the restricted frames of the
            % associated MarkerAnimatior
            frameInds = obj.h{1}.getFrameInds;
            bradyInds = false(max(frameInds),1);
            bradyInds(frameInds) = true;
            CC = bwconncomp(bradyInds);
            bradyInds = cellfun(@(X) X(1:100),CC.PixelIdxList,'uni',0);

            % For each element in markerset, plot the chart in the
            % appropriate place
            nAnimations = min([numel(markerset) numel(bradyInds)]);
            [x,positions,h,titles] = deal(cell(nAnimations,1));
            if isempty(tiles)
                positions = Animal.linearPositions(nAnimations);
            elseif (numel(tiles) == 2) && isnumeric(tiles)
                positions = Animal.tilePositions(tiles(1),tiles(2));
            end
            
            % Randomly select the bouts to use.
            if nAnimations > numel(bradyInds)
                boutId = randperm(numel(bradyInds),numel(bradyInds));
            else
                boutId = randperm(numel(bradyInds),nAnimations);
            end
            
            % Find all of the MarkerAnimators associated with the animal
            isMA = contains(markerset,{'aligned','imputed','global'});
            isMA = isMA(1:numel(boutId));
            
            
            
            
            
            % Build a MarkerAnimator for each chunk. 
            figure('pos',[3, 237, 717, 551]); 
            for i = 1:nAnimations   
                if i > numel(bradyInds)
                   break; 
                end
                % Handle each type of chart appropriately
                switch markerset{i}
                    case 'aligned'
                        x{i} = obj.alignedMarkers(bradyInds{boutId(i)},:);
                        titles{i} = 'Aligned unimputed';
                    case 'imputed'
                        x{i} = obj.imputedMarkers(bradyInds{boutId(i)},:);
                        titles{i} = 'Aligned imputed';
                    case 'global'
                        x{i} = obj.markers(bradyInds{boutId(i)},:);
                        titles{i} = 'Global';
                    otherwise
                        error(['Improper markerset. Must be aligned, ' ...
                            'imputed, or global.']);
                end              
                if isMA(i)
                    if plotSimple
                       skel = obj.skeleton;
                       cVals = ones(size(obj.skeleton.segments.color,1),3);
                       skel.segments.color = mat2cell(cVals,ones(size(cVals,1),1));
                    else
                       skel = obj.skeleton;
                    end
                    
                    h{i} = MarkerAnimator('markers',x{i},...
                        'skeleton',skel,...
                        'frameRate',3,...
                        'AxesPosition',positions{i},...
                        'id',i);
                end
            end
            
            % Set the figure keypress function to iterate through all
            % charts' keypress functions.
            set(h{1}.Parent,'WindowKeyPressFcn',...
                @(src,event) Animator.runAll(h,src,event));

            % Link the axes of the MarkerAnimator objects
            obj.hlinkBrady = linkprop(h{1}.Parent.Children(isMA(end:-1:1)),...
                {'CameraPosition','CameraUpVector'});
            
            % Set axis colors and turn of axes
            for i = 1:numel(h{1}.Parent.Children)
                h{1}.Parent.Children(i).Color = [0 0 0];
                axis(h{1}.Parent.Children(i),'off');
            end
            obj.hBrady = h;
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
            
            % If there is no animation, make one restricted to frameIds
            % If there is a brady movie, use that. 
            % Otherwise, use the restrictedFrames of the existing animation
            if isempty(obj.h)
                mm = movie(obj,markerset,[1 2],frameIds);
            elseif ~isempty(obj.hBrady)
                mm = obj.hBrady;
            else
                mm = obj.h;
            end
            if (numel(mm) == 1) && (~iscell(mm)); mm = {mm}; end
            
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
    
    methods (Static)
       function positions = tilePositions(nIaxes,nJaxes)
            positions = cell(nIaxes*nJaxes,1);
            count = 1;
            for i = 1:nIaxes
                for j = 1:nJaxes
                    height = (1/nIaxes);
                    width = (1/nJaxes);
                    bottom = 1 - (i/nIaxes);
                    left = ((j-1)/nJaxes);
                    positions{count} = [left bottom width height];
                    count = count + 1;
                end
            end
        end
        
        function positions = linearPositions(numComparisons)
            positions = cell(numComparisons,1);            
            for i = 1:numComparisons
                left = (i-1)*(1/numComparisons);
                bottom = 0;
                width = (1/numComparisons);
                height = 1;
                positions{i} = [left bottom width height];
            end
        end 
    end

end