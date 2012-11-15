function objectStr = class2string(object)
%CLASS2STRING String representation of class.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    class2string_test
    return
end

objectStr = class(object);

switch objectStr
    case 'logical'
        
    case 'char'
        
    case {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'}
        objectStr = 'integer';
        
    case {'single', 'double'}
        objectStr = 'real';
        
    case 'cell'
        
    case 'struct'
        
    case 'function_handle'
        
    otherwise
        % User–defined MATLAB class or Java class
end
end
