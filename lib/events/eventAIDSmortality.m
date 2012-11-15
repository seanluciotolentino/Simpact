function varargout = eventAIDSmortality(fcn, varargin)
%EVENTAIDSMORTALITY SIMPACT event function: AIDS mortality
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
    function [elements, msg] = eventAIDSmortality_init(SDS, event)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        
        P.eventTimes = inf(1, elements, SDS.float);
        InfectedIdx = [SDS.males.HIV_positive, SDS.females.HIV_positive];
        InfectedIdx = InfectedIdx<=0;
        P.eventTimes(InfectedIdx) = [SDS.males.AIDSdeath(SDS.males.HIV_positive<=0) + SDS.males.HIV_positive(SDS.males.HIV_positive<=0),...
           SDS.females.AIDSdeath(SDS.females.HIV_positive<=0) + SDS.females.HIV_positive(SDS.females.HIV_positive<=0) ];
         [P.fireMortality, msg] = spTools('handle', 'eventMortality', 'fire');
    end
%% get
    function X= eventAIDSmortality_get(t)
	
        X = P;
    end

%% restore
    function [elements, msg] = eventAIDSmortality_restore(SDS, X)
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';

	    P = X;
	    P.enable = SDS.AIDS_mortality.enable;
        [P.fireMortality, msg] = spTools('handle', 'eventMortality', 'fire');
    end

%% eventTimes
    function eventTimes = eventAIDSmortality_eventTimes(~, ~)
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventAIDSmortality_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventAIDSmortality_fire(SDS, P0)
        
        [SDS, P0] = P.fireMortality(SDS, P0);   % relay to eventMortality
        
        % eventMortality_fire sets P0.male & P0.female
        SDS.males.AIDS_death(P0.male) = true;      % record cause
        SDS.females.AIDS_death(P0.female) = true;
    end


%% enable
    function eventAIDSmortality_enable(P0, eventTime)
        % Invoked by eventTransmission_fire
        
        if ~P.enable
            return
        end
        
        P.eventTimes(P0.index) = eventTime;
    end


%% block
    function eventAIDSmortality_block(P0)
        % Invoked by eventMortality_fire
        
        P.eventTimes(P0.index) = Inf;           % only cats have nine lifes
    end
end


%% properties
function [props, msg] = eventAIDSmortality_properties

props = struct([]);
msg = 'AIDS mortality properties implemented by HIV transmission event.';
end


%% name
function name = eventAIDSmortality_name

name = 'AIDS mortality';
end
