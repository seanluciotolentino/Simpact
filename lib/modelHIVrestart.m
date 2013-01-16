function varargout = modelHIVrestart(fcn, varargin)
%MODELHIV SIMPACT HIV model function which controls the data structure.
%   This function implements new, nextEvent, preprocess, initialise, menu.
%
%   See also SIMPACT, spRun, spTools.

% File settings:
%#ok<*DEFNU>

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

persistent P0

if nargin == 0
    modelHIVrestart_test
    return
end

switch fcn
    case 'handle'
        cmd = sprintf('@%s_%s', mfilename, varargin{1});
        
    otherwise
        cmd = sprintf('%s_%s(varargin{:})', mfilename, fcn);
end

[varargout{1:nargout}] = eval(cmd);


%% preprocess
    function [SDS,msg] = modelHIVrestart_preprocess(SDS,P0)
        % Invoked by spRun('start') during initialisation       
        msg = '';                
        P0.firedEvent = [];
        for ii = 1:P0.numberOfEvents 
            X = P0.event(ii).P;
            feval(P0.event(ii).restore,SDS,X);
        end
        
    end


%% nextEvent
    function [SDS, t] = modelHIVrestart_nextEvent(SDS)
        
        % ******* 1: Fetch Event Times *******
        if P0.now>0
        for ii = 1 : P0.numberOfEvents
            %P0.event(ii).time = P0.event(ii).eventTime(SDS);  % earliest per event
            P0.eventTimes(P0.event(ii).index) = P0.event(ii).eventTimes(SDS, P0);
        end
        end
        
        
        % ******* 2: Find First Event & Its Entry *******
        [P0.eventTime, firstIdx] = min(P0.eventTimes);  % index into event times
        if P0.eventTime <= 0
%             problem = find(P0.cumsum >= firstIdx, 1) - 1
%             time = P0.eventTime
            %debugMsg 'eventTime == 0' %you can ignore this mention as present -Fei  08/17/2012
            P0.eventTime = 0.0001;
            %keyboard
        end
        if ~isfinite(P0.eventTime)
            t = Inf;
            return
        end
        eventIdx = find(P0.cumsum >= firstIdx, 1) - 1;  % index of event
        P0.index = firstIdx - P0.cumsum(eventIdx);      % index into event
        
        
        % ******* 3: Update Time *******
        %SDS.now(end + 1, 1) = SDS.now(end) + P0.eventTime;
        P0.now = P0.now + P0.eventTime;
        P0.maleAge = P0.maleAge + P0.eventTime;
        P0.femaleAge = P0.femaleAge + P0.eventTime;
        P0.meanAge = P0.meanAge + P0.eventTime;
        P0.timeSinceLast = P0.timeSinceLast + P0.eventTime;
        % P0.riskyBehaviour =  P0.meanAge + P0.ageDifference + P0.relationCount + P0.relationsTerm + P0.serodiscordant;        
        %{
        P0.meanAgeSex 
        P0.ageDifferenceSex
        P0.relationTypeSex
        P0.relationCountSex
        P0.serodiscordantSex
        P0.disclosureSex 
            %}
        
        P0.subset = P0.true;
        P0.subset(~P0.aliveMales, :) = false;
        P0.subset(:, ~P0.aliveFemales) = false;
        
        
        % ******* 4: Advance All Events *******
        for ii = 1 : P0.numberOfEvents
            P0.event(ii).advance(P0)
        end
        
        
        % ******* 5: Fire First Event *******
        [SDS, P0] = P0.event(eventIdx).fire(SDS, P0);
        
        P0.firedEvent(end + 1) = eventIdx;
        t = P0.now;
        
    end
end


%% postprocess
function [SDS, msg] = modelHIVrestart_postprocess(SDS)

msg = '';

if any(diff(SDS.relations.time(:, SDS.index.start)) < 0)
    msg = 'Warning: decreasing relation formation';
end

if isfinite(SDS.males.born(end))
    msg = 'Warning: male population limit reached, increase number of males';
end
if isfinite(SDS.females.born(end))
    msg = 'Warning: female population limit reached, increase number of females';
end

SDS.relations.time = roundd(SDS.relations.time, 8);
end


%% new
function [SDS, msg] = modelHIVrestart_new

msg = '';

% ******* Defaults *******
time = now;
SDS = [];
SDS.user_name = getenv('USERNAME');
SDS.file_date = datestr(time);
SDS.data_file = sprintf('data%s.m', datestr(time, 30));
SDS.model_function = mfilename;
SDS.population_function = '';

SDS.start_date = '01-Jan-1985';
SDS.end_date = '31-Dec-2010';
SDS.number_of_communities = 2;

