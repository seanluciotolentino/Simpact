function [ok, msg] = backup(file)
%BACKUP

% Copyright 2009-2011 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    backup_test
    return
end

ok = false;
msg = '';

if exist(file, 'file') ~= 2
    msg = sprintf('can''t find %s', file);
    return
end

pathFile = which(file);

if isempty(pathFile)
    msg = sprintf('%s is not on MATLAB search path', file);
else
    % potentially correct character case
    file = pathFile;
end

%backup_copy
delete(timerfindall('Name', mfilename))
timerObject = timer('BusyMode', 'queue', ...
    'ExecutionMode', 'fixedSpacing', ...
    'Name', mfilename, 'ObjectVisibility', 'off', 'Period', 1e-3, ...
    'TasksToExecute', 2, 'TimerFcn', {@backup_copy, file});
start(timerObject)

ok = true;
end


%% copy
function backup_copy(timerObject, ~, file)

if get(timerObject, 'TasksExecuted') == 1
    return
end
%file = get(timerObject, 'UserData');
[filePath, fileName, fileExt] = fileparts(file);

projectFolder = jproject('folder');
archiveFolder = fullfile(projectFolder, '~archive');

if exist(archiveFolder, 'dir') ~= 7 || ~any(strfind(file, projectFolder))
    % fall-back to file file
    archiveFolder = filePath;
end

D = dir(file);
iso8601 = datestr(D.datenum, 30);
backupFile = fullfile(archiveFolder, [fileName, '.', iso8601, fileExt]);
msg = backupFile;
[status, msg] = copyfile(file, backupFile);
ok = status == 1;
%pause(2)
%debugMsg(backupFile)
if ~ok
    fprintf(2, 'Failure creating backup: %s\n', backupFile)
    return
end
fprintf(1, 'Backup: %s\n', backupFile)
end


%% test
function backup_test

debugMsg

tic
[ok, msg] = backup('ACT_cold_start_01.mat')
toc
end
