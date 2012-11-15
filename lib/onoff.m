function out = onoff(argin)
%ONOFF
% 
% See also class2string.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

out = [];

if nargin == 0
    onoff_test
    return
end

switch class2string(argin)
    case 'char'
        out = strcmpi(argin, 'on');
        
    case {'integer', 'real'}
        out = onoff(logical(argin));
        
    case 'logical'
        if argin
            out = 'on';
        else
            out = 'off';
        end
end
end


%%
function onoff_test

debugMsg

onoff(true)
onoff(false)
onoff(1)
onoff(0)
onoff on
onoff off

end
