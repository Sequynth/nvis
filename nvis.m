classdef nvis < nvisBase
    %nvis visualizes 2D slices from higherdimensional data
    % 	NVIS(I) opens a UI that displays one 2D slice from the input
    % 	matrix I with N dimensions (N>2). Sliders allow to navigate thorugh
    % 	the remaining, non-singleton dimensions. The windowing of the
    % 	colormaps can be dynamically changed by pressing the middle mouse
    % 	button on the image and moving the mouse up/down (center) or
    % 	left/right(width). ROIs can be drawn to measure Signal to Noise
    % 	ratio in image data.
    %
    % 	NVIS(I1, I2): Data from the matrices I1 and I2 are overlaid
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
    %  	<- and -> change the dimensions that are shown along the image
    %  	dimensions. Initially, dimensions 1 and 2 are shown. By presing <-
    %  	/ -> both are decreased/increased by 1, wrapping where necessary.
    %   'Run' starts a timer which loops through the image dimension
    %   selected by the radio button. 'SaveImage' save the currently
    %   visible image to file, 'SaveVideo' saves the running animation as a
    %   video file (.avi or .gif)
    %   The crosshair button creates a circle in the current image and the
    %   'Plot' button opens an external window that shos the behavior of
    %   the data through that point along different dimensions of the input
    %   matrix. Continuous updating of the data shown in the external plot
    %   can be switched on or off using the 'Update' button.
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
    %   'InitPoint',    1x2         coordinates along the first 2
    %                               dimensions of img, where the marker is
    %                               placed
    %	'DimLabel',     cell{char}  char arrays to label the individual
    %                               dimensions in the input data. Cell
    %                               entries can be empty to use default
    %                               label.
    %	'DimVal', cell{cell{char}}  char arrays containing the axis-values
    %                or cell{int}   for each dimension. Cell entries can be
    %                               empty to use default enumeration. Vals
    %                               must not be char, but is encouraged.
    %   'Permute'       1xN         permutation vector, that works similar
    %                               to matlabs permute function. It is used
    %                               to access image information in
    %                               different order. Use this when working
    %                               with large image matrices, to avoid
    %                               additional memory usage from calling
    %                               permute.
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
    
    %______________________________________________________________________
    % Authors:  Johannes Fischer
    %           Yanis Taege
    
    % TODO:
    % - RadioGroup Buttons for animated sliders
    % - make 'SaveVideo' button only active, when timer is running
    % - make clear that externalPlot does not work when fft button is
    % pressed (would require fft of the whole stack)
	
    properties (Access = private)
        
        % DISPLAYING
        locValString
        
        % UI Elements
        pImage
        pSlider
        pControls
        pColorbar
        hBtnShiftL
        hBtnShiftR
        hBtnPoint
        hBtnPlot
        hBtnUpdateExternal
        locAndVals
        
        hBtnG
        hRadioBtnSlider

        InitSlice
        
        %% external plot parameters
        % point for external plots
        hMarker
        point
        
        % called objects
        hExtPlot
        % dimension that is shown in the external plot
        externalDim
        externalSel
        % switch, whether external plot should be updated when selector is
        % changed
        bUpdateExternal
        
        %% UI properties
        
        pSliderHeight
        colorbarWidth
        sliderStartPos
        division
        margin 
        height
        yPadding
        panelPos
        figurePos
        pointEnabled
        color_ma

        

    end
    
    properties (Constant, Access = private)
        %% UI PROPERTIES
        % absolute width of Control panel in pixel
        controlWidth            = 300; % px
        controlWidthMinimized   = 30 ; % px
        sliderHeight            = 20;  % px 
        sliderPadding           = 4;   % px
    end
    
    methods
        function obj = nvis(in, varargin)
            %% CONSTRUCTOR
            obj@nvisBase(in, varargin{:})
            % set the type
            obj.Type = 'nvis';
            
            % only one Axis in nvis
            obj.nAxes    = 1;
            obj.activeAx = 1;
            
            obj.cbDirection = 'vertical';
            
            % per default, update external plots
            obj.bUpdateExternal = 1;

            if obj.nImages == 2
                obj.inputNames{1} = inputname(1);
                obj.inputNames{2} = inputname(2);
                obj.standardTitle = [inputname(1) ' ' inputname(2)];
            else
                obj.inputNames{1} = inputname(1);
                obj.standardTitle = inputname(1);
            end
                 
            obj.prepareParser()
            
            % additional parameters 
            addParameter(obj.p, 'InitSlice',        round(obj.S([false false obj.S(3:end) > 2])/2), @isnumeric);
            addParameter(obj.p, 'InitPoint',        [1 1],                                          @isnumeric);
            addParameter(obj.p, 'InitShift',        0,                                              @(x) isnumeric(x) && isscalar(x));
            addParameter(obj.p, 'MarkerColor',      [1 0 0],                                        @(x) isnumeric(x) && numel(x) == 3);
            addParameter(obj.p, 'ROI_Signal',       [0 0; 0 0; 0 0],                                @isnumeric);
            addParameter(obj.p, 'ROI_Noise',        [0 0; 0 0; 0 0],                                @isnumeric);
            addParameter(obj.p, 'Permute',          1:obj.nDims,                                    @(x) isnumeric(x) && numel(x) >= obj.nDims && isequal(sort(x, 'ascend'), 1:numel(x)) );            
                  
            parse(obj.p, obj.varargin{:});

            % remove all entries from permute, where obj.S is 1. Create a
            % temporary size variable with trailing 1s to mimick behaviour
            % of matlabs inbuilt permute function
            s = [obj.S ones(1, max(obj.p.Results.Permute)-numel(obj.S))];
            permute = obj.p.Results.Permute(s(obj.p.Results.Permute) > 1);
            % which dimensions are shown initially
            obj.showDims = permute([1 2]);

            % are there more than 2 dimensions with size > 1?
            if numel(permute) > 2
                tmp = permute(3:end);
                % create a temporary size variable with trailing 1s to
                % mimick behaviour of matlabs inbuilt permute function
                
                obj.mapSliderToDim  = tmp(s(tmp) > 1);
                obj.nSlider         = numel(obj.mapSliderToDim);
                obj.activeDim       = obj.mapSliderToDim(1);
                obj.externalDim     = obj.mapSliderToDim(1);
            else
                % there is no dimension to slide through anyway
                obj.nSlider         = 0;
                obj.activeDim       = 3;
                obj.externalDim     = [];
            end

            % after parsing the Permute vector, initially shown slices and
            % dimensions might have changed. p.Results is write protected,
            % so we have to provide our own parameter
            if contains('InitSlice', obj.p.UsingDefaults)
                obj.InitSlice = round(obj.S(obj.mapSliderToDim)/2);
            else
                obj.InitSlice = obj.p.Results.InitSlice;
            end

            if contains('InitPoint', obj.p.UsingDefaults)
                obj.point = round(obj.S(obj.showDims)/2);
            else
                obj.point = obj.p.Results.InitPoint;
            end

             % only one image in nvis
            obj.mapSliderToImage = num2cell(ones(1, obj.nSlider));
                        
            % if not specified, start with plotpoint disabled
            if contains('InitPoint', obj.p.UsingDefaults)
                obj.pointEnabled = 0;
            else
                obj.pointEnabled = 1;
            end
            
            obj.cmap{1}             = obj.p.Results.Colormap;
            obj.fps                 = obj.p.Results.fps;
            obj.complexMode         = obj.p.Results.ComplexMode;
            obj.resize              = obj.p.Results.Resize;  
            obj.contrast            = obj.p.Results.Contrast;
            obj.overlay             = obj.p.Results.Overlay;
            obj.unit                = obj.p.Results.Unit;
            obj.color_ma            = obj.p.Results.MarkerColor;            
            obj.fixedDim            = obj.p.Results.fixedDim;
            if obj.fixedDim ~= 0
                if (obj.S(obj.p.Results.fixedDim) > 1)
                obj.interruptedSlider = find(obj.mapSliderToDim == obj.p.Results.fixedDim, 1);
                else
                    warning('fixedDim was set to singleton dimension and will be ignored.')
                    obj.fixedDim = 0;
                end
            else
                obj.interruptedSlider   = obj.p.Results.LoopDimension - 2;
            end
            
            
            % set default values for dimLabel
            obj.dimLabel = strcat(repmat({'Dim'}, 1, numel(obj.S)), cellfun(@num2str, num2cell(1:obj.nDims), 'UniformOutput', false));
            
            obj.parseDimLabelsVals()
            
            obj.prepareGUIElements()
            
            obj.prepareColors()                        
            
            % requires InitSlice to be set
            obj.createSelector()

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

            if obj.p.Results.InitShift ~= 0
                obj.shiftDims(obj.p.Results.InitShift);
            end            
            
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
        %% destructor
            
        end
        
        
        function prepareGUI(obj)            
            %% adjust figure properties
            
            set(obj.f, ...
                'name',                 obj.p.Results.Title, ...
                'Units',                'pixel', ...
                'Position',             obj.p.Results.Position, ...
                'Visible',              'off', ...
                'ResizeFcn',            @obj.guiResize, ...
                'CloseRequestFcn',      @obj.closeRqst, ...
                'WindowButtonMotionFcn',@obj.mouseMovement, ...
                'WindowButtonUpFcn',    @obj.stopDragFcn, ...
                'WindowScrollWheelFcn', @obj.scrollSlider, ...
                'KeyPressFcn',          @obj.keyPressedFcn);
                        
            % absolute height of slider panel            
            obj.pSliderHeight   = obj.nSlider * (obj.sliderHeight + 2*obj.sliderPadding); % px
            % colorbar panel is invisible at first
            obj.colorbarWidth = 0; % px
            obj.calcPanelPos()
            
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
            obj.yPadding = 0.0075 * 660;
            
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
            
            num = {'first', 'second'};
            for ii = 1:obj.nImages
                set(obj.hBtnCwHome(ii), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'HorizontalAlignment',  'left');
                
                set(obj.hBtnCwSlice(ii), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'HorizontalAlignment',  'left');
                
                if obj.nImages == 2
                    set(obj.hBtnCwHome(ii),  'Tooltip', ['use initial windowing on ' num{ii} ' image']);
                    set(obj.hBtnCwSlice(ii), 'Tooltip', ['window current slice of ' num{ii} ' image']);
                end
                
            end
            
            % place cw windowing elements
            if obj.nImages == 2
                set(obj.hBtnCwCopy(1), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'HorizontalAlignment',  'left');
                
                set(obj.hBtnCwCopy(2), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'HorizontalAlignment',  'left');
                
                 set(obj.hBtnCwLink, ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'center');
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
                    'ForegroundColor',      obj.COLOR_m(idh, :));
                
                set(obj.hEditW(idh), ...
                    'Parent',               obj.pControls, ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'right', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             textFont, ...
                    'FontName',             'FixedWidth', ...
                    'ForegroundColor',      obj.COLOR_m(idh, :));
                
                if obj.nImages == 2
                    set(obj.hBtnHide(idh), ...
                        'Parent',               obj.pControls, ...
                        'Value',                1, ...
                        'Units',                'pixel', ...
                        'String',               ['Hide (' obj.BtnHideKey{idh} ')'], ...
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
                'Callback',             { @obj.shiftCallback}, ...
                'String',               char(8592), ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.75, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
                      
            obj.hBtnRotL = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               char(11119), ...
                'Tooltip',              'rotate image counter-clockwise by 90°', ...
                'Callback',             { @obj.rotateView, -90}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.75, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);

            obj.hBtnRotR = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               char(11118), ...
                'Tooltip',              'rotate image clockwise by 90°', ...
                'Callback',             { @obj.rotateView, 90}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.75, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);

            obj.hBtnShiftR = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'Callback',             { @obj.shiftCallback}, ...
                'String',               char(8594), ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.75, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            set(obj.hBtnRoi(1), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               signalString, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.4, ...
                'Tooltip',              'draw signal ROI');
            
            set(obj.hBtnRoi(2), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               noiseString, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.4, ...
                'Tooltip',              'draw noise ROI');
            
            set(obj.hTextRoi(1), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               '', ...
                'Tooltip',              'mean value inside signal ROI', ...
                'HorizontalAlignment',  'right', ...
                'FontUnits',            'normalized', ...
                'FontSize',             textFont, ...
                'FontName',             'FixedWidth');

            set(obj.hTextRoi(2), ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'String',               '', ...
                'Tooltip',              'standard deviation inside noise ROI', ...
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
                'Tooltip',              'signal / noise');
            
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
                set(obj.hBtnRun, ...
                    'Parent',               obj.pControls, ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.45);
                
                set(obj.hEditF, ...
                    'Parent',               obj.pControls, ...
                    'HorizontalAlignment',  'left', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6, ...
                    'FontName',             'FixedWidth');
                
                set(obj.hTextFPS, ...
                    'Parent',               obj.pControls, ...
                    'HorizontalAlignment',  'left', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.6);
                
                obj.hBtnPoint = uicontrol( ...
                    'Parent',               obj.pControls, ...
                    'Style',                'togglebutton', ...
                    'Units',                'pixel', ...
                    'String',               char(8982), ...
                    'Value',                obj.pointEnabled, ...
                    'Callback',             {@obj.togglePoint}, ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.85, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
                
                obj.hBtnPlot = uicontrol( ...
                    'Parent',               obj.pControls, ...
                    'Style',                'pushbutton', ...
                    'Units',                'pixel', ...
                    'String',               'Plot', ...
                    'Callback',             {@obj.openExternalPlot}, ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.45, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
                
                obj.hBtnUpdateExternal = uicontrol( ...
                    'Parent',               obj.pControls, ...
                    'Style',                'pushbutton', ...
                    'Units',                'pixel', ...
                    'String',               'Update: on', ...
                    'Callback',             {@obj.toggleUpdateExternal}, ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.45, ...
                    'Tooltip',              'Update data in external plot', ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
            end
            
            if obj.pointEnabled
                set(obj.hBtnPlot, 'Enable', 'on')
                set(obj.hBtnUpdateExternal, 'Enable', 'on')
            else
                set(obj.hBtnPlot, 'Enable', 'off')
                set(obj.hBtnUpdateExternal, 'Enable', 'off')
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
            
            width_BtnMinimMaxim = obj.controlWidthMinimized - 2*obj.margin;

            set(obj.hBtnSaveImg, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'Position',             [obj.margin ...
                                        obj.margin ...
                                        (obj.controlWidth-width_BtnMinimMaxim-4*obj.margin)/2 ...
                                        obj.height], ...
                'String',               'Save Image', ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);
            
            set(obj.hBtnSaveVid, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'Position',             [(obj.controlWidth-width_BtnMinimMaxim)/2 ...
                                        obj.margin ...
                                        (obj.controlWidth-width_BtnMinimMaxim-4*obj.margin)/2 ...
                                        obj.height], ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);

            set(obj.hBtnMinimMaxim, ...
                'Parent',               obj.pControls, ...
                'Units',                'pixel', ...
                'Position',             [obj.controlWidth-width_BtnMinimMaxim-obj.margin ...
                                        obj.margin ...
                                        width_BtnMinimMaxim ...
                                        obj.height], ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.45);


            
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
                    'Enable',           'on', ...
                    'Value',            iSlider, ...
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
                set(obj.hBtnRun, 'String', 'Stop')
                obj.setAndStartTimer
            end
            
        end
        
        
        function initializeAxis(obj, firstCall)
            %% (re)create the axes in the GUI
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

            ax = axes(...
                'Parent',       obj.pImage, ...
                'Units',        'normal', ...
                'Position',     [0 0 1 1]);            
            
            
            obj.hImage = imagesc(obj.sliceMixer(1), ...
                'Parent',       ax);  % plot image
            hold on
            obj.hMarker = plot(obj.point(1), obj.point(2), ...
                'Parent',       ax, ...
                'MarkerSize',   10, ...
                'LineWidth',    2, ...
                'Color',        obj.color_ma, ...
                'Marker',       'o', ...
                'Visible',      obj.pointEnabled);            
            
            axis(obj.p.Results.AspectRatio)
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
            %% (re)set slider labels and steps
            
            % get the size, dimensionNo, and labels only for the sliders
            s = obj.S(obj.mapSliderToDim);
            labels = obj.dimLabel(obj.mapSliderToDim);
            
            
            for iSlider = 1:obj.nSlider
                set(obj.hTextSlider(iSlider), 'String', labels{iSlider});
                % set the tooltip the same, this helps with longer labels
                % without taking up too much space
                set(obj.hTextSlider(iSlider), 'Tooltip', labels{iSlider});
                
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
            %% change UI colors according to used colormaps
            % this function is called, when the user changes a colormap in
            % the GUI. To keep the colors consistent and easier
            % attributable to each input, the colors in the GUI need to be
            % adapted. Specifically in the locValString and the slider
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
            %% create custom colorbar objects
            
            % add axis to display the colorbars
            for idh = 1:obj.nImages
                % create the colorbar axis for the colorbarpanel
                obj.hAxCb(idh)      = axes('Units',            'normal', ...
                    'Position',         [1/20+(idh-1)/2 1/20 1/4 18/20], ...
                    'Parent',           obj.pColorbar, ...
                    'Color',            obj.COLOR_m(idh, :));
                imagesc(linspace(0, 1, size(obj.cmap{idh}, 1))');
                colormap(obj.hAxCb(idh), obj.cmap{idh});
                clim(obj.hAxCb(idh), [0 1])
                
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
        
        
        function toggleCb(obj, ~, ~)
            %% show/hide custom colorbar(s)
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
        
        
        function calcPanelPos(obj)
            % create a 3x4 array that stores the 'Position' information for
            % the four panels pImage, pSlider, pControl and pColorbar
            
            obj.figurePos = get(obj.f, 'Position');

            if obj.maximized
                controlW = obj.controlWidth;
            else
                controlW = obj.controlWidthMinimized;
            end
            
            % pImage
            obj.panelPos(1, :) =    [controlW ...
                                    obj.pSliderHeight ...
                                    obj.figurePos(3) - controlW - obj.colorbarWidth...
                                    obj.figurePos(4) - obj.pSliderHeight];
            % pSlider                    
            obj.panelPos(2, :) =    [controlW ...
                                    0 ...
                                    obj.figurePos(3) - controlW ...
                                    obj.pSliderHeight];
            % pControl                    
            obj.panelPos(3, :) =    [0 ...
                                    0 ...
                                    controlW ...
                                    obj.figurePos(4)];
                                
            % pColorbar                    
            obj.panelPos(4, :) =    [obj.figurePos(3) - obj.colorbarWidth ...
                                    obj.pSliderHeight ...
                                    obj.colorbarWidth ...
                                    obj.figurePos(4) - obj.pSliderHeight];
        end


        function setPanelPos(obj)
            % change the position of the 4 panels according to the values
            % in obj.panelPos

            set(obj.pImage,     'Position', obj.panelPos(1, :));
            set(obj.pSlider,    'Position', obj.panelPos(2, :));
            set(obj.pControls,  'Position', obj.panelPos(3, :));
            set(obj.pColorbar,  'Position', obj.panelPos(4, :));

        end
        
        
        function createSelector(obj)
            % create slice selector
            obj.sel        = repmat({':'}, 1, obj.nDims);
            obj.sel(obj.mapSliderToDim) = num2cell(obj.InitSlice);
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
                set(obj.hEditSlider(iSlider),   'String',   obj.dimVal{obj.mapSliderToDim(iSlider)}{obj.sel{obj.mapSliderToDim(iSlider)}});
                set(obj.hSlider(iSlider),       'Value',    obj.sel{obj.mapSliderToDim(iSlider)});
            end
            
            % update 'val' when changing slice
            obj.mouseMovement();
            
            % if existing, update the point in the external plot figure
            if ~isempty(obj.hExtPlot) && isvalid(obj.hExtPlot) ...
                    && obj.pointEnabled && obj.bUpdateExternal
                obj.updateExternalData()
                obj.updateExternalPoint()
            end
            
        end
        
        
        function incDecActiveDim(obj, incDec)
            % change the active dimension by incDec
            obj.sel{1, obj.activeDim} = obj.sel{1, obj.activeDim} + incDec;
            % check whether the value is too large and take the modulus
            obj.sel{1, obj.activeDim} = mod(obj.sel{1, obj.activeDim}-1, obj.S(obj.activeDim))+1;
            
            obj.refreshUI();
        end
        
       
        function mouseBtnAlt(obj, ~, ~)
            % code executed when the user presses the right mouse button.
            % currently not implemented.
        end


        function mouseBtnDouble(obj, ~, ~)
            % code executed when the user uses left double-click.
            % currently not implemented.
        end
        
        
        function btnGselection(obj, ~, evtData)
           % the radio buttons are enumerated in their 'Tag' property, get
           % the 'Tag' from the now selected radio button, which is the new
           % value for the interrupted slider.
            obj.interruptedSlider = str2double(evtData.NewValue.Tag);
        end
        
        
        function mouseBtnNormal(obj, pt)
            if obj.pointEnabled
                obj.point = round(pt(1, [2 1]));
                set(obj.hMarker, 'YData', obj.point(1))
                set(obj.hMarker, 'XData', obj.point(2))
                if obj.bUpdateExternal && (~isempty(obj.hExtPlot) && isvalid(obj.hExtPlot))
                    obj.updateExternalData()
                    obj.updateExternalPoint()
                end
            end
        end
        
        
        function togglePoint(obj, src, ~)
            
            if src.Value == 0
                % button is not pressed
                obj.pointEnabled = 0;
                set(obj.hBtnPlot, 'Enable', 'off');
                set(obj.hBtnUpdateExternal, 'Enable', 'off');
                set(obj.hMarker, 'Visible', 'off');
            else
                % button is pressed
                obj.pointEnabled = 1;
                set(obj.hBtnPlot, 'Enable', 'on');
                set(obj.hBtnUpdateExternal, 'Enable', 'on');
                set(obj.hMarker, 'Visible', 'on');
            end
                
        end
        

        function toggleUpdateExternal(obj, ~, ~)

            if obj.bUpdateExternal
                % button is not pressed
                obj.bUpdateExternal = 0;
                set(obj.hBtnUpdateExternal, 'String', 'Updating: off')
            elseif ~obj.bUpdateExternal
                % button is pressed
                obj.bUpdateExternal = 1;
                set(obj.hBtnUpdateExternal, 'String', 'Updating: on')
                if ~(isempty(obj.hExtPlot) || ~isvalid(obj.hExtPlot))
                    % update external data
                    obj.updateExternalDimension()
                    obj.updateExternalData()
                    obj.updateExternalPoint()
                end
            end
        end
        
        
        function openExternalPlot(obj, ~, ~)
            
            % check if expternal plot has not been called yet, or has been
            % closed previously
            if isempty(obj.hExtPlot) || ~isvalid(obj.hExtPlot)
                % initially set the external dimension to the first slider
                % dimension
                obj.externalDim = obj.mapSliderToDim(1);
                
                % create and open plot figure
                obj.hExtPlot = nplot(obj.img{:}, ...
                    'Unit',             obj.unit, ...
                    'DimLabel',         obj.dimLabel, ....
                    'DimVal',           obj.dimVal, ....
                    'initDim',          obj.externalDim, ...
                    'ExternalCall',     1);
                obj.updateExternalDimension()
                obj.updateExternalData()
                obj.updateExternalPoint()
                
                % add listener to react, when plot expect data along a
                % different dimension
                addlistener(obj.hExtPlot, 'selChanged', @(src, eventdata) obj.externalSelChange(src, eventdata));
            else
                % move existing figure to foreground
                figure(obj.hExtPlot.fig)
            end
        end
        
        
        function externalSelChange(obj, ~, ~)
            % is called when the dimension in the external plot is changed
            % by the user
            
            % get selector value from external
            obj.sel = obj.hExtPlot.getSelector();
            
            % set new position of point
            obj.point(1) = obj.sel{obj.showDims(1)};
            obj.point(2) = obj.sel{obj.showDims(2)};
            set(obj.hMarker, 'YData', obj.point(1))
            set(obj.hMarker, 'XData', obj.point(2))
            
            % overwrite shown dimensions
            obj.sel{obj.showDims(1)} = ':';
            obj.sel{obj.showDims(2)} = ':';
            
            obj.refreshUI();
        end
        
        
        function updateExternalDimension(obj)
            obj.hExtPlot.setDimension(obj.externalDim)            
        end
        
        
        function updateExternalSelector(obj)
            obj.externalSel = obj.sel;
            obj.externalSel{obj.showDims(1, 1)} = obj.point(1);
            obj.externalSel{obj.showDims(1, 2)} = obj.point(2);
        end
        
        
        function updateExternalPoint(obj)
            obj.updateExternalSelector();
            %extSelPoint = obj.externalSel;
            
            %obj.hExtPlot.plotPoint(extSelPoint{obj.externalDim}, squeeze(obj.complexPart(obj.img{1}(extSelPoint{:}))))
            
            %obj.updateExternalIndex()
            
            obj.hExtPlot.setSelector(obj.externalSel)
        end
        
        
        function updateExternalData(obj)
            obj.updateExternalSelector();
            %obj.externalSel{obj.externalDim} = ':';            
            
            %YData = squeeze(obj.complexPart(obj.img{1}(obj.externalSel{:})));
            
            % update the external plot
            %obj.hExtPlot.plotData(YData(:));
            
            obj.hExtPlot.setSelector(obj.externalSel)
        end
        
        
        function updateExternalIndex(obj)
            
            selString = 'Index: ';
            
            for ii = 1:numel(obj.externalSel)
                selString = [selString num2str(obj.externalSel{ii}) ', '];
            end
            % remove last comma and whitespace
            selString = selString(1:end-2);
            
            obj.hExtPlot.setIndexString(selString)
             
        end
        
        
        function saveImgBtn(obj, ~, ~)
            % get the filepath from a UI and call saveImage function to save
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
            imwrite(imrotate(obj.sliceMixer(1), -obj.azimuthAng, 'bicubic'), path);
        end


        function minimMaximBtn(obj, ~, ~)

            % toggle the state
            obj.maximized = ~obj.maximized;

            % recalculate panel positions
            obj.calcPanelPos()
            obj.setPanelPos()

            obj.setMinimMaximBtnPos()

            % reclaculate content (e.g. to check inf complex buttons need
            % to be shown)
            obj.guiResize()
            obj.refreshUI()
            

        end


        function setMinimMaximBtnPos(obj)

            if obj.maximized
                set(obj.hBtnMinimMaxim, 'String', '<')
                set(obj.hBtnMinimMaxim, 'Position',...
                    [obj.controlWidth-obj.controlWidthMinimized+obj.margin ...
                    obj.margin ...
                    obj.controlWidthMinimized - 2*obj.margin ...
                    obj.height])

                % show all elements in pControl
                obj.setControlElementsVisibility()
                % set( findobj('Parent', obj.pControls, '-not', 'String', '<'), 'Visible', 1)
            else

                

                set(obj.hBtnMinimMaxim, 'String', '>')
                set(obj.hBtnMinimMaxim, 'Position',...
                    [obj.margin ...
                    obj.margin ...
                    obj.controlWidthMinimized - 2*obj.margin ...
                    obj.height])

                % hide all elements in pControl
                obj.setControlElementsVisibility()
                % set( findobj('Parent', obj.pControls, '-not', 'String', '>'), 'Visible', 0)
                
            end

        end


        function setControlElementsVisibility(obj)
            
            set(obj.hBtnCwHome,         'Visible', obj.maximized)
            set(obj.hBtnCwSlice,        'Visible', obj.maximized)
            set(obj.hBtnCwCopy,         'Visible', obj.maximized)
            set(obj.hBtnCwLink,         'Visible', obj.maximized)
            set(obj.hTextC,             'Visible', obj.maximized)
            set(obj.hTextW,             'Visible', obj.maximized)
            set(obj.hEditC,             'Visible', obj.maximized)
            set(obj.hEditW,             'Visible', obj.maximized)
            set(obj.hBtnHide,           'Visible', obj.maximized)
            set(obj.hBtnToggle,         'Visible', obj.maximized)
            set(obj.hPopCm,             'Visible', obj.maximized)
            set(obj.hPopOverlay,        'Visible', obj.maximized)
            set(obj.hBtnShiftL,         'Visible', obj.maximized)
            set(obj.hBtnRotL,           'Visible', obj.maximized)
            set(obj.hBtnRotR,           'Visible', obj.maximized)
            set(obj.hBtnShiftR,         'Visible', obj.maximized)
            set(obj.hBtnRoi,            'Visible', obj.maximized)
            set(obj.hTextRoi,           'Visible', obj.maximized)
            set(obj.hTextSNR,           'Visible', obj.maximized)
            set(obj.hTextSNRvals,       'Visible', obj.maximized)
            set(obj.hTextRoiType,       'Visible', obj.maximized)
            set(obj.hPopRoiType,        'Visible', obj.maximized)
            set(obj.hBtnDelRois,        'Visible', obj.maximized)
            set(obj.hBtnSaveRois,       'Visible', obj.maximized)
            set(obj.hBtnFFT,            'Visible', obj.maximized)
            set(obj.hBtnCmplx,          'Visible', obj.maximized*any(obj.isComplex))

            set(obj.hBtnRun,            'Visible', obj.maximized*(obj.nDims > 2))
            set(obj.hEditF,             'Visible', obj.maximized*(obj.nDims > 2))
            set(obj.hTextFPS,           'Visible', obj.maximized*(obj.nDims > 2))
            set(obj.hBtnPoint,          'Visible', obj.maximized*(obj.nDims > 2))
            set(obj.hBtnPlot,           'Visible', obj.maximized*(obj.nDims > 2))
            set(obj.hBtnUpdateExternal, 'Visible', obj.maximized*(obj.nDims > 2))

            set(obj.locAndVals,         'Visible', obj.maximized)
            set(obj.hBtnSaveImg,        'Visible', obj.maximized)
            set(obj.hBtnSaveVid,        'Visible', obj.maximized*(obj.nDims > 2))

        end

        
        function closeRqst(obj, ~, ~)
            % closeRqst is called, when the user closes the figure (by 'x' or
            % 'close'). It stops and deletes the timer and closes the figure.
            
            try
                stop(obj.t);
                delete(obj.t);
            catch
            end
            
            % close the figure
            delete(obj.f);
            % and delete the handle to the nvis object
            delete(obj)
        end
        

        function shiftCallback(obj, src, ~)
            % called by the '<-' and '->' UI buttons to trigger a dimension
            % shift
            
            % find out which button was pressed to determine the sign.
            switch (src.String)
                case char(8594)
                    sign = -1;
                case char(8592)
                    sign = 1;
            end
            
            obj.shiftDims(sign)
            
        end
        
        
        function shiftDims(obj, shifts)
            runningState = obj.t.Running;
            if strcmp(runningState, 'on')
                stop(obj.t)
            end

            % this line ignores singleton dimensions, because they dont get
            % a slider and are boring to look at
            dimArray = [obj.showDims obj.mapSliderToDim];

            % before calculating new obj.sel values, keep slider values for
            % dimensions that are mapped to a slider after the shift.
            sliderVals = cell2mat(obj.sel(obj.mapSliderToDim));

            if obj.fixedDim ~= 0
                shifted = obj.circshiftWithFixed(dimArray, shifts);
                fixedSel = obj.sel{obj.fixedDim};
            else
                shifted = circshift(dimArray, shifts);
            end
            
            % activeDim defines the active slider and cant be one
            % of the shown dimensions
            if ismember(obj.activeDim, shifted(1:2))
                if shifts > 0
                    obj.activeDim = shifted(end);
                elseif shifts < 0
                    obj.activeDim = shifted(3);
                end
            end

            obj.showDims        = shifted(1:2);
            obj.mapSliderToDim  = shifted(3:end);
         
            % remove one slider and enter value for incoming slider
            if shifts < 0
                sliderVals(1) = [];
                newVals = [sliderVals round(obj.S(obj.mapSliderToDim(end))/2)];
            else
                sliderVals(end) = [];
                newVals = [round(obj.S(obj.mapSliderToDim(1))/2) sliderVals];
            end

            % renew slice selector for dimensions 3 and higher
            obj.sel        = repmat({':'}, 1, obj.nDims);
            %obj.sel(ismember(1:obj.nDims, obj.mapSliderToDim)) = num2cell(round(obj.S(obj.mapSliderToDim)/2));
            % if possible, keep slider values
            obj.sel(obj.mapSliderToDim) = num2cell(newVals);
            % consider singleton dimensions
            obj.sel(obj.S == 1) = {1};
            % restore selection for fixed dimension
            if obj.fixedDim ~= 0
                obj.sel{obj.fixedDim} = fixedSel;
            end

            if contains('SaveImage', obj.p.UsingDefaults) && contains('SaveVideo', obj.p.UsingDefaults)
                % when no UI is created, because a video or image is saved
                % via NVP, we dont update the (non-existent) GUI.

                obj.initializeSliders()
                obj.initializeAxis(false)

                if obj.pointEnabled
                    % if point is shown, make sure its coordinates are within the limits
                    round(obj.S(obj.showDims)/2);
                    obj.point = round(obj.S(obj.showDims)/2);
                end

                if ~isempty(obj.hExtPlot) && isvalid(obj.hExtPlot) && obj.bUpdateExternal
                    % if opened, update dimensions in external plot
                    obj.externalDim = obj.mapSliderToDim(1);
                    obj.hExtPlot.setDimension(obj.mapSliderToDim(1))
                end

                obj.recolor()

            end

            if strcmp(runningState, 'on')
                start(obj.t)
            end
        end


        function out = circshiftWithFixed(obj, array, shifts)

            % find the index of the fixed dimension
            idx = find(array == obj.fixedDim);

            A = array(1:idx-1);
            B = array(idx+1:end);

            out = circshift([A, B], shifts);

            out = [out(1:idx-1) obj.fixedDim out(idx:end)];

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
                % make sure the window is wide enough
                 obj.f.Position(3) = obj.controlWidth;
            end
            
            obj.calcPanelPos()
            obj.setPanelPos()  
            
            % set Slider positions
            RadioBtnWidth = 30; % px 
            sliderWidth   = obj.pSlider.Position(3) - obj.sliderStartPos - RadioBtnWidth - 10;
            
            if sliderWidth <= 20
                obj.f.Position(3) = obj.controlWidth + obj.sliderStartPos + RadioBtnWidth + 10 + 21;
                obj.calcPanelPos()
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
            
            n = 0.75;
            if obj.nImages == 1
                position = obj.positionN(n, 2, obj.division, 0.75);
                set(obj.hBtnCwHome,  'Position', position(1, :));
                set(obj.hBtnCwSlice, 'Position', position(2, :));
            else
                position = obj.positionN(n, 7, obj.division, 0.75);
                set(obj.hBtnCwHome(1),  'Position', position(1, :));
                set(obj.hBtnCwSlice(1), 'Position', position(2, :));
                set(obj.hBtnCwCopy(1),  'Position', position(3, :));
                set(obj.hBtnCwLink,  'Position', position(4, :));
                set(obj.hBtnCwCopy(2),  'Position', position(5, :));
                set(obj.hBtnCwSlice(2), 'Position', position(6, :));
                set(obj.hBtnCwHome(2),  'Position', position(7, :));
                
            end
            
            n = n + 1;
            position = obj.divPosition(n, obj.nImages);
            set(obj.hTextC, 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hEditC(ii), 'Position', position(ii+1, :));
            end
            
            n = n + 1;
            position = obj.divPosition(n, obj.nImages);
            set(obj.hTextW, 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hEditW(ii), 'Position', position(ii+1, :));
            end
            
            if obj.nImages == 2
                n = n + 1;
                position = obj.divPosition(n, obj.nImages);
                set(obj.hBtnToggle,   'Position', position(1, :));
                set(obj.hBtnHide(1),  'Position', position(2, :));
                set(obj.hBtnHide(2),  'Position', position(3, :));
            end
            
            n = n + 1;
            if obj.nImages == 1
                position = obj.positionN(n, 1);
                set(obj.hPopCm(1), 'Position', position(1, :));
            else
                position = obj.divPosition(n, 2);
                set(obj.hPopOverlay,  'Position', position(1, :));
                set(obj.hPopCm(1),    'Position', position(2, :));
                set(obj.hPopCm(2),    'Position', position(3, :));
            end
            n = n + 1;
            position = obj.divPosition(n, obj.nImages);
            set(obj.hBtnRoi(1), 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hTextRoi(1, ii), 'Position', position(ii+1, :));
            end
            
            n = n + 1;
            position = obj.divPosition(n, obj.nImages);
            set(obj.hBtnRoi(2), 'Position', position(1, :));
            for ii = 1:obj.nImages
                set(obj.hTextRoi(2, ii), 'Position', position(ii+1, :));
            end
            
            n = n + 1;
            position = obj.divPosition(n, obj.nImages);
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
                n = n + 1.5;
                position = obj.positionN(n, 3);                
                set(obj.hBtnPoint,          'Position', position(1, :))
                set(obj.hBtnPlot,           'Position', position(2, :))
                set(obj.hBtnUpdateExternal, 'Position', position(3, :))
            end
        end
            
        
        function pos = divPosition(obj, h, n, hF)
            % one element before a 'division, one or two elements after the
            % division (depending on number of images)
            % h: heigth value
            % n: number of equally spaced horitonzal elements
            % hF: multiplier of the height of the elements.
            
            if nargin == 3
                % set the height changing factor to 1
                hF = 1;
            end
            
            yPos = ceil(obj.figurePos(4)-obj.margin-h*obj.height-(h-1)*obj.yPadding);
            
            pos = [obj.margin/2 yPos obj.division-3/4*obj.margin obj.height*hF];
            pos = [pos; obj.positionN(h, n, obj.division, hF)];
        end
        
          
        function pos = positionN(obj, h, n, x0, hF)
            % euqally space elements in the GUI in a row
            % h: heigth value
            % n: number of equally spaced horitonzal elements
            % x0: startpoint from left side (default: 0)
            % hF: multiplier of the height of the elements.
            
            if nargin == 3
                x0 = 0;
                hF = 1;                
            elseif nargin == 4
                hF = 1;                
            end
            
            yPos  = ceil(obj.figurePos(4)-obj.margin-h*obj.height-(h-1)*obj.yPadding);
            width =(obj.controlWidth-x0-(n+1)*obj.margin)/n;
            
            pos   = repmat([0 yPos width obj.height*hF], [n, 1]);
            xPos  = x0 + (0:(n-1)) * (width+ obj.margin) + obj.margin;
            
            pos(:, 1) = xPos;
        end
    end
end