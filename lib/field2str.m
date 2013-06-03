function out = field2str(argin)
%FIELD2STR
%   See also str2field.

% Copyright 2009-2011 by Hummeling Engineering (www.hummeling.com)

out = '';

if nargin == 0
    field2str_test
    return
end

out = strrep(argin, '_', ' ');
%out = strrep(out, '.', ' � ');
out = strrep(out, '.', [' ', char(183), ' ']);
out = strrep(out, '0x2E', '.');
%out = strrep(out, '0xB7', ' � ');
out = strrep(out, '0x28', '(');
out = strrep(out, '0x29', ')');
end


%% test
function field2str_test

debugMsg

field2str(genvarname('.'))
field2str(genvarname('p.'))
field2str(genvarname('p_r'))

end
