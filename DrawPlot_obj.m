classdef DrawPlot_obj < handle
    % DRAWPLOT plots a line profile from one or more multidimensional matrices.
    %
    %  DRAWPLOT(mat)
    % opens a figure that can plot data along all dimensions of mat.
    %
    %  DRAWPLOT(mat1, mat2, ...)
    % opens a figure that can simultaneously plot data along all dimensions of
    % the input matrices mat1, mat2, ...
    %
    %NAME-VALUE PAIRS
    %
    %   NAME        TYPE        DEFAULT         DESCRIPTION
    %
    %   LineStyle   string      []              Allows to specify the line
    %                                           apperance in the same way it is
    %                                           possible with matlabs plot
    %                                           function.
    %   DimLabel    {char}      []              cell array containing character
    %                                           vectors the describe the
    %                                           dimensions of the data and will
    %                                           be shown next to the sliders.
    %   InputNames  {char}      []              cell array containing character
    %                                           vectors that describe the
    %                                           matrices and are shown in the
    %                                           plot-legend.
    %   DimVal      {double}                    Cell array that contains a
    %                                           1D-double array for each
    %                                           dimension in the input data
    %                                           which will be used for the
    %                                           x-axes. Default values are
    %                                           linear indices counting from 1
    %                                           to the dimension size. Leave
    %                                           cell empty for default values.
    
    % -------------------------------------------------------------------------
    %   TODO
    % -------------------------------------------------------------------------
    % - show value at indicator position
    % - change the way of mouse-navigation:
    %       left-click, change center for x and y axis
    %       right-click, change width for x- and y-axis
    
    % -------------------------------------------------------------------------
    %   Check name-value pairs and set initial values
    % -------------------------------------------------------------------------
    
    properties (Access = public)
        
        fig
        
    end
    
    
    properties (Access = private)
        
        nMats           % number of input matrices
        nSlider         % number of non-singleton dimensions
        nDims           % number of dimensions
        mat             % cell array containing the input matrices
        isComplex       % is one of the inputs complex
        inputNames      % names of the input matrices, shown in legend
        varargin        % all input data is stored in varargin
        p               % input parser
        S               % size of input matrices
        unit            % physical unit of the input data
        minVal          % minVal of all inputData
        maxVal          % maxVal of all inputData
        
        %% DISPLAYING
        
        % showDim specifies the dimension that is currently displayed on
        % the xaxis
        showDim
        
        % stores the current complex representation mode
        complexMode
        
        % cell array that stores the location information in the input data
        % of each currently shown line profile.
        sel
        
        % index of the currently active dimension for slider scrolling
        % etc...
        activeDim
        
        % label for each dimension
        dimLabel
        
        % values for each dimension
        dimVal
        
        % apperance of plotted lines
        lineStyle
        
        % store currently shown x-data
        currXData
        
        % store currently shown y-data
        currYData
        
        %% GUI elements
        
        sliderPanelHeight    % absolute height of slider panel
        controlPanelWidth    % width of control panel Ü(normalized)
        
        % panels
        pPlot
        pSlider
        pControl
        
        % slider handles
        hSliderLabel
        hSlider
        hIndex
        
        % button handles
        hBtnCmp
        
        % plot elements
        hAxis
        hVertLine
        hPlot
        hLine
        
        xaxes
        
        %% external
        bUpdateCaller
        hBtnToggleUpdateCaller 
    end
    
    
    events
        selChanged
    end
    
    
    methods
        function obj = DrawPlot_obj(varargin)
            % CONSTRUCTOR
            obj.varargin = varargin;
            
            obj.checkInputMatrices();
            
            % The slider for which dimension is initially active?
            obj.activeDim   = 1;
            
            % set the correct default value for complexMode
            if any(obj.isComplex)
                obj.complexMode = 1;
            else
                % if neither input is complex, display the real part of the
                % data
                obj.complexMode = 3;
            end
            
            % per default, update the caller about selection changes
            obj.bUpdateCaller = 1;
            
            % prepare the input parser
            obj.parseNVPs();
            
            obj.prepareXaxes();
            
            obj.initializeGUI();
            
            % set initial plot-dimension
            obj.changeDimension(obj.hSliderLabel(1))
            
            % -------------------------------------------------------------------------
            % Last step, make figure visible
            % -------------------------------------------------------------------------
            obj.refreshUI()
            set(obj.fig, 'Visible', 'on');
            
            % do not assign to 'ans' when called without assigned variable
            if nargout == 0
                clear obj
            end
        end
        
        
        function delete(obj)
            % DESTRUCTOR
            delete(obj)
        end
        
        
        function checkInputMatrices(obj)
            % how many matrices are in varargin?
            obj.nMats = find(cellfun(@ischar, obj.varargin), 1, 'first') - 1;
            if isempty(obj.nMats)
                % no name value pair was provided
                obj.nMats = numel(obj.varargin);
            end
            
            % define mats in order to suppress warnings
            obj.mat = cell(obj.nMats);
            obj.isComplex = zeros(obj.nMats, 1);
            
            % create a fixed loop counter
            N = obj.nMats;
            fixidx = 1;
            for idx = 1:N
                
                % check if this matrix actually has data
                if isempty(obj.varargin{1})
                    obj.nMats = obj.nMats - 1;
                else
                    obj.isComplex(fixidx) = ~isreal(obj.varargin{1});
                    obj.mat{fixidx} = obj.varargin{1};
                    fixidx = fixidx + 1;
                end
                
                % at the same time, remove matrices from varargin to save space
                obj.varargin(1) = [];
            end
            
            obj.S = size(obj.mat{1});
            
            % number of Sliders
            obj.nSlider   = ndims(obj.mat{1});
            
            % number of dimensions
            obj.nDims = numel(obj.S);
        end
        
        
        function parseNVPs(obj)
            
            obj.p = inputParser;
            
            % prepare default selector
            obj.sel = num2cell(ceil(obj.S/2));
            
            addParameter(obj.p, 'InputNames',   {},                             @(x) ischar(x) || (iscell(x) && numel(x) == obj.nMats));
            addParameter(obj.p, 'LineStyle',     repmat({'-'}, 1, obj.nMats),   @(x) ischar(x) || (iscell(x) && numel(x) == obj.nMats));
            addParameter(obj.p, 'InitSel',      obj.sel,                        @(x) isnumeric(x) && x <= 4);
            addParameter(obj.p, 'ComplexMode',  obj.complexMode,                @(x) isnumeric(x) && x <= 4);
            addParameter(obj.p, 'DimLabel',     strcat(repmat({}, 1, numel(obj.S))), @(x) iscell(x) && numel(x) >= obj.nDims);
            addParameter(obj.p, 'DimVal',       cellfun(@(x) 1:x, num2cell(obj.S), 'UniformOutput', false), @iscell);
            addParameter(obj.p, 'Unit',         '',                             @(x) ischar(x) || iscell(x));
            addParameter(obj.p, 'InitDim',      1,                              @isnumeric);
            addParameter(obj.p, 'MinMax',       [0 1],                          @isnumeric);
            
            parse(obj.p, obj.varargin{:});
            
            obj.complexMode         = obj.p.Results.ComplexMode;
            obj.inputNames          = obj.p.Results.InputNames;
            obj.lineStyle           = obj.p.Results.LineStyle;
            obj.unit                = obj.p.Results.Unit;
            obj.showDim             = obj.p.Results.InitDim;
            
            obj.minVal = obj.p.Results.MinMax(1);
            obj.maxVal = obj.p.Results.MinMax(2);
            
            obj.parseDimLabelsVals()
        end
        
        
        function initializeGUI(obj)
            % -------------------------------------------------------------------------
            %   Create Figure and partition into panels
            % -------------------------------------------------------------------------
            
            fWidth0  = 400;
            fHeight0 = 200;
            fWidth   = 800;
            fHeight  = 600;
            
            
            obj.sliderPanelHeight = (obj.nSlider+1) * 30;%px
            obj.controlPanelWidth = 0.2;
            
            obj.fig = figure( ...
                'Position',             [fWidth0 fHeight0 fWidth fHeight], ...
                'Units',                'pixel', ...
                'ResizeFcn',            @obj.guiResize, ...
                'Visible',              'off', ...
                'WindowScrollWheelFcn', @obj.scrollSlider);
            
            % -------------------------------------------------------------------------
            % define the plot panel and slider panel.
            % -------------------------------------------------------------------------
            
            lDiv = 0.2;
            
            obj.pPlot  = uipanel( ...
                'Units',        'pixels', ...
                'Position',     [0 obj.sliderPanelHeight fWidth fHeight-obj.sliderPanelHeight]);
            
            obj.pSlider = uipanel( ...
                'Units',        'pixels', ...
                'Position',     [lDiv*fWidth 0 (1-lDiv)*fWidth obj.sliderPanelHeight]);
            
            obj.pControl = uipanel( ...
                'Units',        'pixels', ...
                'Position',     [0 0 lDiv*fWidth obj.sliderPanelHeight]);
            
            % -------------------------------------------------------------------------
            % initialize elements in pSlider
            % -------------------------------------------------------------------------
            
            % divison of Slider panel width (sum must equal 1) into spaces for
            % [Label Index Slider]
            division = [0.15 0.1 0.75];
            % top and bottom padding in normalized units
            tb_pad = 0.05;
            sliderHeight = (1-2*tb_pad)/(obj.nSlider+1);
            
            for iSlider = 1:obj.nSlider
                obj.hSliderLabel(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'togglebutton', ...
                    'Units',            'normalized', ...
                    'Position',         [0 ...
                    1-tb_pad-iSlider*sliderHeight ...
                    division(1) ...
                    sliderHeight], ...
                    'String',           obj.dimLabel{iSlider}, ...
                    'FontUnits',        'normalized', ...
                    'FontSize',         0.8, ...
                    'Callback',         {@obj.changeDimension});
                
                obj.hIndex(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'edit', ...
                    'Units',            'normalized', ...
                    'Position',         [division(1) ...
                    1-tb_pad-iSlider*sliderHeight ...
                    division(2) ...
                    sliderHeight], ...
                    'String',           obj.dimVal{iSlider}{obj.sel{iSlider}}, ...
                    'FontUnits',        'normalized', ...
                    'FontSize',         0.8, ...
                    'Enable',           'Inactive', ...
                    'ButtonDownFcn',    @removeListener);
                set(obj.hIndex(iSlider), 'Callback', { @editIndex});
                
                if obj.S(iSlider) == 1
                    sliderStep = [0, 0];
                else
                    sliderStep = [1/(obj.S(iSlider)-1) 10/(obj.S(iSlider)-1)];
                end
                
                obj.hSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'slider', ...
                    'Units',            'normalized', ...
                    'Position',         [sum(division(1:2)) ...
                    1-tb_pad-iSlider*sliderHeight ...
                    division(3) ...
                    sliderHeight], ...
                    'Min',              1, ...
                    'Max',              size(obj.mat{1}, iSlider), ...
                    'Value',            obj.sel{iSlider}, ...
                    'SliderStep',       sliderStep, ...
                    'Callback',         @obj.sliderMove);
                
                addlistener(obj.hSlider(iSlider), ...
                    'ContinuousValueChange', @obj.sliderMove);
            end
            
            % -------------------------------------------------------------------------
            % initialize elements in control panel
            % -------------------------------------------------------------------------
            
            if sum(obj.isComplex > 0)
                obj.hBtnCmp = gobjects(4,1);
                
                obj.hBtnCmp(1) = uicontrol( ...
                    'Parent',               obj.pControl, ...
                    'Style',                'togglebutton', ...
                    'Units',                'normalized',...
                    'Position',             [0 2/3 0.5 1/3], ...
                    'String',               'Magnitude', ...
                    'Callback',             {@obj.toggleComplex},...
                    'FontUnits',            'normalized', ...
                    'Value',                1, ...
                    'FontSize',             0.3);
                
                obj.hBtnCmp(2) = uicontrol( ...
                    'Parent',               obj.pControl, ...
                    'Style',                'togglebutton', ...
                    'Units',                'normalized',...
                    'Position',             [0.5 2/3 0.5 1/3], ...
                    'String',               'Phase', ...
                    'Callback',             {@obj.toggleComplex},...
                    'FontUnits',            'normalized', ...
                    'Value',                0, ...
                    'FontSize',             0.3);
                
                obj.hBtnCmp(3) = uicontrol( ...
                    'Parent',               obj.pControl, ...
                    'Style',                'togglebutton', ...
                    'Units',                'normalized',...
                    'Position',             [0 1/3 0.5 1/3], ...
                    'String',               'real', ...
                    'Callback',             {@obj.toggleComplex},...
                    'FontUnits',            'normalized', ...
                    'Value',                0, ...
                    'FontSize',             0.3);
                
                obj.hBtnCmp(4) = uicontrol( ...
                    'Parent',               obj.pControl, ...
                    'Style',                'togglebutton', ...
                    'Units',                'normalized',...
                    'Position',             [0.5 1/3 0.5 1/3], ...
                    'String',               'imaginary', ...
                    'Callback',             {@obj.toggleComplex},...
                    'FontUnits',            'normalized', ...
                    'Value',                0, ...
                    'FontSize',             0.3);
                
                obj.complexMode = 1;
            end
            
            % autoscale button
            uicontrol( ...
                'Parent',               obj.pControl, ...
                'Style',                'togglebutton', ...
                'Units',                'normalized',...
                'Position',             [0 0 1/3 1/3], ...
                'String',               'Autoscale', ...
                'Callback',             {@obj.autoscale},...
                'FontUnits',            'normalized', ...
                'Value',                0, ...
                'FontSize',             0.3);
            
            % global scale button
            uicontrol( ...
                'Parent',               obj.pControl, ...
                'Style',                'togglebutton', ...
                'Units',                'normalized',...
                'Position',             [1/3 0 1/3 1/3], ...
                'String',               'Globalscale', ...
                'Callback',             {@obj.globalscale},...
                'FontUnits',            'normalized', ...
                'Value',                0, ...
                'FontSize',             0.3);
            
            % updateCaller
            obj.hBtnToggleUpdateCaller = uicontrol( ...
                'Parent',               obj.pControl, ...
                'Style',                'togglebutton', ...
                'Units',                'normalized',...
                'Position',             [2/3 0 1/3 1/3], ...
                'String',               'Update: on', ...
                'Callback',             {@obj.toggleUpdateCaller},...
                'FontUnits',            'normalized', ...
                'Value',                0, ...
                'FontSize',             0.3);
            
            % -------------------------------------------------------------------------
            % pPlot Elements
            %   INITIALIZE ELEMENTS OF pPlot PANEL HERE
            % -------------------------------------------------------------------------
            
            % scale axis differently when units are provided.
            
            
            obj.hAxis = axes( ...
                'Parent',       obj.pPlot, ...
                'Units',        'normal', ...
                'Position',     [0.05 0.05 0.9 0.9]);
            %set(obj.hAxis, 'ButtonDownFcn', @startDragFcn)
            
            if ~strcmp(obj.unit, '')
                ylabel(obj.unit)
                % leave some space on the left for the ylabel
                set(obj.hAxis, 'Position', [0.075 0.05 0.9 0.9]);
            end
            
            hold on
            
            xData = [1 2];
            yData = [-1 1];
            
            obj.hPlot = gobjects(1, obj.nMats);
            
            for iMat = 1:obj.nMats
                obj.hPlot(iMat) = plot(xData, yData, obj.lineStyle{iMat});
            end
            
            %obj.hVertLine = plot([1 1], [-1 1]);
            obj.hVertLine = xline(1);
            
            % Limits = getLimits();
            
            % add a legend
            if ~sum(contains('InputNames', obj.p.UsingDefaults))
                legend(obj.inputNames)
            end
            
            hold off
            
        end
        
        
        function prepareXaxes(obj)
            
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
        
        
        function refreshUI(obj)
            % refreshUI()
            %
            % called by:    scrollSlider, sliderMove, editIndex, toggleComplex
            
            % check slider values and update slider UI elements
            obj.checkAndRefreshSliders();
            
            % create temporary selector
            tempSel = obj.sel;
            tempSel{obj.showDim} = ':';
            
            % clear yData cache
            obj.currYData = [];
            
            % replot data from all inputs
            for idm = 1:obj.nMats
                y = obj.mat{idm}(tempSel{:});
                if obj.isComplex(idm)
                    y = obj.complexPart(y);
                end
                set(obj.hPlot(idm), 'YData', y(:));
                obj.currYData(idm, :) = y;
            end
            
            % reposition vertical line
            set(obj.hVertLine, 'Value', obj.sel{obj.showDim})
            
            % inform the calling object, that the selector has changed
            if obj.bUpdateCaller
                notify(obj, 'selChanged')
            end
            
        end
        
        
        function checkAndRefreshSliders(obj)
            % called by:    refreshUI
            
            for iSldr = 1:obj.nSlider
                % check whether slider still in bounds
                obj.sel{iSldr} = max([obj.sel{iSldr}, 1]);
                obj.sel{iSldr} = min([obj.sel{iSldr}, obj.S(iSldr)]);
                obj.sel{iSldr} = round(obj.sel{iSldr});
                
                %set(hIndex(iSldr), 'String', num2str(sliderVals(iSldr)));
                set(obj.hSlider(iSldr), 'Value', obj.sel{iSldr});
                
                set(obj.hIndex(iSldr), 'String', obj.xaxes{iSldr}.ticklabels{obj.sel{iSldr}})
            end
        end
        
        
        function parseDimLabelsVals(obj)
            %% dimension labels
            
            % set default values for dimLabel
            obj.dimLabel = strcat(repmat({'Dim'}, 1, numel(obj.S)), cellfun(@num2str, num2cell(1:obj.nDims), 'UniformOutput', false));
            
            if ~contains('DimLabel', obj.p.UsingDefaults)
                % check number of input labels equals dimensions of image
                if numel(obj.p.Results.DimLabel) ~= obj.nDims
                    warning('Number of DimLabel is not equal to the number of image dimensions.')
                end
                % if cell entry is empty, use default value
                emptyCell = cellfun(@isempty, obj.p.Results.DimLabel);
                obj.dimLabel(~emptyCell) = obj.p.Results.DimLabel(~emptyCell);
            end
            
            %% dimension values
            
            % set default values via size of each dimension
            obj.dimVal = cellfun(@(x) 1:x, num2cell(obj.S), 'UniformOutput', false);
            
            if ~contains('DimVal', obj.p.UsingDefaults)
                % check number of value arrays equals dimensions of image
                if numel(obj.p.Results.DimVal) ~= obj.nDims
                    % allow for trailing singleton dimensions
                    % check for all surplus dimensions in DimVal, that
                    % their size is one.
                    if numel(obj.p.Results.DimVal) > obj.nDims && ~all(cellfun(@numel, obj.p.Results.DimVal(obj.nDims+1:end)))
                        error('Number of elements in DimVal must equal the number of image dimensions.')
                    end
                end
                % if cell entry is empty, use default value
                emptyCell = cellfun(@isempty, obj.p.Results.DimVal);
                obj.dimVal(~emptyCell) = obj.p.Results.DimVal(~emptyCell);
                
                % value array for each dimension must have obj.S entries
                %                 if ~isequal(obj.S, cellfun(@numel, obj.dimVal))
                %                     error('Number of elements in DimVal for dimension(s) %s do not match image size', mat2str(find(obj.S ~= cellfun(@numel, obj.dimVal))))
                %                 end
            end
            
            obj.dimVal = valsToString(obj.dimVal);
        end
        
        
        function out = complexPart(obj, in)
            % complexPart(in)
            % in:     array with (potentially) complex data
            % out:    magnitude, phase, real or imaginary part of in
            %
            % called by:    refreshUI
            %
            % depending on the value in 'complexMode' either the magnitude,
            % phase, real part or imaginary part is returned
            
            switch(obj.complexMode)
                case 1
                    out = abs(in);
                case 2
                    out = angle(in);
                case 3
                    out = real(in);
                case 4
                    out = imag(in);
            end
        end
        
        
        %% functions to control object from external
        
        function setSelector(obj, newSel)
            % setSelector(newSel)
            % newSel:       cell array containing all new selector values
            %
            % Called by:    external
            %
            % Is called from external, when the display of different data
            % is requested.
            
            % perform some input checks
            if numel(newSel) ~= numel(obj.sel)
                error('Size mismatch in data selector')
            end
            
            obj.sel = newSel;
            
            obj.refreshUI();
            
        end
        
        
        function out = getSelector(obj)
            % getSelector(newSel)
            % 
            % Called by:    external
            %
            % Is called from external, to get the current selector
            
            out = obj.sel;
            
        end
        
        
        function setDimension(obj, newDim)
            % source:       index of the new dimension shown along ax-axis
            %
            % Called by:    external or button callback
            %
            % Is called from external or button callback, to change the
            % dimension of the input matrices shown along the x-axis.
            
            % perform some input checks
            if newDim > obj.nDims
                error('Dimension value exceeds number of dimensions')
            end
            
            obj.showDim = newDim;
            
            % change x-axis values
            set(obj.hPlot, 'XData', obj.xaxes{obj.showDim}.tickvalues(:))
            % store x-data cache
            obj.currXData = obj.xaxes{obj.showDim}.tickvalues(:);
            
            % unpress all buttons
            set(obj.hSliderLabel, 'Value', 0);
            
            % press current button
            set(obj.hSliderLabel(obj.showDim), 'Value', 1);
            
            obj.refreshUI()
            
        end
        
        %% functions for button callbacks
        
        function toggleComplex(obj, source, ~)
            % toggleComplex(source, ~)
            % source:       handle to uicontrol button
            %
            % called by:    uicontrol togglebutton: Callback
            %
            % Is called when one of the 4 complex data buttons is pressed.
            % These buttons are only visible when at least one matrix has
            % complex data.
            % Depending on which button was pressed last, the magnitude, phase,
            % real part or imaginary part of complex data is shown.
            
            % set all buttons unpreessed
            set(obj.hBtnCmp, 'Value', 0)
            
            % find the index of the pressed button
            btnIdx = find(source == obj.hBtnCmp);
            obj.complexMode = btnIdx;
            set(obj.hBtnCmp(btnIdx), 'Value', 1)
            
            obj.refreshUI()
        end
        
        
        function autoscale(obj, ~, ~)
            % autoscale(~, ~)
            %
            % called by:    autoscale button
            %
            % set the x- and y-limits such that data fills the axis entirely
            
            set(obj.hAxis, 'XLim', [min(obj.currXData) max(obj.currXData)]);
            % in case of a constant line
            if min(obj.currYData, [], 'all') == max(obj.currYData, [], 'all')
                set(obj.hAxis, 'YLim', [min(obj.currYData, [], 'all')-1 min(obj.currYData, [], 'all')+1]);
            else
                set(obj.hAxis, 'YLim', [min(obj.currYData, [], 'all') max(obj.currYData, [], 'all')]);
            end
        end
        
        
        function globalscale(obj, ~, ~)
            % globalscale(~, ~)
            %
            % called by:    globalscale button
            %
            % set the x- and y-limits to the min and max values of the
            % input data
            
            set(obj.hAxis, 'XLim', [min(obj.currXData) max(obj.currXData)]);
            % in case of a constant line
            if obj.minVal == obj.maxVal
                set(obj.hAxis, 'YLim', [obj.minVal-1 obj.minVal+1]);
            else
                set(obj.hAxis, 'YLim', [obj.minVal obj.maxVal]);
            end
        end
        
        
        function toggleUpdateCaller(obj, ~, ~)
            % toggleUpdateCaller(~, ~)
            %
            % called by:    UpdateCaller button
            %
            % toggle the value of bUpdateCaller
            
            if obj.bUpdateCaller == 0
                obj.bUpdateCaller = 1;
                set(obj.hBtnToggleUpdateCaller , 'String', 'Update: on')
                notify(obj, 'selChanged')
            elseif obj.bUpdateCaller == 1
                obj.bUpdateCaller = 0;
                set(obj.hBtnToggleUpdateCaller , 'String', 'Update: off')
            end
        end
        
        %% functions controlling slider behaviour
        
        function scrollSlider(obj, ~, evtData)
            % scrollSlider(source, evtData)
            % source:       handle to uicontrol slider
            % evtData:      information about slider movement
            %
            % Called by:    figure: WindowScrollWheelFcn
            %
            % Is called, when the figure is active and the user uses the scroll
            % wheel on the mouse. The value of the currently active slider will
            % be incremented or decremented by 1 depending on the direction of
            % the scrolling stored in evtData.
            
            if evtData.VerticalScrollCount < 0
                obj.sel{obj.activeDim} = obj.sel{obj.activeDim} - 1;
            elseif evtData.VerticalScrollCount > 0
                obj.sel{obj.activeDim} = obj.sel{obj.activeDim} + 1;
            end
            obj.refreshUI();
        end
        
        function sliderMove(obj, source, ~)
            % sliderMove(source, evtData)
            % source:       handle to uicontrol slider
            % evtData:      information about slider movement
            %
            % Called by:    uicontrol slider: Callback
            %
            % Is called on each move of the slider and updates the respective
            % value in 'sliderVals'
            
            obj.sel{source == obj.hSlider} = round(source.Value);
            % if you want, you can now change the active slider to the just
            % edited one
            obj.activeDim = find(source == obj.hSlider);
            obj.refreshUI();
        end
        
        function changeDimension(obj, source, ~)
            % source:       handle to uicontrol togglebutton
            % evtData:      ~
            %
            % Called by:    uicontrol togglebutton: Callback
            %
            % Is called when one of the sliderbuttons is pressed in order to
            % change the plot dimension
            
            obj.setDimension( find(obj.hSliderLabel == source) );
        end
        
        
        function guiResize(obj, ~, ~)
            % guiResize(varargin)
            % varargin:     unused
            %
            % called by:    figure: ResizeFcn
            %
            % is called when the figure window is resized and makes sure that
            % all elements are scaled correctly. This is only necessary for
            % elements that use 'pixel' units. 'normalized' positions and sizes
            % are adjusted automatically.
            pos     = get(obj.fig, 'Position');
            fWidth  = pos(3);
            fHeight = pos(4);
            
            set(obj.pPlot, ...
                'Position', [0 ...
                obj.sliderPanelHeight ...
                fWidth ...
                fHeight-obj.sliderPanelHeight]);
            set(obj.pSlider, ...
                'Position', [obj.controlPanelWidth*fWidth ...
                0 ...
                (1-obj.controlPanelWidth)*fWidth ...
                obj.sliderPanelHeight]);
            set(obj.pControl, ...
                'Position', [0 ...
                0 ...
                obj.controlPanelWidth*fWidth ...
                obj.sliderPanelHeight]);
        end
        
        
    end
end

function str = valsToString(valCell)
% makes sure all entries in dimVals are strings

% initialize output
str = valCell;

% find numeric arrays
numArray = cellfun(@isnumeric, valCell);
if any(numArray)
    % convert matrix to cell
    str(numArray) = cellfun(@num2cell, valCell(numArray), 'UniformOutput', 0);
    % convert numbers to strings
    for ii = find(numArray)
        str{ii} = cellfun(@num2str, str{ii}, 'UniformOutput', 0);
    end
end

% find char arrays
charArray = cellfun(@ischar, valCell);
if any(charArray)
    % convert char to cell
    str(charArray) = cellfun(@(x) {x}, valCell(charArray), 'UniformOutput', 0);
end
end