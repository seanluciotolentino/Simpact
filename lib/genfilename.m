function out = genfilename(out)
%GENFILENAME Generate a valid cross-platform file name, analogous to
%   genvarname.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

out = strrep(out, '/', '');
out = strrep(out, '\', '');
out = strrep(out, '?', '');
out = strrep(out, '%', '');
out = strrep(out, '*', '');
out = strrep(out, ':', '');
out = strrep(out, '|', '');
out = strrep(out, '"', '');
out = strrep(out, '<', '');
out = strrep(out, '>', '');
end