SDS.iteration_limit = 10000;
SDS.number_of_males = 30;
SDS.number_of_females = 30;
SDS.initial_number_of_males = 20;
SDS.initial_number_of_females = 20;
SDS.number_of_community_members = floor(SDS.initial_number_of_males/2); % 4 communities
SDS.sex_worker_proportion = 0.04;
SDS.number_of_relations = SDS.number_of_males*SDS.number_of_females;
SDS.number_of_tests =  (SDS.number_of_males+SDS.number_of_females);
SDS.number_of_ARV = (SDS.number_of_males+SDS.number_of_females);

%SDS.float = 'single';           % e.g. 3.14 (32 bit floating point)
SDS.float = 'double';           % e.g. 3.14 (64 bit floating point)
SDS.integer = 'uint16';         % e.g. 3 (16 bit positive integer)
%SDS.now = 0;        % [years]

item = [' ', char(183), ' '];

SDS.comments = {
    'Population properties:'
    [item, 'father           ID of father, 0 for initial population']
    [item, 'mother           ID of mother, 0 for initial population']
    [item, 'born             time of birth w.r.t. start date [date]']
    [item, 'deceased         time of death w.r.t. start date [date]']
    [item, 'community        community ID']
    [item, 'exposure         exposure to BCC']
    [item, 'HIV source       ID of HIV source']
    [item, 'HIV positive     time of HIV transmission [date]']
    [item, 'AIDS death       time of AIDS caused death [date]']
    [item, 'HIV test         time of HIV-test [date]']
    [item, 'ARV start        start of antiretroviral treatment [date]']
    [item, 'ARV stop         stop of antiretroviral treatment [date]']
    [item, 'circumcision     time of circumcision [date]']
    [item, 'condom duration  duration of condom use (can be 0)']
    [item, 'conception       time of conception [date]']
    };


% ******* Index Keys *******
SDS.index.male   = logical([1, 0]);
SDS.index.female = logical([0, 1]);
SDS.index.start  = logical([1, 0, 0]);
SDS.index.stop   = logical([0, 1, 0]);
SDS.index.condom = logical([0, 0, 1]);


% ******* Population *******
commonPrp = struct('father',[], 'mother',[], ...
    'born',[], 'deceased',[], ...
    'HIV_source',[], ...                % source of the HIV [ID]
    'HIV_positive',[], ...              % time of HIV transmission [date]
    'AIDS_death',[], ...                % death by AIDS [boolean]
    'HIV_test',[], ...                  % time of HIV-test [date]
    'ARV_start',[], 'ARV_stop',[], ...  % antiretroviral treatment [date]
    'community',[], ...                 % currently integer
    'BCC_exposure',[], ...              % behavioural change camp. [0...1]
    'partnering', []);                  % sexual activity scale [0...1]
SDS.males = mergeStruct(commonPrp, struct(...
    'circumcision',[], ...              % time of circumcision [date]
    'condom',[]));             % duration of condom use (can be 0)
SDS.females = mergeStruct(commonPrp, struct(...
    'conception',[]));                  % time conception [date]


% ******* Relations *******
SDS.relations = struct('ID', [], 'time', []);


% ******* Fetch Available Events *******
folder = [fileparts(which(mfilename)) '/events'];
addpath(folder)
for thisFile = dir(fullfile(folder , 'event*.m'))'
    if strcmp(thisFile.name, 'eventTemplate.m')
        continue
    end    
    [~, eventFile] = fileparts(thisFile.name);
    thisField = str2field(feval(eventFile, 'name'));
    SDS.(thisField) = modelHIVrestart_eventProps(modelHIVrestart_event(eventFile));
    %SDS.(thisField).comments = {''};
end
end


%% add
function [SDS, msg] = modelHIVrestart_add(objectType, Schar, handles)

import javax.swing.ImageIcon
import javax.swing.JOptionPane

msg = '';
SDS = handles.data();
%WHY??? subS = evalstruct(SDS, Schar);
subS = eval(Schar);

Prefs = handles.prefs('retrieve');
object = char(JOptionPane.showInputDialog(handles.frame, ...
    sprintf('%s File:', capitalise(objectType)), Prefs.appName, ...
    JOptionPane.QUESTION_MESSAGE, ImageIcon(which(Prefs.appIcon)), [], objectType));
if isempty(object)
    msg = 'Cancelled by user';
    return
end

% objectField = genvarname(strrep(object, ' ', '_'));
% if isfield(subS, objectField)
%     msg = sprintf('The %s ''%s'' already exists', objectType, object);
%     return
% end
if isempty(which(object))
    msg = sprintf('Warning: can''t find %s file ''%s.m''', objectType, object);
    return
end

switch objectType
    case 'event'
        objectField = str2field(feval(object, 'name'));
        [subS.(objectField), msg] = modelHIVrestart_eventProps(modelHIVrestart_event(object));
        if ~isempty(msg)
            return
        end
        eval(sprintf('%s = subS;', Schar))
        
    otherwise
        error '.'
