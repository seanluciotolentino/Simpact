function [xTicks, yTicks] = ticks(x, y)
%TICKS  Create ticks for multi-line plots.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

dx = [1/60, 5/60, 10/60, 1, 2, 5, 10, 15, 30, 60];
dy = [.1, .5, 1, 2, 5, 10, 25, 50, 100, 250, 500, 1000];

xFinal = max(x);
dxIdx = find(dx >= mean(diff(linspace(0, xFinal, 16))), 1);
xTicks = 0 : dx(dxIdx) : xFinal;

yMax = max(y(:));
dYidx = find(dy >= mean(diff(linspace(0, yMax, 15))), 1);
yTicks = 0 : dy(dYidx) : yMax + dy(dYidx);
yVec = (0 : numel(yTicks) - 1);

for ii = 1 : size(y, 2)
    dIidx = find(dy >= dy(dYidx)/floor(yMax/max(y(:, ii))), 1);
    yTicks(ii, :) = yVec*dy(dIidx);
end
end
