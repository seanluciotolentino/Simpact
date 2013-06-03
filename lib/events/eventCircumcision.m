function varargout = eventCircumcision(fcn, varargin)
%EVENTCIRCUMCISION SIMPACT event function: male circumcision
%
%   See also modelHIV.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

persistent P

if nargin == 0
    return
end

switch fcn
    case 'handle'
        cmd = sprintf('@%s_%s', mfilename, varargin{1});
    otherwise
        cmd = sprintf('%s_%s(varargin{:})', mfilename, fcn);
end
[varargout{1:nargout}] = eval(cmd);


%% init
    function [elements, msg] = eventCircumcision_init(SDS, event)
        
        elements = SDS.number_of_males;
        msg = '';
        
        P = event;                  % copy event parameters
        
        
        % ******* Function Handles *******
        P.rand0toInf = spTools('handle', 'rand0toInf');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        % [P.updateTransmission, thisMsg] = ...
        %     spTools('handle', 'eventTransmission', 'update');
        % if ~isempty(thisMsg)
        %     msg = sprintf('%s%s\n', msg, thisMsg);
        % end
        
        daysPerYear = spTools('daysPerYear');
        
        P.T = P.rand0toInf(elements, 1);
        %tb = SDS.males.born;
        P.gamma = event.Cauchy_scale_parameter;
        P.tp = event.Cauchy_peak_age;
        P.x = event.campaign_scale_factor;
        P.tr = (datenum(event.campaign_start_date) - ...
            datenum(SDS.start_date))/daysPerYear;
        P.Dtr = event.campaign_roll_out_duration;
        P.dt = event.time_vector_resolution;
        tEnd = (datenum(SDS.end_date) - datenum(SDS.start_date))/...
            daysPerYear;
        
        
        % ******* Integrated Hazard Functions *******
        P.t1 = unique([0 : P.dt : P.tr, P.tr])';
        P.t2 = unique([P.tr : P.dt : P.tr + P.Dtr, P.tr + P.Dtr])';
        P.t3 = unique([P.tr + P.Dtr : P.dt : tEnd, tEnd])';
        [P.t, P.idx] = unique([
            P.t1
            P.t2
            P.t3
            ]);
        
        % H1 = zeros(numel(P.t1), elements);
        % H2 = zeros(numel(P.t2), elements);
        % H3 = zeros(numel(P.t3), elements);
        % for ii = 1 : SDS.initial_number_of_males
        %     H1(:,ii) = (atan((P.t1 - P.tp - tb(ii))/P.gamma) + ...
        %         atan(P.tp/P.gamma))/pi;
        %
        %     C2 = H1(end,ii) - (P.gamma/2*(P.x - 1)/P.Dtr*...
        %         log((P.tr - P.tp - tb(ii))^2 + P.gamma^2) + ...
        %         ((P.x - 1)/P.Dtr*(P.tr + P.tp + tb(ii)) + 1)*...
        %         atan((P.tr - P.tp - tb(ii))/P.gamma))/pi;
        %     H2(:,ii) = (P.gamma/2*(P.x - 1)/P.Dtr*...
        %         log((P.t2 - P.tp - tb(ii)).^2 + P.gamma^2) + ...
        %         ((P.x - 1)/P.Dtr*(P.tr + P.tp + tb(ii)) + 1)*...
        %         atan((P.t2 - P.tp - tb(ii))/P.gamma))/pi + C2;
        %
        %     C3 = H2(end,ii) - atan((P.tr + P.Dtr - P.tp - tb(ii))/P.gamma)*P.x/pi;
        %     H3(:,ii) = atan((P.t3 - P.tp - tb(ii))/P.gamma)*P.x/pi + C3;
        % end
        % H = [
        %     H1
        %     H2
        %     H3
        %     ];
        % H = H(P.idx,:);       % discard duplicate values
        
        
        % ******* Variables & Constants *******
        P.rand = rand(1, elements, SDS.float);
        
        
        % ******* Find Event Times *******
        P.eventTimes = inf(1, elements);
        if ~P.enable
            return
        end
        
        % for ii = 1 : SDS.initial_number_of_males
        %     P.eventTimes(ii) = interp1q(H(:,ii), P.t, P.T(ii));
        % end
        % P.eventTimes(isnan(P.eventTimes)) = Inf;
        
        P0temp.now = 0;      % temporary P0
        for ii = 1 : SDS.initial_number_of_males
            P0temp.index = ii;
            eventCircumcision_enable(SDS, P0temp)
        end
    end