end
end


%% event
function event = modelHIVrestart_event(eventFile)

event = struct('object_type', 'event', ...
    'enable', true, ...    'comments', {{''}}, ...
    'event_file', eventFile);
end


%% eventProps
function [subS, msg] = modelHIVrestart_eventProps(subS)

msg = '';

% ******* Checks *******
if ~isfield(subS, 'event_file')
    msg = 'Warning: not a valid event object';
    return
end

if isempty(subS.event_file)
    subS.enable = false;
    msg = 'Warning: not all events have an event file set';
    return
end

if exist(subS.event_file, 'file') ~= 2
    msg = sprintf('Warning: can''t find event function ''%s''', ...
        subS.event_file);
    return
end

subFields = fieldnames(subS);
eventFields = fieldnames(modelHIVrestart_event(''));
handleEvent = str2func(subS.event_file);
[propS, propMsg] = handleEvent('properties');
propFields = fieldnames(propS);


% ******* Remove Obsolete Properties *******
for thisField = subFields'
    
    eventIdx = strcmp(thisField{1}, eventFields);
    propIdx = strcmp(thisField{1}, propFields);
    
    if any(eventIdx) || any(propIdx) || isstruct(subS.(thisField{1}))
        continue
    end
    
    subS = rmfield(subS, thisField{1});
end


% ******* Add Event Properties *******
%subS = mergeStruct(subS, propS);
for thisField = propFields'
    
    if any(strcmp(thisField{1}, subFields))
        % property already present, don't overrule
        continue
    end
    subS.(thisField{1}) = propS.(thisField{1});
end

if ~isfield(subS, 'comments')
    subS.comments = {propMsg};
end
end


%% popupMenu
function modelHIVrestart_popupMenu(Schar, SDS, popupMenu, handles)

import javax.swing.JMenu
import javax.swing.JMenuItem

if isempty(Schar)
    return
end

%WHY??? subS = evalstruct(SDS, Schar);
subS = eval(Schar);
isObject = isfield(subS, 'object_type');

if strcmp(Schar, 'SDS')% || isObject
    menuItem = JMenuItem('Add New Event');
    jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_popupMenu_add, 'event'});
    popupMenu.add(menuItem);
end

% ******* Remove Objects from Data Structure *******
if ~isObject
    return
end

enumC = regexp(Schar, '\.(\w+)\(?(\d*)\)?', 'tokens');
name = sprintf('%s: <i>%s</i>', capitalise(subS.object_type), field2str(enumC{end}{1}));

% if strcmp(subS.object_type, 'event') && ~isempty(subS.event_file)
%     popupMenu.addSeparator()
%
%     %menuItem = JMenuItem('Initialise Event');
%     menuItem = JMenuItem(sprintf('<html>Add Properties: <i>%s</i></html>', subS.event_file));
%     %doesnt work menuItem.setEnabled(~isempty(subS.event_file))
%     jset(menuItem, 'ActionPerformedCallback', @modelHIVrestart_popupMenu_eventProps);
%     popupMenu.add(menuItem);
% end
% popupMenu.addSeparator()

if ~isempty(subS.event_file)
    menuItem = JMenuItem(sprintf('<html>Open %s</html>', name));
    jset(menuItem, 'ActionPerformedCallback', @modelHIVrestart_popupMenu_open);
    popupMenu.add(menuItem);
    
    popupMenu.addSeparator()
end

menuItem = JMenuItem(sprintf('<html>Remove %s</html>', name));
jset(menuItem, 'ActionPerformedCallback', @modelHIVrestart_popupMenu_removeField);
popupMenu.add(menuItem);


%% popupMenu_add
    function modelHIVrestart_popupMenu_add(~, ~, objectType)
        
        %handles.msg('Adding %s...', objectType)
        [SDS, msg] = modelHIVrestart_add(objectType, Schar, handles);
        
        if ~isempty(msg)
            handles.fail(msg)
            return
        end
        
        handles.update(SDS)
        %handles.msg(' ok\n')
    end


%% popupMenu_eventProps CODE DUPL!!!
    function modelHIVrestart_popupMenu_eventProps(~, ~)
        
        [subS, msg] = modelHIVrestart_eventProps(subS);
        if ~isempty(msg)
            handles.fail(msg)
            return
        end
        eval([Schar, ' = subS;'])
        handles.update(SDS, '-restore')
    end


%% popupMenu_open
    function modelHIVrestart_popupMenu_open(~, ~)
        
        file = which(subS.event_file);
        [ok, msg] = backup(file);
        if ok
            handles.msg('Backup: %s\n', msg)
        else
            handles.fail(msg)
        end
        open(file)
    end


