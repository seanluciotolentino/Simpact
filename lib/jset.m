function jset(jObject, varargin)
%JSET support@mathworks.nl solution for setting Java object callbacks.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

hObject = handle(jObject, 'CallbackProperties');
set(hObject, varargin{:})
end
