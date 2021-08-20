classdef DrawSlider < Draw
    %DrawSlider visualizes 2D slices from higherdimensional data
	% 	DRAWSLIDER(I) opens a UI that displays three orthogonal 2D slices
	% 	from the input matrix I with N dimensions (N>3). Sliders allow to
	% 	navigate thorugh the first 3 dimensions. From left to right, the
	% 	axes show a slice perpendicular to the first, second and third
	% 	dimension. The windowing of the colormaps can be dynamically
	% 	changed by pressing the middle mouse button on any image and moving
	% 	the mouse up/down (center) or left/right(width). ROIs can be drawn
	% 	to measure Signal to Noise ratio in image data.
	%
	% 	DRAWSLIDER(I1, I2): Data from the matrices I1 and I2 are overlaid
	% 	by adding (default) the RGB values attributed by the individual
	% 	colormaps. The windowing for the second image can be adjusted by
	% 	using the left mouse button. Image sizes must not be identical, but
	% 	for dimensions, where the size is different, one matrix must be of
	% 	size one.
	%
	%	Usage
	%
	%   Values in the lower right show the array indices of the datapoint
	%   under the cursor as well as the matrix-values at that location. In
	%   case of complex data, the value is shown in the current complex
	%   mode.
	% 	Colorbar button in the matlab figure-toolbar can be used to show
	% 	adapting colorbars. 'SaveImage' saves the currently
	%   visible images to file. 'Guides' switches on and off guidlines that
	%   show the position of the slices in the other axes.
	%
	%	Name-Value-Pairs
	%	
	% 	Name------------Value-------Descripton-----------------------------
    %
	% 	'CW'            1x2 double  Initial values for center and width.
	%                               For two input matrices, Value must be
	%                               2x2 matrix, or values are applied to
	%                               both.
    %   'Colormap'      Nx3 | char	initial colormaps for the image. The
    %                               user can either supply a custom
    %                               colormap or chose from the available
    %                               colormaps. Default is gray(256). For
    %                               two input matrices, value must be 1x2
    %                               cell array. Default is {'green',
    %                               'magenta'}. More colormaps are
    %                               available if 'colorcet.m' is found on
    %                               the MATLAB path (Peter Kovesi,
    %                               https://peterkovesi.com/projects/colourmaps/)
	%   'Contrast'      char        redundant NVP, will be removed in
	%                               future versions.
	%	'Overlay' 		int 		inital overlay mode for two input
	%                               matrices (1: add (default), 2:
	%                               multiply)
	%	'ComplexMode'   int 		For complex data, chooses the initially
	%                               displayed complex part (1: magnitude
	%                               (default), 2: phase, 3: real part, 4:
	%                               imaginary part).
	% 	'AspectRatio'   'image'     the displayed axes have the same aspect
	%                               ratio as the input matrix for that
	%                               slice, i.e. pixels will be squares.
	% 					'square' 	The displayed axes always have a square
	%                               shape.
	% 	'Resize' 		double      uses 'imresize' to resize the currently
	%                               displayed slice by the given value.
	%   'Title' 		char 	    title of the figure window
	%	'Position',     1x4 int 	Position of the figure in pixel    
	%   'Unit'          char        physical unit of the provided image
	%                               data. For two input matrices, value
	%                               must be 1x2 cell array, or both are
	%                               assigned the same unit
	%	'InitSlice',    1x3         set the slices that are shown when the
	%                               figure is opened.
	%	'DimLabel',     cell{char}  char arrays to label the individual
	%                               dimensions in the input data. Cell
	%                               entries can be empty to use default
	%                               label.
    %	'DimVal', cell{cell{char}}  char arrays containing the axis-values
    %                or cell{int}   for each dimension. Cell entries can be
    %                               empty to use default enumeration. Vals
    %                               must not be char, but is encouraged.
	%	'ROI_Signal',   Nx2 		vertices polygon that defines a ROI in
	%                               the initial slice.
	%	'ROI_Noise',    Nx2 		vertices polygon that defines a ROI in
	%                               the initial slice.
	%	'SaveImage',    filename    When provided, the three initial slices
	%                               are prepared according to the other
	%                               inputs, but no figure is shown. The
	%                               three slices are concatenated and saved
	%                               to file under filename.

    
    % TODO:
    % - implement ROI_Signal nvp
    % - implement ROI_Noise nvp
    % - implement SaveImage nvp
    
    properties (Access = private)
        % DISPLAYING
        locValString
        dimensionLabel
        % stores information about the grid in the control bar
        gridSize
        
        % UI Elements
        pColorbar
        pImage
        pSlider
        pControls
        locAndVals
        hGuides         % RGB plot guides in the axes
        hBtnGuides
        
        % UI properties
        pSliderHeight
        panelPos
        controlPanelPos
        figurePos
        cr
    end
    
    
    properties (Constant, Access = private)
        % UI PROPERTIES
        % default figure position and size
        defaultPosition = [ 300, 200, 1000, 800];
        axColors = 'rgb';
        
    end
    
    
    methods
        function obj = DrawSlider(in, varargin)
            % CONSTRUCTOR
            obj@Draw(in, varargin{:})
            
            % Three axes are shown in DrawSlider
            obj.nAxes = 3;
            % one of the following two should be thrown away
            obj.activeAx  = 1;
            obj.activeDim = 1;
            
            obj.cbDirection = 'horizontal';
            
            if obj.nDims < 4
                % TODO: if obj.nDims == 2: open DrawSingle instead
                obj.nSlider = 3;
                obj.mapSliderToImage = num2cell(1:3);
            elseif obj.nDims == 4
                obj.nSlider = 4;
                obj.mapSliderToImage = cat(2, num2cell(1:3), {':'});
            else
                error('Input-size not supported')
            end
            
            if obj.nImages == 2
                obj.inputNames{1} = inputname(1);
                obj.inputNames{2} = inputname(2);
                obj.standardTitle = [inputname(1) ' ' inputname(2)];
            else
                obj.inputNames{1} = inputname(1);
                obj.standardTitle = inputname(1);
            end
            
            obj.prepareParser()
            
            % definer additional Prameters
            addParameter(obj.p, 'InitSlice',    round(obj.S(1:3)/2),  @isnumeric);
            addParameter(obj.p, 'Crosshair',    1,                    @isnumeric);

            parse(obj.p, obj.varargin{:});            
            
            obj.cmap{1}             = obj.p.Results.Colormap;
            obj.complexMode         = obj.p.Results.ComplexMode;
            obj.resize              = obj.p.Results.Resize;
            obj.cr                  = obj.p.Results.Crosshair;
            obj.contrast            = obj.p.Results.Contrast;
            obj.overlay             = obj.p.Results.Overlay;
            obj.unit                = obj.p.Results.Unit;
            
            % set default values for dimLabel
            obj.dimLabel = {'X', 'Y', 'Z'};
            if obj.nDims == 4
                obj.dimLabel{4} = 't';
            end
            
            obj.parseDimLabelsVals()
            
            obj.prepareGUIElements()
            
            obj.prepareColors()
            
            obj.createSelector()     

            % overwrite the default value fot maxLetters in locVal section
            obj.maxLetters = 8;
            obj.setValNames()
            
            obj.setLocValFunction()
            
            obj.prepareSliceData()
            
            obj.prepareGUI()
            
            obj.refreshUI()
            
            obj.guiResize()
            
            obj.recolor()
            
            set(obj.f, 'Visible', 'on');
            
            % do not assign to 'ans' when called without assigned variable
            if nargout == 0
                clear obj
            end
        end
        
        
        function prepareGUI(obj)
            set(obj.f, ...
                'name',                 obj.p.Results.Title, ...
                'Units',                'pixel', ...
                'Position',             obj.p.Results.Position, ...
                'Visible',              'on', ...
                'ResizeFcn',            @obj.guiResize, ...
                'CloseRequestFcn',      @obj.closeRqst, ...
                'WindowButtonMotionFcn',@obj.mouseMovement, ...
                'WindowButtonUpFcn',    @obj.stopDragFcn, ...
                'WindowScrollWheelFcn', @obj.scrollSlider);
            
            obj.setPanelPos()
            
            % create and place panels
            for iim = 1:3
                obj.pImage(iim)  = uipanel( ...
                    'Units',            'pixels', ...
                    'Position',         obj.panelPos(iim, :), ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'HighLightColor',   obj.COLOR_BG, ...
                    'ShadowColor',      obj.COLOR_B);
                
                obj.pSlider(iim) = uipanel( ...
                    'Units',            'pixels', ...
                    'Position',         obj.panelPos(iim+3, :), ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'HighLightColor',   obj.COLOR_BG, ...
                    'ShadowColor',      obj.COLOR_B);
            end
            
            obj.pColorbar = uipanel( ...
                'Units',            'pixels', ...
                'Position',         obj.panelPos(7, :), ...
                'BackgroundColor',  obj.COLOR_BG, ...
                'HighLightColor',   obj.COLOR_BG, ...
                'ShadowColor',      obj.COLOR_B);
                        
            obj.pControls  = uipanel( ...
                'Units',            'pixels', ...
                'Position',         obj.panelPos(8, :), ...
                'BackgroundColor',  obj.COLOR_BG, ...
                'HighLightColor',   obj.COLOR_BG, ...
                'ShadowColor',      obj.COLOR_B);
            
            %% set UI elements
            
            % populate image panels
            ax = gobjects(3, 1);
            obj.hGuides = gobjects(obj.nAxes, 4);
            
            for iim = 1:obj.nAxes
                % axes are not members of Draw or DrawSlider, to get the
                % handle to an axis use: get(hImage(i), 'Parent')
                ax(iim) = axes('Parent', obj.pImage(iim), 'Units', 'normal', 'Position', [0 0 1 1]);
                obj.hImage(iim)  = imagesc(obj.sliceMixer(iim), 'Parent', ax(iim));  % plot image
                hold on
                eval(['axis ', obj.p.Results.AspectRatio]);
                
                set(obj.hImage(iim), 'ButtonDownFcn', @obj.startDragFcn)
                colormap(ax(iim), obj.cmap{1});
                                
                for igu = 1:4
                    obj.hGuides(iim, igu) = plot([1 1], [1 1], ...
                        'Color', obj.axColors(obj.showDims(iim, abs(ceil((igu-6)/2)))));
                end
            end
            
            set(ax, ...
                'XTickLabel',   '', ...
                'YTickLabel',   '', ...
                'XTick',        [], ...
                'YTick',        []);
            
            % populate slider panels
            for iSlider = 1:3
                % if dimension is singleton, set slider steps to 0
                if obj.S(iSlider) == 1
                    steps = [0 0];
                else
                    steps = [1/(obj.S(iSlider)-1) 10/(obj.S(iSlider)-1)];
                end
                
                obj.hTextSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider(iSlider), ...
                    'Style',            'text', ...
                    'Units',            'normalized', ...
                    'Position',         [0.01 1/8 0.04 6/8], ...
                    'String',           [obj.dimLabel{iSlider} ':'], ...
                    'FontUnits',        'normalized', ...
                    'FontSize',         0.8, ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
                
                obj.hEditSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider(iSlider), ...
                    'Style',            'edit', ...
                    'Units',            'normalized', ...
                    'Position',         [0.07 1/8 0.1 6/8], ...
                    'String',           obj.dimVal{iSlider}{obj.sel{iSlider, iSlider}}, ...
                    'FontUnits',        'normalized', ...
                    'FontSize',         0.8, ...
                    'Enable',           'on', ...
                    'Value',            iSlider, ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
                
                set(obj.hEditSlider(iSlider), 'Callback', @obj.setSlider);
                

                obj.hSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider(iSlider), ...
                    'Style',            'slider', ...
                    'Units',            'normalized', ...
                    'Position',         [0.17 1/8 0.6 6/8], ...
                    'Min',              1, ...
                    'Max',              obj.S(iSlider), ...
                    'Value',            obj.sel{obj.mapSliderToDim(iSlider), obj.mapSliderToDim(iSlider)}, ...
                    'SliderStep',       steps, ...
                    'Callback',         @(src, eventdata) obj.newSlice(src, eventdata), ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_BG);

                addlistener(obj.hSlider(iSlider), ...
                    'ContinuousValueChange', ...
                    @(src, eventdata) obj.newSlice(src, eventdata));

                if obj.S(obj.mapSliderToDim(iSlider)) == 1
                    % dont show the slider, if both inputs are singleton,
                    % or if the single input is singleton (i.e. obj.S ~= 1)
                    set(obj.hSlider(iSlider), 'Visible', 'off');
                end
                
            end
            
            % populate control panel
            obj.genControlPanelGrid()
            set(obj.hTextC, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'Center:', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.7, ...
                'HorizontalAlignment',  'left');
            
            set(obj.hTextW, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'Width:', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.7, ...
                'HorizontalAlignment',  'left');
            
            for idh = 1:obj.nImages
                set(obj.hEditC(idh), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'right', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.4, ...
                    'FontName',             'FixedWidth', ...
                    'ForegroundColor',      obj.COLOR_m(idh, :));
                
                set(obj.hEditW(idh), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'right', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.4, ...
                    'FontName',             'FixedWidth', ...
                    'ForegroundColor',      obj.COLOR_m(idh, :));
                
                set(obj.hPopCm(idh), ...
                    'Parent',               obj.pControls, ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6);
                
                if obj.nImages == 2
                    set(obj.hBtnHide(idh), ...
                        'Parent',               obj.pControls, ...
                        'Value',                1, ...
                        'Units',                'pixel', ...
                        'String',               ['Hide (' obj.BtnHideKey(idh) ')'] , ...
                        'HorizontalAlignment',  'left', ...
                        'FontUnits',            'normalized', ...
                        'FontSize',             0.4, ...
                        'ForegroundColor',      obj.COLOR_m(idh, :));
                    
                    set(obj.hPopCm(idh), ...
                        'Parent',               obj.pControls, ...
                        'FontUnits',            'normalized', ...
                        'FontSize',             0.6);
                    
                    set(obj.hPopOverlay, ...
                        'Parent',               obj.pControls, ...
                        'FontUnits',            'normalized', ...
                        'FontSize',             0.6);
                end
            end
            
            if obj.nImages == 2
                % toggle button
                set(obj.hBtnToggle, ...
                    'Parent',               obj.pControls, ...
                    'Value',                1, ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'left', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.4);
            end
            
            %ROI elements
            set(obj.hBtnRoi(1), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'Signal', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.4, ...
                'TooltipString',        'draw signal ROI');
            
            set(obj.hBtnRoi(2), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'Noise', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.4, ...
                'TooltipString',        'draw noise ROI');
            
            set(obj.hTextSNR, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'SNR:', ...
                'HorizontalAlignment',  'left', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.6);
            
            set(obj.hTextRoi, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               '', ...
                'HorizontalAlignment',  'right', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45, ...
                'FontName',             'FixedWidth');
                        
            set(obj.hTextSNRvals, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               '', ...
                'HorizontalAlignment',  'right', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45, ...
                'FontName',             'FixedWidth', ...
                'TooltipString',        'signal / noise');
            
            obj.hBtnGuides = uicontrol(...
                'Parent',               obj.pControls, ...
                'Style',                'togglebutton', ...
                'String',               'Guides', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.4, ...
                'TooltipString',        'Toggle between showing and hiding the guides', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F, ...
                'Callback',             {@obj.toggleGuides});
            
            set(obj.hBtnCmplx(1), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel',...
                'Value',                1, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);
            
            set(obj.hBtnCmplx(2), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel',...
                'Value',                0, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);
            
            set(obj.hBtnCmplx(3), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel',...
                'Value',                0, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);
            
            set(obj.hBtnCmplx(4), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel',...
                'Value',                0, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);
            
            if any(obj.isComplex)% && isempty(obj.img{2})
                set(obj.hBtnCmplx, 'Visible', 'on');
            else
                % when hBtnCmplx are hidden, complexMode must be 3
                obj.complexMode = 3;
                set(obj.hBtnCmplx, 'Visible', 'off');
            end
            
            obj.locAndVals = annotation(obj.pControls, 'textbox', ...
                'LineStyle',            'none', ...
                'Units',                'pixel', ...
                'String',               '', ...
                'HorizontalAlignment',  'left', ...
                'FontUnits',            'pixel', ...
                'FontSize',             16, ...
                'FontName',             'FixedWidth', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'Interpreter',          'Tex');
            
            %% OVERWRITE TOOLBAR BUTTONS
            
            for idh = 1:obj.nImages
                % create the colorbar axis for the colorbarpanel
                obj.hAxCb(idh)      = axes('Units',            'normal', ...
                    'Position',         [1/9+(idh-1)*4/9 1/3 1/3 1/3], ...
                    'Parent',           obj.pColorbar, ...
                    'Color',            obj.COLOR_m(idh, :));
                imagesc(linspace(0, 1, size(obj.cmap{idh}, 1)));
                colormap(obj.hAxCb(idh), obj.cmap{idh});
                caxis(obj.hAxCb(idh), [0 1])
                
                % remove unnecessary Y ticks and labels
                set(obj.hAxCb(idh), ...
                    'YTickLabel',   [], ...
                    'YTick',        []);
            end
            
            % hide colorbar
            obj.cbShown = true;
            obj.toggleCb()
            
            % change callback of 'colorbar' icon in MATLAB toolbar
            hToolColorbar = findall(gcf, 'tag', 'Annotation.InsertColorbar');
            set(hToolColorbar, 'ClickedCallback', {@obj.toggleCb});
        end
        
        
        function setPanelPos(obj)
            pos = get(obj.f, 'Position');
            
            % set size of controlHeight
            colorbarHeight = 80;  % px
            slidersHeight  = 30;  % px
            controlHeight  = 120; % px
            % pImage(..), pColorbar, pSliders, pControl            
            for iim = 1:3
                obj.panelPos(iim, :) = [(iim-1)*1/3*pos(3) ...
                    controlHeight+slidersHeight ...
                    1/3*pos(3) ...
                    pos(4)-controlHeight-slidersHeight-colorbarHeight];
                
                obj.panelPos(iim+3, :) = [(iim-1)*1/3*pos(3) ...
                    controlHeight ...
                    1/3*pos(3) ...
                    slidersHeight];
            end
            % pColorbar
            obj.panelPos(7, :) = [0 ...
                pos(4)-colorbarHeight ...
                pos(3) ...
                colorbarHeight];
            
            % pControls
            obj.panelPos(8, :) = [0 ...
                0 ...
                pos(3) ...
                controlHeight];
        end
        
        
        function genControlPanelGrid(obj)
