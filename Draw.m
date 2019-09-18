classdef (Abstract) Draw < handle
    %Draw Baseclass for Draw.. GUIs
    %   Detailed explanation goes here
    
    % TODO:
    % - implement functionality of ShiftDim buttons
    % - RadioGroup Buttons for animated sliders
    
    properties
        f
    end
    
    properties (Access = protected)
        % INPUT PROPERTIES
        nImages         % number of images (1 or 2)
        nAxes           % number of displayed image Axes (DrawSingle: 1, DrawSlider: 3)
        img             % cell array in which the input matrices are stored
        nDims           % number of image dimensions
        isComplex       % is one of the inputs complex
        layerHider      % which of the images is currently shown?
        S               % size of the image(s)
        p               % input parser
        standardTitle   % name of the figure, default depends on inputnames
        
        % WINDOWING PROPERTIES
        Max             % maximum value in both images
        Min             % minimum value in both images
        center
        width
        widthMin
        centerStep
        widthStep
        nrmFac
        
        fftStatus
        fftData
        
        % DISPLAYING
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
        showDims
        sel
        activeDim
        activeAx
        % complex representation
        complexMode
        resize
        azimuthAng
        elevationAng
        % cell array containing the current slice image information
        slice
        
        contrast
        COLOR_m
        cmap
        
        % GUI ELEMENTS
        % array of images displayed in 'ax', the handle to the respective axis can always be obtained via
		% get(obj.hImage(...), 'Parent')
        hImage
        % array of slider handles to navigate through the slices
        hTextSlider
        hEditSlider
        hSlider
        % cw-windowing element arrays
        hTextC
        hTextW
        hEditC
        hEditW        
        hBtnHide
        hBtnToggle
        hPopContrast
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
        
        % GUI ELEMENT PROPERTIES
        nSlider
        
        % array with ROIs
        rois
        signal
        noise
    end
    
    properties (Constant = true, Hidden = true)
        % color scheme of the GUI
        COLOR_BG  = [0.2 0.2 0.2];
        COLOR_B   = [0.1 0.1 0.1];
        COLOR_F   = [0.9 0.9 0.9];
        COLOR_roi = [1.0 0.0 0.0;
                    0.0 0.0 1.0];
        contrastList = {'green-magenta', 'PET', 'heat'};
        
    end
    
    
    methods
        function obj = Draw(in, varargin)
            % CONSTRUCTOR
            
            obj.img{1}      = in;
            obj.S           = size(in);
            obj.nDims       = ndims(in);
            obj.activeDim   = 1;
            obj.isComplex   = ~isreal(in);
            % necessary for view orientation, already needed when saving image or video
            obj.azimuthAng   = 0;
            obj.elevationAng = 90;
                        
            
            % check varargin for a sencond input matrix
            obj.secondImageCheck(varargin{:})
            
            
            % prepare roi parameters
            obj.rois         = {[], []};
            obj.signal       = NaN(1, obj.nImages);
            obj.noise        = NaN(1, obj.nImages);
            
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
            
            % create GUI elements for cw windowing
            obj.prepareGUIElements()
            
        end
        
        
        function delete(obj)
            delete(obj)
        end
        
        
        function findMinMax(obj)
            % Calculates the minimal and maximal value in the upto two
            % input matrices. If there are +-Inf values in the data, a
            % slower, less memory efficient calculation is performed.
            obj.Max = [max(obj.img{1}, [], 'all', 'omitnan'), max(obj.img{2}, [], 'all', 'omitnan')];
            hasInf = obj.Max == Inf;
            if hasInf(1)
                warning('+Inf values present in input 1. For large input matrices this can cause memory overflow and long startup time.')
                obj.Max(1)           = max(obj.img{1}(~isinf(obj.img{1})), [], 'omitnan');
            elseif obj.nImages == 2 && hasInf(2)
                warning('-Inf values present in input 2. For large input matrices this can cause memory overflow and long startup time.')
                obj.Max(2)           = max(obj.img{2}(~isinf(obj.img{2})), [], 'omitnan');
            end
            
            obj.Min = [min(obj.img{1}, [], 'all', 'omitnan'), min(obj.img{2}, [], 'all', 'omitnan')];
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
        
        
        function secondImageCheck(obj, varargin)
            % check varargin to see if a second matrix was provided
            if ~isempty(varargin) && ( isnumeric(varargin{1}) || islogical(varargin{1}) )
                obj.nImages = 2;
                obj.img{2}  = varargin{1};
                obj.layerHider   = [1, 1];
                obj.isComplex(2) = ~isreal(obj.img{2});
            else
                obj.nImages = 1;
                obj.img{2}  = [];
            end
        end
        
        
        function prepareParser(obj)
            
            obj.p = inputParser;
            isboolean = @(x) x == 1 || x == 0;
            % add parameters to the input parser
            addParameter(obj.p, 'Colormap',     gray(256),                      @(x) obj.isColormap(x));
            addParameter(obj.p, 'Contrast',     'green-magenta',                @(x) obj.isContrast(x, obj.nImages));
            addParameter(obj.p, 'ComplexMode',  obj.complexMode,                @(x) isnumeric(x) && x <= 4);
            addParameter(obj.p, 'AspectRatio',  'square',                       @(x) any(strcmp({'image', 'square'}, x)));
            addParameter(obj.p, 'Resize',       1,                              @isnumeric);
            addParameter(obj.p, 'Title',        obj.standardTitle,              @ischar);
            addParameter(obj.p, 'CW',           [(obj.Max(1) - obj.Min(1))/2+obj.Min(1), ...
                                                obj.Max(1)-obj.Min(1)],         @isnumeric);
            addParameter(obj.p, 'CW2',          [(obj.Max(2) - obj.Min(2))/2+obj.Min(2), ...
                                                obj.Max(2)-obj.Min(2)],         @isnumeric);
            addParameter(obj.p, 'widthMin',     single(0.001*(obj.Max-obj.Min)),@isnumeric);
            addParameter(obj.p, 'Unit',         {[], []},                       @(x) iscell(x) && numel(x) <= 2);
        end
        
        
        function prepareColors(obj)
            % Depending on the amount of input matrices and the provided
            % colormaps or contrast information, the colorscheme for the UI
            % is set and 'center', 'width', and 'widthMin' are given proper
            % initial values.
            %
            % Called by constructor of inheriting class
            % 
            if obj.nImages == 2
                [obj.cmap, c1, c2] = obj.getContrast();
                obj.COLOR_m(1,:) = c1;
                obj.COLOR_m(2,:) = c2;
                
                % if widthMin is scalar, make it a vector
                if isscalar(obj.widthMin)
                    obj.widthMin = [obj.widthMin obj.widthMin];
                end
            else
                obj.COLOR_m(1,:) = obj.COLOR_F;
                obj.COLOR_m(2,:) = obj.COLOR_F;
                
                % if widthMin is scalar, make it a vector
                if isscalar(obj.widthMin)
                    obj.widthMin = [obj.widthMin 0];
                end
            end
            
            obj.center(1)	= double(obj.p.Results.CW(1));
            obj.width(1)    = double(obj.p.Results.CW(2));
            obj.center(2)   = double(obj.p.Results.CW2(1));
            obj.width(2)    = double(obj.p.Results.CW2(2));
            obj.centerStep  = double(obj.center);
            obj.widthStep   = double(obj.width);
            obj.widthMin    = obj.p.Results.widthMin;
        end
        
        
        function prepareGUIElements(obj)
            
            % create figure handle, but hide figure
            obj.f = figure('Color', obj.COLOR_BG, ...
                'Visible',          'off');
            
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
                    'Callback',             @obj.setCW);
                
                obj.hEditW(idh) = uicontrol( ...
                    'Style',                'edit', ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'Enable',               'Inactive', ...
                    'ButtonDownFcn',        @obj.removeListener, ...
                    'Callback',             @obj.setCW);
                
                if obj.nImages == 2
                    obj.hBtnHide(idh) = uicontrol( ...
                        'Style',                'togglebutton', ...
                        'BackgroundColor',      obj.COLOR_BG, ...
                        'Callback',             {@obj.hidelayer});
                end
            end
            
            obj.hPopContrast = uicontrol( ...
                'Style',                'popup', ...
                'String',               {'green-magenta', 'PET', 'heat'}, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F, ...
                'Callback',             {@obj.changeContrast});
            
            if obj.nImages == 2
                obj.hBtnToggle = uicontrol( ...
                    'Style',                'pushbutton', ...
                    'BackgroundColor',      obj.COLOR_BG, ...
                    'ForegroundColor',      obj.COLOR_F, ...
                    'Callback',             {@obj.togglelayers});
            end
            
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
            
            obj.hBtnFFT = uicontrol( ...
                'Style',                'pushbutton', ...
                'String',               'FFT', ...
                'Callback',             {@obj.setFFTStatus}, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnCmplx(1) = uicontrol( ...
                'Style',                'togglebutton', ...
                'String',               'Magnitude', ...
                'Callback',             {@obj.toggleComplex},...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnCmplx(2) = uicontrol( ...
                'Style',                'togglebutton', ...
                'String',               'Phase', ...
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
                'String',               'imaginary', ...
                'Callback',             {@obj.toggleComplex},...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
        end
        
        
        function prepareSliceData(obj)
            % obtain image information form
            for iImg = 1:obj.nImages
                for iax = 1:obj.nAxes
                    obj.slice{iax, iImg} = squeeze(obj.img{iImg}(obj.sel{iax, :}));
                    if obj.fftStatus == 1
                        obj.slice{iax, iImg} = fftshift(fftn(fftshift(obj.slice{iax, iImg})));
                    end
                end
            end
            
            if any(~cellfun(@isreal, obj.slice))
                % at least one of the slices has complex values
                set(obj.hBtnCmplx, 'Visible', 'on');
                obj.slice = cellfun(@single, ...
                    cellfun(@obj.complexPart, obj.slice, 'UniformOutput', false), ...
                    'UniformOutput', false);
            else
                % none of the slices has complex data
                % when hBtnCmplx are hidden, complexMode must be 3
                obj.complexMode = 3;
                set(obj.hBtnCmplx, 'Visible', 'off');
                obj.slice = cellfun(@single, obj.slice, 'UniformOutput', false);
            end
            
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
                cImage  = zeros([size(obj.slice{axNo, 1} ), 3]);
                for idd = 1:obj.nImages
                    % convert images to range [0, cmapResolution]
                    lowerl  = single(obj.center(idd) - obj.width(idd)/2);
                    imshift = (obj.slice{axNo, idd} - lowerl)/single(obj.width(idd)) * size(obj.cmap{idd}, 1);
                    if obj.resize ~= 1
                        imshift = imresize(imshift, obj.resize);
                    end
                    imgRGB  = ind2rgb(round(imshift), obj.cmap{idd}) * obj.layerHider(idd);
                    imgRGB(repmat(isnan(obj.slice{axNo, idd}), [1 1 3])) = 0;
                    cImage  = cImage + imgRGB;
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
        
        
        function startDragFcn(obj, src, ~)
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
                    if ~isempty(obj.img{2}) && obj.layerHider(2)
                        sCenter = obj.center;
                        sWidth  = obj.width;
                        cStep   = [0, obj.centerStep(2)];
                        wStep   = [0, obj.widthStep(2)];
                        obj.f.WindowButtonMotionFcn = {@obj.draggingFcn, callingAx, Pt, sCenter, sWidth, cStep, wStep};
                    end
                case 'extend'
                    if isempty(obj.img{2}) || (~isempty(obj.img{2}) && obj.layerHider(1))
                        sCenter = obj.center;
                        sWidth  = obj.width;
                        cStep   = [obj.centerStep(1), 0];
                        wStep   = [obj.widthStep(1), 0];
                        obj.f.WindowButtonMotionFcn = {@obj.draggingFcn, callingAx, Pt, sCenter, sWidth, cStep, wStep};
                    end
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
        end
        
        
        function hidelayer(obj, src, ~)
            if src.Value == 0
                src.String  = 'Show';
                if src == obj.hBtnHide(1)
                    obj.layerHider(1) = 0;
                else
                    obj.layerHider(2) = 0;
                end
            else
                src.String  = 'Hide';
                if src == obj.hBtnHide(1)
                    obj.layerHider(1) = 1;
                else
                    obj.layerHider(2) = 1;
                end
            end
            obj.refreshUI()
        end
        
        
        function togglelayers(obj, ~, ~)
            if sum(obj.layerHider) == 1
                % if only one of the layers is shown, toggle both
                obj.layerHider = xor(obj.layerHider, [1 1]);
            else
                % if both are hidden or shown, only show the first layer
                obj.layerHider = [1 0];
            end
            % at this point one should be 1 and the other should be 0
            if obj.layerHider(1) == 1
                set(obj.hBtnHide(1), 'String', 'Hide')
                set(obj.hBtnHide(2), 'String', 'Show')
                set(obj.hBtnHide(1), 'Value',  1)
                set(obj.hBtnHide(2), 'Value',  0)
            else
                set(obj.hBtnHide(1), 'String', 'Show')
                set(obj.hBtnHide(2), 'String', 'Hide')
                set(obj.hBtnHide(1), 'Value',  0)
                set(obj.hBtnHide(2), 'Value',  1)
            end
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
            % scroll slider is a callback of the mouse wheel and handles the
            % scrolling through the slices by incrementing or decrementing the
            % index along the activeSlider.
            if evtData.VerticalScrollCount < 0
                obj.incDecActiveDim(-1);
            elseif evtData.VerticalScrollCount > 0
                obj.incDecActiveDim(+1);
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
            
            obj.refreshUI();
            set(obj.f,  'WindowKeyPress',   @obj.keyPress);
            set(src,    'Enable',           'Inactive');
        end
        
        
        function stopDragFcn(obj, varargin)
            % on realease of middle mouse button, stop tracking mouse movement
            set(obj.f, 'WindowButtonMotionFcn', { @obj.mouseMovement});  %reattach mouse movement function
        end
        
        
        function mouseMovement(obj, ~, ~)        % display location and value
            for ida = 1:numel(obj.hImage)
				iteratingAx = get(obj.hImage(ida), 'Parent');
                pAx = round(get(iteratingAx, 'CurrentPoint')/obj.resize);
                if obj.inAxis(iteratingAx, pAx(1, 1), pAx(1, 2))
                    obj.locVal({pAx(1, 2) pAx(1, 1)});
                    return
                end
            end
            % if the cursor is not on top of any axis
            obj.locVal([]);
        end
        
        
        function b = inAxis(obj, ax, x, y)
            if x >= (ax.XLim(1)-0.5)/obj.resize+0.5 && x <= (ax.XLim(2)-0.5)/obj.resize+0.5 && ...
                    y >= (ax.YLim(1)-0.5)/obj.resize+0.5 && y <= (ax.YLim(2)-0.5)/obj.resize+0.5
                b = true;
            else
                b = false;
            end
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
                
        
        function removeListener(obj, src, ~)
            set(obj.f, 'WindowKeyPress', '');
            set(src, 'Enable', 'On');
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
        
        
        function changeContrast(obj, ~, ~)
            obj.contrast = obj.contrastList{get(obj.hPopContrast, 'Value')};
            obj.prepareColors
            % TODO: change color of c/w edit fields
            obj.refreshUI
        end
        
        
        function isMap = isColormap(~, inputMap)
            colorMaps = {'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink', 'lines', 'colorcube', 'prism', 'flag', 'white'};
            switch class(inputMap)
                case 'double'
                    if ~isequal(size(inputMap,2), 3)
                        error('Colormap size must be a (N x 3) array');
                    else
                        if max(inputMap(:)) > 1 || min(inputMap(:) < 0)
                            error('Colormap must be in the range [0,1]');
                        else
                            isMap = true;
                        end
                    end
                case 'char'
                    if sum(strcmp(colorMaps, inputMap))
                        isMap = true;
                    else
                        fprintf('ColorMap must be any of the following:\n');
                        for map = colorMaps
                            fprintf('%s\n', map{1});
                        end
                        error('Choose a valid color map');
                    end
                otherwise
                    error('Colormap must be numeric or string.');
            end
        end
        
        
        function [cm, c1, c2] = getContrast(obj)
            % depending on the selected contrast, both colormaps are generated
            % and stored in cm, as well as the colors for the text in the control
            % panel (c1, c2)
            cmapResolution = 256;
            if iscell(obj.contrast)
                cm1 = obj.contrast{1};
                cm2 = obj.contrast{2};
                c1  = cm1(end,:);
                c2  = cm2(end,:);
            else
                switch obj.contrast
                    case 'green-magenta'
                        cm1 = [linspace(0,1,cmapResolution)' zeros(cmapResolution,1) linspace(0,1,cmapResolution)'];
                        cm2 = [zeros(cmapResolution,1) linspace(0,1,cmapResolution)' zeros(cmapResolution,1)];
                        c1  = [1 .4 1];
                        c2  = cm2(end,:);
                    case 'PET'
                        cm1 = gray(cmapResolution);
                        cm2 = colorcet('L3', 'N', cmapResolution);
                        c1  = [.9 .9 .9];
                        c2  = [1 1 0];
                    case 'heat'
                        cm1 = gray(cmapResolution);
                        cm2 = colorcet('D4', 'N', cmapResolution);
                        c1  = [.9 .9 .9];
                        c2  = [.7 .7 1];
                    otherwise
                        error(['Contrast not available. Choose', ...
                            "\t'green-magenta'", ...
                            "\t'PET'", ...
                            "or \t''"]);
                end
            end
            % append both cmaps to form one matrix
            cm = cell(1, 2);
            cm{1} = cm1;
            cm{2} = cm2;
        end
    end
    
    %% abstract methods
    
    methods (Abstract)
        locVal(obj)
        refreshUI(obj)
        keyPress(obj)
        incDecActiveDim(obj, incDec)
    end
end

