function varargout = jproject(fcn, varargin)
%JPROJECT Java project menu.
%   JPROJECT opens a Java dialog from which a project van be selected and
%   projects can be added and removed.
%
%   JPROJECT('folder') returns the last selected project folder.
% 
%   Requires filedate.

% Copyright 2009-2011 by Hummeling Engineering (www.hummeling.com)

%#function jproject_folder, jproject_username

persistent P

if isempty(P)
    P.verbose = false;
end

if nargin
    [varargout{1:nargout}] = eval(sprintf('%s_%s(varargin{:})', mfilename, fcn));
    return
end

fprintf(1, ' ******* %s %s *******\n', datestr(now), mfilename)

import javax.swing.JFileChooser
import javax.swing.UIManager

[Prefs, icon] = jproject_prefs;

fileChooser = JFileChooser();
lastFile = java.io.File(Prefs.lastProject);
fileChooser.setCurrentDirectory(lastFile.getParentFile())
fileChooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY)

%jproject_dialog
jproject_lucioalt

jproject_update

%% lucio alt open
    function jproject_lucioalt
        projectFolder = fileparts(fileparts(which(mfilename)));
        %itemC = {Prefs.project};
        if exist(projectFolder, 'dir') ~= 7
                warning('JPROJECT:open','Project %s doesn''t exist', projectFolder)
                jproject
                return
        end

        jproject_setPath(projectFolder)
        jproject_dialog_open_archive

        if exist('debugMsg', 'file')
            debugMsg -on
        end

        Prefs.lastProject = projectFolder;
        jproject_save

        if exist('go', 'file') ~= 2
            return
        end


        %% archive
        function jproject_dialog_open_archive

            archiveFolder = fullfile(projectFolder, '~archive');
            if exist(archiveFolder, 'dir') == 7
                return
            end

            [ok, msg, msgID] = mkdir(archiveFolder);
            if ~ok
                warning(msgID, msg)
            end
        end
    end

%% dialog
    function jproject_dialog
        
        import javax.swing.JOptionPane
        
        labelC = jproject_label(Prefs.project);
        lastLabelC = jproject_label({Prefs.lastProject});
        spaceString = '<html>&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;<html>';
        addString = 'Add project...';
        removeString = 'Remove project...';
        
        itemC = {labelC{:}, spaceString, addString, removeString};
        if isempty(strcmp(lastLabelC{1}, itemC))
            % empty lastProject or obsolete (removed) project
            lastLabelC = {addString};
        end
        
        choice = JOptionPane.showInputDialog([], 'Project', Prefs.name, ...
            JOptionPane.PLAIN_MESSAGE, icon, itemC, lastLabelC{1});
        drawnow
        
        if isempty(choice)
            % cancelled
            return
        end
        
        switch choice
            case spaceString
                jproject_dialog
                
            case addString
                jproject_add
                jproject_dialog
                
            case removeString
                jproject_remove
                jproject_dialog
                
            otherwise
                jproject_dialog_open
        end
        
        
        %% open
        function jproject_dialog_open
            
            projectFolder = Prefs.project{strcmp(choice, itemC)};
            
            if exist(projectFolder, 'dir') ~= 7
                warning('JPROJECT:open','Project %s doesn''t exist', projectFolder)
                jproject
                return
            end
            
            jproject_setPath(projectFolder)
            jproject_dialog_open_archive
            
            if exist('debugMsg', 'file')
                debugMsg -on
            end
            
            Prefs.lastProject = projectFolder;
            jproject_save
            
            if exist('go', 'file') ~= 2
                return
            end
            
            
            %% archive
            function jproject_dialog_open_archive
                
                archiveFolder = fullfile(projectFolder, '~archive');
                if exist(archiveFolder, 'dir') == 7
                    return
                end
                
                [ok, msg, msgID] = mkdir(archiveFolder);
                if ~ok
                    warning(msgID, msg)
                end
            end
        end
    end


%% add
    function jproject_add
        
        if fileChooser.showDialog([], 'Add Project') ~= fileChooser.APPROVE_OPTION
            return
        end
        folder = char(fileChooser.getSelectedFile);
        
        if exist(folder, 'dir') ~= 7
            jproject_add
        end
        
        if any(strcmpi(folder, Prefs.project))
            warning('JPROJECT:add', 'Project %s already present', folder)
            return
        end
        
        project = {folder, Prefs.project{:}};
        [~, idx] = sort(jproject_label(project));
        Prefs.project = project(idx);
        Prefs.lastProject = folder;
        
        jproject_save
    end


%% save
    function jproject_save
        
        matFile = jproject_file;
        save(matFile, 'Prefs')
    end


%% check
    function [ok, msg] = jproject_check(folders)
        
        ok = false;
        msg = '';
        
        for thisProject = folders(:)'
            
            if exist(thisProject{1}, 'dir') == 7
                continue
            end
            
            msg = sprintf('Can''t find project %s', thisProject{1});
            if P.verbose
                fprintf(2, '%s\n', msg)
            end
        end
        
        P.verbose = false;      % once per session is enough
        ok = true;
    end


%% remove
    function jproject_remove
        
        import javax.swing.JOptionPane
        
        choice = JOptionPane.showInputDialog([], 'Remove Project', Prefs.name, ...
            JOptionPane.PLAIN_MESSAGE, icon, Prefs.project, Prefs.project{1});
        
        if isempty(choice)
            return
        end
        
        removeIdx = strcmp(choice, Prefs.project);
        Prefs.project(removeIdx) = [];
        jproject_save
    end


