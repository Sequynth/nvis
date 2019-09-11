function str = num2sci(val, varargin)
% The input 'val' is interpreted as 'factor*10^expon' with abs(a) <
% 10. The output is of the form 'factorNew*10^exponNew', where
% 'exponNew' is a multiple of three and factorNew is between 1 and 999
%
%NAME-VALUE PAIRS
%
%   'padding'
%   parameter that allows to specify, on which side whitespace should be
%   added for proper alignment of the string.
%   'left':     whitespace is added to the left side of the string, useful
%               when the data is aligned left (default).
%   'right':    whitespace is added to the right side of the string, useful
%               when the data is aligned right.
%   'both':     whitespace is added to both sides of the string.
%   'none':     no whitespace is added, useful when the data is presented
%               in text.
%
%   'precision'
%   type: positive whole number
%   specifies the precision of the outputstring, default is 2
%   

%__________________________________________________________________________
%            2019-07-03
% Author:    Johannes Fischer
%            University Medical Center FREIBURG
%            Dept. of Radiology, Medical Physics
%
%            Killianstr. 5a · 79106 Freiburg
%            johannes.fischer@uniklinik-freiburg.de
%            www.mr.uniklinik-freiburg.de

p = inputParser;

addParameter(p, 'padding',      'left', @(x) ismember(x, {'left', 'right', 'both', 'none'}));
addParameter(p, 'precision',    2',     @(x) round(x)==x & x > 0);
addParameter(p, 'latex',        0,      @isnumeric);

parse(p, varargin{:});

padding     = p.Results.padding;
precision   = p.Results.precision;
latex       = p.Results.latex;

% if necessary, convert val to floating point
if ~isfloat(val)
    val = single(val);
end

if nargin == 1
    % if padding is not specified, set it to default value
    padding = 'left';
end


if isnan(val) | isinf(val)
    str = [' ' num2str(val)];
elseif val == 0
    str = sprintf('%1$+*2$.*3$f', 0, 5+precision, precision);
elseif(isnumeric(val))
    % value of the exponent
    expon = floor(log10(abs(val)));
    % value of the factor
    factor = val/10^expon;
    
    r = mod(expon, 3);
    
    % new exponent
    exponNew = expon - r;
    
    % new factor
    factorNew = factor * 10^r;
    
    if exponNew ~= 0
        % the following line creates a string that is 7 characters long and
        % might have padding to the left. No right padding needs to be
        % added, i.e. only in the case of 'right' and 'none' must the left
        % padding be removed
        if latex
            str = sprintf('%1$+*2$.*3$f\\cdot10^{%4$+03d}', factorNew, 5+precision, precision, exponNew);
        else
            str = sprintf('%1$+*2$.*3$fe%4$+03d', factorNew, 5+precision, precision, exponNew);
        end
        
        switch(padding)
            case {'right', 'none'}
                str = strtrim(str);
            case {'left', 'both'}
                % do nothing
            otherwise
                error('padding must be one of the following: left, right, both, none')
        end
    else
        % the following line creates a string that is left padded
        str = sprintf('%1$+*2$.*3$f', factorNew, 5+precision, precision);
        
        switch(padding)
            case 'right'
                str = strtrim(str);
                str = [str '    '];
            case 'none'
                str = strtrim(str);
            case 'both'
                str = [str '    '];
            case 'left'
                % do nothing
            otherwise
                error('padding must be one of the following: left, right, both, none')
        end
        
    end
else
    str = 'unknown';
end