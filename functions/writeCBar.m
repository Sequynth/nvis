function writeCBar(cmap, CW, savename,scaling)

N = size(cmap, 1);

x = flip(1:N);

range = [ CW(1) - CW(2)/2, CW(1) + CW(2)/2];

aspectRatio = 0.08;

cbWidth = round(scaling*75);
cbHeight = cbWidth / aspectRatio;

margin = round(scaling*50);

f = figure('Units','pixels', 'Position', [100 100 3*margin+cbWidth 2*margin+cbHeight], 'Visible', 'off');
colormap(cmap)
hIm = imagesc(x');%, 'units', 'pixels', 'Position', [margin margin cbWidth cbHeight]);

set(hIm.Parent, 'units', 'pixels', 'Position', [margin margin cbWidth cbHeight]);


delta = diff(range) / N/2;
data = linspace(range(1) + delta, range(2) - delta, N);

set(hIm, 'CData', linspace(0, 1, N)')

set(hIm.Parent, ['YTick' 'Mode'], 'auto')
set(hIm, 'YData', data)
set(hIm.Parent, 'YLim', range)

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

