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
            axis(obj.Axes,'off');
            
            % Private constructions
            obj.nFrames = size(obj.markers,1);
            obj.frameInds = 1:obj.nFrames;
            obj.markersX = obj.markers(:,1:3:end);
            obj.markersY = obj.markers(:,2:3:end);
            obj.markersZ = obj.markers(:,3:3:end);
            obj.nMarkers = size(obj.markers,2);
            obj.color = obj.skeleton.segments.color;
            obj.joints = cat(1,obj.skeleton.segments.joints_idx{:});
            
            % Initialize the markers
            curX = obj.markersX(obj.frame,:);
            curY = obj.markersY(obj.frame,:);
            curZ = obj.markersZ(obj.frame,:);
            
            obj.PlotSegments = plot3(obj.Axes, curX(obj.joints)',...
                curY(obj.joints)',...
                curZ(obj.joints)',...
                '.-','MarkerSize',obj.MarkerSize,...
                'LineWidth',obj.LineWidth);
            set(obj.PlotSegments, {'color'}, obj.color);
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
                    fprintf(obj.instructions);
                case 's'
                    fprintf(obj.statusMsg,...
                        obj.frameInds(obj.frame),obj.frameRate);
            end
            update(obj);
        end
    end
    
    methods (Access = protected)
        function update(obj)
            % Create the chart graphics
            curX = obj.markersX(obj.frame,:);
            curY = obj.markersY(obj.frame,:);
            curZ = obj.markersZ(obj.frame,:);
            for i = 1:size(obj.joints,1)
                set(obj.PlotSegments(i),'XData',curX(obj.joints(i,:)),...
                    'YData',curY(obj.joints(i,:)),...
                    'ZData',curZ(obj.joints(i,:)))
            end
        end
    end
end