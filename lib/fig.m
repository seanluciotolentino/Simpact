function hFig = fig(varargin)
%FIG   Create new (or clear existing) caller-unique figure window.
% 
%   See also figure, caller.

% Copyright 2009-2011 by Hummeling Engineering (www.hummeling.com)

name = '';

if nargin == 0
    figPrp = [];

else
    argin = varargin{1};

    if isstruct(argin)
        figPrp = argin;
    
    elseif ischar(argin)
        name = [' - ', argin];
    end
end

fcns = regexp(caller(1), '[^/]+', 'match');

figPrp.DefaultLineLineWidth = 1;
figPrp.DockControls = 'off';
figPrp.HandleVisibility = 'off';
figPrp.IntegerHandle = 'off';
%figPrp.Name = [caller(1), name];
if ~isfield(figPrp, 'Name')
    figPrp.Name = [fcns{end}, name];
end
figPrp.NumberTitle = 'off';

hFig = findall(0, 'Name',figPrp.Name, 'Type','figure');
if isempty(hFig)
    hFig = figure(figPrp);
else
    clf(hFig)
    set(hFig, figPrp)
    %figure(hFig) % give focus
end

end
