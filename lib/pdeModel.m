function varargout = pdeModel(fcn, varargin)
%PDEMODEL SIMPACT PDE model function.
%   This function implements _init, _nextEvent.
%
% See also spGui, spRun, spTools.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    pdeModel_test
    return
end

switch fcn
    case 'handle'
        cmd = sprintf('@%s_%s', mfilename, varargin{1});
        
    otherwise
        cmd = sprintf('%s_%s(varargin{:})', mfilename, fcn);
end

[varargout{1:nargout}] = eval(cmd);
end


%% test
function pdeModel_test

debugMsg -on
debugMsg

% ******* Relay to GUI Test *******
spGui
end


%% menu
function modelMenu = pdeModel_menu(handlesFcn)

import java.awt.event.ActionEvent
import java.awt.event.KeyEvent
import javax.swing.JMenu
import javax.swing.JMenuItem
import javax.swing.KeyStroke

modelMenu = JMenu('Model');
modelMenu.setMnemonic(KeyEvent.VK_M)

if any(strcmp(getenv('USERNAME'), {'ralph', 'RHummeling'}))
    menuItem = JMenuItem('Pre Process');
    set(menuItem, 'ActionPerformedCallback', @pdeModel_menu_callback)
    modelMenu.add(menuItem);
    
    menuItem = JMenuItem('Post Process');
    set(menuItem, 'ActionPerformedCallback', @pdeModel_menu_callback)
    modelMenu.add(menuItem);
    
    modelMenu.addSeparator()
end

menuItem = JMenuItem('Open Project Folder', KeyEvent.VK_P);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_P, ActionEvent.CTRL_MASK))
menuItem.setDisplayedMnemonicIndex(5)
menuItem.setToolTipText('Open project folder in Windows Explorer')
set(menuItem, 'ActionPerformedCallback', @pdeModel_menu_callback)
modelMenu.add(menuItem);

menuItem = JMenuItem('Open Data File', KeyEvent.VK_D);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Open data script -if available- in editor')
set(menuItem, 'ActionPerformedCallback', @pdeModel_menu_callback)
modelMenu.add(menuItem);

% modelMenu.addSeparator()
% 
% menuItem = JMenuItem('Add Event', KeyEvent.VK_A);
% menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_A, ActionEvent.CTRL_MASK))
% menuItem.setToolTipText('Add an event to this model')
% set(menuItem, 'ActionPerformedCallback', @pdeModel_menu_callback)
% modelMenu.add(menuItem);

modelMenu.addSeparator()

menuItem = JMenuItem('To MATLAB Workspace', KeyEvent.VK_W);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_W, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Assign SDS data structure to MATLAB workspace (Command Window)')
set(menuItem, 'ActionPerformedCallback', @pdeModel_menu_callback)
modelMenu.add(menuItem);


%% menu_callback
    function pdeModel_menu_callback(hObject, actionEvent)
        
        handles = handlesFcn();
        SDS = handles.data();
        handles.wait('busy')
        
        try
            switch get(actionEvent, 'ActionCommand')                    
                case 'Pre Process'
                    handles.msg('Pre processing... ')
                    [SDS, msg] = pdeModel_update(SDS);
                    if ~isempty(msg)
                        handles.fail(msg)
                        return
                    end
                    handles.update(SDS)
                    handles.msg(' done\n')
                    
                case 'Post processing'
                    handles.msg('Post processing... ')
                    SDS = pdeModel_postprocess(SDS);
                    handles.update(SDS)
                    handles.msg(' done\n')
                    
                case 'Open Project Folder'
                    handles.msg('Opening project folder...')
                    winopen(jproject('folder'))
                    handles.msg(' done\n')
                    
                case 'Open Data File'
                    handles.msg('Opening data file...')
                    [ok, msg] = pdeModel_open('script', SDS);
                    if ok
                        handles.msg(' done\n')
                    else
                        handles.fail(msg)
                    end
                    
                case 'Add Event'
                    debugMsg 'Add Event'
                    
                case 'To MATLAB Workspace'
                    handles.msg('Assigning data structure to MATLAB workspace...')
                    base(SDS)
                    handles.msg(' done\n')
                    
                otherwise
                    handles.fail('Warning: unknown action command\n')
                    return
            end
            
        catch% FireWall
            %handles.fail('Error: %s\n', FireWall.message)
            handles.fail('Error: %s\n', lasterr)
            return
        end
        
        handles.wait('ready')
    end
