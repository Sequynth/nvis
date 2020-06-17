classdef DrawSingle < Draw
	%DrawSingle visualizes 2D slices from higherdimensional data
	% 	DRAWSINGLE(I) opens a UI that displays one 2D slice from the input
	% 	matrix I with N dimensions (N>2). Sliders allow to navigate thorugh
	% 	the remaining, non-singleton dimensions. The windowing of the
	% 	colormaps can be dynamically changed by pressing the middle mouse
	% 	button on the image and moving the mouse up/down (center) or
	% 	left/right(width). ROIs can be drawn to measure Signal to Noise
	% 	ratio in image data.
	%
	% 	DRAWSINGLE(I1, I2): Data from the matrices I1 and I2 are overlaid
	% 	by adding (default) the RGB values attributed by the individual
	% 	colormaps. The windowing for the second image can be adjusted by
	% 	using the left mouse button. Image sizes must not be identical, but
	% 	for dimensions, where the size is different, one matrix must be of
	% 	size one.
	%
	%	Usage
	%
	%   Values in the lower left show the array indices of the datapoint
	%   under the cursor as well as the matrix-values at that location. In
	%   case of complex data, the value is shown in the current complex
	%   mode.
	% 	Colorbar button in the matlab figure-toolbar can be used to show
	% 	adapting colorbars.
	%  	<- and -> change the dimensions that are schown along the image
	%  	dimensions. Initially, dimensions 1 and 2 are shown. By presing <-
	%  	/ -> both are decreased/increased by 1, wrapping where necessary.
	%   'Run' starts a timer which loops through the image dimension
	%   selected by the radio button. 'SaveImage' save the currently
	%   visible image to file, 'SaveVideo' saves the running animation as a
	%   video file (.avi or .gif)
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
	%	'InitSlice',    1xN-2       set the slice that is shown when the
	%                               figure is opened.
	%	'InitRot',      int         initial rotation angle of the displayed
	%                               image
	%	'DimLabel',     cell{char}  char arrays to label the individual
	%                               dimensions in the input data, if
	%                               provided, must be provided for all
	%                               dimensions.
    %	'DimVal',       cell{char}  char arrays containing the axis-values
    %                or cell{int}   for each dimension. Cell entries can be
    %                               empty to use default enumberation. Vals
    %                               must not be char, but is encouraged.
	%	'fps',          double      defines how many times per second the
	%                               slider value provided by 'LoopDim' is
	%                               increased.
	%	'LoopDim',      int     	Dimension, along which the slider is
	%                               incremented 'fps' times per second
	%	'ROI_Signal',   Nx2 		vertices polygon that defines a ROI in
	%                               the initial slice.
	%	'ROI_Noise',    Nx2 		vertices polygon that defines a ROI in
	%                               the initial slice.
	%	'SaveImage',    filename    When provided, the image data is
	%                               prepared according to the other inputs,
	%                               but no figure is shown. The prepared
	%                               image data is directly saved to file
	%                               under filename.
	%	'SaveVideo',    filename    When provided, the image data is
	%                               prepared according to the other inputs,
	%                               but no figure is shown. 'fps' gives the
	%                               framerate for the video that is saved
	%                               under filename. Only '.avi' and '.gif'
	%                               supported so far. 'LoopDim' can be used
	%                               to specify the dimension along which
	%                               the video loops.
	
	
    % TODO:
    % - RadioGroup Buttons for animated sliders
    % - make 'SaveVideo' button only active, when timer is running
	
    properties (Access = private)
        t           % interrupt timer
        fps
        
        % DISPLAYING
        interruptedSlider
        locValString
        
        % UI Elements
        pImage
        pSlider
        pControls
        pColorbar
        hBtnShiftL
        hBtnShiftR
        hBtnRotL
        hBtnRotR
        hBtnRun
        hEditF
        hTextFPS
        locAndVals
        hBtnSaveImg
        hBtnSaveVid
        
        hBtnG
        hRadioBtnSlider
        
        % UI properties
        
        pSliderHeight
        colorbarWidth
        sliderStartPos
        division
        margin 
        height
        yPadding
        panelPos
        figurePos
    end
    
    properties (Constant, Access = private)
        % UI PROPERTIES
        % absolute width of Control panel in pixel
        controlWidth  = 300; % px        
        sliderHeight  = 20;  % px 
        sliderPadding = 4;   % px
    end
    
    methods
        function obj = DrawSingle(in, varargin)
            % CONSTRUCTOR
            obj@Draw(in, varargin{:})
            
            % only one Axis in DrawSingle
            obj.nAxes    = 1;
            obj.activeAx = 1;
            
            obj.cbDirection = 'vertical';
            
            % only show slider for a dimension with a length higher than 1
            if obj.nDims > 2
                tmp = 3:obj.nDims;
                obj.mapSliderToDim  = tmp(obj.S(3:end) > 1);
                obj.nSlider         = numel(obj.mapSliderToDim);
                obj.activeDim       = obj.mapSliderToDim(1);
            else
                % there is no dimension to slide through anyway
                obj.nSlider   = 0;
                obj.activeDim = 3;
            end
            
            obj.mapSliderToImage = num2cell(ones(1, obj.nSlider));
            if obj.nImages == 2
                obj.inputNames{1} = inputname(1);
                obj.inputNames{2} = inputname(2);
                obj.standardTitle = [inputname(1) ' ' inputname(2)];
            else
                obj.inputNames{1} = inputname(1);
                obj.standardTitle = inputname(1);
            end
            
            % default figure position and size. is adapdet to actual screensize
            % and is separated from top/bottom by 10% of up/down screensize
            screenS = get(0, 'ScreenSize');
            defaultPosition = [ 300, round(0.1*screenS(4)), 800, round(0.8*screenS(4))];
            
            obj.prepareParser()
            
            % additional parameters
            addParameter(obj.p, 'InitRot',          0,                                  @(x) isnumeric(x));
            addParameter(obj.p, 'Position',         defaultPosition,                    @(x) isnumeric(x) && numel(x) == 4);
            addParameter(obj.p, 'InitSlice',        round(obj.S(obj.mapSliderToDim)/2), @isnumeric);
            addParameter(obj.p, 'fps',              0,                                  @isnumeric);
            addParameter(obj.p, 'ROI_Signal',       [0 0; 0 0; 0 0],                    @isnumeric);
            addParameter(obj.p, 'ROI_Noise',        [0 0; 0 0; 0 0],                    @isnumeric);
            addParameter(obj.p, 'SaveImage',        '',                                 @ischar);
            addParameter(obj.p, 'SaveVideo',        '',                                 @ischar);
            addParameter(obj.p, 'LoopDimension',    3,                                  @(x) isnumeric(x) && x <= obj.nDims && obj.nDims >= 3);
                  
            parse(obj.p, obj.varargin{:});
            
            obj.cmap{1}             = obj.p.Results.Colormap;
            obj.fps                 = obj.p.Results.fps;
            obj.complexMode         = obj.p.Results.ComplexMode;
            obj.resize              = obj.p.Results.Resize;  
            obj.contrast            = obj.p.Results.Contrast;
            obj.overlay             = obj.p.Results.Overlay;
            obj.unit                = obj.p.Results.Unit;
            
            % set default values for dimLabel
            obj.dimLabel = strcat(repmat({'Dim'}, 1, numel(obj.S)), cellfun(@num2str, num2cell(1:obj.nDims), 'UniformOutput', false));
            
            obj.parseDimLabelsVals()
            
            obj.prepareGUIElements()
            
            obj.prepareColors()
                        
            % which dimensions are shown initially
            obj.showDims = [1 2]; 
            obj.createSelector()            
            
            obj.interruptedSlider = 1;
            % necessary for view orientation, already needed when saving image or video
            obj.azimuthAng   = obj.p.Results.InitRot;
                        
            % when an image or a video is saved, dont create the GUI and
            % terminate the class after finishing
            if ~contains('SaveImage', obj.p.UsingDefaults)
                obj.saveImage(obj.p.Results.SaveImage);
                if contains('SaveVideo', obj.p.UsingDefaults)
                    % the user does not want a video to be saved at the
                    % same time so close the figure and delete the object.
                    clear obj
                    return
                end                
            end
            if ~contains('SaveVideo', obj.p.UsingDefaults)
                if obj.fps == 0
                    error('Can''t write video file with 0 fps!')
                else
                    obj.saveVideo(obj.p.Results.SaveVideo);
                    clear obj
                    return
                end
            end
            
            % overwrite the default value fot maxLetters in locVal section
            obj.maxLetters = 8;
            obj.setValNames()
            
            obj.setLocValFunction()            
            
            obj.prepareGUI()
            
            obj.optimizeInitialFigureSize()   
            
            obj.guiResize()
            
            obj.recolor()
            
            set(obj.f, 'Visible', 'on');
            
            if ~contains('ROI_Signal', obj.p.UsingDefaults)
                obj.createROI(1, obj.p.Results.ROI_Signal)
            end
            if ~contains('ROI_Noise', obj.p.UsingDefaults)
                obj.createROI(2, obj.p.Results.ROI_Noise)
            end
            
            % do not assign to 'ans' when called without assigned variable
            if nargout == 0
                clear obj
            end
        end
        
        
        function delete(obj)
        % destructor
            
        end
        
        
        function prepareGUI(obj)            
            % adjust figure properties
            
            set(obj.f, ...
                'name',                 obj.p.Results.Title, ...
                'Units',                'pixel', ...
                'Position',             obj.p.Results.Position, ...
                'Visible',              'off', ...
                'ResizeFcn',            @obj.guiResize, ...
                'CloseRequestFcn',      @obj.closeRqst, ...
                'WindowKeyPress',       @obj.keyPress, ...
                'WindowButtonMotionFcn',@obj.mouseMovement, ...
                'WindowButtonUpFcn',    @obj.stopDragFcn, ...
                'WindowScrollWheelFcn', @obj.scrollSlider);
                        
            % absolute height of slider panel            
            obj.pSliderHeight   = obj.nSlider * (obj.sliderHeight + 2*obj.sliderPadding); % px
            % colorbar panel is invisible at first
            obj.colorbarWidth = 0; % px
            obj.setPanelPos()
            
            % create and place panels
            obj.pImage  = uipanel( ...
                'Units',            'pixels', ...
                'Position',         obj.panelPos(1, :), ...
                'BackgroundColor',  obj.COLOR_BG, ...
                'HighLightColor',   obj.COLOR_BG, ...
                'ShadowColor',      obj.COLOR_B);
            
            obj.pSlider = uipanel( ...
                'Units',            'pixels', ...
                'Position',         obj.panelPos(2, :), ...
                'BackgroundColor',  obj.COLOR_BG, ...
                'HighLightColor',   obj.COLOR_BG, ...
                'ShadowColor',      obj.COLOR_B);
            
            obj.pControls  = uipanel( ...
                'Units',            'pixels', ...
                'Position',         obj.panelPos(3, :), ...
                'BackgroundColor',  obj.COLOR_BG, ...
                'HighLightColor',   obj.COLOR_BG, ...
                'ShadowColor',      obj.COLOR_B);
            
            obj.pColorbar  = uipanel( ...
                'Units',            'pixels', ...
                'Position',         obj.panelPos(4, :), ...
                'BackgroundColor',  obj.COLOR_BG, ...
                'HighLightColor',   obj.COLOR_BG, ...
                'ShadowColor',      obj.COLOR_B);
            
            % place UIcontrol elements
            
            obj.margin   = 0.02 * obj.controlWidth;
            obj.height   = 0.05 * 660;
            obj.yPadding = 0.01 * 660;
            
            if obj.nImages == 1
                obj.division    = 0.40 * obj.controlWidth;
                centerString    = 'Center:';
                widthString     = 'Width:';
                signalString    = 'Signal ROI';
                noiseString     = 'Noise ROI';
                textFont        = 0.6;
            else
                obj.division    = 0.22 * obj.controlWidth;
                centerString    = 'C: ';
                widthString     = 'W: ';
                signalString    = 'S';
                noiseString     = 'N';
                textFont        = 0.4;
            end
            
            % place cw windowing elements
            if obj.nImages == 2
                set(obj.hBtnCwCopy(1), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'String',               '->', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'HorizontalAlignment',  'left');
                
                set(obj.hBtnCwCopy(2), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'String',               '<-', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'HorizontalAlignment',  'left');
            end
            
            set(obj.hTextC, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               centerString, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.6, ...
                'HorizontalAlignment',  'left');
            
            set(obj.hTextW, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               widthString, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.6, ...
                'HorizontalAlignment',  'left');
            
            for idh = 1:obj.nImages
                set(obj.hEditC(idh), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'right', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             textFont, ...
                    'FontName',             'FixedWidth', ...
                    'ForegroundColor',      obj.COLOR_m(idh, :), ...
                    'Enable',               'Inactive');
                
                set(obj.hEditW(idh), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'right', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             textFont, ...
                    'FontName',             'FixedWidth', ...
                    'ForegroundColor',      obj.COLOR_m(idh, :), ...
                    'Enable',               'Inactive');
                
                if obj.nImages == 2
                    set(obj.hBtnHide(idh), ...
                        'Parent',               obj.pControls, ...
                        'Value',                1, ...
                        'Units',                'pixel', ...
                        'String',               ['Hide (' obj.BtnHideKey(idh) ')'], ...
                        'HorizontalAlignment',  'left', ...
                        'FontUnits',            'normalized', ...
                        'FontSize',             0.4, ...
                        'ForegroundColor',      obj.COLOR_m(idh, :));                    
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
            
            set(obj.hPopCm(1), ...
                'Parent',               obj.pControls, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.6);
            if obj.nImages == 2
                set(obj.hPopCm(2), ...
                    'Parent',               obj.pControls, ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6);
                
                set(obj.hPopOverlay, ...
                    'Parent',               obj.pControls, ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6);
            end
            
            obj.hBtnShiftL = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               '<-', ...
                'Callback',             { @obj.shiftDims}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnRotL = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               'rotL', ...
                'Callback',             { @obj.rotateView}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnRotR = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               'rotR', ...
                'Callback',             { @obj.rotateView}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnShiftR = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               '->', ...
                'Callback',             { @obj.shiftDims}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            set(obj.hBtnRoi(1), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               signalString, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.4, ...
                'TooltipString',        'draw signal ROI');
            
            set(obj.hBtnRoi(2), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               noiseString, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.4, ...
                'TooltipString',        'draw noise ROI');
            
            set(obj.hTextRoi, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               '', ...
                'HorizontalAlignment',  'right', ...
                'FontUnits',            'normalized', ...
                'FontSize',             textFont, ...
                'FontName',             'FixedWidth');
            
            set(obj.hTextSNR, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'SNR:', ...
                'HorizontalAlignment',  'left', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.6);
            
            set(obj.hTextSNRvals, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               '', ...
                'HorizontalAlignment',  'right', ...
                'FontUnits',            'normalized', ...
                'FontSize',             textFont, ...
                'FontName',             'FixedWidth', ...
                'TooltipString',        'signal / noise');
            
            set(obj.hTextRoiType, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'ROI Shape', ...
                'HorizontalAlignment',  'left', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.6);
            
            set(obj.hPopRoiType, ...
                'Parent',               obj.pControls, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.6);
            
            set(obj.hBtnDelRois, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'Delete ROIs', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);
            
            set(obj.hBtnSaveRois, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               'Save ROIs', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);
            
            set(obj.hBtnFFT, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);
            
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
            
            if obj.nDims > 2
                obj.hBtnRun = uicontrol( ...
                    'Parent',               obj.pControls, ...
                    'Style',                'pushbutton', ...
                    'Units',                'pixel', ...
                    'String',               'Run', ...
                    'Callback',             { @obj.toggleTimer}, ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.45, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
                
                obj.hEditF = uicontrol( ...
                    'Parent',               obj.pControls, ...
                    'Style',                'edit', ...
                    'Units',                'pixel', ...
                    'String',               sprintf('%.2f', obj.fps), ...
                    'HorizontalAlignment',  'left', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F, ...
                    'Enable',               'Inactive', ...
                    'FontName',             'FixedWidth', ...
                    'Tooltip',              'timer precision is 1 ms', ...
                    'ButtonDownFcn',        @obj.removeListener, ...
                    'Callback',             @obj.setFPS);
                
                obj.hTextFPS = uicontrol( ...
                    'Parent',               obj.pControls, ...
                    'Style',                'text', ...
                    'Units',                'pixel', ...
                    'String',               sprintf('fps'), ...
                    'HorizontalAlignment',  'left', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
            end
            
            obj.locAndVals = annotation(obj.pControls, 'textbox', ...
                'LineStyle',            'none', ...
                'Units',                'pixel', ...
                'Position',             [obj.margin ...
                                        obj.margin+obj.height+2*obj.yPadding ...
                                        obj.controlWidth-2*obj.margin ...
                                        2.5*obj.height], ...
                'String',               '', ...
                'HorizontalAlignment',  'left', ...
                'FontUnits',            'pixel', ...
                'FontSize',             16, ...
                'FontName',             'FixedWidth', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'Interpreter',          'Tex');
            
            obj.hBtnSaveImg = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'Position',             [obj.margin ...
                                        obj.margin ...
                                        (obj.controlWidth-3*obj.margin)/2 ...
                                        obj.height], ...
                'String',               'Save Image', ...
                'Callback',             { @obj.saveImgBtn}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnSaveVid = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'Position',             [(obj.controlWidth+obj.margin)/2 ...
                                        obj.margin ...
                                        (obj.controlWidth-3*obj.margin)/2 ...
                                        obj.height], ...
                'String',               'Save Video', ...
                'Callback',             { @obj.saveVidBtn}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            if obj.nDims <= 2
                set(obj.hBtnSaveVid, 'Visible', 'off')
            end
            
            
            obj.t = timer(...
                'BusyMode',         'queue', ...
                'ExecutionMode',    'fixedRate', ...
                'Period',           1, ...
                'StartDelay',       0, ...
                'TimerFcn',         @(t, event) obj.interrupt, ...
                'TasksToExecute',   Inf);
            
            % create uibuttongroup
            obj.hBtnG = uibuttongroup( ...
                'Parent',               obj.pSlider, ...
                'Visible',              'Off', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F, ...
                'ShadowColor',          obj.COLOR_B, ...
                'HighLightColor',       obj.COLOR_BG, ...
                'SelectionChangedFcn',  @(bg, event) obj.btnGselection(bg, event), ...
                'Visible',              'on');
            
            % create and position the sliders
            for iSlider = 1:obj.nSlider
                
                sliderHeight0  = obj.pSliderHeight - iSlider*(2*obj.sliderPadding+obj.sliderHeight) + obj.sliderPadding;                
                TextWidth0     = 10;
                TextWidth      = 50;
                EditWidth0     = TextWidth0 + TextWidth + 10;
                EditWidth      = 75;
                obj.sliderStartPos = EditWidth0 + EditWidth + 10;
                
                
                obj.hTextSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'text', ...
                    'Units',            'pixel', ...                    
                    'FontUnits',        'normalized', ...
                    'Position',         [TextWidth0 sliderHeight0 TextWidth obj.sliderHeight], ...
                    'FontSize',         0.8, ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
                
                obj.hEditSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'edit', ...
                    'Units',            'pixel', ...
                    'FontUnits',        'normalized', ...
                    'Position',         [EditWidth0 sliderHeight0 EditWidth obj.sliderHeight], ...
                    'FontSize',         0.8, ...
                    'Enable',           'Inactive', ...
                    'Value',            iSlider, ...
                    'ButtonDownFcn',    @obj.removeListener, ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
                
                set(obj.hEditSlider(iSlider), 'Callback', @obj.setSlider);
                
                obj.hSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'slider', ...
                    'Units',            'pixel', ...                    
                    'Callback',         @(src, eventdata) obj.newSlice(src, eventdata), ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_BG);
                
                addlistener(obj.hSlider(iSlider), ...
                    'ContinuousValueChange', ...
                    @(src, eventdata) obj.newSlice(src, eventdata));                
                
                obj.hRadioBtnSlider(iSlider) = uicontrol(obj.hBtnG, ...
                    'Style',            'radiobutton', ...
                    'Units',            'pixel', ...
                    'Tag',              num2str(iSlider), ...
                    'HandleVisibility', 'off', ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
            end
            
            obj.initializeColorbars()
            
            obj.initializeSliders
            
            obj.initializeAxis(true)
            
            if ~sum(ismember(obj.p.UsingDefaults, 'fps')) && length(obj.S) > 2
                obj.fps = obj.p.Results.fps;
                set(obj.hBtnRun, 'String', 'Stop')
                obj.setAndStartTimer
            end
            
        end
        
        
        function initializeAxis(obj, firstCall)
            % initializeAxis is called, to create the GUI, or when the
            % dimensions of the image are shifted and a reset of UI elements is
            % necessary. Both cases differ in the value of the bool 'firstCall'
            % This includes:
            %   axes        ax1
            %   ROIs
            %   imageData   h1
            
            if ~firstCall
                delete(obj.hImage.Parent)
                obj.delRois()
            end
                         
            obj.prepareSliceData;

            ax      = axes('Parent', obj.pImage, 'Units', 'normal', 'Position', [0 0 1 1]);            
            obj.hImage  = imagesc(obj.sliceMixer(1), 'Parent', ax);  % plot image

            hold on
            eval(['axis ', obj.p.Results.AspectRatio]);
            set(ax, ...
                'XTickLabel',   '', ...
                'YTickLabel',   '', ...
                'XTick',        [], ...
                'YTick',        []);
            set(obj.hImage, 'ButtonDownFcn', @obj.startDragFcn)
            colormap(ax, obj.cmap{1});
            
            view([obj.azimuthAng 90])
        end
        
        
        function initializeSliders(obj)
            % get the size, dimensionNo, and labels only for the sliders
            s = obj.S(obj.mapSliderToDim);
            labels = obj.dimLabel(obj.mapSliderToDim);
            
            
            for iSlider = 1:obj.nSlider
                set(obj.hTextSlider(iSlider), 'String', labels{iSlider});
                
                % if dimension is singleton, set slider steps to 0
                if s(iSlider) == 1
                    steps = [0 0];
                else
                    steps = [1/(s(iSlider)-1) 10/(s(iSlider)-1)];
                end
                                
                set(obj.hSlider(iSlider), ...
                    'Min',              1, ...
                    'Max',              s(iSlider), ...
                    'Value',            obj.sel{obj.mapSliderToDim(iSlider)}, ...
                    'SliderStep',       steps);
                if s(iSlider) == 1
                    set(obj.hSlider(iSlider), ...
                        'Enable',       'off');
                end
                
                set(obj.hEditSlider(iSlider), 'String', obj.dimVal{obj.mapSliderToDim(iSlider)}{obj.sel{obj.mapSliderToDim(iSlider)}});
            end
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
                
        
        function initializeColorbars(obj)
            % add axis to display the colorbars
            for idh = 1:obj.nImages
                % create the colorbar axis for the colorbarpanel
                obj.hAxCb(idh)      = axes('Units',            'normal', ...
                    'Position',         [1/20+(idh-1)/2 1/20 1/4 18/20], ...
                    'Parent',           obj.pColorbar, ...
                    'Color',            obj.COLOR_m(idh, :));
                imagesc(linspace(0, 1, size(obj.cmap{idh}, 1))');
                colormap(obj.hAxCb(idh), obj.cmap{idh});
                caxis(obj.hAxCb(idh), [0 1])
                
                % change the y direction of the colorbars
                set(obj.hAxCb(idh), 'YDir', 'normal')
                set(obj.hAxCb(idh), 'YAxisLocation', 'Right')
                
                % remove unnecessary X ticks and labels
                set(obj.hAxCb(idh), ...
                    'XTickLabel',   [], ...
                    'XTick',        []);
            end
            
            % hide colorbar
            obj.cbShown = true;
            obj.toggleCb()
            % change callback of 'colorbar' icon in MATLAB toolbar
            hToolColorbar = findall(gcf, 'tag', 'Annotation.InsertColorbar');
            set(hToolColorbar, 'ClickedCallback', {@obj.toggleCb});
        end
        
        
        function setPanelPos(obj)
            % create a 3x4 array that stores the 'Position' information for
            % the four panels pImage, pSlider, pControl and pColorbar
            
            obj.figurePos = get(obj.f, 'Position');
            
            % pImage
            obj.panelPos(1, :) =    [obj.controlWidth ...
                                    obj.pSliderHeight ...
                                    obj.figurePos(3) - obj.controlWidth - obj.colorbarWidth...
                                    obj.figurePos(4) - obj.pSliderHeight];
            % pSlider                    
            obj.panelPos(2, :) =    [obj.controlWidth ...
                                    0 ...
                                    obj.figurePos(3) - obj.controlWidth ...
                                    obj.pSliderHeight];
            % pControl                    
            obj.panelPos(3, :) =    [0 ...
                                    0 ...
                                    obj.controlWidth ...
                                    obj.figurePos(4)];
                                
            % pColorbar                    
            obj.panelPos(4, :) =    [obj.figurePos(3) - obj.colorbarWidth ...
                                    obj.pSliderHeight ...
                                    obj.colorbarWidth ...
                                    obj.figurePos(4) - obj.pSliderHeight];
        end
        
        
        function createSelector(obj)
            % create slice selector
            obj.sel        = repmat({':'}, 1, obj.nDims);
            obj.sel(ismember(1:obj.nDims, obj.mapSliderToDim)) = num2cell(obj.p.Results.InitSlice);
            % consider singleton dimensions            
            obj.sel(obj.S == 1) = {1};
            % obj.sel{obj.S == 1} = 1; does not work here, because the
            % condition might return an empty array which fails with curly
            % brackets
        end
        
        
        function setLocValFunction(obj)
            % check 'Units' input
            if ~contains('Unit', obj.p.UsingDefaults)
                if ischar(obj.unit)
                    % make it a cell array
                    obj.unit = {obj.unit, obj.unit};
                end
            end
            
            % check the currently shown dimensions for necessity of color
            % indication, if one input is singleton along dimension
           
            
            if obj.nImages == 1
                obj.locValString = @(dim1L, dim1, dim2L, dim2, val) sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%s\n%s:%s\n%s:%s', ...
                    obj.COLOR_F, ...
                    dim1L, ...
                    dim1, ...
                    dim2L, ...
                    dim2, ...
                    obj.valNames{1}, ...
                    [num2sci(val) ' ' obj.unit{1}]);
            else
                % check the currently shown dimensions for necessity of color
                % indication, if one input is singleton along dimension
                
                adjColorStr = {'', ''};
                for iImg = 1:obj.nImages
                    match = ismember(obj.showDims, obj.ston{iImg});
                    
                    for iDim = find(match)
                        % set color to different dimensions color
                        adjColorStr{iDim} = sprintf('\\color[rgb]{%.2f,%.2f,%.2f}', obj.COLOR_m(mod(iImg, 2)+1, :));
                    end
                    
                end
                
                obj.locValString = @(dim1L, dim1, dim2L, dim2, val1, val2) ...
                    sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%s%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s', ...
                    obj.COLOR_F, ...
                    dim1L, ...
                    adjColorStr{1}, ...
                    dim1, ...
                    obj.COLOR_F, ...
                    dim2L, ...
                    adjColorStr{2}, ...
                    dim2, ...
                    obj.COLOR_m(1, :), ...
                    obj.valNames{1}, ...
                    [num2sci(val1) obj.unit{1}], ...
                    obj.COLOR_m(2, :), ...
                    obj.valNames{2}, ...
                    [num2sci(val2) obj.unit{2}]);
            end
        end
        
        
        function locVal(obj, point, ~)
            if ~isempty(point)
                if obj.nImages == 1
                    val = obj.slice{1, 1}(point{:});
                    set(obj.locAndVals, 'String', obj.locValString(...
                        obj.dimLabel{obj.showDims(1)}, obj.dimVal{obj.showDims(1)}{point{1}}, ...
                        obj.dimLabel{obj.showDims(2)}, obj.dimVal{obj.showDims(2)}{point{2}}, val));
                else
                    val1 = obj.slice{1, 1}(point{:});
                    val2 = obj.slice{1, 2}(point{:});
                    set(obj.locAndVals, 'String', obj.locValString(...
                        obj.dimLabel{obj.showDims(1)}, obj.dimVal{obj.showDims(1)}{point{1}}, ...
                        obj.dimLabel{obj.showDims(2)}, obj.dimVal{obj.showDims(2)}{point{2}}, val1, val2));
                end
            else
                set(obj.locAndVals, 'String', '');
            end
        end
        
        
        function refreshUI(obj, ~, ~)
            
            obj.prepareSliceData;            
            set(obj.hImage, 'CData', obj.sliceMixer(1));
            
            for iSlider = 1:obj.nSlider
                set(obj.hEditSlider(iSlider), 'String', obj.dimVal{obj.mapSliderToDim(iSlider)}{obj.sel{obj.mapSliderToDim(iSlider)}});
                set(obj.hSlider(iSlider), 'Value', obj.sel{obj.mapSliderToDim(iSlider)});
            end
            % update 'val' when changing slice
            obj.mouseMovement();
            
            
%             if ~isempty(Sroi) | ~isempty(Nroi)
%                 % only calculate SNR, when there are ROIs to calculate
%                 calcROI();
%             end
        end
        
        
        function keyPress(obj, src, ~)
            
            keyPress@Draw(obj, src)
            
            % in case of input with more than 2 dimensions, the image stack
            % can be scrolled with 1 and 3 on the numpad
            key = get(src, 'CurrentCharacter');
            switch(key)
                case '1'
                    if obj.nDims > 2
                        obj.incDecActiveDim(-1);
                    end
                case '3'
                    if obj.nDims > 2
                        obj.incDecActiveDim(+1);
                    end
            end
        end
        
        
        function incDecActiveDim(obj, incDec)
            % change the active dimension by incDec
            obj.sel{1, obj.activeDim} = obj.sel{1, obj.activeDim} + incDec;
            % check whether the value is too large and take the modulus
            obj.sel{1, obj.activeDim} = mod(obj.sel{1, obj.activeDim}-1, obj.S(obj.activeDim))+1;
            obj.refreshUI();
        end
        
        
        function mouseButtonAlt(obj, src, evtData)
            % code executed when the user presses the right mouse button.
            % currently not implemented.
        end
        
        
        function btnGselection(obj, ~, evtData)
           % the radio buttons are enumerated in their 'Tag' property, get
           % the 'Tag' from the now selected radio button, which is the new
           % value for the interrupted slider.
            obj.interruptedSlider = str2double(evtData.NewValue.Tag);
        end
        
        
        function interrupt(obj, ~, ~)
            % this function is called for every interrupt of the timer and
            % increments/decrements the slider value.
            if obj.fps > 0
                obj.sel{1, obj.interruptedSlider+2} = obj.sel{1, obj.interruptedSlider+2} + 1;
            elseif obj.fps < 0
                obj.sel{1, obj.interruptedSlider+2} = obj.sel{1, obj.interruptedSlider+2} - 1;
            end
                obj.sel{1, obj.interruptedSlider+2} = mod(obj.sel{1, obj.interruptedSlider+2}-1, obj.S(obj.interruptedSlider+2))+1;
            obj.refreshUI();
        end
        
        
        function setFPS(obj, src, ~)
            % called by the center and width edit fields
            s = get(src, 'String');
            %turn "," into "."
            s(s == ',') = '.';
            
            obj.fps = str2double(s);
            % set(src, 'String', num2str(obj.fps));
            stop(obj.t)
            set(obj.hBtnRun, 'String', 'Run');
            if obj.fps ~= 0
                obj.setAndStartTimer;
                set(obj.hBtnRun, 'String', 'Stop');
            end
        end
        
        
        function setAndStartTimer(obj)
            % make sure fps is not higher 100
            period  = 1/abs(obj.fps) + (abs(obj.fps) > 100)*(1/100-1/abs(obj.fps));
            % provide 1 ms precision to avoid warning
            period = round(period*1000)/1000;
            
            obj.t.Period    = period;
            obj.t.TimerFcn  = @(t, event) obj.interrupt(obj.fps);
            set(obj.hEditF, 'String', num2str(sign(obj.fps)/obj.t.Period));
            start(obj.t)
        end
        
        
        function toggleTimer(obj, ~, ~)
            %called by the 'Run'/'Stop' button and controls the state of the
            %timer
            if strcmp(get(obj.t, 'Running'), 'off') && obj.fps ~= 0
                obj.setAndStartTimer;
                set(obj.hBtnRun, 'String',  'Stop');
                set(obj.hBtnG,   'Visible', 'on');
            else
                stop(obj.t)
                set(obj.hBtnRun, 'String',  'Run');
                set(obj.hBtnG,   'Visible', 'off');
            end
        end
        
        
        function saveImgBtn(obj, ~, ~)
            % get the filepath from a UI and call saveImage funciton to save
            % the image
            [filename, filepath] = uiputfile({'*.jpg; *.png'}, 'Save image', '.png');
            if filepath == 0
                % uipufile was closed without providing filename.
                return
            else
                obj.saveImage([filepath, filename])
            end
        end
        
        
        function saveImage(obj, path)
            % save image of current slice with current windowing to filename
            % definde in path
            
            obj.prepareSliceData;       
            % apply the current azimuthal rotation to the image and save
            imwrite(rot90(obj.sliceMixer(1), -round(obj.azimuthAng/90)), path);
        end
        
        
        function saveVidBtn(obj, ~, ~)
            % get the filepath from a UI and call saveVideo funciton to save
            % the video or gif
            [filename, filepath] = uiputfile({'*.avi', 'AVI-file (*.avi)'; ...
                '*.gif', 'gif-Animation (*.gif)'}, ...
                'Save video', '.avi');
            
            if filepath == 0
                return
            else
                obj.saveVideo([filepath, filename])
            end
        end
        
        
        function saveVideo(obj, path)
            % save video of matrix with current windowing and each frame being
            % one slice in the 3rd dimension.
            
            if ~isempty(obj.t)
                % get the state of the timer
                bRunning = strcmp(obj.t.Running, 'on');
                % stop the interrupt, to get control over the data shown.
                if bRunning
                    stop(obj.t)
                end
            end
            
            if strcmp(path(end-2:end), 'avi') || strcmp(path(end-2:end), 'gif')
                
                if  strcmp(path(end-2:end), 'gif')
                    gif = 1;
                else
                    gif = 0;
                    % start the video writer
                    v           = VideoWriter(path);
                    v.FrameRate = obj.fps;
                    v.Quality   = 100;
                    open(v);
                end
                % select the looping slices that are currently shown in the DrawSingle
                % window, resize image, apply the colormap and rotate according
                % to the azimuthal angle of the view.
                for ii = 1: obj.S(obj.interruptedSlider+2)
                    obj.sel{obj.interruptedSlider+2} = ii;
                    obj.prepareSliceData
                    imgOut = rot90(obj.sliceMixer(1), -round(obj.azimuthAng/90));
                    
                    if gif
                        [gifImg, cm] = rgb2ind(imgOut, 256);
                        if ii == 1
                            imwrite(gifImg, cm, path, 'gif', ...
                                'WriteMode',    'overwrite', ...
                                'DelayTime',    1/obj.fps, ...
                                'LoopCount',    Inf);
                        else
                            imwrite(gifImg, cm, path, 'gif', ...
                                'WriteMode',    'append',...
                                'DelayTime',    1/obj.fps);
                        end
                    else
                        writeVideo(v, imgOut);
                    end
                end
            else
                warning('Invalid filename! Data was not saved.');
            end
            
            if ~gif
                close(v)
            end
            
            if ~isempty(obj.t)
                % restart the timer if it was running before
                if bRunning
                    start(obj.t)
                end
            end
        end
        
        
        function closeRqst(obj, ~, ~)
            % closeRqst is called, when the user closes the figure (by 'x' or
            % 'close'). It stops and deletes the timer, frees up memory taken
            % by img and closes the figure.
            
            try
                stop(obj.t);
                delete(obj.t);
            catch
            end
            
            delete(obj.f);
            delete(obj)
        end
        
        
        function toggleCb(obj, ~, ~)
            images = allchild(obj.hAxCb);
            if ~obj.cbShown
                obj.colorbarWidth = 150;
                set(obj.hAxCb,      'Visible', 'on')
                if obj.nImages == 1
                    set(images,      'Visible', 'on')
                else
                    set([images{:}],    'Visible', 'on')
                end
                obj.cbShown = true;
                % guiResize() must be called before cw(), otherwise tick
                % labels are not shown
                obj.guiResize()
                % run cw() again, to update ticklabels
                obj.cw();
            else
                obj.colorbarWidth = 0;
                set(obj.hAxCb,      'Visible', 'off')
                if obj.nImages == 1
                    set(images,    'Visible', 'off')
                else
                    set([images{:}],    'Visible', 'off')
                end
                obj.cbShown = false;
                obj.guiResize()
            end
        end
        
        
        function rotateView(obj, src, ~)
            % function is called by the two buttons (rotL, rotR)
            switch (src.String)
                case 'rotL'
                    obj.azimuthAng = mod(obj.azimuthAng - 90, 360);
                case 'rotR'
                    obj.azimuthAng = mod(obj.azimuthAng + 90, 360);
            end
            view([obj.azimuthAng 90])
        end
        
        
        function shiftDims(obj, src, ~)
            % this line ignores singleton dimensions, because they dont get
            % a slider and a boring to look at
            dimArray = [obj.showDims obj.mapSliderToDim];
            switch (src.String)
                case '->'
                    shifted = circshift(dimArray, -1);
                    % activeDim defines the active slider and cant be one
                    % of the shown dimensions
                    if ismember(obj.activeDim, shifted(1:2))
                        obj.activeDim = shifted(3);
                    end
                case '<-'
                    shifted = circshift(dimArray, +1);
                    if ismember(obj.activeDim, shifted(1:2))
                        obj.activeDim = shifted(end);
                    end
            end
            obj.showDims        = shifted(1:2);
            obj.mapSliderToDim  = shifted(3:end);
                        
            % renew slice selector for dimensions 3 and higher
            obj.sel        = repmat({':'}, 1, obj.nDims);
            %obj.sel(ismember(1:obj.nDims, obj.mapSliderToDim)) = num2cell(round(obj.S(obj.mapSliderToDim)/2));
            obj.sel(obj.mapSliderToDim) = num2cell(round(obj.S(obj.mapSliderToDim)/2));
            % consider singleton dimensions
            obj.sel(obj.S == 1) = {1};
            
            obj.initializeSliders()
            obj.initializeAxis(false)
            obj.recolor()
        end
        
        
        function optimizeInitialFigureSize(obj)
            % cange the figure size such, that the image fill pImage
            % without border
            % no aspect ratio was specified -> the image is a square.
            % The necessary figure dimension is increased to make pImage
            % a square
            addPix = max(obj.pImage.Position(3:4)) - obj.pImage.Position(3:4);
            obj.f.Position(3:4) =  obj.f.Position(3:4) + addPix;
            % limit the figure size
            if obj.f.Position(3) > 1800
                obj.f.Position(3) = 1800;
            end
            if obj.f.Position(4) > 1000
                obj.f.Position(4) = 1000;
            end
        end
        
        
        function guiResize(obj, ~, ~)
            obj.figurePos = get(obj.f, 'Position');
            
            if obj.figurePos(3) < obj.controlWidth
                % make sure the window is not wide enough
                 obj.f.Position(3) = obj.controlWidth;
            end
            
            obj.setPanelPos()            
            set(obj.pImage,     'Position', obj.panelPos(1, :));
            set(obj.pSlider,    'Position', obj.panelPos(2, :));
            set(obj.pControls,  'Position', obj.panelPos(3, :));
            set(obj.pColorbar,  'Position', obj.panelPos(4, :));
                  
            % set Slider positions
            RadioBtnWidth = 30; % px 
            sliderWidth   = obj.pSlider.Position(3) - obj.sliderStartPos - RadioBtnWidth - 10;
            
            if sliderWidth <= 20
                obj.f.Position(3) = obj.controlWidth + obj.sliderStartPos + RadioBtnWidth + 10 + 21;
                obj.setPanelPos()
                set(obj.pControls,  'Position', obj.panelPos(3, :));
                sliderWidth       = obj.pSlider.Position(3) - obj.sliderStartPos - RadioBtnWidth - 10;
            end
            
            for iSlider = 1:obj.nSlider
                sliderHeight0  = obj.pSliderHeight - iSlider*(2*obj.sliderPadding+obj.sliderHeight) + obj.sliderPadding;
                
                set(obj.hSlider(iSlider), 'Position', [obj.sliderStartPos ...
                                        sliderHeight0 ...
                                        sliderWidth ...
                                        obj.sliderHeight]);
                                        
                set(obj.hRadioBtnSlider(iSlider), 'Position', [obj.sliderStartPos + sliderWidth + 10 ...
                                        sliderHeight0 ...
                                        RadioBtnWidth ...
                                        obj.sliderHeight]);
            end
            
            n = 0.5;
            if obj.nImages == 2
                position = obj.divPosition(n, 0.5);
                set(obj.hBtnCwCopy(1), 'Position', position(2, :));
                set(obj.hBtnCwCopy(2), 'Position', position(3, :));
            end
            
            n = n + 1;
            position = obj.divPosition(n);
            set(obj.hTextC, 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hEditC(ii), 'Position', position(ii+1, :));
            end
            
            n = n + 1;
            position = obj.divPosition(n);
            set(obj.hTextW, 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hEditW(ii), 'Position', position(ii+1, :));
            end
            
            if obj.nImages == 2
                n = n + 1;
                position = obj.divPosition(n);
                set(obj.hBtnToggle,   'Position', position(1, :));
                set(obj.hBtnHide(1),  'Position', position(2, :));
                set(obj.hBtnHide(2),  'Position', position(3, :));
            end
            
            n = n + 1;
            if obj.nImages == 1
                position = obj.positionN(n, 1);
                set(obj.hPopCm(1), 'Position', position(1, :));
            else
                position = obj.divPosition(n);
                set(obj.hPopOverlay,  'Position', position(1, :));
                set(obj.hPopCm(1),    'Position', position(2, :));
                set(obj.hPopCm(2),    'Position', position(3, :));
            end
            n = n + 1;
            position = obj.divPosition(n);
            set(obj.hBtnRoi(1), 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hTextRoi(1, ii), 'Position', position(ii+1, :));
            end
            
            n = n + 1;
            position = obj.divPosition(n);
            set(obj.hBtnRoi(2), 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hTextRoi(2, ii), 'Position', position(ii+1, :));
            end
            
            n = n + 1;
            position = obj.divPosition(n);
            set(obj.hTextSNR, 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hTextSNRvals(ii), 'Position', position(ii+1, :));
            end
            
            n = n + 1;
            position = obj.positionN(n, 2);
            set(obj.hTextRoiType, 'Position', position(1, :));
            set(obj.hPopRoiType,  'Position', position(2, :));    
            
            n = n + 1;
            position = obj.positionN(n, 2);
            set(obj.hBtnSaveRois,  'Position', position(1, :));
            set(obj.hBtnDelRois, 'Position', position(2, :)); 
            
            n = n + 1;
            position = obj.positionN(n, 4);
            set(obj.hBtnShiftL, 'Position', position(1, :));
            set(obj.hBtnRotL,   'Position', position(2, :));
            set(obj.hBtnRotR,   'Position', position(3, :));
            set(obj.hBtnShiftR, 'Position', position(4, :));
            
            n = n + 1.5;
            set(obj.hBtnFFT, 'Position', obj.positionN(n, 1));
            
            n = n + 1;
            position = obj.positionN(n, 4);
            set(obj.hBtnCmplx(1), 'Position', position(1, :))
            set(obj.hBtnCmplx(2), 'Position', position(2, :))
            set(obj.hBtnCmplx(3), 'Position', position(3, :))
            set(obj.hBtnCmplx(4), 'Position', position(4, :))
            
            if obj.nDims > 2
                n = n + 1.5;
                position = obj.positionN(n, 3);
                set(obj.hBtnRun,    'Position', position(1, :))
                set(obj.hEditF,     'Position', position(2, :))
                set(obj.hTextFPS,   'Position', position(3, :))
            end
        end
            
        
        function pos = divPosition(obj, N, hF)
            if nargin == 2
                % set the height changing factor to 1
                hF = 1;
            end
            
            yPos = ceil(obj.figurePos(4)-obj.margin-(N)*obj.height-(N-1)*obj.yPadding);
            if obj.nImages == 1
                pos = [obj.margin ...
                    yPos ...
                    obj.division-2*obj.margin ...
                    obj.height*hF; ...
                    obj.division+obj.margin/2 ...
                    yPos ...
                    (obj.controlWidth-obj.division)-obj.margin ...
                    obj.height*hF];
            else
                pos = [obj.margin/2 ...
                    yPos ...
                    obj.division-3/4*obj.margin ...
                    obj.height*hF; ...
                    obj.division+obj.margin/4 ...
                    yPos ...
                    (obj.controlWidth-obj.division)/2-5/4*obj.margin ...
                    obj.height*hF; ...
                    obj.division+obj.margin/2+((obj.controlWidth-obj.division)/2-3/4*obj.margin) ...
                    yPos ...
                    (obj.controlWidth-obj.division)/2-5/4*obj.margin ...
                    obj.height*hF];
            end
        end
        
        
        function pos = divPosition3(obj, N)
            yPos = ceil(obj.figurePos(4)-obj.margin-N*obj.height-(N-1)*obj.yPadding);
            pos = [obj.division+obj.margin/2 ...
                yPos ...
                (obj.controlWidth-obj.division-7/2*obj.margin)/3 ...
                obj.height; ...
                obj.division+1/2*obj.margin+(obj.controlWidth-obj.division-1/2*obj.margin)/3 ...
                yPos ...
                (obj.controlWidth-obj.division-7/2*obj.margin)/3 ...
                obj.height; ...
                obj.division+1/2*obj.margin+2*(obj.controlWidth-obj.division-1/2*obj.margin)/3 ...
                yPos ...
                (obj.controlWidth-obj.division-7/2*obj.margin)/3 ...
                obj.height];
        end
        
        
        function pos = positionN(obj, h, n)
            % h: heigth value
            % n: number of equally spaced horitonzal elements
            yPos  = ceil(obj.figurePos(4)-obj.margin-h*obj.height-(h-1)*obj.yPadding);
            width =(obj.controlWidth-(n+1)*obj.margin)/n;
            
            pos   = repmat([0 yPos width obj.height], [n, 1]);
            xPos  = (0:(n-1)) * (width+ obj.margin) + obj.margin;
            
            pos(:, 1) = xPos;
        end
    end
end