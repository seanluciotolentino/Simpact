function openlog(logFile)
%OPENLOG

% Copyright 2009-2011 by Hummeling Engineering (www.hummeling.com)


if ispc
    % Windows
    winopen(logFile)
    
elseif isunix
    % Linux
    for editorC = {'gedit', 'kedit', 'vi'}
        cmd = sprintf(' %s %s &', editorC{1}, logFile);
        [status, result] = system(cmd);
        if status == 0
            break
        end
    end
    
else
    % fall-back to MATLAB editor
    edit(logFile)
end
end
