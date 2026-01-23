function writeCBar(cmap, varargin)
% creates a colorbar and saves it to file
% cmap:     N x 3 colormap
% clim:     colormap limits
% savename: filename of the created image
% scaling:  scaling factor to adjust font size

p = inputParser;


% Required input
addRequired(p, 'cmap', @(x) isnumeric(x) && size(x,2) == 3);
% Name–value parameters
addParameter(p, 'clim',     [0 1],          @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));
addParameter(p, 'savename', 'colorbar.png', @(x) ischar(x) || isstring(x));
addParameter(p, 'scaling',  1,              @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'label',    '',             @(x) ischar(x) || isstring(x));

% Parse inputs
parse(p, cmap, varargin{:});

% Extract results
clim     = p.Results.clim;
savename = p.Results.savename;
scaling  = p.Results.scaling;
label    = p.Results.label;

N = size(cmap, 1);

x = flip(1:N);

aspectRatio = 0.08;

cbWidth = round(scaling*75);
cbHeight = cbWidth / aspectRatio;

margin = round(scaling*50);

f = figure('Units','pixels', 'Position', [100 100 3*margin+cbWidth 2*margin+cbHeight], 'Visible', 'off');
colormap(cmap)
hIm = imagesc(x');

set(hIm.Parent, 'units', 'pixels', 'Position', [margin margin cbWidth cbHeight]);


delta = diff(clim) / N/2;
data = linspace(clim(1) + delta, clim(2) - delta, N);

set(hIm, 'CData', linspace(0, 1, N)')

set(hIm.Parent, ['YTick' 'Mode'], 'auto')
set(hIm, 'YData', data)
set(hIm.Parent, 'YLim', clim)

ylabel(label)

% get tick positions
ticks = get(hIm.Parent, 'YTick');
% prepend a color for each tick label
ticks_new = cell(size(ticks));
for ii = 1:length(ticks)
    % ticks_new{ii} = [sprintf('\\color[rgb]{%.3f,%.3f,%.3f} ', obj.COLOR_m(idi,  :)) num2str(ticks(ii))];
    ticks_new{ii} = num2str(ticks(ii));
end
set(hIm.Parent, 'YTickLabel', ticks_new);
% change the y direction of the colorbars
set(hIm.Parent, 'YDir', 'normal')
set(hIm.Parent, 'YAxisLocation', 'Right')
% hide xTicks and labels
set(hIm.Parent, 'XTick', [])
set(hIm.Parent, 'XTickLabel', [])
set(hIm.Parent, 'FontSize', scaling*24)

exportgraphics(hIm.Parent, savename, 'resolution', 300)

close(f)

