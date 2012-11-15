function varargout = eventANC(fcn, varargin)
%eventANC SIMPACT event function: ANC
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
    function [elements, msg] = eventANC_init(SDS, event)
        
        elements = SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        
        daysPerYear = spTools('daysPerYear');
        P.rand = rand(1, elements, SDS.float);
        P.eventTimes = inf(1, elements, SDS.float);
        P.attendingTimes = nan(1,elements);
        P.non = event.attendance{2,4}/100;
        P.both = (event.attendance{2,2}+event.attendance{2,3}+event.attendance{2,4})/100-1;
        P.early = event.attendance{2,2}/100 - P.both;
        P.late = event.attendance{2,3}/100 - P.both;
        P.earlyTime = event.attendance{3, 2}*7/daysPerYear;
        P.lateTime = event.attendance{3, 3}*7/daysPerYear;
        [P.fireTest, msg] = spTools('handle', 'eventTest', 'fire');
        
    end


%% get
    function X = eventANC_get(t)
        X = P;
    end

%% restore
    function [elements,msg] = eventANC_restore(SDS,X)
        
        elements = SDS.number_of_females;
        msg = '';
        
        
        P = X;
        
        P.enable = SDS.antenatal_care.enable;
        [P.fireTest, msg] = spTools('handle', 'eventTest', 'fire');
    end

%% eventTimes
    function eventTimes = eventANC_eventTimes(~, ~)
        
        %subset = P0.subset & P0.current;    % what about relations braking up?
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventANC_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventANC_fire(SDS, P0)
        P.attendingTimes(P0.index) = P.attendingTimes(P0.index)-1;
        P0.female = P0.index;
        if P.attendingTimes(P0.index)==1
            eventANC_enable(P0)
        else
            eventANC_block(P0)
        end
        if isnan(SDS.females.HIV_test(P0.female))||(SDS.females.HIV_test(P0.female)<SDS.females.HIV_positive(P0.female))
            P0.index = P0.index + SDS.number_of_males;
            P0.ANC = true;
            [SDS, P0] = P.fireTest(SDS, P0); % use P0.index
            P0.ANC = false;
        end
        
    end


%% enable
    function eventANC_enable(P0)
        % Invoked by eventConception using P0.female;
        if ~P.enable
            return
        end
        
        if P.attendingTimes(P0.female)==1
            P.eventTimes(P0.female) = P.lateTime - P.earlyTime;
        else
            rTemp = rand;
            if rTemp<=P.early
                P.attendingTimes(P0.female) =1;
                P.eventTimes(P0.female) = P.earlyTime;
            else
                if rTemp<=P.early+P.both
                    P.attendingTimes(P0.female) =2;
                    P.eventTimes(P0.female) = P.earlyTime;
                else
                    if rTemp<=1-P.non
                        P.attendingTimes(P0.female) =1;
                        P.eventTimes(P0.female) = P.lateTime;
                    end
                end
            end
        end
    end


%% block
    function eventANC_block(P0)
        % Invoked by event
        if isnan(P0.female)
            P0.female = P0.index;
        end
        P.eventTimes(P0.female) = Inf;
        
    end
end


%% properties
function [props, msg] = eventANC_properties

props.attendance = {
    'attendance' 'early' 'late' 'none'
    'percentage'   55                55                           10
    'time(weeks)'  22                32                     'None'
    };


msg = 'Antenatal care implemented by ANC event.';
end


%% name
function name = eventANC_name

name = 'antenatal care';
end