%% popupMenu_removeField
    function modelHIVrestart_popupMenu_removeField(~, ~)
        
        import javax.swing.ImageIcon
        import javax.swing.JOptionPane
        
        remC = regexp(Schar, '(.+)\.(.+)', 'tokens', 'once');
        action = sprintf('<html>Remove %s <i>%s</i>?</html>', ...
            subS.object_type, field2str(remC{2}));
        %handles.msg([action, '...'])
        
        Prefs = handles.prefs('retrieve');
        choice = JOptionPane.showConfirmDialog(handles.frame, ...
            [action, '?'], Prefs.appName, JOptionPane.OK_CANCEL_OPTION, ...
            JOptionPane.QUESTION_MESSAGE, ImageIcon(which(Prefs.appIcon)));
        
        if choice ~= JOptionPane.OK_OPTION
            %handles.fail('Cancelled by user')
            return
        end
        
        subS = rmfield(eval(remC{1}), remC{2});
        eval([remC{1}, ' = subS;'])
        
        handles.update(SDS)
        %handles.msg(' ok\n')
    end
end


%% menu
function modelMenu = modelHIVrestart_menu(handlesFcn)

import java.awt.event.ActionEvent
import java.awt.event.KeyEvent
import javax.swing.JMenu
import javax.swing.JMenuItem
import javax.swing.KeyStroke

handles = handlesFcn();

modelMenu = JMenu('Model');
modelMenu.setMnemonic(KeyEvent.VK_M)

menuItem = JMenuItem('Start Simulation', KeyEvent.VK_S);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_T, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Start simulation')
jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
modelMenu.add(menuItem);

if strcmp(getenv('USERNAME'), 'ralph')
    menuItem = JMenuItem('Pre Process');
    jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
    modelMenu.add(menuItem);
    
    menuItem = JMenuItem('Post Process');
    jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
    modelMenu.add(menuItem);
end

modelMenu.addSeparator()

menuItem = JMenuItem('Open Project Folder', KeyEvent.VK_P);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_P, ActionEvent.CTRL_MASK))
menuItem.setDisplayedMnemonicIndex(5)
menuItem.setToolTipText('Open project folder in Windows Explorer')
jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
modelMenu.add(menuItem);

menuItem = JMenuItem('Open Data File', KeyEvent.VK_D);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Open data script -if available- in editor')
jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
modelMenu.add(menuItem);

modelMenu.addSeparator()

% menuItem = JMenuItem('Add Event', KeyEvent.VK_A);
% menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_A, ActionEvent.CTRL_MASK))
% menuItem.setToolTipText('Add an event to this model')
% jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
% modelMenu.add(menuItem);
% modelMenu.addSeparator()

menuItem = JMenuItem('To MATLAB Workspace', KeyEvent.VK_W);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_W, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Assign SDS data structure to MATLAB workspace (Command Window)')
jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
modelMenu.add(menuItem);
end


%% callback
function modelHIVrestart_callback(~, actionEvent, handles)

SDS = handles.data();
handles.state('busy')

try
    action = get(actionEvent, 'ActionCommand');
    
    switch action
        case 'Pre Process'
            handles.msg('Pre processing... ')
            [SDS, msg] = modelHIVrestart('preprocess', SDS);    % modelHIVrestart_preprocess
            if ~isempty(msg)
                handles.fail(msg)
                return
            end
            handles.update(SDS, '-restore')
            handles.msg(' ok\n')
            
        case 'Post Process'
            handles.msg('Post processing... ')
            [SDS, msg] = modelHIVrestart_postprocess(SDS);
            if ~isempty(msg)
                handles.fail(msg)
                return
            end
            handles.update(SDS, '-restore')
            handles.msg(' ok\n')
            
        case 'Start Simulation'
            spRun('start', handles);
            
        case 'Open Project Folder'
            handles.msg('Opening project folder...')
            winopen(jproject('folder'))
            handles.msg(' ok\n')
            
        case 'Open Data File'
            handles.msg('Opening data file...')
            [ok, msg] = spTools('edit', modelHIVrestart_dataFile(SDS));
            if ok
                handles.msg(' ok\n')
            else
                handles.fail(msg)
            end
            
        case 'Add Event'
            debugMsg 'Add Event'
            
        case 'To MATLAB Workspace'
            handles.msg('Assigning data structure to MATLAB workspace...')
            base(SDS)
            handles.msg(' ok\n')
            
        otherwise
            handles.fail('Warning: unknown action ''%s''\n', action)
            return
    end
    
catch Exception
    handles.fail(Exception)
    return
end

handles.state('ready')
end


%% dataFile
function dataFile = modelHIVrestart_dataFile(SDS)

dataFile = SDS.data_file;
end


%% test
function modelHIVrestart_test

debugMsg -on
debugMsg

% ******* Relay to GUI Test *******
SIMPACT
end


%%
function modelHIVrestart_

end
