classdef nvisRGB < nvisBase
    
%__________________________________________________________________________
% Authors:  Johannes Fischer
%           Yanis Taege
    properties (Access = private)
        
        % DISPLAYING
        locValString
        dimensionLabel
        
        % UI Elements
        pImage
        pSlider
        pControls
        hBtnShiftL
        hBtnShiftR
        locAndVals
        
        hBtnG
        hRadioBtnSlider
        
        % UI properties
        
        pSliderHeight
        division
        margin 
        height
        yPadding
        panelPos
        figurePos
        
        isUint
    end
    
    properties (Constant, Access = private)
        % UI PROPERTIES
        % default figure position and size
        defaultPosition = [ 300, 200, 1000, 800];
        % absolute width of Control panel in pixel
        controlWidth = 275; % px
        controlWidthMinimized   = 30 ; % px
    end
    
    methods
        function obj = nvisRGB(in, varargin)
            % CONSTRUCTOR
            obj@nvisBase(in, varargin{:})
            
            % only one Axis in nvisRGB
            obj.nAxes    = 1;
            obj.activeAx = 1;

            % make sure last dimension has exactly size 3
            if size(obj.img{1}, obj.nDims) ~= 3
                error('Size of last dimension must be 3!')
            end

             % only show slider for a dimension with a length higher than 1
            if obj.nDims-1 > 2
                % we dont need sliders for the first two and the last dimension
                tmp = 3:obj.nDims-1;
                obj.mapSliderToDim  = tmp(obj.S(3:end-1) > 1);
                obj.nSlider         = numel(obj.mapSliderToDim);
                obj.activeDim       = obj.mapSliderToDim(1);
            else
                % there is no dimension to slide through anyway
                obj.nSlider   = 0;
                obj.activeDim = 3;
            end
            
            
            obj.standardTitle = inputname(1);
            % since we expect only real valued data, we set the
            % complex-part to the real-part
            obj.complexMode = 3;
            if isa(in, 'integer')
                obj.isUint = true;
            else
                obj.isUint = false;
            end

            obj.mapSliderToImage = num2cell(ones(1, obj.nSlider));
            if obj.nImages == 2
                obj.inputNames{1} = inputname(1);
                obj.inputNames{2} = inputname(2);
                obj.standardTitle = [inputname(1) ', ' inputname(2)];
            else
                obj.inputNames{1} = inputname(1);
                obj.standardTitle = inputname(1);
            end
            
            obj.prepareParser()
            
            % additional parameters
             addParameter(obj.p, 'InitSlice',        round(obj.S(obj.mapSliderToDim)/2), @isnumeric);
%             addParameter(obj.p, 'InitSlice',        round(obj.S(3:end)/2),              @isnumeric);
%             addParameter(obj.p, 'LoopDimension',    3,                                  @(x) isnumeric(x) && x <= obj.nDims && obj.nDims >= 3);
%             addParameter(obj.p, 'DimensionLabel',   strcat(repmat({'Dim'}, 1, numel(obj.S)), ...
%                                                     cellfun(@num2str, num2cell(1:obj.nDims), 'UniformOutput', false)), ...
%                                                                                         @(x) iscell(x) && numel(x) == obj.nSlider+2);
          
            parse(obj.p, varargin{:});
                        
