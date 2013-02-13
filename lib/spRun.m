function varargout = spRun(fcn, varargin)
%SPRUN SIMPACT simulation run.
%   This function implements start, stop, pause.
%
%   See also SIMPACT, modelHIV, spTools.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

%#function spRun_start, spRun_pause, spRun_stop
%#function spRun_parallel, spRun_parallel_start, spRun_parallel_stop
%#function spRun_batch

persistent P 

if nargin == 0
    spRun_test
    return
end

if isempty(P)
    P.stop = true;
end

[varargout{1:nargout}] = eval(sprintf('%s_%s(varargin{:});', mfilename, fcn));


%% start
    function [SDS, msgLog] = spRun_start(S)
        
        SDS = [];
        msgLog = '';
        
        
        % ******* Checks *******
        if ~isstruct(S)
            return
        end
        
        if isfield(S, 'data') && isa(S.data, 'function_handle')
            handles = S;
            handles.msg('\nStarting simulation at %s\n', datestr(now))
            SDS = handles.data();
        else
            fprintf(1, 'Console run progress: <init>')
            handles = struct('msg', @spRun_start_msg, ...
                'fail', @spRun_start_fail, ...
                'progress', @spRun_start_progress, ...
                'update', @spRun_start_update);
            SDS = S;
        end
        
        reqField = 'model_function';
        if ~isfield(SDS, reqField)
            handles.fail('Error: required field %s not present', reqField)
            return
        end
        
        if exist(SDS.model_function, 'file') ~= 2
            handles.fail('Error: can''t find model function %s.m', SDS.model_function)
            return
        end
        
        
        % ******* Pre Process *******
        P.stop = false;
        daysPerYear = spTools('daysPerYear');
        handles.msg('Pre processing...')
        try
            handles.nextEvent = feval(SDS.model_function, 'handle', 'nextEvent');
            [SDS, msg] = feval(SDS.model_function, 'preprocess', SDS);  % apply changes
        catch Exception
            handles.fail(Exception)
            handles.update(SDS, '-restore')
            P.stop = true;
            rethrow(Exception)
        end
        if ~isempty(msg)
            % less severe
            handles.fail(msg)
            handles.update(SDS, '-restore')
            P.stop = true;
            return
        end
        %dateRange = datenum(SDS.end_date) - datenum(SDS.start_date);
        dateRange = (datenum(SDS.end_date) - datenum(SDS.start_date))/daysPerYear;
        handles.update(SDS, '-restore')     % update GUI
        handles.msg(' ok\n')
        
        
        % ******* Grand Event Loop *******
        handles.msg('Simulating...')
        tic
        
        for ii = 1 : SDS.iteration_limit
            % ******* Next Event *******
            try
                [SDS, t] = handles.nextEvent(SDS);   % SDS = modelHIV('nextEvent', SDS);
            catch Exception
                handles.fail(Exception)
                handles.update(SDS, '-restore')
                P.stop = true;
                rethrow(Exception)
                %return
            end
            
            
            % ******* Interruption *******
            pause(eps)  % required for GUI events, i.e., stop button
            progress = t/dateRange;
            if progress >= 1 || P.stop
                handles.progress(min(1, progress), handles)
                break
            end
            handles.progress(progress, handles) %comment this out to get rid of constant updates
        end
        
        elapsedTime = timestr(toc);
        handles.update(SDS, '-restore')     % update GUI
        
        if P.stop
            handles.fail('Warning: interrupt by user')
            
        elseif ii == SDS.iteration_limit
            nowStr = datestr(datenum(SDS.start_date) + t*daysPerYear);
            handles.fail('Warning: iteration limit reached at %s (%0.2f%%)', ...
                nowStr, progress*100)
            
        else
            handles.msg(' ok\n')
            P.stop = ~P.stop;
        end
        
        
        % ******* Post Processing *******
        handles.msg('Post processing...')
        [SDS, msg] = feval(SDS.model_function, 'postprocess', SDS);
        if isempty(msg)
            handles.msg(' ok\n')
        else
            handles.fail(msg)
        end
        handles.update(SDS, '-restore')     % update GUI
        
        
        handles.msg('Elapsed time %s, %d iterations\n', elapsedTime, ii)
        P.stop = true;
        
        
        %% start_msg
        function spRun_start_msg(msg, varargin)
            %msgLog = [msgLog, sprintf(msg, varargin{:})];
            %This is throwing errors for an unknown reason-- so I commented
            %it out. -Lucio 08/17/2012
        end
        
        
        %% start_fail
        function spRun_start_fail(msg, varargin)
            
            spRun_start_msg('\n')
            spRun_start_msg(msg, varargin{:})
            spRun_start_msg('\n')
        end
        
        
        %% start_progress
        function spRun_start_progress(fraction, varargin)
            
            fprintf(1, '\b\b\b\b\b\b')
            fprintf(1, '%5.1f%%', fraction*100)
        end
        
        
        %% start_update
        function spRun_start_update(SDSnew, varargin)
            
            %WHY fprintf(1, '\n')
            SDS = SDSnew;
            SDS.file_date = datestr(now);
        end
    end


%% pause/continue
    function spRun_pause(handles)
        
        P.stop = ~P.stop;
    end


