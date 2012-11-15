function out = caller(depth)
%CALLER Caller function name
%
%   See also fig.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    depth = 0;
end

stack = dbstack;
stackCount = length(stack);

if stackCount == 1
    out = 'Command Window';
    return
end

idx = min([depth + 2, stackCount]);
out = stack(idx).name;
end