end


%% init
function [SDS, msg] = pdeModel_init

msg = '';

% ******* Defaults *******
SDS = [];
SDS.user_name = getenv('USERNAME');
SDS.model_function = mfilename;
SDS.data_file = sprintf('data%s.m', datestr(now, 30));

SDS.start_date = '1 jan 1970';
SDS.end_date = '31 dec 1999';
SDS.event_range = (0 : 2)*90;  % [days]
SDS.iteration_limit = 1e2;
SDS.number_of_males = 1e2;
SDS.number_of_females = 1e2;
SDS.number_of_relations = 1e4;
SDS.subset_fraction = 1;
SDS.float = 'single';
SDS.integer = 'uint16';
SDS.now = 0;  % [day]


% ******* Index Keys *******
SDS.index.male   = logical([1, 0]);
SDS.index.female = logical([0, 1]);
SDS.index.start  = logical([1, 0, 0]);
SDS.index.stop   = logical([0, 1, 0]);
SDS.index.condom = logical([0, 0, 1]);


% ******* Population *******
commonPrp = struct('father',[], 'mother',[], ...
    'born',[], 'deceased',[], ...
    'HIV_test',[], ...              time of HIV-test [date]
    'ARV_start',[], 'ARV_stop',[]); % start-stop of antiretroviral treatment [date]
SDS.males = mergestruct(commonPrp, ...
    struct('circumcision',[], ...   time of circumcision [date]
    'condom_duration',[]));         % duration of condom use (can be 0)
SDS.females = mergestruct(commonPrp, struct(...
    'conception',[]));              % time conception [date]


% ******* Relations *******
SDS.relations = struct('ID',[],'time',[]);


% ******* Events *******
%hazardTypeC = {'<html>exp(&alpha; + &beta; t)</html>', 'table lookup'};
%hazardType = struct('component','JComboBox', 'items', {hazardTypeC}, 'selectedIndex', 0);

% fieldC = {'name', 'enable', 'event_file', 'hazard_function_type', 'comment'};
% table = {
%     'Partnership formation'     true    @eventFormation  hazardType  {''; ''}
%     'Partnership dissolution'   false   ''  hazardType  {''; ''}
%     'HIV aquisition'            false   ''  hazardType  {''; ''}
%     'Non-AIDS mortality'        false   ''  hazardType  {''; ''}
%     'AIDS mortality'            false   ''  hazardType  {''; ''}
%     };
fieldC = {'name', 'enable', 'event_file', 'properties', 'comment'};
table = {
    'Partnership formation'     true    @eventFormation eventFormation('init')  {''; ''}
    'Partnership dissolution'   false   ''              struct() {''; ''}
    'HIV aquisition'            false   ''              struct() {''; ''}
    'Non-AIDS mortality'        false   ''              struct() {''; ''}
    'AIDS mortality'            false   ''              struct() {''; ''}
    };

SDS.event = cell2struct(table, fieldC, 2);

SDS.comment = {''; ''};
end


%% update
function [SDS, msg] = pdeModel_update(SDS)

msg = '';

spTools('resetRand')	% reset random number generator
daysPerYear = spTools('daysPerYear');


SDS.t0 = datenum(SDS.start_date);
SDS.tFinal = datenum(SDS.end_date);


