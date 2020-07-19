classdef (Abstract) Draw < handle
    %Draw Baseclass for Draw. GUIs
    %   This class serves as a base class for the 'Draw...' classes,
    % 	which are optimized for visualizing multidimensional (complex)
    % 	matrices. Draw.m provides the building block for the GUI which are
    % 	placed in the figure by the inheriting classes.
    %
    %   Many of the UI features (windowing, colormap overlay,...) are
    %   handled by Draw member functions. 
   
    properties
        f
    end
		
    properties (Access = private)
        % DISPLAY PROPERTIES
        layerShown      % which of the images is currently shown?
        fftStatus       % keeps track of fft-button status
        
        
        % WINDOWING PROPERTIES
        Max             % maximum value in both images
        Min             % minimum value in both images
        center          % current value mapped to the center of the colormap
        width           % width of values mapped to the colormap, around center
        widthMin        % minimalWidth of the colormap, prevents division by 0
        centerStep      % how much 'center' changes when windowing
        widthStep       % how much 'width' changes when windowing
        nrmFac          % normalization factor for windowing process
        
        
    end
    
    properties (Access = protected)
        %% INPUT PROPERTIES
        
        nImages         % number of images (1 or 2)
        nAxes           % number of displayed image Axes (DrawSingle: 1, DrawSlider: 3)
        img             % cell array in which the input matrices are stored
        nDims           % number of image dimensions
        ston            % cell array for dimensions where a matrix is the only singleton
        isComplex       % is one of the inputs complex
        S               % size of the image(s)
        p               % input parser
        standardTitle   % name of the figure, default depends on inputnames
        varargin        % member variable varargin
                
        %% DISPLAYING
        
        % link sliders to image dimensions
        % mapSliderToDim(2) = 4 means, that slider 2 controls the slice along the
        % 4th dimension.
        mapSliderToDim
        
        % link sliders to images
        % mapSliderToImage{2} = 1   means, that slider 2 changes values in
        % obj.sel{1, :}.
        % mapSliderToImage{2} = ':' means, that slider 2 changes the
        % selector for all shown images
        mapSliderToImage
        
        % showDims(1, :) = [3 4] means, that in axis 1, the first
        % dimensions shows the input data along its third dimension, the
        % second axis shows the input data along its fourth dimension.
        showDims
        
        % cell array that stores the location information in the input data
        % of each currently shown slice.
        % obj.sel{2, :} contains the subscripts to obtain the image shown
        % in axis 2
        sel
        
        % cell array containing the current slice image information
        slice
                
        % index of the currently active dimension for slider scrolling
        % etc...
        activeDim
        
        % index of the currently active ax element
        activeAx
        
        % timer
        t
        % index of the slider that is inc- or decremented by the timer
        % interrupt
        interruptedSlider
        % framerate of timer
        fps
        
        % stores the current complex representation mode
        complexMode
        
        % resize factor for the displayed data
        resize
        
        % used to rotate the view on the axes when necessary
        azimuthAng
        
        % coordinates of the current point under the cursor (third element
        % is the axis, pt is empty when curser not over any axis)
        pt
        
        % contains the information, which contrast is currently chosen
        contrast
        
        % Foregroud color for text, similar in hue to the colormap of the
        % associated image
        COLOR_m
        
        % colormap for all images as a cell array, containing Nx3 colormaps
        cmap
        
        % overlay mode (1: add, 2: multiply)
        overlay
        
        % label for each dimension
        dimLabel
        
        % values for each dimension
        dimVal
        
        %% GUI ELEMENTS
        
        % array of images displayed in 'ax', the handle to the respective axis can always be obtained via
		% get(obj.hImage(...), 'Parent')
        hImage
               
        % array of slider handles to navigate through the slices
        hSlider
        hTextSlider
        hEditSlider
        
        % cw-windowing element arrays
        hTextC
        hTextW
        hEditC
        hEditW        
        hBtnHide
        hBtnToggle
        hBtnCwCopy
        hBtnCwHome
        hBtnCwSlice
        hBtnCwLink
        
        % select the colormap for each input image
        hPopCm
        
        % select the overlay mode
        hPopOverlay
        
        % buttons array for complex data display
        hBtnCmplx
        
        % FFT button
        hBtnFFT
        
        % Roi
        hBtnRoi
        hTextRoi
        hTextSNR
        hTextSNRvals
        hTextRoiType
        hPopRoiType
        hBtnDelRois
        hBtnSaveRois
        hLocAndVals
        
        % colorbars
        hAxCb        
        
        % animation elements
        hBtnRun
        hEditF
        hTextFPS
        
        % saving images and videos
        hBtnSaveImg
        hBtnSaveVid
        
        %% GUI ELEMENT PROPERTIES
        
        % number of sliders in the UI
        nSlider
        inputNames
        valNames
        
        % units of the input data
        unit
        
        % array with ROIs
        rois
        
        % mean in the signal rois
        signal
        
        % std-deviation in the noie rois
        noise
        
        % do we see the colorbars?
        cbShown
        
        % how are the colorbars oriented ('horizontal' or 'vertical')
        cbDirection
        
        % max number of letters for variable names in the locVal section
        maxLetters
        
        % colormaps available
        availableCmaps
        cmapStrings
    end
    
    
    properties (Constant = true, Hidden = true)
        % color scheme of the GUI
        COLOR_BG  = [0.2 0.2 0.2];
        COLOR_B   = [0.1 0.1 0.1];
        COLOR_F   = [0.9 0.9 0.9];
        COLOR_roi = [1.0 0.0 0.0;
                     0.0 0.0 1.0];
        contrastList = {'green-magenta', 'PET', 'heat'};
        zoomInFac  = 1.1;
        zoomOutFac = 0.9;
        
        BtnHideKey = ['w' 'e'];
        BtnTgglKey = 'q';
        
        overlayStrings = {'add', 'multiply'}
    end    
    
    
    %% abstract methods    
    methods (Abstract)
        locVal(obj, axNo)
        refreshUI(obj)
        incDecActiveDim(obj, incDec)
        mouseButtonAlt(src, evtData)
        recolor(obj)
        saveImgBtn(obj)
    end
        
    
    methods
        function obj = Draw(in, varargin)
            % CONSTRUCTOR
            obj.varargin = varargin;
            
            % check varargin for a sencond input matrix
            obj.inputCheck(in)
            
            % The slider for which dimension is initially active?
            obj.activeDim   = 1;
            
            % necessary for view orientation, already needed when saving image or video
            obj.azimuthAng  = 0;
            
            % set the default value for max Number of letters is locVal
            % section
            obj.maxLetters = 6;
            
            % prepare roi parameters
            obj.rois         = {[], []};
            obj.signal       = NaN(1, obj.nImages);
            obj.noise        = NaN(1, obj.nImages);
            
            % initialize UI colors
            obj.COLOR_m = [obj.COLOR_F; obj.COLOR_F];
            
            % set the correct default value for complexMode
            if any(obj.isComplex)
                obj.complexMode = 1;
            else
                % if neither input is complex, display the real part of the
                % data
                obj.complexMode = 3;
            end
            
            % find min and max values in the input data
            obj.findMinMax()
            
            % prepare the input parser
            obj.prepareParser()
            
            % prepare the colormaps
            obj.prepareColormaps()
            
        end
        
        
        function delete(obj)
            delete(obj)
        end
        
        
        function findMinMax(obj)
            % Calculates the minimal and maximal value in the upto two
            % input matrices. If there are +-Inf values in the data, a
            % slower, less memory efficient calculation is performed.
            
            % min and max values are cast as doubles, to have their
            % datatype be independet of the input datatype
            if sum(version('-release') < '2018b')
                % version is older than 2018b, use slower, but not very
                % slow max/min calculation implementation.
                obj.Max = [double(obj.cleverMax(obj.img{1})), double(obj.cleverMax(obj.img{2}))];
                obj.Min = [double(obj.cleverMin(obj.img{1})), double(obj.cleverMin(obj.img{2}))];
            else
                obj.Max = [double(max(obj.img{1}, [], 'all', 'omitnan')), double(max(obj.img{2}, [], 'all', 'omitnan'))];
                obj.Min = [double(min(obj.img{1}, [], 'all', 'omitnan')), double(min(obj.img{2}, [], 'all', 'omitnan'))];
            end
            
            hasInf = obj.Max == Inf;
            if hasInf(1)
                warning('+Inf values present in input 1. For large input matrices this can cause memory overflow and long startup time.')
                obj.Max(1)           = max(obj.img{1}(~isinf(obj.img{1})), [], 'omitnan');
            elseif obj.nImages == 2 && hasInf(2)
                warning('-Inf values present in input 2. For large input matrices this can cause memory overflow and long startup time.')
                obj.Max(2)           = max(obj.img{2}(~isinf(obj.img{2})), [], 'omitnan');
            end
            
            hasInf = obj.Min == -Inf;
            if hasInf(1)
                warning('+Inf values present in input 1. For large input matrices this can cause memory overflow and long startup time.')
                obj.Min(1)           = [min(obj.img{1}(~isinf(obj.img{1})), [], 'omitnan'), 0];
            elseif obj.nImages == 2 && hasInf(2)
                warning('-Inf values present in input 2. For large input matrices this can cause memory overflow and long startup time.')
                obj.Min(2)           = [min(obj.img{2}(~isinf(obj.img{2})), [], 'omitnan'), 0];
            end
            
            if obj.nImages == 1
                obj.Min(2) = 0;
                obj.Max(2) = 1;
            end
            
            obj.Max(obj.isComplex) = abs(obj.Max(obj.isComplex));
            obj.Min(obj.isComplex) = abs(obj.Min(obj.isComplex));
        end
        
        
        function inputCheck(obj, in)
            
            if ~isempty(obj.varargin) && ( isnumeric(obj.varargin{1}) || islogical(obj.varargin{1}) )
                % two input matrices
                obj.img{1}      = in;
                % get second matrix from varargin
                obj.img{2}      = obj.varargin{1};
                % remove second matrix from varargin, should only contain
                % NVPs now
                obj.varargin(1) = [];
                isEmpt          = cellfun(@isempty, obj.img);
                if ~sum( isEmpt )
                    % neither is empty
                    obj.nImages     = 2;
                    obj.isComplex   = ~cellfun(@isreal, obj.img);
                    obj.layerShown  = [1, 1];
                    obj.checkSize()
                elseif sum(isEmpt) == 1
                    % one input matrix is empty
                    warning('Input %d is empty! Only non-empty iputs are shown', find(isEmpt))
                    obj.nImages     = 1;
                    obj.isComplex   = ~cellfun(@isreal, obj.img);
                    obj.img(isEmpt) = [];
                    % for nImages=1, the second cell must be explicitly
                    % empty
                    obj.img{2} = [];
                    obj.S = size(obj.img{1});
                    obj.ston{1} = [];
                else
                    error('Both input matrices are empty')                    
                end
            else
                % one input matrix
                obj.img{1}       = in;
                obj.img{2}       = [];
                obj.nImages      = 1;                
                obj.isComplex    = ~isreal(obj.img{1});
                obj.S = size(obj.img{1});
                obj.ston{1} = [];
            end            
            obj.nDims = numel(obj.S);
        end
        
        
        function checkSize(obj)
            
            % get the image sizes
            s1 = size(obj.img{1});
            s2 = size(obj.img{2});
            if numel(s1) ~= numel(s2)
                % and image dimensions (trailing singleton dimensions are not
                % considered by size)
                d1 = ndims(obj.img{1});
                d2 = ndims(obj.img{2});
                if d1 > d2
                    s2 = [s2 ones(1, d1-d2)];
                else
                    s1 = [s1 ones(1, d2-d1)];
                end
            end
            
            if any(s1 ~= s2)
                % there are dimensions, in wich both matrices have different
                % sizes
                
                % combine the sizes into one array
                s = [s1; s2];
                
                % check that for those dimensions, where the size differs,
                % one is equal to 1
                if any(min(s(:, s1~=s2),[], 1) ~= 1)
                    % there are dimensions where the size differs and
                    % neither of the matrices has a size of one along that
                    % dimension
                    error('Matrix dimensions must agree.')
                else
                    % find unique singleton dimensions in matrices
                    obj.ston{1} = find((s1 ~= s2) & s1 == 1);
                    obj.ston{2} = find((s1 ~= s2) & s2 == 1);
                end
                
                obj.S = max(s, [], 1);
            else
                % both input matrices have exactly the same size
                obj.ston{1} = [];
                obj.ston{2} = [];
                obj.S = size(obj.img{1});
            end
        end
        
        
        function prepareParser(obj)
            
            % default figure position and size. is adapted to actual screensize
            % and is separated from top/bottom by 10% of up/down screensize
            screenS = get(0, 'ScreenSize');
            defaultPosition = [ 300, round(0.1*screenS(4)), 800, round(0.8*screenS(4))];

            obj.p = inputParser;
            isboolean = @(x) x == 1 || x == 0;
            % add parameters to the input parser
            addParameter(obj.p, 'Position',     defaultPosition,                @(x) isnumeric(x) && numel(x) == 4);
            addParameter(obj.p, 'Overlay',      1,                              @(x) floor(x)==x && x >= 1); %is integer greater 1
            addParameter(obj.p, 'Colormap',     gray(256),                      @(x) iscell(x) | isnumeric(x) | ischar(x));
            addParameter(obj.p, 'Contrast',     'green-magenta',                @(x) obj.isContrast(x));
            addParameter(obj.p, 'ComplexMode',  obj.complexMode,                @(x) isnumeric(x) && x <= 4);
            addParameter(obj.p, 'AspectRatio',  'square',                       @(x) any(strcmp({'image', 'square'}, x)));
            addParameter(obj.p, 'Resize',       1,                              @isnumeric);
            addParameter(obj.p, 'Title',        obj.standardTitle,              @ischar);
            addParameter(obj.p, 'CW',           [(obj.Max(1) - obj.Min(1))/2+obj.Min(1), ...
                                                obj.Max(1)-obj.Min(1); ...
                                                (obj.Max(2) - obj.Min(2))/2+obj.Min(2), ...
                                                obj.Max(2)-obj.Min(2)],         @isnumeric);            
            addParameter(obj.p, 'widthMin',     single(0.001*(obj.Max-obj.Min)),@isnumeric);
            addParameter(obj.p, 'Unit',         {[], []},                       @(x) (iscell(x) && numel(x) <= 2) | ischar(x));
            addParameter(obj.p, 'DimLabel',     strcat(repmat({}, 1, numel(obj.S))), @(x) iscell(x) && numel(x) == obj.nDims);
            addParameter(obj.p, 'DimVal',       cellfun(@(x) 1:x, num2cell(obj.S), 'UniformOutput', false), @iscell);
            addParameter(obj.p, 'SaveImage',    '',                                 @ischar);
            addParameter(obj.p, 'SaveVideo',    '',                                 @ischar);
            addParameter(obj.p, 'fps',          0,                              @isnumeric);
            addParameter(obj.p, 'LoopCount',    Inf,                            @isnumeric);

        end
        
        
        function prepareColors(obj)            
            % Depending on the amount of input matrices and the provided
            % colormaps or contrast information, the colorscheme for the UI
            % is set and 'center', 'width', and 'widthMin' are given proper
            % initial values.
            %
            % Called by constructor of inheriting class
            %
            
            % set the string values for the colormaps in the popdown menus.
            
            
            % from the inputParser, get the initial colormaps
            if ~contains('Colormap', obj.p.UsingDefaults)
                % Colormap was used as NVP, this overrules any input from
                % the 'Contrast' NVP     
                obj.setInitialColormap(obj.p.Results.Colormap)
            elseif obj.nImages == 2
                % get initial Contrast for the display from InputParser values
                obj.setInitialContrast()
            end
            
            set(obj.hPopCm(1), 'String', obj.cmapStrings)
            if obj.nImages == 2
                set(obj.hPopCm(2), 'String', obj.cmapStrings)
            end
        
            obj.widthMin = obj.p.Results.widthMin;
            for idh = 1:obj.nImages
                obj.center(idh)	= double(obj.p.Results.CW(idh, 1));
                obj.width(idh)  = double(obj.p.Results.CW(idh, 2));
                set(obj.hEditC(idh), 'String', num2sci(obj.center(idh), 'padding', 'right'));
                set(obj.hEditW(idh), 'String', num2sci(obj.width(idh),  'padding', 'right'));
                % apply the initial colormaps to the popdown menus
                obj.setCmap(obj.hPopCm(idh))
            end
            obj.centerStep  = double(obj.center);
            obj.widthStep   = double(obj.width);
        end
        
        
        function prepareGUIElements(obj)
            
            % create figure handle, but hide figure
            obj.f = figure('Color', obj.COLOR_BG, ...
                'Visible',              'off', ...
                'WindowKeyPress',       @obj.keyPress);
            
            % create UI elements for center and width
            obj.hTextC = uicontrol( ...
                'Style',                'text', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hTextW = uicontrol( ...
                'Style',                'text', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            for idh = 1:obj.nImages
                obj.hEditC(idh) = uicontrol( ...
                    'Style',                'edit', ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'Enable',               'Inactive', ...
                    'ButtonDownFcn',        @obj.removeListener, ...
                    'Callback',             @obj.setCW, ...
                    'TooltipString',        'center value for applied colormap');
                
                obj.hEditW(idh) = uicontrol( ...
                    'Style',                'edit', ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'Enable',               'Inactive', ...
                    'ButtonDownFcn',        @obj.removeListener, ...
                    'Callback',             @obj.setCW, ...
                    'TooltipString',        'width value for applied colormap');
                
                if obj.nImages == 2
                    obj.hBtnHide(idh) = uicontrol( ...
                        'Style',                'togglebutton', ...
                        'BackgroundColor',      obj.COLOR_BG, ...
                        'Callback',             {@obj.BtnHideCallback});
                    
                    num = {'second', 'first'};
                    obj.hBtnCwCopy(idh) = uicontrol( ...
                        'Style',                'pushbutton', ...
                        'BackgroundColor',      obj.COLOR_BG, ...
                        'ForegroundColor',      obj.COLOR_F, ...
                        'TooltipString',        ['copy CW values to '   num{idh} ' second image']);
                end
            end
            
            if obj.nImages == 2
                obj.hBtnToggle = uicontrol( ...
                    'Style',                'pushbutton', ...
                    'String',               ['Toggle (' obj.BtnTgglKey ')'], ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F, ...
                    'Callback',             {@obj.BtnToggleCallback});
            end
                        
            obj.hPopCm(1) = uicontrol( ...
                'Style',                'popup', ...
                'String',               {''}, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F, ...
                'Callback',             {@obj.changeCmap});
            
            if obj.nImages == 2
                obj.hPopOverlay = uicontrol( ...
                    'Style',                'popup', ...
                    'String',               obj.overlayStrings, ...
                    'Value',                obj.overlay, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F, ...
                    'Callback',             {@obj.changeOverlay});
                
                obj.hPopCm(2) = uicontrol( ...
                    'Style',                'popup', ...
                    'String',               {''}, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F, ...
                    'Callback',             {@obj.changeCmap});
            end
            
            %--
            % regions of interest
            %--
            
            % uicontrols must be initialized alone, cannot be done without
            % loop (i guess...)
            for iHdl = 1:2
                obj.hBtnRoi(iHdl) = uicontrol( ...
                    'Style',                'pushbutton', ...
                    'Callback',             {@obj.drawRoi}, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
                for jHdl = 1:obj.nImages
                    obj.hTextRoi(iHdl, jHdl) = uicontrol( ...
                        'Style',                'text', ...
                        'BackgroundColor',      obj.COLOR_BG, ...
                        'ForegroundColor',      obj.COLOR_F);
                end
            end
            
            for iHdl = 1:obj.nImages
                obj.hTextSNRvals(iHdl) = uicontrol( ...
                    'Style',                'text', ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
            end
            
            obj.hTextSNR = uicontrol( ...
                'Style',                'text', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hTextRoiType = uicontrol( ...
                'Style',                'text', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hPopRoiType = uicontrol( ...
                'Style',                'popup', ...
                'String',               {'Polygon', 'Ellipse', 'Freehand'}, ...
                'Value',                1, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnDelRois = uicontrol( ...
                'Style',                'pushbutton', ...
                'Callback',             {@obj.delRois}, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnSaveRois = uicontrol( ...
                'Style',                'pushbutton', ...
                'Callback',             {@obj.saveRois}, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);            
            
            %--
            % FFT and complex mode display
            %--
            obj.hBtnFFT = uicontrol( ...
                'Style',                'pushbutton', ...
                'String',               'FFT', ...
                'Callback',             {@obj.setFFTStatus}, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnCmplx(1) = uicontrol( ...
                'Style',                'togglebutton', ...
                'String',               'abs', ...
                'Callback',             {@obj.toggleComplex},...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnCmplx(2) = uicontrol( ...
                'Style',                'togglebutton', ...
                'String',               'phase', ...
                'Callback',             {@obj.toggleComplex},...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnCmplx(3) = uicontrol( ...
                'Style',                'togglebutton', ...
                'String',               'real', ...
                'Callback',             {@obj.toggleComplex},...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnCmplx(4) = uicontrol( ...
                'Style',                'togglebutton', ...
                'String',               'imag', ...
                'Callback',             {@obj.toggleComplex},...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            %--
            % animation
            %--
            if obj.nDims > 2
                obj.hBtnRun = uicontrol( ...
                    'Style',                'pushbutton', ...
                    'Units',                'pixel', ...
                    'String',               'Run', ...
                    'Callback',             { @obj.toggleTimer}, ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
                
                obj.hEditF = uicontrol( ...
                    'Style',                'edit', ...
                    'Units',                'pixel', ...
                    'String',               sprintf('%.2f', obj.fps), ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F, ...
                    'Enable',               'Inactive', ...
                    'Tooltip',              'timer precision is 1 ms', ...
                    'ButtonDownFcn',        @obj.removeListener, ...
                    'Callback',             @obj.setFPS);
                
                obj.hTextFPS = uicontrol( ...
                    'Style',                'text', ...
                    'Units',                'pixel', ...
                    'String',               sprintf('fps'), ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F);
            end
            %--
            % saving
            %--
            obj.hBtnSaveImg = uicontrol( ...
                'Style',                'pushbutton', ...
                'String',               'Save Image', ...
                'Callback',             {@obj.saveImgBtn}, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnSaveVid = uicontrol( ...
                'Style',                'pushbutton', ...
                'String',               'Save Video', ...
                'Callback',             {@obj.saveVidBtn}, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.t = timer(...
                'BusyMode',         'queue', ...
                'ExecutionMode',    'fixedRate', ...
                'Period',           1, ...
                'StartDelay',       0, ...
                'TimerFcn',         @(t, event) obj.interrupt, ...
                'TasksToExecute',   Inf);
            
        end
        
        
        function parseDimLabelsVals(obj)
            % dimension labels
            
            
            
            if ~contains('DimLabel', obj.p.UsingDefaults)
                % check number of input labels equals dimensions of image
                if numel(obj.p.Results.DimLabel) ~= obj.nDims
                    error('Number of DimLabel must equal the number of image dimensions.')
                end
               % if cell entry is empty, use default value
               emptyCell = cellfun(@isempty, obj.p.Results.DimLabel);
               obj.dimLabel(~emptyCell) = obj.p.Results.DimLabel(~emptyCell);
            end
            
            % dimension values
            
            % set default values via size of each dimension
            obj.dimVal = cellfun(@(x) 1:x, num2cell(obj.S), 'UniformOutput', false);
            
            if ~contains('DimVal', obj.p.UsingDefaults)
                % check number of value arrays equals dimensions of image
                if numel(obj.p.Results.DimVal) ~= obj.nDims
                    error('Number of elements in DimVal must equal the number of image dimensions.')
                end
                % if cell entry is empty, use default value
                emptyCell = cellfun(@isempty, obj.p.Results.DimVal);
                obj.dimVal(~emptyCell) = obj.p.Results.DimVal(~emptyCell);
                
                % value array for each dimension must have obj.S entries
                if ~isequal(obj.S, cellfun(@numel, obj.dimVal))
                    error('Number of elements in DimVal for dimension(s) %s do not match image size', mat2str(find(obj.S ~= cellfun(@numel, obj.dimVal))))
                end
            end
            
            obj.dimVal = valsToString(obj.dimVal);
        end
        
        
        function prepareSliceData(obj)
            % obtain image information form
            for iImg = 1:obj.nImages
                for iax = 1:obj.nAxes
                    % get the image information of the current slice(s)
                    % from the input matrices
                    
                    % for dimensions where one matrix is singleton, the
                    % selector-value must be adjusted to 1
                    select = obj.sel(iax, :);
                    select(obj.ston{iImg}) = {1};
                    
                    if ~isempty(obj.ston{iImg})
                        % this matrix has singleton dimensions where the
                        % other does not
                        
                        % is the matrix singleton along a shown dimension?
                        isect = intersect(obj.showDims(iax, :), obj.ston{iImg});
                        % if the matrix is singleton along one of the shown
                        % image dimensions, use repmat
                        repDims = ones(1, obj.nDims);
                        repDims(isect) = obj.S(isect);
                    else
                        % no unique singleton dimensions, no repetition
                        % necessary
                        repDims = ones(1, obj.nDims);
                    end
                    
                    % use permute instead of squeeze, because squeeze
                    % reduces a matrix of  size 1, 1, 100 to 100, 1
                    % instead of 1, 100
                    permDims = 1:obj.nDims;
                    permDims(obj.showDims(iax, :)) = [];
                    permDims = [obj.showDims(iax, :) permDims];
                    
                    % repeat along singleton if necessary, then permute to
                    % get orientation right
                    obj.slice{iax, iImg} = permute(repmat(obj.img{iImg}(select{:}), repDims), permDims);
                    
                    if obj.fftStatus == 1
                        % if chosen by the user, perform a 2D fft on the
                        % Data
                        obj.slice{iax, iImg} = fftshift(fftn(fftshift(obj.slice{iax, iImg})));
                    end
                end
            end
            
            if any(~cellfun(@isreal, obj.slice(:)))
                % at least one of the slices has complex values, that
                % means:
                % show the complex Buttons
                set(obj.hBtnCmplx, 'Visible', 'on');
                % convert the displayed data to the complex mode chosen by
                % the user and then to datatype single
                obj.slice = cellfun(@single, ...
                    cellfun(@obj.complexPart, obj.slice, 'UniformOutput', false), ...
                    'UniformOutput', false);
            else
                % none of the slices has complex data
                % when hBtnCmplx are hidden, complexMode must be 3
                obj.complexMode = 3;
                set(obj.hBtnCmplx, 'Visible', 'off');
                % convert the displayed data to datatype single
                obj.slice = cellfun(@single, obj.slice, 'UniformOutput', false);
            end
            
            % Why is this here? Just curious. But somebody might want to
            % add some comment here (@Johannes?)
            obj.calcROI
        end
        
        
        function cImage = sliceMixer(obj, axNo)
            % calculates an RGB image depending on the windowing values,
            % the used colormaps and the current slice position. when the
            % slice position was changed, obj.prepareSliceData should be
            % run before calling the slice mixer.
            % axNo defines the axis for which the image is prepared.
            if nargin == 1
                axNo = 1;
            end
            
            if obj.nImages == 1
                lowerl  = single(obj.center(1) - obj.width(1)/2);
                imshift = (obj.slice{axNo, 1} - lowerl)/single(obj.width(1)) * size(obj.cmap{1}, 1);
                if obj.resize ~= 1
                    imshift = imresize(imshift, obj.resize);
                end
                cImage = ind2rgb(round(imshift), obj.cmap{1});
            else
                switch (obj.overlay)
                        % for assignment of overlay modes, see
                        % obj.overlayStrings
                        case 1 % add
                            cImage  = zeros([size(obj.slice{axNo, 1} ), 3]);
                        case 2 % multiply
                            cImage  = ones([size(obj.slice{axNo, 1} ), 3]);
                end
                for idd = 1:obj.nImages
                    % convert images to range [0, cmapResolution]
                    lowerl  = single(obj.center(idd) - obj.width(idd)/2);
                    imshift = (obj.slice{axNo, idd} - lowerl)/single(obj.width(idd)) * size(obj.cmap{idd}, 1);
                    if obj.resize ~= 1
                        imshift = imresize(imshift, obj.resize);
                    end
                    imgRGB  = ind2rgb(round(imshift), obj.cmap{idd}) * obj.layerShown(idd);
                    imgRGB(repmat(isnan(obj.slice{axNo, idd}), [1 1 3])) = 0;
                    switch (obj.overlay)
                        % for assignment of overlay modes, see
                        % obj.overlayStrings
                        case 1 % add
                            cImage  = cImage + imgRGB;
                        case 2 % multiply
                            cImage  = cImage .* imgRGB;
                    end
                end
                cImage(isnan(obj.slice{axNo, 1}) & isnan(obj.slice{axNo, 2})) = NaN;
            end
            
            % make sure no channel has values above 1
            cImage(cImage > 1) = 1;
        end
        
        
        function out = complexPart(obj, in)
            % complexPart(obj, in)
            % in:           array with (potentially) complex data
            % complexMode:  int defining the complex part of out
            %               1: Magnitude
            %               2: Phase
            %               3: real part
            %               4: imaginary part
            %
            % out:    magnitude, phase, real or imaginary part of in
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
            %
            % complexMode:
            % 1:    magnitude
            % 2:    phase
            % 3:    real
            % 4:    imag
            
            % set all buttons unpreessed
            set(obj.hBtnCmplx, 'Value', 0)
            btnIdx = find(source == obj.hBtnCmplx);
            
            if obj.complexMode == 2
                % restore CW values
                obj.width  = obj.Max  - obj.Min;
                obj.center = obj.width/2 + obj.Min;
            elseif btnIdx == 2
                obj.center = [0 0];
                obj.width  = 2*pi*[1 1];
            end
            
            obj.complexMode = btnIdx;
            set(obj.hBtnCmplx(btnIdx), 'Value', 1)
            
            obj.cw()
            obj.refreshUI()
        end
        
        
        function startDragFcn(obj, src, evtData)
            % when middle mouse button is pressed, save current point and start
            % tracking of mouse movements
            callingAx = src.Parent;
            Pt = get(callingAx, 'CurrentPoint');
            imgIdx = find(obj.hImage == src);
            if obj.nAxes > 1
                obj.activateAx(imgIdx)
            end
            % normalization factor
            obj.nrmFac = [obj.S(find(obj.showDims(imgIdx, :), 1, 'first')) obj.S(find(obj.showDims(imgIdx, :), 1, 'last'))]*obj.resize;
            switch get(gcbf, 'SelectionType')
                case 'normal'
                    if ~isempty(obj.img{2}) && obj.layerShown(2)
                        sCenter = obj.center;
                        sWidth  = obj.width;
                        cStep   = [0, obj.centerStep(2)];
                        wStep   = [0, obj.widthStep(2)];
                        obj.f.WindowButtonMotionFcn = {@obj.draggingFcn, callingAx, Pt, sCenter, sWidth, cStep, wStep};
                    end
                case 'extend'
                    if isempty(obj.img{2}) || (~isempty(obj.img{2}) && obj.layerShown(1))
                        sCenter = obj.center;
                        sWidth  = obj.width;
                        cStep   = [obj.centerStep(1), 0];
                        wStep   = [obj.widthStep(1), 0];
                        obj.f.WindowButtonMotionFcn = {@obj.draggingFcn, callingAx, Pt, sCenter, sWidth, cStep, wStep};
                    end
                case 'alt'
                    obj.mouseButtonAlt(src, evtData)
            end
        end
        
        
        function draggingFcn(obj, ~, ~, callingAx, StartPt, sCenter, sWidth, cStep, wStep)
            % track motion of mouse and change center and width variables
            % accordingly
            pt = get(callingAx, 'CurrentPoint');
            switch (obj.azimuthAng)
                case 0
                    obj.center = sCenter - cStep * (pt(1, 2)-StartPt(1, 2))/obj.nrmFac(1);
                    obj.width  = sWidth  + wStep * (pt(1, 1)-StartPt(1, 1))/obj.nrmFac(2);
                case 90
                    obj.center = sCenter - cStep * (pt(1, 1)-StartPt(1, 2))/obj.nrmFac(2);
                    obj.width  = sWidth  - wStep * (pt(1, 2)-StartPt(1, 1))/obj.nrmFac(1);
                case 180
                    obj.center = sCenter + cStep * (pt(1, 2)-StartPt(1, 2))/obj.nrmFac(1);
                    obj.width  = sWidth  - wStep * (pt(1, 1)-StartPt(1, 1))/obj.nrmFac(2);
                case 270
                    obj.center = sCenter + cStep * (pt(1, 1)-StartPt(1, 2))/obj.nrmFac(2);
                    obj.width  = sWidth  + wStep * (pt(1, 2)-StartPt(1, 1))/obj.nrmFac(1);
            end
            obj.cw()
        end
        
        
        function cw(obj)
            % adjust windowing values depending on values for center and width
            obj.width(obj.width <= obj.widthMin) = obj.widthMin(obj.width <= obj.widthMin);
            
            for ida = 1:numel(obj.hImage)
                set(obj.hImage(ida), 'CData', obj.sliceMixer(ida));
            end
            
            for idi = 1:obj.nImages
                set(obj.hEditC(idi), 'String', num2sci(obj.center(idi), 'padding', 'right'));
                set(obj.hEditW(idi), 'String', num2sci(obj.width(idi) , 'padding', 'right'));
            end
            
            if obj.cbShown
                % only recalculate the tickvalues when colorbars are
                % acutally visible
                
                % depending on the direction of the colorbar, elementy of
                % the x or y axis must be changed
                if strcmp(obj.cbDirection, 'horizontal')
                    Data = 'XData';
                    Lim = 'XLim';
                    Tick = 'XTick';
                    TickLabel = 'XTickLabel';
                else
                    Data = 'YData';
                    Lim = 'YLim';
                    Tick = 'YTick';
                    TickLabel = 'YTickLabel';
                end
                
                for idi = 1:obj.nImages                    
                    set(allchild(obj.hAxCb(idi)), ...
                        Data,    linspace(obj.center(idi)-obj.width(idi)/2, obj.center(idi)+obj.width(idi)/2, size(obj.cmap{idi}, 1)))
                    set(obj.hAxCb(idi), ...
                        Lim,     [obj.center(idi)-obj.width(idi)/2, obj.center(idi)+obj.width(idi)/2])
                    
                    % get tick positions
                    ticks = get(obj.hAxCb(idi), Tick);
                    % prepend a color for each tick label
                    ticks_new = cell(size(ticks));
                    for ii = 1:length(ticks)
                        ticks_new{ii} = [sprintf('\\color[rgb]{%.3f,%.3f,%.3f} ', obj.COLOR_m(idi,  :)) num2str(ticks(ii))];
                    end
                    set(obj.hAxCb(idi), TickLabel, ticks_new);
                end
            end
        end
        
        
        function BtnCwHomeCallback(obj, src, ~)
            % set center and width to the initial values
            iImg = (obj.hBtnCwHome == src);
            obj.center(iImg) = obj.p.Results.CW(iImg, 1);
            obj.width(iImg) = obj.p.Results.CW(iImg, 2);
            % apply changes to center and width
            obj.cw();
        end
        
        
        function BtnCwSliceCallback(obj, src, ~)
            % set center and width to optimize display of the current slice
            iImg = (obj.hBtnCwSlice == src);
            
            % calculate cw values for the slice
            obj.center(iImg) = (obj.cleverMax(obj.slice{iImg})+obj.cleverMin(obj.slice{iImg})) / 2;
            obj.width(iImg)  = obj.cleverMax(obj.slice{iImg})-obj.cleverMin(obj.slice{iImg});
            
            % apply changes to center and width
            obj.cw();
        end
        
        
        function BtnHideCallback(obj, src, ~)
            % call the toggle layer fucntion
            obj.toggleLayer( find(obj.hBtnHide == src) );
        end
        
        
        function BtnCwCopyCallback(obj, src, ~)
            % copy the CW-values from one image to another
            obj.center(obj.hBtnCwCopy ~= src) = obj.center(obj.hBtnCwCopy == src);
            obj.width(obj.hBtnCwCopy ~= src)  = obj.width(obj.hBtnCwCopy == src);
            obj.cw();
        end
        
        
        function BtnToggleCallback(obj, ~, ~)
            if sum(obj.layerShown) == 1
                % if only one of the layers is shown, toggle both
                obj.toggleLayer(1);
                obj.toggleLayer(2);
            else
                % if both are hidden or shown, only show the first or the
                % last layer
                obj.toggleLayer(1);
            end
        end
        
        
        function toggleLayer(obj, layer)
            % toggles the display of obj.img{layer}
            % toggle the state
            %obj.hBtnHide(layer)
            obj.layerShown(layer) = ~obj.layerShown(layer);
            
            if obj.layerShown(layer)
                string = ['Hide (' obj.BtnHideKey(layer) ')'];
                set(obj.hBtnHide(layer), 'String', string)
            else
                string = ['Show (' obj.BtnHideKey(layer) ')'];
                set(obj.hBtnHide(layer), 'String', string)
            end
            set(obj.hBtnHide(layer), 'Value', obj.layerShown(layer))
            obj.refreshUI()
        end
        
        
        function setFFTStatus(obj, ~, ~)
            %called by the 'Run'/'Stop' button and controls the state of the
            %timer
            if obj.fftStatus == 1
                obj.fftStatus = 0;
                set(obj.hBtnFFT, 'String', 'FFT')
                % when leaving fft mode, also reset CW values to initial
                % values
                obj.prepareColors
                obj.cw                
            else
                obj.fftStatus = 1;
                set(obj.hBtnFFT, 'String', '<HTML>FFT<SUP>-1</SUP>')
            end
            obj.refreshUI;
        end
        
        
        function setSlider(obj, src, ~)
            % function is called when an index next to a slider is changed
            % and sets the selector and the image to the new coordinate.
            dim = obj.mapSliderToDim(obj.hEditSlider == src);            
            inSlice = round(str2double(get(src, 'String')));
            % make sure the new value is within reasonable bounds
            inSlice = max([1 inSlice]);
            inSlice = min([inSlice obj.S(dim)]);
                        
            obj.sel{obj.mapSliderToImage{obj.hEditSlider == src}, dim} = inSlice;
            obj.activateSlider(dim)
            
            obj.refreshUI();
            set(obj.f,  'WindowKeyPress',   @obj.keyPress);
            set(src,    'Enable',           'Inactive');
        end
        
        
        function newSlice(obj, src, ~)
            % called when slider is moved, get current slice
            dim = obj.mapSliderToDim(obj.hSlider == src);
            im  = obj.mapSliderToImage{obj.hSlider == src};
            obj.sel{im, dim} = round(src.Value);
            
            obj.activateSlider(dim);
            obj.refreshUI();
        end
        
        % Think about combining setSlider, newSlice and scrollSlider
        
        function scrollSlider(obj, ~, evtData)
            % scroll slider is a callback of the mouse wheel and handles
            % zooming within a slice and scrolling through the slices by
            % incrementing or decrementing the index along the
            % activeSlider.
            if strcmp(get(gcf, 'CurrentModifier'), 'control') & ~isempty(obj.pt)
                % zoom-mode
                % ctrl-key is pressed and obj.pt is not empty
                ax = get(obj.hImage(obj.pt(3)), 'Parent');
                if evtData.VerticalScrollCount < 0
                    % zoom in
                    % keep the point below the cursor at its position so
                    % users can zoom exactly to the point they want to
                    ax.XLim(1) = ax.XLim(1)/obj.zoomInFac + obj.resize*obj.pt(2)*(1-1/obj.zoomInFac);
                    ax.XLim(2) = ax.XLim(2)/obj.zoomInFac + obj.resize*obj.pt(2)*(1-1/obj.zoomInFac);
                    
                    ax.YLim(1) = ax.YLim(1)/obj.zoomInFac + obj.resize*obj.pt(1)*(1-1/obj.zoomInFac);
                    ax.YLim(2) = ax.YLim(2)/obj.zoomInFac + obj.resize*obj.pt(1)*(1-1/obj.zoomInFac);                    
                elseif evtData.VerticalScrollCount > 0
                    % zoom out
                    % zoom out such, that limits increase independent of
                    % cursor position
                    dX = 0.5*(ax.XLim(2)-ax.XLim(1))*(1/obj.zoomOutFac-1);
                    XLim(1) = ax.XLim(1) - dX;
                    XLim(2) = ax.XLim(2) + dX;
                    
                    dY = 0.5*(ax.YLim(2)-ax.YLim(1))*(1/obj.zoomOutFac-1);
                    YLim(1) = ax.YLim(1) - dY;
                    YLim(2) = ax.YLim(2) + dY;
                    
                    % make sure not to scroll beyond the limits
                    XLim(1) = max([XLim(1) 0.5]);
                    YLim(1) = max([YLim(1) 0.5]);
                    XLim(2) = min([XLim(2) obj.resize*size(obj.slice{obj.pt(3)}, 2)+0.5]);
                    YLim(2) = min([YLim(2) obj.resize*size(obj.slice{obj.pt(3)}, 1)+0.5]);
                    
                    ax.XLim = XLim;
                    ax.YLim = YLim;
                end
            else
                % scroll mode
                if evtData.VerticalScrollCount < 0 && obj.nDims > 2
                    obj.incDecActiveDim(-1);
                elseif evtData.VerticalScrollCount > 0 && obj.nDims > 2
                    obj.incDecActiveDim(+1);
                end
            end
        end
        
        
        function activateSlider(obj, dim)
            % change current axes and indicate to user by drawing coloured line
            % around current axes, but only if dim wasnt the active axis before
            if obj.activeDim ~= dim
                obj.activeDim = dim;
            end
        end
        
        
        function setCW(obj, src, ~)
            % called by the center and width edit fields
            s = get(src, 'String');
            %turn "," into "."
            s(s == ',') = '.';
            
            for idi = 1:obj.nImages
                if src == obj.hEditC(idi)
                    obj.center(idi) = str2double(s);
                    set(src, 'String', num2sci(obj.center(idi), 'padding', 'right'));
                elseif src == obj.hEditW(idi)
                    obj.width(idi) = str2double(s);
                    set(src, 'String', num2sci(obj.width(idi), 'padding', 'right'));
                end
            end
            
            % cw is called in order to update the colobar ticks
            obj.cw();
            obj.refreshUI();
            set(obj.f,  'WindowKeyPress',   @obj.keyPress);
            set(src,    'Enable',           'Inactive');
        end
        
        
        function stopDragFcn(obj, ~, ~)
            % on realease of middle mouse button, stop tracking mouse movement
            set(obj.f, 'WindowButtonMotionFcn', { @obj.mouseMovement});  %reattach mouse movement function
        end
        
        
        function mouseMovement(obj, ~, ~)        % display location and value
            for ida = 1:numel(obj.hImage)
				iteratingAx = get(obj.hImage(ida), 'Parent');
                pAx = round(get(iteratingAx, 'CurrentPoint')/obj.resize);                
                if obj.inAxis(iteratingAx, pAx(1, 1), pAx(1, 2))
                    pAx = round(pAx);
                    obj.locVal({pAx(1, 2), pAx(1, 1)}, ida);
                    obj.pt = [pAx(1, 2) pAx(1, 1) ida];
                    return
                end
            end
            % if the cursor is not on top of any axis, set it empty
            obj.locVal([]);
            obj.pt = [];
        end
        
        
        function b = inAxis(obj, ax, x, y)
            % inAxis checks, whether the point with coordinates (x, y) lies
            % within the limits of 'ax' and returns a bool
            if x >= ax.XLim(1)/obj.resize && x <= ax.XLim(2)/obj.resize && ...
                    y >= ax.YLim(1)/obj.resize && y <= ax.YLim(2)/obj.resize
                b = true;
            else
                b = false;
            end
        end
        
        
        function keyPress(obj, src, ~)
            key = get(src, 'CurrentCharacter');
            
            if isletter(key) & obj.nImages == 2
                if ismember(lower(key), obj.BtnHideKey)
                    obj.toggleLayer(find(ismember(obj.BtnHideKey, lower(key))))
                elseif key == obj.BtnTgglKey
                    obj.BtnToggleCallback()
                end
            end
        end
        
        
        function createROI(obj, roiNo, polygon)
            % when the user provides coordinates for a ROI polygon, create
            % the UI object
            
            obj.rois{roiNo} = images.roi.Polygon(...
                'Parent',   gca, ...
                'Color',    obj.COLOR_roi(roiNo, :), ...
                'Position', polygon);
            
            obj.calcROI()
            addlistener(obj.rois{roiNo}, 'MovingROI', @obj.calcROI);
            
        end
        
        
        function drawRoi(obj, src, ~)
            % check for signal or noise ROI
            roiNo = find(obj.hBtnRoi == src);
            % if there is currently a roi connected to the handle, delete
            % graphics element
            if ~isempty(obj.rois{roiNo})
                obj.deleteRoi(roiNo)
            end
            
            % instantiate new roi depending on choice
            switch(get(obj.hPopRoiType, 'Value'))
                case 1
                    obj.rois{roiNo} = images.roi.Polygon('Parent', gca, 'Color', obj.COLOR_roi(roiNo, :));
                case 2
                    obj.rois{roiNo} = images.roi.Ellipse('Parent', gca, 'Color', obj.COLOR_roi(roiNo, :));
                case 3
                    obj.rois{roiNo} = images.roi.Freehand('Parent', gca, 'Color', obj.COLOR_roi(roiNo, :));
            end
            
            addlistener(obj.rois{roiNo}, 'MovingROI', @obj.calcROI);
            draw(obj.rois{roiNo})
            
            obj.calcROI();
        end
        
        
        function calcROI(obj, ~, ~)
            % calculate masks, mean/std and display values and SNR
            
            % TODO: write code that finds the axes for both rois
            % hard fix:
            axNo = 1;
            
            % get current image
            for ii = 1:obj.nImages
                if ~isempty(obj.rois{1})
                    % This use does not work with resize ~= 1 !
                    Mask = obj.slice{axNo, ii}(obj.rois{1}.createMask);
                    obj.signal(ii) = mean(Mask(:));
                    set(obj.hTextRoi(1, ii), 'String', num2sci(obj.signal(ii), 'padding', 'right'));
                end
                if ~isempty(obj.rois{2})
                    % This use does not work with resize ~= 1 !
                    Mask = obj.slice{axNo, ii}(obj.rois{2}.createMask);
                    % input to std must ne floating point
                    obj.noise(ii) = std(single(Mask(:)));
                    set(obj.hTextRoi(2, ii), 'String', num2sci(obj.noise(ii), 'padding', 'right'));
                end
                set(obj.hTextSNRvals(ii), 'String', num2sci(obj.signal(ii)./obj.noise(ii), 'padding', 'right'));
            end
        end        
        
        
        function deleteRoi(obj, roiNo)
            % remove roi shape from axes
            delete(obj.rois{roiNo})
            % make roi handle empty
            obj.rois{roiNo} = [];
            set(obj.hTextRoi(roiNo, :), 'String', '');           
            set(obj.hTextSNRvals(:),    'String', '');
            if roiNo == 1
                obj.signal = [NaN NaN];
            else
                obj.noise = [NaN NaN];
            end
        end
        
        
        function delRois(obj, ~, ~)
            obj.deleteRoi(1)
            obj.deleteRoi(2)
        end
        
        
        function saveRois(obj, ~, ~)
            % function is called by the 'Save ROIs' button and saves the
            % vertices of the current ROIs to the base workspace.
            if ~isempty(obj.rois{1})
                assignin('base', 'ROI_Signal', obj.rois{1}.Position);
                fprintf('ROI_Signal saved to workspace\n');
            else
                fprintf('ROI_Signal not found\n');
            end
            if ~isempty(obj.rois{2})
                assignin('base', 'ROI_Noise', obj.rois{2}.Position);
                fprintf('ROI_Noise saved to workspace\n');
            else
                fprintf('ROI_Noise not found\n');
            end
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
%                 set(obj.hBtnG,   'Visible', 'on');
            else
                stop(obj.t)
                set(obj.hBtnRun, 'String',  'Run');
%                 set(obj.hBtnG,   'Visible', 'off');
            end
        end
        
        
        function interrupt(obj, ~, ~)
            % this function is called for every interrupt of the timer and
            % increments/decrements the slider value.
            
            % what dimension to adjust
            interDim = obj.mapSliderToDim(obj.interruptedSlider);
            if obj.fps > 0
                obj.sel{1, interDim} = obj.sel{1, interDim} + 1;
            elseif obj.fps < 0
                obj.sel{1, interDim} = obj.sel{1, interDim} - 1;
            end
                obj.sel{1, interDim} = mod(obj.sel{1, interDim}-1, obj.S(interDim))+1;
            obj.refreshUI();
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
                if strcmp(filename(end-2:end), 'avi') || strcmp(filename(end-2:end), 'gif')
                obj.saveVideo([filepath, filename])
                else
                    warning('Invalid filename! Data was not saved. Choose ''.gif'' or ''.avi'' as filetype.');
                end
            end
        end
        
        
        function saveVideo(obj, path)
            % save video of matrix with current windowing and each frame being
            % one slice along the dimension connectoed to the interrupted slider.
            
            if ~isempty(obj.t)
                % get the state of the timer
                bRunning = strcmp(obj.t.Running, 'on');
                % stop the interrupt, to get control over the data shown.
                if bRunning
                    stop(obj.t)
                end
            end
            
            
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
            for ii = 1:obj.S(obj.mapSliderToDim(obj.interruptedSlider))
                obj.sel{obj.mapSliderToDim(obj.interruptedSlider)} = ii;
                obj.prepareSliceData
                imgOut = rot90(obj.sliceMixer(), -round(obj.azimuthAng/90));
                
                if gif
                    [gifImg, cm] = rgb2ind(imgOut, 256);
                    if ii == 1
                        imwrite(gifImg, cm, path, 'gif', ...
                            'WriteMode',    'overwrite', ...
                            'DelayTime',    1/obj.fps, ...
                            'LoopCount',    obj.p.Results.LoopCount);
                    else
                        imwrite(gifImg, cm, path, 'gif', ...
                            'WriteMode',    'append',...
                            'DelayTime',    1/obj.fps);
                    end
                else
                    writeVideo(v, imgOut);
                end
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
        
        
        function setValNames(obj)
            
            for ii = 1:obj.nImages
                % create default val name
                obj.valNames{ii} = ['val' num2str(ii)];
                
                % if available, take the name of the input variable
                if ~isempty(obj.inputNames{ii})
                    if numel(obj.inputNames{ii}) > obj.maxLetters
                        obj.valNames{ii} = obj.inputNames{ii}(1:obj.maxLetters);
                    else
                        obj.valNames{ii} = obj.inputNames{ii};
                    end
                    % text is shown using the LaTeX interpreter. We need to
                    % escape underscores
                    obj.valNames{ii} = strrep(obj.valNames{ii}, '_', '\_');
                end
            end
            
            % to get the number of the displayed characters correct, we
            % need to know howm many '_' are in each name to compensate the
            % result from numel
            usNo = cellfun(@(x) sum(x == '_'), obj.valNames);
            
            % find number of trailing whitespace
            wsToAdd = max(cellfun(@numel, obj.valNames) - usNo) - (cellfun(@numel, obj.valNames) - usNo);
            ws = cell(1, obj.nImages);
            for ii = 1:obj.nImages
                ws{ii} = repmat(' ', [1, wsToAdd(ii)]);
            end
            obj.valNames = strcat(obj.valNames, ws);
        end
        
        
        function removeListener(obj, src, ~)
            set(obj.f, 'WindowKeyPress', '');
            set(src, 'Enable', 'On');
        end
        
        
        function changeOverlay(obj, src, ~)
            % get the index of the new overlay value in obj.overlayStrings
            obj.overlay = find(cellfun( @(x) strcmp(x, obj.overlayStrings{get(src, 'Value')}), obj.overlayStrings));
            obj.refreshUI()
        end
        
        
        function setCmap(obj, src, ~)            
            % which colormap is selected
            idx = find(src == obj.hPopCm);
            cm = obj.cmapStrings{get(src, 'Value')};
            obj.cmap{idx} = obj.availableCmaps.(cm);
            
            % set UI text colors
                obj.COLOR_m(idx, :) = obj.cmap{idx}(round(size(obj.availableCmaps.(cm), 1) * 0.9), :);
                
                % change color of c/w edit fields
                set(obj.hEditC(idx), 'ForegroundColor', obj.COLOR_m(idx, :))
                set(obj.hEditW(idx), 'ForegroundColor', obj.COLOR_m(idx, :))
                if obj.nImages == 2
                set(obj.hBtnHide(idx), 'ForegroundColor', obj.COLOR_m(idx, :))
                end
                
            % change colorbar axes
            if ~isempty(obj.hAxCb)
                % many UI elements dont exist when prepare colors is called
                % the first time
                colormap(obj.hAxCb(idx), obj.cmap{idx})
                % recolor the ticks on the colorbars
            	obj.cw()
            end
                                  
            if obj.nImages == 2 && strcmp(get(obj.f, 'Visible'), 'on')
                % the first time setCmap is called, not all UI Elements are
                % created yet, so we wait until obj.f is actually shown to
                % the user
                                
                obj.recolor()
            end
        end
        
        
        function changeCmap(obj, src, ~)
            
            obj.setCmap(src)
            
            % reclaculate the shown image with the new colormap
            obj.refreshUI()
        end
        
        
        function isContrast = isContrast(obj, inputContrast)
            contrasts = {'green-magenta', 'PET', 'heat'};
            if obj.nImages == 1
                isContrast = true;
                warning('Only one image available - contrast value ignored');
            else
                switch class(inputContrast)
                    case 'char'
                        if sum(strcmp(contrasts, inputContrast))
                            isContrast = true;
                        else
                            fprintf('Contrast must be any of the following or cell:\n');
                            for con = contrasts
                                fprintf('%s\n', con{1});
                            end
                            error('Choose a valid contrast!');
                        end
                    case 'cell'
                        isContrast = obj.isColormap(inputContrast{1}) && obj.isColormap(inputContrast{2});
                    otherwise
                        error('Contrast must be an identifier string or colormap-cell!');
                end
            end
        end
        
        
        function prepareColormaps(obj)
            cmapResolution = 256;
            obj.availableCmaps.gray    = gray(cmapResolution);
            obj.availableCmaps.green   = [zeros(cmapResolution,1) linspace(0,1,cmapResolution)' zeros(cmapResolution,1)];;
            obj.availableCmaps.magenta = [linspace(0,1,cmapResolution)' zeros(cmapResolution,1) linspace(0,1,cmapResolution)'];
            obj.availableCmaps.hot     = hot(cmapResolution);
            obj.availableCmaps.parula  = parula(cmapResolution);
            
            % check whether colorcet is available
            if exist('colorcet.m',  'file') == 2
                % replace hot with fire, maybe add more cmaps?
                obj.availableCmaps.fire = colorcet('fire', 'N', cmapResolution);
                obj.availableCmaps = rmfield(obj.availableCmaps, 'hot');
                
                % add some more cmaps
                obj.availableCmaps.redblue      = colorcet('D4', 'N', cmapResolution);
                obj.availableCmaps.cyclic       = colorcet('C2', 'N', cmapResolution);
                obj.availableCmaps.isolum       = colorcet('I1', 'N', cmapResolution);
                obj.availableCmaps.protanopic   = colorcet('CBL2', 'N', cmapResolution);
                obj.availableCmaps.tritanopic   = colorcet('CBTL1', 'N', cmapResolution);
                obj.availableCmaps.rainbow      = colorcet('R2', 'N', cmapResolution);
            end
            % check whether certain colormaps are available
            if exist('viridis.m', 'file') == 2
                obj.availableCmaps.viridis = viridis;
            end
            if exist('inferno.m', 'file') == 2
                obj.availableCmaps.inferno = inferno;
            end
            
            obj.cmapStrings = fieldnames(obj.availableCmaps);
        end
        
        
        function setInitialColormap(obj, inputMap)            
            if iscell(inputMap) & numel(inputMap)==1 & obj.nImages==2
                inputMap{2} = inputMap{1};
            end
            
            % make non-cell input easier to work with
            if ~iscell(inputMap)
                inputMap = {inputMap, inputMap};
            end
            
                        
            % counter for custom colormaps
            customCtr = 1;
            for idx = 1:obj.nImages
                % set both popdownmenus to 'gray' (such that both cmaps are
                % defined if only one is provided in case of nImages=2
                obj.setPopCm(idx, 'gray')
                if ischar(inputMap{idx})
                    % find index in colormap List
                    if ismember(inputMap{idx}, obj.cmapStrings)
                        obj.setPopCm(idx, inputMap{idx})
                        continue
                    end
                elseif isnumeric(inputMap{idx})
                    if size(inputMap{idx}, 2) == 3
                        obj.availableCmaps.(['custom' num2str(customCtr)]) = inputMap{idx};
                        obj.cmapStrings = fieldnames(obj.availableCmaps);
                        obj.setPopCm(idx, ['custom' num2str(customCtr)])
                        customCtr = customCtr+1;
                        continue
                    end
                end
                
                % input not supported
                warning('Could not parse input for colormap %d, using gray(256) instead', idx)
            end
        end
        
        
        function setInitialContrast(obj)
            % depending on the selected contrast, both colormaps are generated
            % and stored in cm, as well as the colors for the text in the control
            % panel (c1, c2)
            switch obj.contrast
                case 'green-magenta'
                    obj.setPopCm(1, 'magenta')
                    obj.setPopCm(2, 'green')
                case 'PET'
                    obj.setPopCm(1, 'gray')
                    if isfield(obj.availableCmaps, 'fire')
                        obj.setPopCm(2, 'fire')
                    else
                        obj.setPopCm(2, 'hot')
                    end
                case 'heat'
                    obj.setPopCm(1, 'gray')
                    obj.setPopCm(2, 'redblue')
                otherwise
                    error(['Contrast not available. Choose', ...
                        "\t'green-magenta'", ...
                        "\t'PET'", ...
                        "or \t''"]);
            end
        end
        
        
        function setPopCm(obj, idx, cName)
           % sets the value of hPopCm(idx) to the string specified by cName
           
           idxValue = find(cellfun( @(x) strcmp(x, cName), obj.cmapStrings));
           
           set(obj.hPopCm(idx), 'Value', idxValue);            
        end
        
        
        function tmp = cleverMax(~, in)
            % this function is called by MATLAB versions older than R2018a
            % in which 'max(A, [], 'all')' syntax was implemented. It
            % iteratively calculates the max value along the remaining
            % largest dimension. Calculating max like this proves less
            % memory intensive than max(in(:)), which gets slow for large
            % arrays.
            
            sz = size(in);
            
            for i = 1:numel(sz)
                % find the index for the largest dimenison
                [~, idx] = max(sz);
                if i==1
                    tmp = max(in,[], idx(1), 'omitnan');
                else
                    tmp = max(tmp,[], idx(1), 'omitnan');
                end
                sz = size(tmp);
            end
        end
        
        
        function tmp = cleverMin(~, in)
            % this function is called by MATLAB versions older than R2018a
            % in which 'min(A, [], 'all')' syntax was implemented. It
            % iteratively calculates the min value along the remaining
            % largest dimension. Calculating min like this proves less
            % memory intensive than min(in(:)), which gets slow for large
            % arrays.
            
            sz = size(in);
            
            for i = 1:numel(sz)
                % find the index for the largest dimenison
                [~, idx] = max(sz);
                if i==1
                    tmp = min(in,[], idx(1), 'omitnan');
                else
                    tmp = min(tmp,[], idx(1), 'omitnan');
                end
                sz = size(tmp);
            end
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