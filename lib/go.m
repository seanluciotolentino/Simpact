function go(to)
%GO Open Windows Explorer at specified location.
% GO without input opens current directory
% GO with string input:
%  * go archive     [...]\~archive (in project folder, when it exists)
%  * go c           C:\
%  * go doc         C:\Users\<USERNAME>
%  * go matlab      C:\Program Files\MATLAB\R2009b
%  * go pref        C:\Users\<USERNAME>\AppData\MathWorks\MATLAB\R2009b
%  * go temp        C:\Users\<USERNAME>\AppData\Local\Temp
%  * go user        C:\Users\<USERNAME>\Documents\MATLAB
%  * go win         C:\Windows
% 
% GO also works with the first letter of the string input, e.g., go a, for
% archive
% 
%   See also jproject.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    to = '';
    
    if isunix
        to = '.';
    end
end

if exist(to, 'dir') == 7
    folder = to;
else
    go_folder
end

%cmd = sprintf('%%SystemRoot%%\\explorer.exe /n, /e, %s', folder);
%[status, result] = dos(cmd);
%[status, result] = system(cmd);
%ok = status == 0;
if ispc
    winopen(folder)
    
elseif isunix
    unix(['xdg-open ' strrep(folder, ' ', '\\ ')]);
    
elseif ismac
    debugMsg 'MAC currently not supported'
end


%% folder
    function go_folder
        
        homeDrive = getenv('HOMEDRIVE');
        %NIU homePath = getenv('HOMEPATH');
        
        switch lower(to)
            case {'a', 'archive'}
                folder = jproject('folder');
                archiveFolder = fullfile(folder, '~archive');
                
                if exist(archiveFolder, 'dir') == 7
                    folder = archiveFolder;
                end
                
            case 'c'
                folder = homeDrive;
                
            case {'d', 'doc', 'documents'}
                % My Documents | Documents (Vista)
                %folder = fullfile(homeDrive, homePath);
                folder = getenv('USERPROFILE');
                switch getenv('OS')
                    case 'Windows_NT'
                        if exist(fullfile(folder, 'My Documents'), 'dir') == 7
                            folder = fullfile(folder, 'My Documents');
                            
                        elseif exist(fullfile(folder, 'Documents'), 'dir') == 7
                            % Vista
                            folder = fullfile(folder, 'Documents');
                        end
                end
                
            case {'m', 'matlab'}
                folder = matlabroot;
                
            case {'p', 'pref'}
                folder = prefdir;
                
            case {'t', 'temp'}
                folder = getenv('TEMP');
                
            case {'u', 'user', 'userpath'}
                folder = strrep(userpath, pathsep, '');
                
            case {'w', 'win', 'windows'}
                folder = getenv('WINDIR');
                
            otherwise
                % current directory
                folder = cd;
        end
    end
end