%             if obj.nImages == 1
%                 obj.gridSize = [3 8];
%             else
                obj.gridSize = [4 8];
%             end
            pos = get(obj.pControls, 'Position');
            
            xPadding = 3;
            yPadding = 3;
            width  = 90;%(pos(3) - (obj.gridSize(2)+1)*xPadding) / obj.gridSize(2);
            height = (pos(4) - (obj.gridSize(1)+1)*yPadding) / obj.gridSize(1);
            
            
            % repeat arrays to create gridSize x 4 matrix
            width  = repmat(width, [1, obj.gridSize(2)]);
            
            % set some columns to fixed width
            if obj.nImages == 1
               width(3) = 0; 
            end
            
            w0 = [xPadding cumsum(width, 2) + (1:obj.gridSize(2)) * xPadding];
            h0 = pos(4) - yPadding - (1:obj.gridSize(1)) * (height+yPadding);
            width  = repmat(width, [obj.gridSize(1) 1]);
            height = repmat(height, obj.gridSize);
            w0 = repmat(w0(1:end-1), [obj.gridSize(1) 1]);
            h0 = repmat(h0', [1 obj.gridSize(2)]);
            obj.controlPanelPos = cat(3, w0, h0, width, height);
        end
        
        
        function guidePos = calcGuidePos(obj)
            guidePos = zeros(obj.nAxes, 4, 4);
            for iim = 1:obj.nAxes
                guidePos(iim, 1, :) = [...
                    obj.sel{obj.showDims(iim, 2), obj.showDims(iim, 2)}*obj.resize, ...
                    obj.sel{obj.showDims(iim, 2), obj.showDims(iim, 2)}*obj.resize, ...
                    0.5, ...
                    obj.sel{obj.showDims(iim, 1), obj.showDims(iim, 1)}*obj.resize-obj.cr];
                guidePos(iim, 2, :) = [...
                    obj.sel{obj.showDims(iim, 2), obj.showDims(iim, 2)}*obj.resize, ...
                    obj.sel{obj.showDims(iim, 2), obj.showDims(iim, 2)}*obj.resize, ...
                    obj.sel{obj.showDims(iim, 1), obj.showDims(iim, 1)}*obj.resize+obj.cr, ...
                    obj.S(obj.showDims(iim, 1))*obj.resize+0.5];
                guidePos(iim, 3, :) = [...                    
                    0.5, ...
                    obj.sel{obj.showDims(iim, 2), obj.showDims(iim, 2)}*obj.resize-obj.cr, ...
                    obj.sel{obj.showDims(iim, 1), obj.showDims(iim, 1)}*obj.resize, ...
                    obj.sel{obj.showDims(iim, 1), obj.showDims(iim, 1)}*obj.resize];
                guidePos(iim, 4, :) = [...    
                    obj.sel{obj.showDims(iim, 2), obj.showDims(iim, 2)}*obj.resize+obj.cr, ...
                    obj.S(obj.showDims(iim, 2))*obj.resize+0.5, ...
                    obj.sel{obj.showDims(iim, 1), obj.showDims(iim, 1)}*obj.resize, ...
                    obj.sel{obj.showDims(iim, 1), obj.showDims(iim, 1)}*obj.resize];
            end
        end
        
        
        function createSelector(obj)
            % which dimensions are shown initially
            obj.showDims = [2 3; 1 3; 1 2];
            obj.mapSliderToDim   = 1:4;
            % create slice selector for dimensions 3 and higher
            obj.sel        = repmat({':'}, obj.nAxes, ndims(obj.img{1}));
            for iim = 1:obj.nAxes
                obj.sel(iim, obj.mapSliderToDim == iim) = num2cell(obj.p.Results.InitSlice(iim));
            end
            
            if obj.nSlider == 4
                obj.sel(:, 4) = num2cell(round(obj.S(4)));
            end
            
            % consider singleton dimensions            
            obj.sel(:, obj.S == 1) = {1};
            % obj.sel{obj.S == 1} = 1; does not work here, because the
            % condition might return an empty array which fails with curly
            % brackets
        end
        
        
        function refreshUI(obj)
            % fill obj.slice
            obj.prepareSliceData;
            
            for iim = 1:obj.nAxes
                % update the images
                set(obj.hImage(iim), 'CData', obj.sliceMixer(iim));
                
                % set position of guides
                if true % guides visible
                    guidePos = obj.calcGuidePos();
                    set(obj.hGuides(iim, 1), ...
                        'XData', guidePos(iim, 1, 1:2), ...
                        'YData', guidePos(iim, 1, 3:4));
                    set(obj.hGuides(iim, 2), ...
                        'XData', guidePos(iim, 2, 1:2), ...
                        'YData', guidePos(iim, 2, 3:4));
                    set(obj.hGuides(iim, 3), ...
                        'XData', guidePos(iim, 3, 1:2), ...
                        'YData', guidePos(iim, 3, 3:4));
                    set(obj.hGuides(iim, 4), ...
                        'XData', guidePos(iim, 4, 1:2), ...
                        'YData', guidePos(iim, 4, 3:4));
                end
            end
            
            for iSlider = 1:obj.nSlider
                % update the values is the edit fields
                if obj.mapSliderToImage{iSlider}  == ':'
                    val = obj.sel{1, iSlider};
                else
                    val = obj.sel{obj.mapSliderToDim(iSlider), obj.mapSliderToDim(iSlider)};
                end
                
                if iSlider < 4
                    set(obj.hEditSlider(iSlider), 'String', obj.dimVal{iSlider}{obj.sel{iSlider, iSlider}});
                else
                    set(obj.hEditSlider(iSlider), 'String', obj.dimVal{iSlider}{obj.sel{1, iSlider}});
                end
                set(obj.hSlider(iSlider), 'Value', val);
            end
            % update 'val' when changing slice
            obj.mouseMovement();
            
            
            %             if ~isempty(Sroi) | ~isempty(Nroi)
            %                 % only calculate SNR, when there are ROIs to calculate
            %                 calcROI();
            %             end
        end
        
        
        function activateAx(obj, axNo)
            if obj.activeAx ~= axNo
                obj.activeAx  = axNo;
                obj.activeDim = axNo;
                for iax = 1:obj.nAxes
                    set(get(obj.hImage(iax), 'Parent'), 'XColor', [0 0 0]);
                    set(get(obj.hImage(iax), 'Parent'), 'YColor', [0 0 0]);
                end
                % TODO: implement 4th slider first
                % set(pSlider(4),'ShadowColor',color_B)
                if axNo < 4
                    axes(get(obj.hImage(axNo), 'Parent'))
                    set(get(obj.hImage(axNo), 'Parent'), ...
                        'XColor',   obj.axColors(obj.activeAx), ...
                        'YColor',   obj.axColors(obj.activeAx));
                else
                    % set(pSlider(4),'ShadowColor', color_F)
                end
            end
        end
        
        
        function activateSlider(obj, dim)
            % change current axes and indicate to user by drawing coloured line
            % around current axes, but only if dim wasnt the active axis before
            if obj.activeDim ~= dim
                obj.activeDim = dim;
            end
            
            if obj.nSlider < 4
                obj.activateAx(dim);
            end
        end
        
        
        function incDecActiveDim(obj, incDec)
            % change the active dimension by incDec
            if obj.activeDim == 4
                obj.sel{1:obj.nAxes, obj.activeDim} = obj.sel{1:obj.nAxes, obj.activeDim} + incDec;
            else
                obj.sel{obj.activeAx, obj.activeDim} = obj.sel{obj.activeAx, obj.activeDim} + incDec;
            end
            % check whether the value is too large and take the modulus
            obj.sel{obj.activeAx, obj.activeDim} = mod(obj.sel{obj.activeAx, obj.activeDim}-1, obj.S(obj.activeDim))+1;
            obj.refreshUI();
        end
        
        
        function mouseButtonAlt(obj, src, evtData)
            Pt = round(get(gca, 'CurrentPoint')/obj.resize);
            iim = find(src == obj.hImage);
            obj.sel{obj.showDims(iim, 1), obj.showDims(iim, 1)} = Pt(1, 2);
            obj.sel{obj.showDims(iim, 2), obj.showDims(iim, 2)} = Pt(1, 1);
            obj.refreshUI()
        end
                
        
        function recolor(obj)
            % this function is callen, when the user changes a colormap in
            % the GUI. To keep the colors consistent an easier
            % attribuateble ti each in put, the colors in the GUI need to
            % be adapted. Specifically in the locValString and the slider
            % indices in the case of uniquely singleton dimensions.
            
            obj.setLocValFunction()
            
            % reset color to standard foreground color
            set(obj.hEditSlider, 'ForegroundColor', obj.COLOR_F)
            
            % if necessary, change color for unique singleton
            % dimensions
            for iImg = 1:obj.nImages
                stonSliderDims = ismember(obj.mapSliderToDim, obj.ston{iImg});
                set(obj.hEditSlider(stonSliderDims), ...
                    'ForegroundColor', obj.COLOR_m(mod(iImg, 2)+1, :))
            end
        end
        
        
        function setLocValFunction(obj)
            % sets the function for the locAndVal string depending on the
            % amount of input images
            
            % check 'Units' input
            if ~contains('Unit', obj.p.UsingDefaults)
                if ischar(obj.unit)
                    % make it a cell array
                    obj.unit = {obj.unit, obj.unit};
                end
            end
            
            if obj.nImages == 1
                obj.locValString = @(dim1L, dim1, dim2L, dim2, dim3L, dim3, val) sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%s\n%s:%s\n%s:%s\n%s:%s', ...
                    obj.COLOR_F, ...
                    dim1L, ...
                    dim1, ...
                    dim2L, ...
                    dim2, ...
                    dim3L, ...
                    dim3, ...
                    obj.valNames{1}, ...
                    [num2sci(val) ' ' obj.unit{1}]);
            else
                % check the currently shown dimensions for necessity of color
                % indication, if one input is singleton along dimension
                
                adjColorStr = {'', '', ''};
                for iImg = 1:obj.nImages
                    % in DrawSlider, always the first three dimensions are
                    % shown
                    match = ismember([1 2 3], obj.ston{iImg});
                    for iDim = find(match)
                        % set color to different dimensions color
                        adjColorStr{iDim} = sprintf('\\color[rgb]{%.2f,%.2f,%.2f}', obj.COLOR_m(mod(iImg, 2)+1, :));
                    end
                end
                
                obj.locValString = @(dim1L, dim1, dim2L, dim2, dim3L, dim3, val1, val2) ...
                    sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%s%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s', ...
                    obj.COLOR_F, ...
                    dim1L, ...
                    adjColorStr{1}, ...
                    dim1, ...
                    obj.COLOR_F, ...
                    dim2L, ...
                    adjColorStr{2}, ...
                    dim2, ...
                    obj.COLOR_F, ...
                    dim3L, ...
                    adjColorStr{3}, ...
                    dim3, ...
                    obj.COLOR_m(1, :), ...
                    obj.valNames{1}, ...
                    [num2sci(val1) obj.unit{1}], ...
                    obj.COLOR_m(2, :), ...
                    obj.valNames{2}, ...
                    [num2sci(val2) obj.unit{2}]);
            end
        end
        
        
        function locVal(obj, point, axNo)
            if ~isempty(point)
                switch (axNo)
                    case 1
                        point = [obj.sel{axNo, axNo}, point(:)'];
                    case 2
                        point = [point(1), obj.sel(axNo, axNo), point(2)];
                    case 3
                        point = [point(:)', obj.sel{axNo, axNo}];
                end
                
                if obj.nImages == 1
                    val = obj.slice{axNo}(point{obj.showDims(axNo, :)});
                    set(obj.locAndVals, 'String', obj.locValString(...
                        obj.dimLabel{1}, obj.dimVal{1}{point{1}}, ...
                        obj.dimLabel{2}, obj.dimVal{2}{point{2}}, ...
                        obj.dimLabel{3}, obj.dimVal{3}{point{3}}, val));
                else
                    val1 = obj.slice{axNo, 1}(point{obj.showDims(axNo, :)});
                    val2 = obj.slice{axNo, 2}(point{obj.showDims(axNo, :)});
                    set(obj.locAndVals, 'String', obj.locValString(...
                        obj.dimLabel{1}, obj.dimVal{1}{point{1}}, ...
                        obj.dimLabel{2}, obj.dimVal{2}{point{2}}, ...
                        obj.dimLabel{3}, obj.dimVal{3}{point{3}}, val1, val2));
                end
            else
                set(obj.locAndVals, 'String', '');
            end
        end
        
        
        function toggleGuides(obj, ~, ~)
            if strcmp(get(obj.hGuides, 'Visible'), 'on')
                set(obj.hGuides, 'Visible', 'off');
            else
                set(obj.hGuides, 'Visible', 'on');
            end
        end
        
        
        function saveImgBtn(obj)
            fprinf('Functionality currently not implemented')
        end
        
        
        function closeRqst(obj, ~, ~)
            % closeRqst is called, when the user closes the figure (by 'x' or
            % 'close'). It stops and deletes the timer, frees up memory taken
            % by img and closes the figure.
            
            delete(obj.f);
            obj.delete
        end
        
        
        function toggleCb(obj, ~, ~)
            images = allchild(obj.hAxCb);
            if ~obj.cbShown
                set(obj.hAxCb,      'Visible', 'on')
                if obj.nImages == 1
                    set(images,      'Visible', 'on')
                else
                    set([images{:}],    'Visible', 'on')
                end
                obj.cbShown = true;
                % run cw() again, to update ticklabels
                obj.cw();
            else
                set(obj.hAxCb,      'Visible', 'off')
                if obj.nImages == 1
                    set(images,    'Visible', 'off')
                else
                    set([images{:}],    'Visible', 'off')
                end
                obj.cbShown = false;
            end
        end
        
        
        function guiResize(obj, ~, ~)
            obj.setPanelPos()
            obj.genControlPanelGrid()
            
            for iim = 1:obj.nAxes
                set(obj.pImage(iim),  'Position', obj.panelPos(iim, :));
                set(obj.pSlider(iim), 'Position', obj.panelPos(iim+obj.nAxes, :));
            end
            set(obj.pColorbar, 'Position', obj.panelPos(7, :));
            set(obj.pControls, 'Position', obj.panelPos(8, :));
            
            set(obj.hTextC, 'Position', obj.controlPanelPos(1, 1, :));
            set(obj.hTextW, 'Position', obj.controlPanelPos(2, 1, :));
            for ii = 1:obj.nImages
                set(obj.hEditC(ii), 'Position', obj.controlPanelPos(1, 1+ii, :));
                set(obj.hEditW(ii), 'Position', obj.controlPanelPos(2, 1+ii, :));
            end
            
            if obj.nImages == 1
                set(obj.hPopCm(1),   'Position', obj.controlPanelPos(3, 2, :));
            else
                set(obj.hBtnToggle,  'Position', obj.controlPanelPos(3, 1, :));
                set(obj.hBtnHide(1), 'Position', obj.controlPanelPos(3, 2, :));
                set(obj.hBtnHide(2), 'Position', obj.controlPanelPos(3, 3, :));
                set(obj.hPopOverlay, 'Position', obj.controlPanelPos(4, 1, :));
                set(obj.hPopCm(1),   'Position', obj.controlPanelPos(4, 2, :));
                set(obj.hPopCm(2),   'Position', obj.controlPanelPos(4, 3, :));
            end
            
            set(obj.hBtnRoi(1), 'Position', obj.controlPanelPos(1, 4, :));
            set(obj.hBtnRoi(2), 'Position', obj.controlPanelPos(2, 4, :));
            set(obj.hTextSNR,   'Position', obj.controlPanelPos(3, 4, :));
            
            for iImg = 1:obj.nImages
                set(obj.hTextRoi(1, iImg),  'Position', obj.controlPanelPos(1, 4+iImg, :));
                set(obj.hTextRoi(2, iImg),  'Position', obj.controlPanelPos(2, 4+iImg, :));
                set(obj.hTextSNRvals(iImg), 'Position', obj.controlPanelPos(3, 4+iImg, :));
            end
            
            set(obj.hBtnGuides, 'Position', obj.controlPanelPos(1, 4+obj.nImages+1, :));
            
            set(obj.hBtnCmplx(1), 'Position', obj.controlPanelPos(1, 4+obj.nImages+2, :));
            set(obj.hBtnCmplx(2), 'Position', obj.controlPanelPos(2, 4+obj.nImages+2, :));
            set(obj.hBtnCmplx(3), 'Position', obj.controlPanelPos(3, 4+obj.nImages+2, :));
            set(obj.hBtnCmplx(4), 'Position', obj.controlPanelPos(4, 4+obj.nImages+2, :));
            
            lavWidth = 250; % px
            set(obj.locAndVals, ...
                'Position', [obj.panelPos(8, 3)-lavWidth 0 lavWidth obj.panelPos(8, 4)]);
            
        end
        
        
%         function vertPos(obj, N)
    end
end
    
    
    
    
    
    
    
    
    
