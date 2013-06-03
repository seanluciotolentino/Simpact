function out = roundd(in, precision)
%ROUNDD Round with decimal precision
%   ROUNDD(pi, 2)
%   ans = 
%        3.14

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

out = round(in*10^precision)/10^precision;
end
