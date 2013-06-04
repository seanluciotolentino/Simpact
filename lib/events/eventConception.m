function varargout = eventConception(fcn, varargin)
%EVENTCONCEPTION SIMPACT event function: conception
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
    function [elements, msg] = eventConception_init(SDS, event)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        
        P.eventTimes = inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.pregnant = false(1, SDS.number_of_females);
        
        P.rand0toInf = spTools('handle', 'rand0toInf');
        
        if ~P.fertility_rate_from_data_file
            P.fertility_rate_parameter = event.constant_fertility_parameter;
        else
            daysPerYear = spTools('daysPerYear');
            P.start = datenum(SDS.start_date)/daysPerYear;
            filename = event.fertility_rate_reference_file;
            P.data = csvread(filename,1,0)/10;
            P.data = [-Inf, P.data(1,2);P.data;Inf, P.data(size(P.data,1),2)];
           
            P.fertility_rate_parameter = interp1q(P.data(:,1),P.data(:,2),P.start);
            
        end
        %P.enableBirth = eventBirth('handle', 'enable');
        [P.enableBirth, msg] = spTools('handle', 'eventBirth', 'enable');
        [P.enableANC, msg] = spTools('handle', 'eventANC', 'enable');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
    end
%% get
    function X = eventConception_get(t)
        X = P;
    end

%% restore
    function [elements,msg] = eventConception_restore(SDS,X)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
        
        P = X;
        P.enable = SDS.conception.enable;
        
        [P.enableBirth, msg] = spTools('handle', 'eventBirth', 'enable');
        [P.enableANC, msg] = spTools('handle', 'eventANC', 'enable');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
    end

%% eventTimes
    function eventTimes = eventConception_eventTimes(~, ~)
        
        %subset = P0.subset & P0.current;    % what about relations braking up?
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventConception_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventConception_fire(SDS, P0)
        
        P0.male = rem(P0.index - 1, SDS.number_of_males) + 1;
        P0.female = ceil(P0.index/SDS.number_of_males);
        
        
        
        P0.pregnant(P0.female) = true;
        P.enableBirth(P0)                   % uses P0.male, P0.female
        P.enableANC(P0)
        
        %eventConception_block(P0)
        P.eventTimes(:,P0.female) = Inf;
        P0.index = P0.female + SDS.number_of_males;
        P0.thisPregnantTime(P0.female) = P0.now;
        currentIdx = SDS.relations.time(:, SDS.index.stop) == Inf;
        for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.female) == P0.female) &...
                ismember(SDS.relations.ID(:, SDS.index.male),find(isnan(SDS.males.HIV_positive))))'
            P0.male = SDS.relations.ID(relIdx, SDS.index.male);
            if P0.serodiscordant(P0.male, P0.female)
                P0.conception = true;
                [SDS, P0] = P.updateTransmission(SDS, P0);
                P0.conception = false;
            end
        end
        
        
    end


%% enable
    function eventConception_enable(SDS,P0)
        % Invoked by eventFormation_fire
        % Invoked by eventBirth_fire
        
        %P.pregnant(P0.female) = false;
        
        if ~P.enable
            return
        end
        
        if P0.pregnant(P0.female)
            return
        end
        
        % P.eventTimes(P0.male, P0.female) = ...
        %     P.Weibull_scale_parameter*(P.rand0toInf(1, 1)/...
        %     P.fertility_scale_factor)^(1/P.Weibull_shape_parameter);
        % P_F = min(1, P.rand0toInf(1, 1)/P.fertility_scale_factor);
        % P.eventTimes(P0.male, P0.female) = -log(1 - P_F)/P.exponential_rate_parameter;
        adjustment = 0.38;
        motherBorn =  SDS.females.born(P0.female);
        age = P0.now - motherBorn;
        age = [age^4 age^3 age^2 age 1];
        coefficient = [-1.96e-05     0.002876     -0.15373        3.448      -25.407];
        
        if ~P.fertility_rate_from_data_file
            fertilityFactor = P.fertility_rate_parameter;
        else          
            fertilityFactor = interp1q(P.data(:,1),P.data(:,2),P0.now +P.start+1.5);            
        end
        fertilityFactor= sum(age.*coefficient)*adjustment*fertilityFactor;
        P_F = P.rand0toInf(1, 1);
        P.eventTimes(P0.male, P0.female) = P_F/fertilityFactor;
        if P.eventTimes(P0.male, P0.female)<0
            P.eventTimes(P0.male, P0.female) = Inf;
        end
        
    end


%% block
    function eventConception_block(P0)
        % Invoked by eventDissolution_dump
        % Invoked by eventConception_fire
        
        P.eventTimes(P0.male, P0.female) = Inf;
    end
end


%% properties
function [props, msg] = eventConception_properties
props.constant_fertility_parameter = 2.3;
props.fertility_rate_from_data_file = true;
props.fertility_rate_reference_file = '/Simpact/empirical_data/sa_fertility.csv';
msg = 'Birth implemented by birth event.';
end


%% name
function name = eventConception_name

name = 'conception';
end
