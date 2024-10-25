function map = randomColors(m)
%RANDOMCOLORS   colormap with random colors
%   RANDOMCOLORS(M) returns an M-by-3 matrix containing a random color for
%   each entry. RANDOMCOLORS, by itself, is the same length as the current
%   figure's colormap. If no figure exists, MATLAB uses the length of the
%   default colormap.
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(randomColors)
%

if nargin < 1
    f = get(groot,'CurrentFigure');
    if isempty(f)
        m = size(get(groot,'DefaultFigureColormap'),1);
    else
        m = size(f.Colormap,1);
    end
end

values =  rand(256, 3);

P = size(values, 1);
map = interp1(1:size(values,1), values, linspace(1,P,m), 'linear');
