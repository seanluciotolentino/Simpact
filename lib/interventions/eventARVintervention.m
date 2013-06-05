function varargout = eventARVintervention(fcn, varargin)
%eventARVintervention SIMPACT event function: ARVintervention
%
% See also SIMPACT, spRun, spTools, modelHIV.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

persistent P

switch fcn
    case 'handle'
        cmd = sprintf('@%s_%s', mfilename, varargin{1});
    otherwise
        cmd = sprintf('%s_%s(varargin{:})', mfilename, fcn);
end
[varargout{1:nargout}] = eval(cmd);


%% init
    function [elements, msg] = eventARVintervention_init(SDS, event)
        
        elements = 4;
        msg = '';
        
        P = event;                  % copy event parameters
        P.eventTimes = Inf(1,elements);
        
        daysPerYear = spTools('daysPerYear');
        P.eventTimes(1) = (datenum(P.ARV_expansion_strategies{2,2}) - ...
            datenum(SDS.start_date))/daysPerYear;
        P.eventTimes(2) = (datenum(P.ARV_expansion_strategies{3,2}) - ...
            datenum(SDS.start_date))/daysPerYear;
        P.eventTimes(3) = (datenum(P.ARV_expansion_strategies{4,2}) - ...
            datenum(SDS.start_date))/daysPerYear;
        P.eventTimes(4) = (datenum(P.ARV_expansion_strategies{5,2}) - ...
            datenum(SDS.start_date))/daysPerYear;
        P.names ={'population' 'pregnant' 'discordant' 'fsw'};
        P.threshold =[P.ARV_expansion_strategies{2,3}, P.ARV_expansion_strategies{3,3},...
            P.ARV_expansion_strategies{4,3},P.ARV_expansion_strategies{5,3}];
        P.coverage =[P.ARV_expansion_strategies{2,4}, P.ARV_expansion_strategies{3,4},...
            P.ARV_expansion_strategies{4,4},P.ARV_expansion_strategies{5,4}];
        [P.interveneTest, msg] = spTools('handle', 'eventTest', 'intervene');
        
    end

%% get
    function X = eventARVintervention_get(t)
        X = P;
    end

%% restore
    function [elements,msg] = eventARVintervention_restore(SDS,X)
        
        elements = 4;
        msg = '';       
        P = X;
        [P.interveneTest, msg] = spTools('handle', 'eventTest', 'intervene');        
    end

%% eventTimes
    function eventTimes = eventARVintervention_eventTimes(~, ~)  
        eventTimes = P.eventTimes;
    end


%% advance
    function eventARVintervention_advance(P0)
        
        P.eventTimes = P.eventTimes - P0.eventTime;
        
    end


%% fire
    function [SDS, P0] = eventARVintervention_fire(SDS, P0)
        if ~P.enable
            return
        end
               P.interveneTest(P.names{P0.index},P.threshold(P0.index), P.coverage(P0.index));
               P.eventTimes(P0.index) = Inf;

    end

%% enable
function eventARVintervention_enable(SDS, P0)
% by eventBirth, eventTransmission
% new random number
if ~P.enable
    return
end
end

%% block
function eventARVintervention_block(P0)
P.eventTimes(P0.index) = Inf;
end


end


%% properties
function [props, msg] = eventARVintervention_properties

props.ARV_expansion_strategies = {
'target population'            'time'         'CD4 threshold'         'coverage'
'population'                      '01-Jan-2050'     350         60  
'pregnant women'            '01-Jan-2050'       350       60
'serodiscordant couples'  '01-Jan-2050'     350         60
'female sex workers'        '01-Jan-2050'       350       60
};
msg = 'ARV treatment interventions implemented by ARV intervention event.';
end


%% name
function name = eventARVintervention_name

name = 'ARV intervention';
end
