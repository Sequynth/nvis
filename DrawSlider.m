classdef DrawSlider < Draw
    
    properties (Access = private)
        % DISPLAYING
        locValString
        dimensionLabel
        inputNames
        valNames
        
        % UI Elements
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
    
	methods
		function obj = DrawSlider(in, varargin)
			obj@Draw(in, varargin(:))
			
			obj.standardTitle = inputname(1);
			
			obj.prepareParser()
			
			% definer additional Prameters
			
			if obj.nImages == 1
                parse(obj.p, varargin{:});
            else
                parse(obj.p, varargin{2:end});
            end
			
			obj.activDim = 3;
			% get names of input variables
            obj.inputNames{1} = inputname(1);
            if obj.nImages == 2
                obj.inputNames{2} = inputname(2);
            end
			
			obj.setLocValFunction
			
			obj.prepareGUI()
            
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
			end
            
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
			
			% set UI elements
			
			% populate image panels
			for iim = 1:3
				ax(iim) = axes('Parent', obj.pImage(iim), 'Units', 'normal', 'Position', [0 0 1 1]);
				obj.hImage(iim)  = imagesc(obj.sliceMixer(), 'Parent', ax(iim));  % plot image
				hold on
				eval(['axis ', obj.p.Results.AspectRatio]);
				
				set(obj.hImage(iim), 'ButtonDownFcn', @obj.startDragFcn)
				colormap(ax, obj.cmap{1});
			end
			
			% populate slider panels
			
			% populate control panel
			
			set(ax, ...
				'XTickLabel',   '', ...
				'YTickLabel',   '', ...
				'XTick',        [], ...
				'YTick',        []);
		
		end
		
		
		function setPanelPos(obj)
			pos = get(obj.f, 'Position');
			
			controlHeight = 200; % px
			slidersHeight = 100; % px
			% pImage(..), pSliders, pControl
			for iim = 1:3
				obj.panelPos(iim, :) = [(iim-1)*1/3*pos(3) ...
									controlHeight+slidersHeight ...
									1/3*pos(3) ...
									pos(4)-controlHeight-slidersHeight];
			end
			% pSliders
			obj.panelPos(4, :) = [0 ...
							controlHeight ...
							pos(3) ...
							slidersHeight];
			obj.panelPos(5, :) = [0 ...
							0 ...
							pos(3) ...
							controlHeight];
		end
		
		
		function createSelector(obj)
            % which dimensions are shown initially
            obj.showDims = [2 3; 1 3; 1 2];
            obj.dimMap   = 1:4;
            % create slice selector for dimensions 3 and higher
            obj.sel        = repmat({':'}, 1, ndims(obj.img{1}));
            obj.sel(ismember(1:obj.nDims, obj.dimMap)) = num2cell(obj.p.Results.InitSlice);
        end
		
		
		function refreshUI(obj)            
            obj.prepareSliceData; 

			for iim = 1:3
				set(obj.hImage(iim), 'CData', obj.sliceMixer(iim));
			end
            
            for iSlider = 1:obj.nSlider
                set(obj.hEditSlider(iSlider), 'String', num2str(obj.sel{obj.dimMap(iSlider)}));
                set(obj.hSlider(iSlider), 'Value', obj.sel{obj.dimMap(iSlider)});
            end
            % update 'val' when changing slice
            obj.mouseMovement();
            
            
%             if ~isempty(Sroi) | ~isempty(Nroi)
%                 % only calculate SNR, when there are ROIs to calculate
%                 calcROI();
%             end
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
		
		
		function closeRqst(obj, varargin)
            % closeRqst is called, when the user closes the figure (by 'x' or
            % 'close'). It stops and deletes the timer, frees up memory taken
            % by img and closes the figure.

            delete(obj.f);
            obj.delete
        end
		
		
		function guiResize(obj, varargin)
            obj.setPanelPos()
            
			for iim = 1:3
				set(obj.pImage(iim),     'Position', obj.panelPos(iim, :));
			end
            set(obj.pSlider,    'Position', obj.panelPos(4, :));
            set(obj.pControls,  'Position', obj.panelPos(5, :));
		end
end