%             if contains('dimensionLabel', obj.p.UsingDefaults)
%                 for ff = 1:obj.nDims
%                     obj.dimensionLabel{ff} = [obj.p.Results.DimensionLabel{ff} num2str(ff)];
%                 end
%             else
%                 obj.dimensionLabel = obj.p.Results.DimensionLabel;
%             end
                        
            obj.cmap{1}             = obj.p.Results.Colormap;
            obj.fps                 = obj.p.Results.fps;
            obj.resize              = obj.p.Results.Resize;

            % set default values for dimLabel
            obj.dimLabel = strcat(repmat({'Dim'}, 1, numel(obj.S)), cellfun(@num2str, num2cell(1:obj.nDims), 'UniformOutput', false));

            obj.parseDimLabelsVals()

            obj.prepareGUIElements()
            
            obj.createSelector()            
            
            obj.activeDim = 3;
            obj.interruptedSlider = 1;
            % necessary for view orientation, already needed when saving image or video
            obj.azimuthAng   = 0;
                        
            % when an image or a video is saved, dont create the GUI and
            % terminate the class after finishing
            if ~contains('SaveImage', obj.p.UsingDefaults)
                obj.saveImage(obj.p.Results.SaveImage);
                clear obj
                return
            end            
            if ~contains('SaveVideo', obj.p.UsingDefaults)
                obj.saveVideo(obj.p.Results.SaveVideo);
                clear obj
                return
            end

            obj.setValNames()

            obj.setTitle()
                        
            obj.setLocValFunction            
            
            obj.prepareGUI()
            
            obj.guiResize()
            set(obj.f, 'Visible', 'on');
            
            % do not assign to 'ans' when called without assigned variable
            if nargout == 0
                clear obj
            end
        end
        
        
        function delete(obj)
            try
                stop(obj.t);
                delete(obj.t);
            catch
            end
        end
        
        
        function prepareGUI(obj)
            
            % adjust figure properties
            
            set(obj.f, ...
                'name',                 obj.figureTitle, ...
                'Units',                'pixel', ...
                'Position',             obj.p.Results.Position, ...
                'Visible',              'on', ...
                'ResizeFcn',            @obj.guiResize, ...
                'CloseRequestFcn',      @obj.closeRqst, ...
                'WindowKeyPress',       @obj.keyPress, ...
                'WindowButtonMotionFcn',@obj.mouseMovement, ...
                'WindowButtonUpFcn',    @obj.stopDragFcn);
            
            if obj.nDims > 2
                set(obj.f, ...
                    'WindowScrollWheelFcn', @obj.scrollSlider);
            end
            
            % absolute height of slider panel
            obj.pSliderHeight = obj.nSlider*30;%px
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
            
            % place UIcontrol elements
            
            obj.margin   = 0.02 * obj.controlWidth;
            obj.height   = 0.05 * 660;
            obj.yPadding = 0.01 * 660;
            
            obj.hBtnShiftL = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               char(8592), ...
                'Callback',             { @obj.shiftDims}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.75, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnRotL = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               char(11119), ...
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
                'Callback',             { @obj.rotateView, 90}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.75, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
            obj.hBtnShiftR = uicontrol( ...
                'Parent',               obj.pControls, ...
                'Style',                'pushbutton', ...
                'Units',                'pixel', ...
                'String',               char(8594), ...
                'Callback',             { @obj.shiftDims}, ...
                'FontUnits',            'normalized', ...
                'FontSize',             0.75, ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F);
            
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
            end
            
            obj.locAndVals = annotation(obj.pControls, 'textbox', ...
                'LineStyle',            'none', ...
                'Units',                'pixel', ...
                'Position',             [obj.margin ...
                                        obj.margin+obj.height+2*obj.yPadding ...
                                        obj.controlWidth-2*obj.margin ...
                                        3*obj.height], ...
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
            
            % create uibuttongroup
            obj.hBtnG = uibuttongroup( ...
                'Parent',               obj.pSlider, ...
                'Visible',              'Off', ...
                'BackgroundColor',      obj.COLOR_BG, ...
                'ForegroundColor',      obj.COLOR_F, ...
                'ShadowColor',          obj.COLOR_B, ...
                'HighLightColor',       obj.COLOR_BG, ...
                'SelectionChangedFcn',  @(bg, event) obj.BtnGselection(bg, event));
            
            % create and position the sliders
            sliderHeight    = 6/(8*obj.nSlider);
            for iSlider = 1:obj.nSlider
                
                sliderHeight0   = 1 - (iSlider-1)/obj.nSlider - 1/(8*obj.nSlider) - sliderHeight;
                SliderWidth     = 0.75;
                SliderWidth0    = 0.2;
                IndexWidth      = 0.1;
                IndexWidth0     = 0.1;
                TextWidth       = 0.1;
                TextWidth0      = 0;
                
                obj.hTextSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'text', ...
                    'Units',            'normalized', ...
                    'Position',         [TextWidth0 ...
                                        sliderHeight0 ...
                                        TextWidth ...
                                        sliderHeight], ...
                    'FontUnits',        'normalized', ...
                    'FontSize',         0.8, ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);                
                
                obj.hSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'slider', ...
                    'Units',            'normalized', ...
                    'Position',         [SliderWidth0 ...
                                        sliderHeight0 ...
                                        SliderWidth ...
                                        sliderHeight], ...
                    'Callback',         @(src, eventdata) obj.newSlice(src, eventdata), ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_BG);
                
                addlistener(obj.hSlider(iSlider), ...
                    'ContinuousValueChange', ...
                    @(src, eventdata) obj.newSlice(src, eventdata));
                
                obj.hEditSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider, ...
                    'Style',            'edit', ...
                    'Units',            'normalized', ...
                    'Position',         [IndexWidth0 ...
                                        sliderHeight0 ...
                                        IndexWidth ...
                                        sliderHeight], ...
                    'FontUnits',        'normalized', ...
                    'FontSize',         0.8, ...
                    'Enable',           'Inactive', ...
                    'Value',            iSlider, ...
                    'ButtonDownFcn',    @obj.removeListener, ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
                
                set(obj.hEditSlider(iSlider), 'Callback', @obj.setSlider);
                
                obj.hRadioBtnSlider(iSlider) = uicontrol(obj.hBtnG, ...
                    'Style',            'radiobutton', ...
                    'Units',            'normalized', ...
                    'Tag',              num2str(iSlider), ...
                    'Position',         [SliderWidth0+SliderWidth+0.02 ...
                                        sliderHeight0 ...
                                        0.02 ...
                                        sliderHeight], ...
                    'HandleVisibility', 'off', ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
            end
            
            obj.initializeSliders
            
            obj.initializeAxis(true)
            
            if ~sum(ismember(obj.p.UsingDefaults, 'fps')) && length(obj.S) > 2
                set(obj.hBtnRun, 'String', 'Stop')
                obj.setAndStartTimer
            end
            
        end
        
        
        function prepareSliceData(obj)
            % obtain image information form
            sel_temp = obj.sel;
            sel_temp{1, end} = ':';
            obj.slice{1, 1} = squeeze(obj.img{1}(sel_temp{1, :}));
        end
        
        
        function cImage = sliceMixer(obj)
            % overrides the sliceMixer function from nvisBase and treats
            % the current data in obj.slice as truecolor values.
            if obj.isUint
                cImage = double(obj.slice{1, 1})/255;
            else
                cImage = obj.slice{1, 1};
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
                delete(ax1)
                deleteROIs()
            end
            
            obj.sel(1, ~obj.showDims) = num2cell(round(obj.S(~obj.showDims)/2));
             
            obj.prepareSliceData;

            ax      = axes('Parent', obj.pImage, 'Units', 'normal', 'Position', [0 0 1 1]);            
            obj.hImage  = imagesc(obj.sliceMixer(), 'Parent', ax);  % plot image

            hold on
            eval(['axis ', obj.p.Results.AspectRatio]);
            set(ax, ...
                'XTickLabel',   '', ...
                'YTickLabel',   '', ...
                'XTick',        [], ...
                'YTick',        []);
            colormap(ax, obj.cmap{1});
            
            view([obj.azimuthAng 90])
        end
        
        
        function initializeSliders(obj)
            % get the size, dimensionNo, and labels only for the sliders
            s = size(obj.img{1});
            labels = obj.dimLabel;
            s(     obj.showDims) = [];
            labels(obj.showDims) = [];
            
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
                
                set(obj.hEditSlider(iSlider), 'String', num2str(obj.sel{obj.mapSliderToDim(iSlider)}));
            end
        end


        function calcPanelPos(obj)
            % create a 3x4 array that stores the 'Position' information for
            % the four panels pImage, pSlider, pControl
            
            obj.figurePos = get(obj.f, 'Position');

            if obj.maximized
                controlW = obj.controlWidth;
            else
                controlW = obj.controlWidthMinimized;
            end
            
            % pImage
            obj.panelPos(1, :) =    [controlW ...
                                    obj.pSliderHeight ...
                                    obj.figurePos(3) - controlW...
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
        end
        
        
        function setPanelPos(obj)
            % change the position of the 4 panels according to the values
            % in obj.panelPos

            set(obj.pImage,     'Position', obj.panelPos(1, :));
            set(obj.pSlider,    'Position', obj.panelPos(2, :));
            set(obj.pControls,  'Position', obj.panelPos(3, :));

        end
        
        
        function createSelector(obj)
            % which dimensions are shown initially
            obj.showDims = [1 2];
            obj.mapSliderToDim   = 3:obj.nDims-1;
            % create slice selector for dimensions 3 and higher
            obj.sel        = repmat({':'}, 1, ndims(obj.img{1}));
            obj.sel(ismember(1:obj.nDims, obj.mapSliderToDim)) = num2cell(obj.p.Results.InitSlice);
        end
        
        
        function setLocValFunction(obj)
            if obj.nImages == 1
                obj.locValString = @(dim1L, dim1, dim2L, dim2, val) sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%4d\n%s:%4d\n%s:%s', ...
                    obj.COLOR_F, ...
                    dim1L, ...
                    dim1, ...
                    dim2L, ...
                    dim2, ...
                    obj.valNames{1}, ...
                    [num2sci(val) ' ' obj.p.Results.Unit{1}]);
            else
                obj.locValString = @(dim1L, dim1, dim2L, dim2, val1, val2) sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%4d\n%s:%4d\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s', ...
                    obj.COLOR_F, ...
                    dim1L, ...
                    dim1, ...
                    dim2L, ...
                    dim2, ...
                    obj.COLOR_m(1, :), ...
                    obj.valNames{1}, ...
                    [num2sci(val1) obj.p.Results.Unit{1}], ...
                    obj.COLOR_m(2, :), ...
                    obj.valNames{2}, ...
                    [num2sci(val2) obj.p.Results.Unit{2}]);
            end
        end
        
        
        function locVal(obj, point, ~)
            if ~isempty(point)
                % select all color values
                point{3} = ':';
                val = obj.slice{1, 1}(point{:});
                set(obj.locAndVals, 'String', ...
                    sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%4d\n%s:%4d\n\\color[rgb]{1,0.3,0.3}%s\n\\color[rgb]{0.3,1,0.3}%s\n\\color[rgb]{0.3,0.3,1}%s', ...
                    obj.COLOR_F, ...
                    obj.dimLabel{obj.showDims(1)}, ...
                    point{1}, ...
                    obj.dimLabel{obj.showDims(2)}, ...
                    point{2}, ...
                    num2sci(val(1)), num2sci(val(2)), num2sci(val(3))));
            else
                set(obj.locAndVals, 'String', '');
            end
        end
        
        
        function refreshUI(obj)            
            obj.prepareSliceData;            
            set(obj.hImage, 'CData', obj.sliceMixer());
            
            for iSlider = 1:obj.nSlider
                set(obj.hEditSlider(iSlider), 'String', num2str(obj.sel{obj.mapSliderToDim(iSlider)}));
                set(obj.hSlider(iSlider), 'Value', obj.sel{obj.mapSliderToDim(iSlider)});
            end
            % update 'val' when changing slice
            obj.mouseMovement();
        end
        
        
        function keyPress(obj, src, ~)
            % in case of 3D input, the image stack can be scrolled with 1 and 3
            % on the numpad
            key = get(src, 'CurrentCharacter');
            switch(key)
                case '1'
                    obj.incDecActiveDim(-1);
                case '3'
                    obj.incDecActiveDim(+1);
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

        function mouseBtnNormal(obj, pt)
        end

        function mouseBtnDouble(obj, ~, ~)
            % code executed when the user uses left double-click.
            % currently not implemented.
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
            imwrite(rot90(obj.sliceMixer(), -obj.azimuthAng/90), path);
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

            set(obj.locAndVals,         'Visible', obj.maximized)
            set(obj.hBtnSaveImg,        'Visible', obj.maximized)
            set(obj.hBtnSaveVid,        'Visible', obj.maximized*(obj.nDims > 2))

        end
        
         
        function closeRqst(obj, varargin)
            % closeRqst is called, when the user closes the figure (by 'x' or
            % 'close'). It stops and deletes the timer, frees up memory taken
            % by img and closes the figure.
