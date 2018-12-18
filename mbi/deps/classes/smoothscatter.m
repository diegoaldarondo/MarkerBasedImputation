classdef smoothscatter < Chart
    
    properties (Access = private)
        State = 'Scatter'
        kdSkip = .2;
        binSkip = 10;
        binlims
        params
    end
    
    properties (Access = public)
        kdBandWidth = 1;
        XData
        kd
        YData
        Scatter
        KDEstimate
        numPoints = 100;
        binSlider
        kdSlider
    end
    
    methods
        
        function obj = smoothscatter(X,Y,varargin)
            % User defined inputs
            obj.params = varargin;
%             if ~isempty(varargin)
%                 set(obj,varargin{:});
%             end
            obj.XData = X;
            obj.YData = Y;
            
            obj.Parent = figure;
%             hold(obj.Axes,'on');
            obj.Axes.DeleteFcn = @obj.onAxesDeleted;
            set(obj.Parent,'WindowKeyPressFcn',...
                @(src,event) keyPressCallback(obj,src,event));
            
            obj.Scatter = scatter(X,Y, varargin{:});
            axis(obj.Axes,'equal');
            obj.binlims = axis(obj.Axes);
            axis(obj.Axes,obj.binlims);
            set(obj.Axes,'position',[0.15 0.15  0.75 0.75])
            
            
            obj.binSlider = uicontrol('Parent',obj.Parent,'Style',...
                'Slider','Units','normalized','Position',[.15,0,.75,.025],...
                'value',obj.numPoints, 'min',1, 'max',250);
            obj.binSlider.Callback = @(es,ed) updateNumBins(obj,es,ed);
            obj.kdSlider = uicontrol('Parent',obj.Parent,'Style',...
                'Slider','Units','normalized','Position',[.15,.05,.75,.025],...
                'value',obj.kdBandWidth, 'min',.01, 'max',10);
            obj.kdSlider.Callback = @(es,ed) updateKdKernel(obj,es,ed);
        end
        
        function updateNumBins(obj,es,ed)
            obj.numPoints = round(es.Value);
            update(obj);
        end
        
        function updateKdKernel(obj,es,ed)
            obj.kdBandWidth = round(es.Value);
            update(obj);
        end
        
        function keyPressCallback(obj,source,eventdata)
              % determine the key that was pressed
              keyPressed = eventdata.Key;
              switch keyPressed
                  case 's'
                      obj.State = 'Scatter';
                  case 'k'
                      obj.State = 'KDEstimate';
                  case 'b'
                      obj.State = 'BinScatter';
                  case 'downarrow'
                      if strcmp(obj.State,'BinScatter')
                          obj.numPoints = obj.numPoints - 10;
                      elseif strcmp(obj.State,'KDEstimate')
                          obj.kdBandWidth = obj.kdBandWidth - 10;
                      end
                  case 'uparrow'
                      if strcmp(obj.State,'BinScatter')
                          obj.numPoints = obj.numPoints + obj.binSkip;
                          if obj.numPoints > 250 % binscatter limit
                              obj.numPoints = 250;
                          end
                      elseif strcmp(obj.State,'KDEstimate')
                          obj.kdBandWidth = obj.kdBandWidth + obj.kdSkip;
                      end
              end
              update(obj);
        end 
        
        function scatterpts(obj)
            cla(obj.Axes)
            scatter(obj.Axes,obj.XData,obj.YData,obj.params{:});
            axis(obj.Axes,'equal')
            axis(obj.Axes,obj.binlims);
            obj.State = 'Scatter';
        end
        
        function estimateKD(obj)
            
            minVal = min(min(obj.XData),min(obj.YData));
            maxVal = max(max(obj.XData),max(obj.YData));
            [xpoints,ypoints] = deal(linspace(minVal,maxVal,obj.numPoints));
            x = repelem(xpoints,numel(xpoints));
%             ypoints = linspace(min(obj.YData),max(obj.YData),obj.numPoints);
            y = repmat(ypoints,1,numel(ypoints));
            pts = [x;y]';
            [f,xi] = ksdensity([obj.XData, obj.YData],pts,'BandWidth',obj.kdBandWidth);
            grid = meshgrid(xpoints,ypoints);
            obj.kd = zeros(size(grid));
            obj.kd(:) = f;
            
            cla(obj.Axes)
            imagesc(obj.Axes, obj.kd);
            set(obj.Axes,'XLim',[0 size(obj.kd,1)],...
                'YLim',[0 size(obj.kd,2)],'position',[0.15 0.15  0.75 0.75])
            axis(obj.Axes,'xy')
            axis(obj.Axes,'fill')
            obj.State = 'KDEstimate';
        end
        
        function createBinScatter(obj)
            cla(obj.Axes)
            binscatter(obj.Axes,obj.XData,obj.YData,obj.numPoints);
            axis(obj.Axes,'equal')
            axis(obj.Axes,obj.binlims);
            obj.State = 'BinScatter';
        end
        
        function update(obj)
            switch obj.State
                case 'Scatter'
                    scatterpts(obj);
                case 'BinScatter'
                    createBinScatter(obj);
                case 'KDEstimate'
                    estimateKD(obj);
            end
        end
    end
end