classdef DrawSlider < Draw
    
    % TODO: make axLabels a NVP
    
    properties (Access = private)
        % DISPLAYING
        locValString
        dimensionLabel
        
        % UI Elements
        pColorbar
        pImage
        pSlider
        pControls
        locAndVals
        hBtnSaveImg
        hBtnSaveVid
        hGuides         % RGB plot guides in the axes
        
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
            addParameter(obj.p, 'Position',     obj.defaultPosition,  @(x) isnumeric(x) && numel(x) == 4);
            addParameter(obj.p, 'InitSlice',    round(obj.S(1:3)/2),  @isnumeric);
            addParameter(obj.p, 'Crosshair',    1,                    @isnumeric);

            
            if obj.nImages == 1
                parse(obj.p, varargin{:});
            else
                parse(obj.p, varargin{2:end});
            end
            
            obj.cmap{1}             = obj.p.Results.Colormap;
            obj.complexMode         = obj.p.Results.ComplexMode;
            obj.resize              = obj.p.Results.Resize;
            obj.contrast            = obj.p.Results.Contrast;
            obj.cr                  = obj.p.Results.Crosshair;
            
            obj.prepareColors()
            
            obj.createSelector()     

            obj.setValNames()
            
            obj.setLocValFunction()
            
            obj.prepareSliceData()
            
            obj.prepareGUI()
            
            obj.refreshUI()
            
            obj.guiResize()
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
            obj.hGuides = gobjects(obj.nAxes, 4);
            
            for iim = 1:obj.nAxes
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
                    'Value',            obj.sel{obj.mapSliderToDim(iSlider), obj.mapSliderToDim(iSlider)}, ...
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
                    'String',               num2sci(obj.center(idh), 'padding', 'right'), ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'right', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.4, ...
                    'FontName',             'FixedWidth', ...
                    'ForegroundColor',      obj.COLOR_m(idh, :), ...
                    'Enable',               'Inactive');
                
                set(obj.hEditW(idh), ...
                    'Parent',               obj.pControls, ...
                    'String',               num2sci(obj.center(idh), 'padding', 'right'), ...
                    'Units',                'pixel', ...
                    'HorizontalAlignment',  'right', ...
                    'FontUnits',            'normalized', ...
                    'FontSize',             0.4, ...
                    'FontName',             'FixedWidth', ...
                    'ForegroundColor',      obj.COLOR_m(idh, :), ...
                    'Enable',               'Inactive');
                
                if obj.nImages == 2
                    set(obj.hBtnHide(idh), ...
                        'Parent',               obj.pControls, ...
                        'Value',                1, ...
                        'Units',                'pixel', ...
                        'String',               'Hide', ...
                        'HorizontalAlignment',  'left', ...
                        'FontUnits',            'normalized', ...
                        'FontSize',             0.4, ...
                        'ForegroundColor',      obj.COLOR_m(idh, :));                    
                end
                
                % create the colorbar axis for the colorbarpanel
                obj.hAxCb(idh)      = axes('Units',            'normal', ...
                    'Position',         [1/9+(idh-1)*4/9 1/3 1/3 1/3], ...
                    'Parent',           obj.pColorbar, ...
                    'Color',            obj.COLOR_m(idh, :));
                imagesc(linspace(0, 1, size(obj.cmap{idh}, 1)));
                colormap(obj.hAxCb(idh), obj.cmap{idh});
                caxis(obj.hAxCb(idh), [0 1])
                
                % get the current tick labeks
                ticklabels = get(obj.hAxCb(idh), 'XTickLabel');
                % prepend a color for each tick label
                ticklabels_new = cell(size(ticklabels));
                for i = 1:length(ticklabels)
                    ticklabels_new{i} = [sprintf('\\color[rgb]{%.3f,%.3f,%.3f} ', obj.COLOR_m(idh,  1), obj.COLOR_m(idh,  2), obj.COLOR_m(idh,  3)) ticklabels{i}];
                end
                set(obj.hAxCb(idh), ...
                    'XTickLabel',   ticklabels_new, ...
                    'YTickLabel',   [], ...
                    'YTick',        []);
                
            end
            
            if obj.nImages == 2
                % toggle button
                set(obj.hBtnToggle, ...
                    'Parent',               obj.pControls, ...
                    'Value',                1, ...
                    'Units',                'pixel', ...
                    'String',               'Toggle', ...
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
            
            % hide colorbar
            obj.cbShown = true;
            obj.toggleCb()
            
            % change callback of 'colorbar' icon in MATLAB toolbar
            hToolColorbar = findall(gcf, 'tag', 'Annotation.InsertColorbar');
            set(hToolColorbar, 'ClickedCallback', {@obj.toggleCb});
            
            
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
        
        
        function genControlPanelGrid(obj)
            gridSize = [3 8];
            pos = get(obj.pControls, 'Position');
            
            xPadding = 3;
            yPadding = 3;
            width  = 90;%(pos(3) - (gridSize(2)+1)*xPadding) / gridSize(2);
            height = (pos(4) - (gridSize(1)+1)*yPadding) / gridSize(1);
            
            
            % repeat arrays to create gridSize x 4 matrix
            width  = repmat(width, [1, gridSize(2)]);
            
            % set some columns to fixed width
            width([1 4]) = 75;
            if obj.nImages == 1
               width([3 6]) = 0; 
            end
            
            w0 = [xPadding cumsum(width, 2) + (1:gridSize(2)) * xPadding];
            h0 = pos(4) - yPadding - (1:gridSize(1)) * (height+yPadding);
            width  = repmat(width, [gridSize(1) 1]);
            height = repmat(height, gridSize);
            w0 = repmat(w0(1:end-1), [gridSize(1) 1]);
            h0 = repmat(h0', [1 gridSize(2)]);
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
        end
        
        
        function refreshUI(obj)
            obj.prepareSliceData;
            
            for iim = 1:obj.nAxes
                set(obj.hImage(iim), 'CData', obj.sliceMixer(iim));
                
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
                set(obj.hEditSlider(iSlider), 'String', num2str(obj.sel{obj.mapSliderToDim(iSlider), obj.mapSliderToDim(iSlider)}));
                set(obj.hSlider(iSlider), 'Value', obj.sel{obj.mapSliderToDim(iSlider), obj.mapSliderToDim(iSlider)});
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
            Pt = round(get(gca, 'CurrentPoint'));
            iim = find(src == obj.hImage);
            obj.sel{obj.showDims(iim, 1), obj.showDims(iim, 1)} = Pt(1, 2);
            obj.sel{obj.showDims(iim, 2), obj.showDims(iim, 2)} = Pt(1, 1);
            obj.refreshUI()
        end
        
        
        function setValNames(obj)
            obj.valNames = {'val1', 'val2'};
            
            if ~isempty(obj.inputNames{1})
                if numel(obj.inputNames{1}) > obj.maxLetters
                    obj.valNames{1} = obj.inputNames{1}(1:obj.maxLetters);
                else
                    obj.valNames{1} = obj.inputNames{1};
                end
            end
            
            if obj.nImages == 2 && ~isempty(obj.inputNames{2})
                if numel(obj.inputNames{2}) > obj.maxLetters
                    obj.valNames{2} = obj.inputNames{2}(1:obj.maxLetters);
                else
                    obj.valNames{2} = obj.inputNames{2};
                end
            end
            
            % find number of trailing whitespace
            wsToAdd = max(cellfun(@numel, obj.valNames)) - cellfun(@numel, obj.valNames);
            ws = {repmat(' ', [1, wsToAdd(1)]), repmat(' ', [1, wsToAdd(2)])};
            obj.valNames = strcat(obj.valNames, ws);
        end
        
        
        function setLocValFunction(obj)
            % sets the function for the locAndVal string depending on the
            % amount of input images
            if obj.nImages == 1
                obj.locValString = @(dim1L, dim1, dim2L, dim2, dim3L, dim3, val) sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%4d\n%s:%4d\n%s:%4d\n%s:%s', ...
                    obj.COLOR_F, ...
                    dim1L, ...
                    dim1, ...
                    dim2L, ...
                    dim2, ...
                    dim3L, ...
                    dim3, ...
                    obj.valNames{1}, ...
                    [num2sci(val) ' ' obj.p.Results.Unit{1}]);
            else
                obj.locValString = @(dim1L, dim1, dim2L, dim2, dim3L, dim3, val1, val2) sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%s:%4d\n%s:%4d\n%s:%4d\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s\n\\color[rgb]{%.2f,%.2f,%.2f}%s:%s', ...
                    obj.COLOR_F, ...
                    dim1L, ...
                    dim1, ...
                    dim2L, ...
                    dim2, ...
                    dim3L, ...
                    dim3, ...
                    obj.COLOR_m(1, :), ...
                    obj.valNames{1}, ...
                    [num2sci(val1) obj.p.Results.Unit{1}], ...
                    obj.COLOR_m(2, :), ...
                    obj.valNames{2}, ...
                    [num2sci(val2) obj.p.Results.Unit{2}]);
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
                    val = obj.complexPart(obj.slice{axNo}(point{obj.showDims(axNo, :)}));
                    set(obj.locAndVals, 'String', obj.locValString(...
                        obj.axLabels(1), point{1}, ...
                        obj.axLabels(2), point{2}, ...
                        obj.axLabels(3), point{3}, val));
                else
                    val1 = obj.complexPart(obj.slice{axNo, 1}(point{obj.showDims(axNo, :)}));
                    val2 = obj.complexPart(obj.slice{axNo, 2}(point{obj.showDims(axNo, :)}));
                    set(obj.locAndVals, 'String', obj.locValString(...
                        obj.axLabels(1), point{1}, ...
                        obj.axLabels(2), point{2}, ...
                        obj.axLabels(3), point{3}, val1, val2));
                end
            else
                set(obj.locAndVals, 'String', '');
            end
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
        
        
        function closeRqst(obj, varargin)
            % closeRqst is called, when the user closes the figure (by 'x' or
            % 'close'). It stops and deletes the timer, frees up memory taken
            % by img and closes the figure.
            
            delete(obj.f);
            obj.delete
        end
        
        
        function guiResize(obj, varargin)
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
            
            if obj.nImages == 2
                set(obj.hBtnToggle,   'Position', obj.controlPanelPos(3, 1, :));
                set(obj.hBtnHide(1),  'Position', obj.controlPanelPos(3, 2, :));
                set(obj.hBtnHide(2),  'Position', obj.controlPanelPos(3, 3, :));
            end
            
            set(obj.hBtnRoi(1), 'Position', obj.controlPanelPos(1, 4, :));
            set(obj.hBtnRoi(2), 'Position', obj.controlPanelPos(2, 4, :));
            set(obj.hTextSNR,   'Position', obj.controlPanelPos(3, 4, :));
            
            for iImg = 1:obj.nImages
                set(obj.hTextRoi(1, iImg),  'Position', obj.controlPanelPos(1, 4+iImg, :));
                set(obj.hTextRoi(2, iImg),  'Position', obj.controlPanelPos(2, 4+iImg, :));
                set(obj.hTextSNRvals(iImg), 'Position', obj.controlPanelPos(3, 4+iImg, :));
            end
            
            lavWidth = 200; % px
            set(obj.locAndVals, ...
                'Position', [obj.panelPos(8, 3)-lavWidth 0 lavWidth obj.panelPos(8, 4)]);
            
        end
    end
end
    
    
    
    
    
    
    
    
    
