function out = str2field(argin)
%STR2FIELD
%   See also field2str.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

out = argin;

if nargin == 0
    str2field_test
    return
end

out = strrep(out, '.', '0x2E');
out = strrep(out, [' ', char(183), ' '], '.');
out = strrep(out, ' ', '_');
out = strrep(out, '___', '__');
end


%% test
function str2field_test

debugMsg


end


%%
function str2field_

end