%% update -- Added by Lucio 09/03
    function X = eventCircumcision_update(new_date,duration,scale)
        %P.campaign_start_date doesn't get updated...
        P.tr = new_date;
        
        P.campaign_roll_out_duration = duration;
        P.Dtr = P.campaign_roll_out_duration;
        
        P.campaign_scale_factor = scale;
        P.x = scale;
    end
%% get
    function X = eventCircumcision_get(t)
        
        X = P;
    end

%% restore
    function [elements,msg] = eventCircumcision_restore(SDS,X)
        
        elements = SDS.number_of_males;
        msg = '';
        
        
        P = X;
        P.enable = SDS.male_circumcision.enable;
        P.rand0toInf = spTools('handle', 'rand0toInf');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        
    end

%% eventTimes
    function eventTimes = eventCircumcision_eventTimes(~, ~)
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventCircumcision_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventCircumcision_fire(SDS, P0)
        
        P0.male = P0.index;
        
        SDS.males.circumcision(P0.male) = P0.now;
        eventCircumcision_block(P0)     % uses P0.male
        
        %update transmission:
        currentIdx = SDS.relations.time(:, SDS.index.stop) == Inf;
        for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.male) == P0.male) ...
                & ismember(SDS.relations.ID(:, SDS.index.female),find(isnan(SDS.females.HIV_positive))))'
            P0.female = SDS.relations.ID(relIdx, SDS.index.female);
            if P0.serodiscordant(P0.male, P0.female)
                [SDS, P0] = P.updateTransmission(SDS, P0);
            end
        end
    end


%% enable
    function eventCircumcision_enable(SDS, P0)
        % Invoked by eventCircumcision_init <- This isn't an event....
        % Invoked by eventBirth_fire
        %
        % See SIMPACTimplementation.pdf for a derivation of the Cauchy
        % distributed hazard function and the linear scaled campaign
        % roll-out phase.
        
        if ~P.enable
            return
        end
        
        tb = SDS.males.born(P0.index);
        
        H1 = (atan((P.t1 - P.tp - tb)/P.gamma) + atan(P.tp/P.gamma))/pi; %before rollout hazard
        
        C2 = H1(end) - (P.gamma/2*(P.x - 1)/P.Dtr*...
            log((P.tr - P.tp - tb)^2 + P.gamma^2) + ...
            ((P.x - 1)/P.Dtr*(P.tr + P.tp + tb) + 1)*...
            atan((P.tr - P.tp - tb)/P.gamma))/pi;
        H2 = (P.gamma/2*(P.x - 1)/P.Dtr*...     %hazard during rollout
            log((P.t2 - P.tp - tb).^2 + P.gamma^2) + ...
            ((P.x - 1)/P.Dtr*(P.tr + P.tp + tb) + 1)*...
            atan((P.t2 - P.tp - tb)/P.gamma))/pi + C2;
        
        C3 = H2(end) - atan((P.tr + P.Dtr - P.tp - tb)/P.gamma)*P.x/pi;
        H3 = atan((P.t3 - P.tp - tb)/P.gamma)*P.x/pi + C3;
        
        H = [
            H1
            H2
            H3
            ];
        if tb > P.tr
            % shift to null at birth
            dH = interp1q(P.t, H(P.idx), tb);
        else
            dH = 0;
        end
        eventTime = interp1q(H(P.idx) - dH, P.t, P.T(P0.index)) - P0.now;
        eventTime(isnan(eventTime)) = Inf;
        
        P.eventTimes(P0.index) = eventTime;
    end


%% block
    function eventCircumcision_block(P0)
        % Invoked by eventCircumcision_fire
        % Invoked by eventMortality_fire
        
        P.eventTimes(P0.male) = Inf;       % once is enough
    end
end


%% name
function name = eventCircumcision_name

name = 'male circumcision';
end


%% properties
function [props, msg] = eventCircumcision_properties

msg = '';

props.Cauchy_scale_parameter = 1;                       % gamma
props.Cauchy_peak_age = 40;                             % tp
props.campaign_scale_factor = 1;                        % x
props.campaign_start_date = datestr('01-Jan-2050');     % tr
props.campaign_roll_out_duration = 2;                   % Dtr
props.time_vector_resolution = .5;                      % Dt
end
