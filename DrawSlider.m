classdef DrawSlider < Draw
    
    properties (Access = private)
        % DISPLAYING
        locValString
        dimensionLabel
        inputNames
        valNames
        
        % UI Elements
        pColorbar
        pImage
        pSlider
        pControls
        locAndVals
        hBtnSaveImg
        hBtnSaveVid
        
        % UI properties
        pSliderHeight
        division
        margin
        height
        yPadding
        panelPos
        figurePos
    end
    
    
    properties (Constant, Access = private)
        % UI PROPERTIES
        % default figure position and size
        defaultPosition = [ 300, 200, 1000, 800];
        axLabels = 'XYZ';  % displayed planes (names)
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
            
            if obj.nDims < 4
                % TODO: if obj.nDims == 2: open DrawSingle instead
                obj.nSlider = 3;
            elseif obj.nDims == 4
                obj.nSlider = 4;
            else
                error('Input-size not supported')
            end
            
            obj.standardTitle = inputname(1);
            
            obj.prepareParser
            
            % definer additional Prameters
            addParameter(obj.p, 'Position',     obj.defaultPosition,    @(x) isnumeric(x) && numel(x) == 4);
            addParameter(obj.p, 'InitSlice',    round(obj.S(1:3)/2),  @isnumeric);            
            
            if obj.nImages == 1
                parse(obj.p, varargin{:});
            else
                parse(obj.p, varargin{2:end});
            end
            
            obj.cmap{1}             = obj.p.Results.Colormap;
            obj.complexMode         = obj.p.Results.ComplexMode;
            obj.resize              = obj.p.Results.Resize;
            obj.contrast            = obj.p.Results.Contrast;
            
            obj.prepareColors
            
            obj.createSelector      
            
            % get names of input variables
            obj.inputNames{1} = inputname(1);
            if obj.nImages == 2
                obj.inputNames{2} = inputname(2);
            end
            
            obj.setLocValFunction
            
            obj.prepareSliceData
            
            obj.prepareGUI
            
            obj.guiResize
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
                'WindowKeyPress',       @obj.keyPress, ...
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
            for iim = 1:obj.nAxes
                ax(iim) = axes('Parent', obj.pImage(iim), 'Units', 'normal', 'Position', [0 0 1 1]);
                obj.hImage(iim)  = imagesc(obj.sliceMixer(iim), 'Parent', ax(iim));  % plot image
                hold on
                eval(['axis ', obj.p.Results.AspectRatio]);
                
                set(obj.hImage(iim), 'ButtonDownFcn', @obj.startDragFcn)
                colormap(ax(iim), obj.cmap{1});
            end
            
            % populate slider panels
            for iSlider = 1:obj.nSlider
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
                    'String',           [obj.axLabels(iSlider) ':'], ...
                    'FontUnits',        'normalized', ...
                    'FontSize',         0.8, ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
                
                obj.hSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider(iSlider), ...
                    'Style',            'slider', ...
                    'Units',            'normalized', ...
                    'Position',         [0.17 1/8 0.6 6/8], ...
                    'Min',              1, ...
                    'Max',              obj.S(iSlider), ...
                    'Value',            obj.sel{obj.dimMap(iSlider), obj.dimMap(iSlider)}, ...
                    'SliderStep',       steps, ...
                    'Callback',         @(src, eventdata) obj.newSlice(src, eventdata), ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_BG);
                
                addlistener(obj.hSlider(iSlider), ...
                    'ContinuousValueChange', ...
                    @(src, eventdata) obj.newSlice(src, eventdata));
                
                obj.hEditSlider(iSlider) = uicontrol( ...
                    'Parent',           obj.pSlider(iSlider), ...
                    'Style',            'edit', ...
                    'Units',            'normalized', ...
                    'Position',         [0.07 1/8 0.1 6/8], ...
                    'String',           num2str(obj.sel{iSlider, iSlider}), ...
                    'FontUnits',        'normalized', ...
                    'FontSize',         0.8, ...
                    'Enable',           'Inactive', ...
                    'Value',            iSlider, ...
                    'ButtonDownFcn',    @obj.removeListener, ...
                    'BackgroundColor',  obj.COLOR_BG, ...
                    'ForegroundColor',  obj.COLOR_F);
                
                set(obj.hEditSlider(iSlider), 'Callback', @obj.setSlider);
                
            end
            
            % populate control panel
            
            set(ax, ...
                'XTickLabel',   '', ...
                'YTickLabel',   '', ...
                'XTick',        [], ...
                'YTick',        []);
            
        end
        
        
        function setPanelPos(obj)
            pos = get(obj.f, 'Position');
            
            colorbarHeight = 80; % px
            slidersHeight  = 30;   % px
            controlHeight  = 100;  % px
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
        
        
        function createSelector(obj)
            % which dimensions are shown initially
            obj.showDims = [2 3; 1 3; 1 2];
            obj.dimMap   = 1:4;
            % create slice selector for dimensions 3 and higher
            obj.sel        = repmat({':'}, obj.nAxes, ndims(obj.img{1}));
            for iim = 1:obj.nAxes
                obj.sel(iim, obj.dimMap == iim) = num2cell(obj.p.Results.InitSlice(iim));
            end
        end
        
        
        function refreshUI(obj)
            obj.prepareSliceData;
            
            for iim = 1:obj.nAxes
                set(obj.hImage(iim), 'CData', obj.sliceMixer(iim));
            end
            
            for iSlider = 1:obj.nSlider
                set(obj.hEditSlider(iSlider), 'String', num2str(obj.sel{obj.dimMap(iSlider), obj.dimMap(iSlider)}));
                set(obj.hSlider(iSlider), 'Value', obj.sel{obj.dimMap(iSlider), obj.dimMap(iSlider)});
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
        
        
        function keyPress(obj, src, ~)
            % in case of 3D input, the image stack can be scrolled with 1 and 3
            % on the numpad
            key = get(src, 'CurrentCharacter');
            switch(key)
                case '1'
                    obj.incDecActiveDim(-1);
                case '3'
                    obj.incDecActiveDim(+1);
                case '4'
                    obj.incDecActiveDim(-1);
                case '6'
                    obj.incDecActiveDim(+1);
                case '7'
                    obj.incDecActiveDim(-1);
                case '9'
                    obj.incDecActiveDim(+1);
            end
        end
        
        
        function setLocValFunction(obj)
            obj.locValString = 'WIP';
        end
        
        
        function locVal(obj, point)
            
        end
        
        
        function closeRqst(obj, varargin)
            % closeRqst is called, when the user closes the figure (by 'x' or
            % 'close'). It stops and deletes the timer, frees up memory taken
            % by img and closes the figure.
            
            delete(obj.f);
            obj.delete
        end
        
        
        function guiResize(obj, varargin)
            obj.setPanelPos()
            
            for iim = 1:obj.nAxes
                set(obj.pImage(iim),  'Position', obj.panelPos(iim, :));
                set(obj.pSlider(iim), 'Position', obj.panelPos(iim+obj.nAxes, :));
            end
            set(obj.pColorbar, 'Position', obj.panelPos(7, :));
            set(obj.pControls, 'Position', obj.panelPos(8, :));
        end
    end
end
    
    
    
    
    
    
    
    
    