%% prefs
    function [Prefs, icon] = jproject_prefs
        
        import javax.swing.ImageIcon
        
        Prefs0 = struct('project', {{}}, 'lastProject', '');
        icon = [];

        matFile = jproject_file;
        
        Prefs = Prefs0;     % fail-save
        
        if exist(matFile, 'file') ~= 2
            jproject_save
        end
        
        %ERR Prefs = Prefs0;     % fail-save
        load(matFile)
        
        for thisField = fieldnames(Prefs)'
            Prefs0.(thisField{1}) = Prefs.(thisField{1});
        end
        
        Prefs = Prefs0;     % assign
        
        [ok, msg] = jproject_check(Prefs.project);
        
        
        % ******* Project Specifics *******
        Prefs.name = 'Start Project';
        Prefs.icon = 'HummelingEngineering.png';
        jproject_prefs_specifics
        if exist(Prefs.icon, 'file') == 2
            icon = ImageIcon(which(Prefs.icon));
        end
        
        
        %% prefs_specifics
        function jproject_prefs_specifics
            
            if exist('shortcut', 'file') ~= 2
                return
            end
            
            S = shortcut;
            
            if isfield(S, 'name') && ~isempty(S.name)
                Prefs.name = ['Start ', S.name, ' Project'];
            end
            
            if ~isfield(S, 'icon') || exist(S.icon, 'file') ~= 2
                return
            end
            
            supportedExt = {'.jpeg', '.jpg', '.png', '.gif'};
            [~, file, ext] = fileparts(S.icon);
            if any(strcmpi(ext, supportedExt))
                Prefs.icon = S.icon;
                return
            end
            
            for extC = supportedExt
                % try to find a supported image
                S.icon = [file, extC{1}];
                if exist(S.icon, 'file') == 2
                    Prefs.icon = S.icon;
                    break
                end
            end
        end
    end


%% label
    function labelC = jproject_label(folderC)
        
        %labelC = regexp(folderC(:), '.*\\([^\\]+)', 'tokens', 'once');
        pattern = strrep(sprintf('.*%s([^%s]+)', filesep, filesep), '\', '\\');    % win/linux
        labelC = regexp(folderC(:), pattern, 'tokens', 'once');
        
        for jj = 1 : numel(labelC)
            if isempty(labelC{jj})
                labelC{jj} = '';
                continue
            end
            labelC{jj} = labelC{jj}{end};
        end
    end


%% file
    function file = jproject_file
        
        thisFolder = fileparts(which(mfilename));
        file = fullfile(thisFolder, [mfilename, '.mat']);
    end


%% folder
    function folder = jproject_folder()
        
        folder = pwd;
        
        if isdeployed
            return
        end
        
        Prefs = jproject_prefs;
        
        [ok, msg] = jproject_check(Prefs.project);
        if ~ok
            return
        end
        
        folder = Prefs.lastProject;
    end
end


%% setPath
function jproject_setPath(folder)

evalin('base', 'clear classes')

path(pathdef)   % doesn't remove user path(s)

if exist(folder, 'dir') == 7
    cd(folder)
    addpath(folder, '-end')
end

libFolder  = fullfile(folder, 'lib');
if exist(libFolder, 'dir') == 7
    libPaths = genpath(libFolder);
    libPaths = jproject_pathArch(libPaths);
    addpath(libPaths, '-end')   % add lib folder & subfolders
    
    warnState = warning('off', 'MATLAB:Java:DuplicateClass');
    javaaddpath(libFolder)      % add lib folder to dynamic Java path
    for thisJar = dir(fullfile(libFolder, '*.jar'))'
        javaaddpath(fullfile(libFolder, thisJar.name), '-end')
    end
    warning(warnState)
end

srcFolder  = fullfile(folder, 'src');
if exist(srcFolder, 'dir') == 7
    addpath(srcFolder, '-end') % add src folder
end
end


%% pathArch: remove paths for other computer architectures
function paths = jproject_pathArch(paths)

arch = {'win32',  'win64', 'glnx86', 'glnxa64','maci', 'maci64', 'sol64'};
thisArch = computer('arch');
archIdx = strcmp(thisArch, arch);
removeArch = sprintf('|%s', arch{~archIdx});
pattern = sprintf('[^;]+(%s)[^;]*;', removeArch(2:end));
paths = regexprep(paths, pattern, '', 'ignorecase');
end


%% update
function jproject_update

files = which(mfilename, '-all');

if numel(files) == 1
    return
end

% ******* Update *******
filedates = filedate(files);
[~, latestIdx] = max(filedates);
latestFile = files{latestIdx};
files(latestIdx) = [];

for thisFile = files'
    if abs(filedate(latestFile) - filedate(thisFile{1})) < 1/86400
        continue
    end
    debugMsg
    fprintf(1, 'Old: %s\n', thisFile{1})
    fprintf(1, 'New: %s\n', latestFile)
    [status, msg, msgID] = copyfile(latestFile, thisFile{1}, 'f');
    if ~status
        warning(msgID, msg)
    end
end
end


%% username
function username = jproject_username

username = getenv('USERNAME');
end


%%
function jproject_

% ******* *******

end
