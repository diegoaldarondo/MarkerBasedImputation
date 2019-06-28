classdef embedMovie < Chart
   %embedMovie - interactive movie of movement through behavioral embedding
   %
   %Syntax: embedMovie('embed',embed,'embedFrames',...
   %                    embedFrames,'numFrames',numFrames)
   %
   %embedMovie Properties:
   %    embed - embedded points (replicated so size matches numFrames); 
   %    embedFrames - corresponding movie Frames (replicated)
   %    AxesPosition - Position of axes within parent figure
   %    Frame  - Frame number
   %    frameRate - frame rate
   %    scatterFig - handle to the background scatter plot
   %    currentPoint - handle to the current point
   %    animal - handle to the calling Animal object to sync with
   %             MarkerMovies. 
    properties (Access = private)
        instructions = ['embedMovie Guide:\n' ...
            'rightarrow: next frame\n' ...
            'leftarrow: previous frame\n' ...
            'uparrow: increase frame rate by 10\n' ...
            'downarrow: decrease frame rate by 10\n' ...
            'space: set frame rate to 1\n' ...
            'control: set frame rate to 50\n' ...
            'shift: set frame rate to 250\n' ...
            'h: help guide\n' ...
            'i: input polygon\n' ...
            'r: reset\n' ...
            's: print current matched frame and rate\n'];
        statusMsg = 'EmbedMovie:\nFrame: %d\nframeRate: %d\n'
        numFrames
        poly
        pointsInPoly
        embedX
        embedY
        frameInds
    end
    
    properties (Access = public)
        embed
        embedFrames
        AxesPosition = [0 0 1 1]
        Frame = 1
        frameRate = 1
        scatterFig
        currentPoint
        animal
    end
    
    methods
        function obj = embedMovie(varargin)
            % User defined inputs
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            obj.frameInds = obj.embedFrames;           
            [obj.frameInds, I] = deal(zeros(obj.numFrames,1));
            count = 1;
            for i = 1:numel(obj.frameInds)
                if i <= obj.embedFrames(count)
                    obj.frameInds(i) = obj.embedFrames(count);
                else
                    if count < numel(obj.embedFrames)
                        count = count + 1;
                    end
                    obj.frameInds(i) = obj.embedFrames(count);
                end
                I(i) = count;
            end
            
            % Set up the figure
            obj.Parent = gcf; hold on;
            addToolbarExplorationButtons(gcf);
            set(obj.Parent,'WindowKeyPressFcn',...
                @(src,event) keyPressCallback(obj,src,event));
            set(obj.Axes,'Units','normalized',...
                'Position',obj.AxesPosition);
            
            % Create the backgound scatter
            c = lines(2);
            obj.scatterFig = scatter(obj.Axes,obj.embed(:,1),...
                obj.embed(:,2),2,c(1,:),'.');
            
            % Expand to fit the number of actual frames. This makes
            % indexing a whole lot easier later. 
            obj.embedX = obj.embed(I,1);
            obj.embedY = obj.embed(I,2);
            obj.embed = obj.embed(I,:);
            obj.embedFrames = obj.embedFrames(I);
            
            % Plot the current point
            obj.currentPoint = scatter(obj.Axes,obj.embedX(1),...
                obj.embedY(1),500,c(2,:),'.');
            axis off;
        end
        
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
        
        function restrictPoints(obj, newPoints)
            obj.embedX = obj.embed(newPoints,1);
            obj.embedY = obj.embed(newPoints,2);
            obj.frameInds = obj.embedFrames(newPoints);
            obj.numFrames = numel(obj.frameInds);                     
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
                  case 'i'
                      inputPoly(obj);
                  case 'r'
                      reset(obj);
              end
              update(obj);
        end
    end
    
    methods (Access = private)
        
        function reset(obj)
            if ~isempty(obj.poly)
                delete(obj.poly)
            end
            
            % Set embedMovie and associated MarkerMovies to the orig. size
            restrictPoints(obj,true(size(obj.embed,1),1));
            for i = 1:numel(obj.animal.h)
                if isa(obj.animal.h{i},'MarkerMovie')
                    restrictFrames(obj.animal.h{i},...
                                   1:size(obj.animal.h{i}.markers,1))
                end
            end
        end
        
        function inputPoly(obj)
            if ~isempty(obj.poly)
                delete(obj.poly)
            end
            
            % Draw a poly and find the points within. 
            obj.poly = drawpolygon(obj.Axes,'Color','w');
            xv = obj.poly.Position(:,1);
            yv = obj.poly.Position(:,2);
            obj.pointsInPoly = inpolygon(obj.embed(:,1),...
                                         obj.embed(:,2),xv,yv);
                                  
            % Find a window surrounding the frames within the polygon.                         
            behaviorWindow = -50:50;
            framesInPoly = obj.embedFrames(obj.pointsInPoly);
            framesInPoly = unique(framesInPoly);
            framesInPoly = framesInPoly + behaviorWindow;
            framesInPoly = unique(sort(framesInPoly(:)));
            framesInPoly = framesInPoly((framesInPoly > 0) &...
                (framesInPoly <= numel(obj.embedFrames)));
            % Restrict associated MarkerMovies to those frames
            for i = 1:numel(obj.animal.h)
                if isa(obj.animal.h{i},'MarkerMovie')
                    restrictFrames(obj.animal.h{i},framesInPoly)
                end
            end
            
            % Restrict the embedding movie to those frames
            restrictPoints(obj,framesInPoly);
        end
        
        function update(obj)
            set(obj.currentPoint,'XData',obj.embedX(obj.Frame),...
                                 'YData',obj.embedY(obj.Frame));
        end
    end
    
    methods (Static)
        
    end
end