%% stop
    function spRun_stop(handles)
        
        P.stop = true;
    end
end


%% test
function spRun_test

debugMsg

% ******* Relay to GUI Test *******
%SIMPACT


% ******* Start Default Run *******
[SDS, msg] = modelHIV('new');

[SDS, msgLog] = spRun('start', SDS);    % spRun_start

base(SDS)
base(msgLog)
end


%% parallel
function spRun_parallel

debugMsg

% ******* *******


%% parallel_start
    function spRun_parallel_start
        
        matlabpool open
    end


%% parallel_stop
    function spRun_parallel_stop
        
        matlabpool close
    end
end


%% batch
function spRun_batch(folder)
%BATCH  Perform SIMPACT batch run on folder containing MAT-files.
%   >> spRun('batch', '/path/to/folder/with/MAT/files')

debugMsg -on
debugMsg
tic

% ******* Checks *******
if nargin == 0
    debugMsg(['Enter a folder which contains MATLAB files that can ' ...
        'be run by SIMPACT, e.g., spRun(''batch'', ''/folder/to/run'')'])
    return
end

if ~ischar(folder)
    debugMsg 'Input argument must be a string'
    return
end

if exist(folder, 'dir') ~= 7
    debugMsg 'Can''t find folder'
    fprintf(2, '%s\n', folder)
    return
end

%mD = dir(fullfile(folder, '*.m'));
%matD = dir(fullfile(folder, '*.mat'));
%files = sort({mD.name, matD.name});
D = dir(fullfile(folder, '*.mat'));
files = sort({D.name});


% ******* Batch Runs *******
matlabpool open                         % uses the default configuration!

n = numel(files);
parfor ii = 1 : n
    try
        matFile = fullfile(folder, files{ii});
        MAT = load(matFile);
        
        fprintf(1, '\n ******* Run %d of %d *******\n%s\n', ii, n, matFile)
        [MAT.SDS, msgLog] = spRun('start', MAT.SDS);    % spRun_start
        fprintf(1, '\nRun %d completed without errors\n', ii)
        
        [ok, msg] = spRun_save(matFile, MAT.SDS, msgLog);
        if ~ok
            fprintf(2, ' Warning saving run %d:\n%s\n', ii, msg)
        end
        
    catch ME
        fprintf(2, ' Error in run %d:\n%s\n', ii, ME.message)
    end
end

matlabpool close


fprintf(1, '\n ******* Elapsed time: %s *******\n', timestr(toc))
debugMsg
end


%% save
function [ok, msg] = spRun_save(matFile, SDS, msgLog)

ok = false;
msg = '';


% ******* Store Data Structure *******
try
    save(matFile, 'SDS')
    ok = true;
    
catch ME
    msg = ME.message;
end


% ******* Store Message Log *******
[folder, file] = fileparts(matFile);
logFile = fullfile(folder, [file, '.txt']);

try
    fid = fopen(logFile, 'w', 'n', 'UTF-8');
    fprintf(fid, '******* %s SIMPACT console run %s *******\n', ...
        SDS.file_date, matFile);
    fprintf(fid, msgLog);
    fprintf(fid, '\n<EOF>');
    status = fclose(fid);
    ok = ok & status == 0;
    
catch ME
    msg = ME.message;
end
end


%% build
function [ok, msg] = spRun_build
%   Compiling script
%
%   Installing MCR:
%   MCR resides at /toolbox/compiler/deploy/glnxa64/MCRInstaller.bin
%   chmod a+x MCRInstaller.bin
%   sudo ./MCRInstaller.bin
%   MCR default installation folder was /opt/MATLAB/MATLAB_Compiler_Runtime
%
%   Compiling SIMPACT:
%   call this function from MATLAB >> spRun build
% 
%   Change file mode to executable:
%   chmod a+x run_simpact.sh
% 
%   Running SIMPACT:
%   ./run_simpact.sh "/opt/MATLAB/MATLAB_Compiler_Runtime/v714" batch "/path/to/MAT/files"

ok = false;
msg = '';

debugMsg -on
debugMsg


% ******* Info *******
%mbuild -setup
%[installer_path, major, minor, platform, list] = mcrinstaller;


% ******* Build Folder *******
buildFolder = fullfile(jproject('folder'), 'build');
if exist(buildFolder, 'dir') ~= 7
    [ok, msg, msgID] = mkdir(buildFolder);
    if ~ok
        % fall-back to project folder
        warning(msgID, msg)
        buildFolder = jproject('folder');
    end
end


% ******* Options *******
optionsC = {
    '-m', ...
    '-d', buildFolder, ...
    '-o', 'simpact', ...    '-a', strrep(userpath, pathsep, ''), ...
    '-a', './lib'
    };


% ******* Build Application *******
tic
debugMsg 'Building application...'
%mcc(optionsC{:}, 'SIMPACT')     % compile SIMPACT including GUI
mcc(optionsC{:}, mfilename)     % compile this
%mcc(optionsC{:}, 'jproject')     % compile jproject to test
debugMsg('ok, output in folder: %s', buildFolder)
toc


ok = true;
end


%%
function spRun_

debugMsg

% ******* *******
end