%             try
%                 stop(obj.t);
%                 delete(obj.t);
%             catch
%             end
%             delete(obj.f);
            delete(obj.f);
            obj.delete
        end
        
                
        function shiftDims(obj, src, ~)
            disp('Functionality not yet implemented')
        end
        
        
        function guiResize(obj, varargin)

            obj.calcPanelPos()
            obj.setPanelPos()
            
            set(obj.pImage,     'Position', obj.panelPos(1, :));
            set(obj.pSlider,    'Position', obj.panelPos(2, :));
            set(obj.pControls,  'Position', obj.panelPos(3, :));
             
            
            n = 5;
            position = obj.positionN(n, 4);
            set(obj.hBtnShiftL, 'Position', position(1, :));
            set(obj.hBtnRotL,   'Position', position(2, :));
            set(obj.hBtnRotR,   'Position', position(3, :));
            set(obj.hBtnShiftR, 'Position', position(4, :));
            
            n = n + 1;
            position = obj.positionN(n, 3);
            set(obj.hBtnRun,    'Position', position(1, :))
            set(obj.hEditF,     'Position', position(2, :))
            set(obj.hTextFPS,   'Position', position(3, :))
            
        end
            
        
        function pos = divPosition(obj, N)
            yPos = ceil(obj.figurePos(4)-obj.margin-N*obj.height-(N-1)*obj.yPadding);
            if obj.nImages == 1
                pos = [obj.margin ...
                    yPos ...
                    obj.division-2*obj.margin ...
                    obj.height; ...
                    obj.division+obj.margin/2 ...
                    yPos ...
                    (obj.controlWidth-obj.division)-obj.margin ...
                    obj.height];
            else
                pos = [obj.margin ...
                    yPos ...
                    obj.division-2*obj.margin ...
                    obj.height; ...
                    obj.division+obj.margin/2 ...
                    yPos ...
                    (obj.controlWidth-obj.division)/2-5/4*obj.margin ...
                    obj.height; ...
                    obj.division+obj.margin/2+((obj.controlWidth-obj.division)/2-3/4*obj.margin) ...
                    yPos ...
                    (obj.controlWidth-obj.division)/2-5/4*obj.margin ...
                    obj.height];
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
        
        
        function recolor(obj)
            % is never called in nvisRGB
        end
    end
end