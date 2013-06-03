function base(argin)
%BASE Assign variable to base workspace.
% 
%   See also assignin.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

assignin('base', inputname(1), argin)
fprintf(1, 'Variable %s assigned to base workspace.\n', inputname(1))
evalin('base', ['whos ', inputname(1)])
end