% ******* Population *******
SDS.males.father = zeros(1, SDS.number_of_males, SDS.integer);
SDS.males.mother = SDS.males.father;
SDS.males.born = nan(1, SDS.number_of_males, SDS.float);
SDS.males.deceased = SDS.males.born;
SDS.females.father = zeros(1, SDS.number_of_females, SDS.integer);
SDS.females.mother = SDS.males.father;
SDS.females.born = nan(1, SDS.number_of_females, SDS.float);
SDS.females.deceased = SDS.females.born;

agesMale = empiricalage(SDS.number_of_males);
SDS.males.born = cast(-agesMale*daysPerYear, SDS.float);
agesFemale = empiricalage(SDS.number_of_females);
SDS.females.born = cast(-agesFemale*daysPerYear, SDS.float);

% all males become 85 and females 87 TEMP
SDS.males.deceased = SDS.males.born + 85*daysPerYear;   % TEMP
SDS.females.deceased = SDS.females.born + 87*daysPerYear;   % TEMP


% ******* Initialise Relations *******
SDS.relations.ID = zeros(SDS.number_of_relations, 2, SDS.integer);

% single requires relative time (dt) for accuracy,
% for base 1/1/00 datenum results in 1.5 hrs resolution
%SDS.relations.time = nan(SDS.number_of_relations, 2, SDS.type.relations.time);
SDS.relations.time = [
    nan(SDS.number_of_relations, 1, SDS.float), ...
    inf(SDS.number_of_relations, 1, SDS.float), ...
    zeros(SDS.number_of_relations, 1, SDS.float)
    ];


% ******* Update Event Functions *******
for thisEvent = SDS.event'
    if isempty(thisEvent.event_file)
        continue
    end
    thisEvent.event_file('preprocess', SDS, thisEvent)
end


% ******* Messages *******
if max([SDS.number_of_males, SDS.number_of_females]) > intmax(SDS.integer)
    msg = sprintf('Warning: Insufficient type SDS.integer = %s', SDS.integer);
end
end


%% nextEvent
function SDS = pdeModel_nextEvent(SDS)

persistent SMP

% ******* Initialise *******
if isempty(SMP)
    pdeModel_nextEvent_init
end


% ******* Event Times *******
for ii = SMP.eventIdx
    %SDS.event(ii).output = SDS.event(ii).event_file(SDS);
    SMP.output(ii) = SMP.eventTime{ii}(SDS);
end


% ******* First Event *******
%[eventTime, idx] = min([SDS.event(SMP.eventIdx).output.time]);
[eventTime, idx] = min([SMP.output(SMP.eventIdx).time]);


% ******* Update Time *******
SDS.now(end + 1) = SDS.now(end) + eventTime;  % growing time vector


% ******* fire Event *******
%SDS = SDS.event(SMP.eventIdx(idx)).output.fire(SDS);
SDS = SMP.fire{SMP.eventIdx(idx)}(SDS);



%% nextEvent_init ==> move to pdeModel_update!!!
    function pdeModel_nextEvent_init
        
        SMP.eventIdx = [];
        
        for jj = 1 : numel(SDS.event)
            
            if ~SDS.event(jj).enable
                continue
            end
            SMP.eventIdx = [SMP.eventIdx, jj];
            
            % ******* Clear Persistent Variables *******
            %clear(func2str(SDS.event(jj).event_file))
            
            %feval(SDS.event(jj).event_file, 'preprocess')
            %SMP.eventFcn{jj} = feval(SDS.event(jj).event_file, 'handle', 'eventTime');
            SMP.eventTime{jj} = SDS.event(jj).event_file('handle', 'eventTime');
            SMP.fire{jj} = SDS.event(jj).event_file('handle', 'fire');
        end
    end
end


%% postprocess
function pdeModel_postprocess

end


%% dataFile
function dataFile = pdeModel_dataFile(SDS)

dataFile = SDS.data_file;
end


%%
function pdeModel_

end
