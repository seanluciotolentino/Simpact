function out = matlab
%MATLAB Version number

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

out = str2double(regexp(version, '\d+\.\d+', 'match', 'once'));
end
