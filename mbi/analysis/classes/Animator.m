classdef (Abstract) Animator < Chart
    %Animator - Abstract superclass for data animation. Subclass of Chart.
    %
    %Animator Properties:
    %   frame - current frame of animation
    %   frameRate - current frame rate. 
    %
    %Animator methods: 
    %   Animator - constructor
    %   delete - delete Animator
    %   get/set frame
    %   get/set frameRate
    %   restrict - restrict animation to subset of frames
    %   keyPressCallback - callback function
    properties (Access = protected)
        frameInds
        nFrames
    end
    
    properties (Access = public)
        frameRate = 1;
        frame = 1;
        id
        scope
    end
    
    methods
        function obj = Animator(varargin)
            %Animator - constructor for Animator abstract class.
            
            % User defined inputs
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            
            % Set up the figure and callback function
            obj.Parent = gcf;
            addToolbarExplorationButtons(gcf);
            set(obj.Parent,'WindowKeyPressFcn',...
                @(src,event) keyPressCallback(obj,src,event));
            
            % Set up the axes
            hold(obj.Axes,'on');
            obj.Axes.DeleteFcn = @obj.onAxesDeleted;
        end
        
        function delete(obj)
            delete(obj.Axes);
        end % delete obj
        
        function frame = get.frame( obj )
            frame = obj.frame;
        end % get.frame
        
        function set.frame( obj, newFrame )
            obj.frame= mod(newFrame,obj.nFrames);
            if obj.frame == 0
                obj.frame = obj.nFrames;
            end
            update(obj)
        end % set.frame
        
        function frameRate = get.frameRate( obj )
            frameRate = obj.frameRate;
        end % get.frame
        
        function set.frameRate( obj, newframeRate )
            obj.frameRate = newframeRate;
            if obj.frameRate < 1
                obj.frameRate = 1;
            end
        end % set.frame
        
        function frameInds = getFrameInds(obj)
            frameInds = obj.frameInds;
        end
        
        function restrict(obj, newFrames)
            obj.frameInds = newFrames;
            obj.nFrames = numel(newFrames);
            obj.frame = 1;
        end
        
        function keyPressCallback(obj,source,eventdata)
            % determine the key that was pressed
            keyPressed = eventdata.Key;
%             disp(keyPressed)
            switch keyPressed
                case 'rightarrow'
                    newVals = num2cell([obj.frame] + [obj.frameRate]);
                    [obj.frame] = newVals{:};
                case 'leftarrow'
                    newVals = num2cell([obj.frame] - [obj.frameRate]);
                    [obj.frame] = newVals{:};
                case 'uparrow'
                    newVals = num2cell([obj.frameRate] + 10);
                    [obj.frameRate] = newVals{:};
                case 'downarrow'
                    newVals = num2cell([obj.frameRate] - 10);
                    [obj.frameRate] = newVals{:};
                case 'space'
                    newVals = num2cell(ones(numel(obj),1));
                    [obj.frameRate] = newVals{:};
                case 'control'
                    newVals = num2cell(ones(numel(obj),1)*50);
                    [obj.frameRate] = newVals{:};
                case 'shift'
                    newVals = num2cell(ones(numel(obj),1)*250);
                    [obj.frameRate] = newVals{:};
                case {'1','2','3','4','5','6','7','8','9'}
                    val = str2double(keyPressed);
                    newVals = num2cell(repmat(val,numel(obj),1));
                    [obj.scope] = newVals{:};
                    fprintf('Scope is Animation %d\n', val);
            end
        end
    end
    
    methods (Abstract, Access = protected)
        update(obj)
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
%             %          that listen for key presses.
%             firstClass = class(h{1});
%             for i = 1:
            for i = 1:numel(h)
                keyPressCallback(h{i},src,event)
            end
            
%             keyPressCallback([h{:}],src,event)
            
        end
    end
end