function debugMsg(msg, varargin)
%DEBUGMSG

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

fid = 2;

if nargin == 0
    msg = sprintf('\b');    % backspace
    fid = 1;
    
elseif nargin > 1
    msg = sprintf(msg, varargin{:});
end

switch msg
    case '-on'
        setappdata(0, mfilename, true)
        return
        
    case '-off'
        setappdata(0, mfilename, false)
        return
end

if ~isappdata(0, mfilename)
    setappdata(0, mfilename, true)
end

if ~getappdata(0, mfilename)
    return
end

stack = dbstack;

if isdeployed
    link = sprintf(' %s', stack(2).name);
else
    link = sprintf(' <a href="matlab: opentoline(''%s'',%u)">%s</a>', ...
        which(stack(2).file), stack(2).line, stack(2).name);
end

fprintf(fid, ' ******* %s%s %s *******\n', datestr(now), link, msg)
end
