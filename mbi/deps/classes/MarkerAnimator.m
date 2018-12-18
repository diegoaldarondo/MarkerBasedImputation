classdef MarkerAnimator < Animator
    %MarkerAnimator - Make a movie of markers tracked over time. Concrete
    %subclass of Animator.
    %
    %   MarkerAnimator Properties:
    %   lim - limits of viewing window
    %   camPosition - cameraPosition of viewing window
    %   AxesPosition - position of axes within figure
    %   frame - current frame number
    %   frameRate - current frame rate
    %   MarkerSize - size of markers
    %   LineWidth - width of segments
    %   movieTitle - title to display at top of movie
    %   markers - global markerset
    %   skeleton - skeleton relating markers to one another
    %   ScatterMarkers - handle to scatter plot
    %   PlotSegments - handles to linesegments
    %
    %   MarkerAnimator Methods:
    %   MarkerAnimator - constructor
    %   restrict - restrict the animation to a subset of the frames
    %   keyPressCallback - handle UI
    properties (Access = private)
        nMarkers
        markersX
        markersY
        markersZ
        color
        joints
        instructions = ['MarkerAnimator Guide:\n'...
            'rightarrow: next frame\n' ...
            'leftarrow: previous frame\n' ...
            'uparrow: increase frame rate by 10\n' ...
            'downarrow: decrease frame rate by 10\n' ...
            'space: set frame rate to 1\n' ...
            'control: set frame rate to 50\n' ...
            'shift: set frame rate to 250\n' ...
            'h: help guide\n'];
        statusMsg = 'MarkerAnimator:\nFrame: %d\nframeRate: %d\n'
    end
    
    properties (Access = public)
        lim = [-130 130]
        camPosition = [1.5901e+03 -1.7910e+03 1.0068e+03];
        MarkerSize = 20;
        LineWidth = 3;
        movieTitle
        markers
        skeleton
        AxesPosition = [0 0 1 1];
        ScatterMarkers
        PlotSegments
    end
    
    methods
        function obj = MarkerAnimator(varargin)
            %MarkerAnimator - constructor for MarkerAnimator class.
            %MarkerAnimator is a concrete subclass of Animator.
            %
            %   Syntax: MarkerAnimator(varargin);
            
            % User defined inputs
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            set(obj.Parent,'color','k')
            set(obj.Axes,'Units','normalized',...
                'Position',obj.AxesPosition,...
                'xlim',obj.lim,'ylim',obj.lim,'zlim',obj.lim,...
                'color','k','CameraPosition',obj.camPosition);
            
            % Private constructions
            obj.nFrames = size(obj.markers,1);
            obj.frameInds = 1:obj.nFrames;
            obj.markersX = obj.markers(:,1:3:end);
            obj.markersY = obj.markers(:,2:3:end);
            obj.markersZ = obj.markers(:,3:3:end);
            obj.nMarkers = size(obj.markers,2);
            obj.color = obj.skeleton.segments.color;
            obj.joints = cat(1,obj.skeleton.segments.joints_idx{:});
            
            % get color groups
            c = cell2mat(obj.color);
            [colors,~,cIds] = unique(c,'rows');
            [~, MaxNNodes] = mode(cIds);
            
            % Get the first frames marker positions
            curX = obj.markersX(obj.frame,:);
            curY = obj.markersY(obj.frame,:);
            curZ = obj.markersZ(obj.frame,:);            
            curX = curX(obj.joints)';
            curY = curY(obj.joints)';
            curZ = curZ(obj.joints)';
            
            %%% Very fast updating procedure with low level graphics. 
            % Concatenate with nans between segment ends to represent all 
            % segments with the same color as one single line object
            catnanX = cat(1,curX,nan(1,size(curX,2)));
            catnanY = cat(1,curY,nan(1,size(curY,2)));
            catnanZ = cat(1,curZ,nan(1,size(curZ,2)));
            
            % Put into array for vectorized graphics initialization
            nanedXVec = nan(MaxNNodes*3,size(colors,1));
            nanedYVec = nan(MaxNNodes*3,size(colors,1));
            nanedZVec = nan(MaxNNodes*3,size(colors,1));
            for i = 1:size(colors,1)
                nanedXVec(1:numel(catnanX(:,cIds==i)),i) = reshape(catnanX(:,cIds==i),[],1);
                nanedYVec(1:numel(catnanY(:,cIds==i)),i) = reshape(catnanY(:,cIds==i),[],1);
                nanedZVec(1:numel(catnanZ(:,cIds==i)),i) = reshape(catnanZ(:,cIds==i),[],1);
            end
            
            % Build line objects and set final properties
            obj.PlotSegments = line(obj.Axes,...
                nanedXVec,...
                nanedYVec,...
                nanedZVec,...
                'LineStyle','-',...
                'Marker','.',...
                'MarkerSize',obj.MarkerSize,...
                'LineWidth',obj.LineWidth);
            set(obj.PlotSegments, {'color'}, mat2cell(colors,ones(size(colors,1),1)));
            title(obj.Axes, obj.movieTitle,'Color','w',...
                'Position',[0,0,obj.lim(2)]);
        end % constructor
        
        function restrict(obj, newFrames)
            %restrict - restricts animation to a subset of frames
            obj.markersX = obj.markers(newFrames,1:3:end);
            obj.markersY = obj.markers(newFrames,2:3:end);
            obj.markersZ = obj.markers(newFrames,3:3:end);
            restrict@Animator(obj, newFrames);
        end
        
        
        function keyPressCallback(obj,source,eventdata)
            % keyPressCallback - Handle UI
            % Extends Animator callback function
            
            % Extend Animator callback function
            keyPressCallback@Animator(obj,source,eventdata);
            
            % determine the key that was pressed
            keyPressed = eventdata.Key;
            switch keyPressed
                case 'h'
                    message = obj(1).instructions;
                    fprintf(message);
                case 's'
                    fprintf(obj(1).statusMsg,...
                        obj(1).frameInds(obj(1).frame),obj(1).frameRate);
                    %                     for i = 1:numel(obj)
                    %                         fprintf(obj(i).statusMsg,...
                    %                             obj(i).frameInds(obj(i).frame),obj(i).frameRate);
                    %                     end
            end
        end
    end
    
    methods (Access = protected)
        function update(obj)
            % Find color groups
            c = cell2mat(obj.color);
            [colors,~,cIds] = unique(c,'rows');
            
            % Get the joints for the current frame
            curX = obj.markersX(obj.frame,:);
            curY = obj.markersY(obj.frame,:);
            curZ = obj.markersZ(obj.frame,:);
            curX = curX(obj.joints)';
            curY = curY(obj.joints)';
            curZ = curZ(obj.joints)';
            
            %%% Very fast updating procedure with low level graphics. 
            % Concatenate with nans between segment ends to represent all 
            % segments with the same color as one single line object
            catnanX = cat(1,curX,nan(1,size(curX,2)));
            catnanY = cat(1,curY,nan(1,size(curY,2)));
            catnanZ = cat(1,curZ,nan(1,size(curZ,2)));
            
            % Put into cell for vectorized graphics update
            nanedXVec = cell(size(colors,1),1);
            nanedYVec = cell(size(colors,1),1);
            nanedZVec = cell(size(colors,1),1);
            for i = 1:size(colors,1)
                nanedXVec{i} = reshape(catnanX(:,cIds==i),[],1);
                nanedYVec{i} = reshape(catnanY(:,cIds==i),[],1);
                nanedZVec{i} = reshape(catnanZ(:,cIds==i),[],1);
            end
            
            % Update the values
            valueArray = cat(2, nanedXVec, nanedYVec, nanedZVec);
            nameArray = {'XData','YData','ZData'};
            segments = obj.PlotSegments;
            set(segments,nameArray,valueArray)
        end
    end
end