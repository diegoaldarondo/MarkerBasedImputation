classdef MarkerMovie < Chart
    %MarkerMovie - Make a movie of markers tracked over time.
    %   
    %   MarkerMovie Properties:
    %   lim - limits of viewing window
    %   camPosition - cameraPosition of viewing window
    %   AxesPosition - position of axes within figure
    %   Frame - current frame number
    %   frameRate - current frame rate
    %   MarkerSize - size of markers
    %   LineWidth - width of segments
    %   movieTitle - title to display at top of movie
    %   markers - global markerset
    %   skeleton - skeleton relating markers to one another
    %   ScatterMarkers - handle to scatter plot
    %   PlotSegments - handles to linesegments
    properties (Access = private)
        numMarkers
        numFrames
        markersX
        markersY
        markersZ
        frameInds
        color
        joints
        instructions = ['rightarrow: next frame\n' ...
            'leftarrow: previous frame\n' ...
            'uparrow: increase frame rate by 10\n' ...
            'downarrow: decrease frame rate by 10\n' ...
            'space: set frame rate to 1\n' ...
            'control: set frame rate to 50\n' ...
            'shift: set frame rate to 250\n' ...
            'h: help guide\n'];
        statusMsg = 'MarkerMovie:\nFrame: %d\nframeRate: %d\n'
    end
    
    properties (Access = public)
        lim = [-130 130]
        camPosition = [1.5901e+03 -1.7910e+03 1.0068e+03];
        AxesPosition = [0 0 1 1]
        frameRate = 1
        Frame = 1
        MarkerSize = 20;
        LineWidth = 3;
        movieTitle
        markers
        skeleton
        ScatterMarkers
        PlotSegments
    end 
    
    methods
        function obj = MarkerMovie(varargin)
            % User defined inputs
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            
            % Set up the figure
            obj.Parent = gcf;
            addToolbarExplorationButtons(gcf);
            set(obj.Parent,'color','k')
            set(obj.Parent,'WindowKeyPressFcn',...
                @(src,event) keyPressCallback(obj,src,event));
            
            % Set up the axes
            hold(obj.Axes,'on');
            obj.Axes.DeleteFcn = @obj.onAxesDeleted;
            
            set(obj.Axes,'Units','normalized',...
                'Position',obj.AxesPosition,...
                'xlim',obj.lim,'ylim',obj.lim,'zlim',obj.lim,...
                'color','k','CameraPosition',obj.camPosition) 
            axis(obj.Axes,'off');
            
            % Private constructions
            obj.markersX = obj.markers(:,1:3:end);
            obj.markersY = obj.markers(:,2:3:end);
            obj.markersZ = obj.markers(:,3:3:end);
            
            obj.numFrames = size(obj.markers,1);
            obj.frameInds = 1:obj.numFrames;
            obj.numMarkers = size(obj.markers,2);
            obj.color = obj.skeleton.segments.color;
            obj.joints = cat(1,obj.skeleton.segments.joints_idx{:});
            
            % Initialize the markers
            curX = obj.markersX(obj.Frame,:);
            curY = obj.markersY(obj.Frame,:);
            curZ = obj.markersZ(obj.Frame,:);

            obj.PlotSegments = plot3(obj.Axes, curX(obj.joints)',...
                                     curY(obj.joints)',...
                                     curZ(obj.joints)',...
                                     '.-','MarkerSize',obj.MarkerSize,...
                                     'LineWidth',obj.LineWidth);
            set(obj.PlotSegments, {'color'}, obj.color);  
            title(obj.Axes, obj.movieTitle,'Color','w',...
                  'Position',[0,0,obj.lim(2)]); 
        end % constructor
        
        function delete(obj)
            delete(obj.Axes);
        end % delete obj
        
        function frame = get.Frame( obj )
            frame = obj.Frame;
        end % get.Frame
        
        function set.Frame( obj, newFrame )
            obj.Frame = mod(newFrame,obj.numFrames);
            if obj.Frame == 0
                obj.Frame = obj.numFrames;
            end
            update(obj)
        end % set.Frame
        
        function restrictFrames(obj, newFrames)
            obj.markersX = obj.markers(newFrames,1:3:end);
            obj.markersY = obj.markers(newFrames,2:3:end);
            obj.markersZ = obj.markers(newFrames,3:3:end);
            obj.frameInds = newFrames;
            obj.numFrames = numel(newFrames);
            obj.Frame = 1;
        end
        
        function frameRate = get.frameRate( obj )
            frameRate = obj.frameRate;
        end % get.Frame
        
        function set.frameRate( obj, newframeRate )
            obj.frameRate = newframeRate;
            if obj.frameRate < 1
               obj.frameRate = 1;
            end
        end % set.Frame
        
        function keyPressCallback(obj,source,eventdata)
              % determine the key that was pressed
              keyPressed = eventdata.Key;
              switch keyPressed
                  case 'rightarrow'
                      obj.Frame = obj.Frame + obj.frameRate;
                  case 'leftarrow'
                      obj.Frame = obj.Frame - obj.frameRate;
                  case 'uparrow'
                      obj.frameRate = obj.frameRate + 10;
                  case 'downarrow'
                      obj.frameRate = obj.frameRate - 10;
                  case 'space'
                      obj.frameRate = 1;
                  case 'control'
                      obj.frameRate = 50;
                  case 'shift'
                      obj.frameRate = 250;
                  case 'h'
                      fprintf(obj.instructions);
                  case 's'
                      fprintf(obj.statusMsg,...
                              obj.frameInds(obj.Frame),obj.frameRate);
              end
              update(obj);
        end  
    end 
    
    methods (Static)
        function runAll(h,src,event)
            %runAll - iterate through the keyPressCallback function of all
            %charts within a cell array.
            %
            %   Syntax: runAll(h,src,event);
            %
            %   Notes: It is useful to assign this function as the 
            %          WindowKeyPressFcn of a figure with multiple axes
            %          that listen for key presses. 
            for i = 1:numel(h)
                keyPressCallback(h{i},src,event)
            end
        end
    end

    methods (Access = private)
        
        function update(obj)
            % Create the chart graphics
            curX = obj.markersX(obj.Frame,:);
            curY = obj.markersY(obj.Frame,:);
            curZ = obj.markersZ(obj.Frame,:);           
            for i = 1:size(obj.joints,1)
                set(obj.PlotSegments(i),'XData',curX(obj.joints(i,:)),...
                                        'YData',curY(obj.joints(i,:)),...
                                        'ZData',curZ(obj.joints(i,:)))
            end         
        end   
    end     
end