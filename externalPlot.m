classdef externalPlot < handle
    % opens an axis in a new figure which can be controlled by the calling
    % object to change the data displayed.
   
    properties
        f
        
        %% UI properties
        figurePos
        panelPos
        
        %% UI elements
        pControls
        pPlot
        
        hAx
        hPlot
        hPlotPoint
        hPopDim
        hTextIndex
        
        xaxes % struct-cell containing x-axis information for each dimension
        
        %% input properties
        dimLabel
        dimVal
        unit
        cDim    % index of the currently shown dimension
        MinMax
        nPlots
        
        
    end
    
    
    properties (Constant, Access = private)
        % UI PROPERTIES
        % default figure position depends on the screen size. It will
        % appear in the top rigt
        % absolute width of Control panel in pixel
        controlHeight = 50; % px
        %         sliderHeight  = 20;  % px
        %         sliderPadding = 4;   % px
    end
    
    
    events
        dimChanged
    end
    
    methods
        function obj = externalPlot(varargin)
            % CONSTRUCTOR
            
            screenSize = get(0,'ScreenSize');
            defaultPosition = [ 1/2*screenSize(3), 1/2*screenSize(4), 1/3*screenSize(3), 1/3*screenSize(4)];
  
            p = inputParser;
            addParameter(p, 'nPlots',               1, @(x) isnumeric(x));
            addParameter(p, 'Position',             defaultPosition,  @(x) isnumeric(x));
            addParameter(p, 'unit',                 '', @(x) ischar(x) || iscell(x));
            addParameter(p, 'DimLabel',             '', @(x) ischar(x) || iscell(x));
            addParameter(p, 'DimVal',               {}, @iscell);
            addParameter(p, 'initDim',              1,  @(x) isnumeric(x));
            addParameter(p, 'MinMax',               [], @(x) isnumeric(x));
           
            parse(p, varargin{:});
            
            obj.nPlots          = p.Results.nPlots;
            obj.figurePos       = p.Results.Position;
            obj.dimLabel        = p.Results.DimLabel;
            obj.dimVal          = p.Results.DimVal;
            obj.unit            = p.Results.unit;
            obj.cDim            = p.Results.initDim;
            obj.MinMax          = p.Results.MinMax;
            
            obj.createGUI()
        end
        
        
        function createGUI(obj)
            % create figure handle
            obj.f = figure(...
                'Units',                'pixel', ...
                'Position',             obj.figurePos, ...
                'Visible',              'off', ...
                'ResizeFcn',            @obj.guiResize, ...
                'CloseRequestFcn',      @obj.closeRqst);
            
            obj.setPanelPos()
            
            %% create panels
            obj.pControls = uipanel( ...
                'Units',            'pixels', ...
                'Position',         obj.panelPos(1, :));
            
            obj.pPlot = uipanel( ...
                'Units',            'pixels', ...
                'Position',         obj.panelPos(2, :));
            
            %% pControl
            obj.hPopDim = uicontrol( ...
                'Units',                'pixels', ...
                'Parent',               obj.pControls, ...
                'Position',             [10 10 100 30], ...
                'Style',                'popup', ...
                'String',               obj.dimLabel, ...
                'Value',                obj.cDim, ...
                'Callback',             @obj.changeDim);
            
            obj.hTextIndex = uicontrol( ...
                'Units',                'pixels', ...
                'Parent',               obj.pControls, ...
                'Position',             [130 10 150 30], ...
                'Style',                'text', ...
                'String',               'Index: ');
            
            %% pPlot
            obj.hAx = axes( ...
                'Parent',               obj.pPlot, ...
                'Units',                'normalized', ...
                'Position',             [0.1 0.15 0.85 0.80]);
            xlabel(obj.dimLabel(obj.hPopDim.Value))
            hold on
            
            %for ii = 1:obj.nPlots
                obj.hPlot = plot([0 1], [1 1], ...
                    'Marker',               'x');
            %end
            
            obj.hPlotPoint = plot([0 1], [1 1], ...
                'Marker',               'x', ...
                'MarkerSize',           10, ...
                'LineWidth',            2);
            
            if ~isempty(obj.MinMax)
                set(obj.hAx, 'YLim', obj.MinMax)
            end
            
            obj.prepareXaxis();
            
            % after everything is created, make the figure visible
            set(obj.f, 'Visible', 'on');
        end
        
        function prepareXaxis(obj)
            
            % find axis with values that cannot be converted to numbers
            for ii = 1:numel(obj.dimVal)
                obj.xaxes{ii}.ticklabels = obj.dimVal{ii};
                
                if iscell(cellfun(@str2num, obj.dimVal{ii}, 'UniformOutput', false))
                    % some entries in dimVal for this axis cannot be
                    % converted to numbers
                    obj.xaxes{ii}.tickvalues = 1:numel(obj.dimVal{ii});
                else
                    % all enries in dimVal can be converted to numbers
                    obj.xaxes{ii}.tickvalues = cellfun(@str2num, obj.dimVal{ii});
                end
            end
            
        end
        
        
        function plotData(obj, y)
            %set(obj.hPlot, 'XData', x)
            set(obj.hPlot, 'XData', obj.xaxes{obj.cDim}.tickvalues)
            set(obj.hPlot, 'YData', y)
        end
        
        
        function plotPoint(obj, x, y)
            set(obj.hPlotPoint, 'XData', x)
            set(obj.hPlotPoint, 'YData', y)
        end
        
        
        function setDimension(obj, dimNo)
            % called from extern to let the plot panel know about a
            % necessary change of dimension, i.e. when the plotted
            % dimensions are changed.
            
            obj.cDim = dimNo;
            obj.hAx.XLabel.String = obj.dimLabel(obj.cDim);
            obj.hAx.XTickLabels = obj.xaxes{obj.cDim}.ticklabels;
            obj.hAx.XTick = obj.xaxes{obj.cDim}.tickvalues;
            set(obj.hPopDim,    'Value', obj.cDim);
            
        end
        
        
        function setIndexString(obj, string)
            % called from extern to let the plot panel know about a
            % necessary change of dimension, i.e. when the plotted
            % dimensions are changed.
            
            set(obj.hTextIndex,    'String', string);
            
        end
        
        
        function changeDim(obj, ~, ~)
            % call the calling function and request data from a different
            % dimension
            
            obj.hAx.XLabel.String = obj.dimLabel(obj.hPopDim.Value);
            notify(obj, 'dimChanged')
            
        end
        
        
        function closeRqst(obj, ~, ~)
            % closeRqst is called, when the user closes the figure (by 'x' or
            % 'close'). It closes the figure.            
            
            delete(obj.f);
            delete(obj)
        end
        
        
        function setPanelPos(obj)            
            % create a 3x4 array that stores the 'Position' information for
            % the four panels pImage, pSlider, pControl and pColorbar
            
            obj.figurePos = get(obj.f, 'Position');
            
            % pControl
            obj.panelPos(1, :) =    [1 ...
                                    obj.figurePos(4) - obj.controlHeight ...
                                    obj.figurePos(3)...
                                    obj.controlHeight];
                                
            % pPlot
            obj.panelPos(2, :) =    [1 ...
                                    1 ...
                                    obj.figurePos(3) ...
                                    obj.figurePos(4) - obj.controlHeight];
        end
        
        
        function guiResize(obj, ~, ~)
            obj.figurePos = get(obj.f, 'Position');
            
            if obj.figurePos(4) < obj.controlHeight
                % make sure the window is tall enough
                 obj.f.Position(4) = obj.controlHeight;
            end
            
            obj.setPanelPos()            
            set(obj.pControls,  'Position', obj.panelPos(1, :));
            set(obj.pPlot,      'Position', obj.panelPos(2, :));
        end
    end    
end