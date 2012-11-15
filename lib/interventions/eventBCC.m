function varargout = eventBCC(fcn, varargin)
%eventBCC SIMPACT event function: 
%
%   Implements init, eventTime, fire, internalClock, properties, name.
%   
%   See also SIMPACT, spRun, modelHIV, spTools.

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
    function [elements, msg] = eventBCC_init(SDS, event)
        
        elements = 1;
        msg = '';
        P = event;
        P.start_time = spTools('dateTOsimtime',P.campaign_start_date,SDS.start_date);
        P.eventTimes = P.start_time;
        
        %%Stuff that came from formationBCC
        P.rand0toInf = spTools('handle', 'rand0toInf');
        P.expLinear = spTools('handle', 'expLinear');
        P.intExpLinear = spTools('handle', 'intExpLinear');
        [P.enableConception, thisMsg] = spTools('handle', 'eventConception', 'enable');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.enableDissolution, thisMsg] = spTools('handle', 'eventDissolution', 'enable');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.enableTransmission, thisMsg] = spTools('handle', 'eventTransmission', 'enable');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.updateTest, thisMsg] = spTools('handle', 'eventTest', 'update');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        %NIU P.repmat = @eventFormationBCC_repmat;
        %NIU P.meshgrid = @eventFormationBCC_meshgrid;
        
        
        % ******* Indices *******
        P.indexStartStop = SDS.index.start | SDS.index.stop;
        P.relation = find(SDS.relations.ID(:,1), 1, 'last');
        if isempty(P.relation)
            P.relation = 0;
        end
        
        
        % ******* Variables & Constants *******
        daysPerYear = spTools('daysPerYear');
        P.tBCC = (datenum(P.campaign_start_date) - ...
            datenum(SDS.start_date))/daysPerYear;
        P.tEnd = (datenum(SDS.end_date) - datenum(SDS.start_date))/...
            daysPerYear;
        
        P.alpha = -inf(SDS.number_of_males, SDS.number_of_females, 3, SDS.float);
        false3D = false(size(P.alpha));
        P.subset = false3D;         % memory allocation
        P.subset2 = false3D;        % memory allocation
        P.subset3 = false3D;        % memory allocation
        
        P.beta = P.mean_age_factor + P.last_change_factor;
        P.beta2 = P.beta*ones(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.rand = P.rand0toInf(SDS.number_of_males, SDS.number_of_females);
        P.time0 = zeros(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.false = false(SDS.number_of_males, SDS.number_of_females);
    end


%% eventTimes
    function eventTimes = eventBCC_eventTimes(SDS,P0)
        
        %P.eventTimes = Inf;
        eventTimes = P.eventTimes;
    end

%% advance
    function eventBCC_advance(P0)
        % Also invoked when this event isn't fired.        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end

%% fire
    function [SDS,P0] = eventBCC_fire(SDS, P0)
        %After firing the eventTimes should be set to infinity
        
        %change formation hazard handle relative to current time
        if P.start_time >= P0.now
            %fprintf(1,'\nfire1!\n')
            SDS.events.formation.hazard = spTools('handle','eventBCC','Phase2Hazard');
            P.eventTimes = P0.now + P.campaign_roll_out_duration; %when we switch to phase 3
        else
            %fprintf(1,'\nfire2!\n')
            SDS.events.formation.hazard = spTools('handle','eventBCC','Phase3Hazard');
            P.eventTimes = Inf; %right now it's a one time thing
        end
    end

    function eventTimes = eventBCC_Phase2Hazard(SDS,P0,R)
        P0.subset(~P0.aliveMales, :) = false;
        P0.subset(:, ~P0.aliveFemales) = false;
        R.subset = repmat(P0.subset, [1 1 3]);  % 3D logical index matrix
        R.subset2(:, :, 2) = P0.subset; % alpha2 3D index matrix
        R.subset3(:, :, 3) = P0.subset; % alpha3 3D index matrix


        % ******* Age Limit *******
        boy = R.age_limit - P0.maleAge;
        boy(boy < 0) = 0;
        girl = R.age_limit - P0.femaleAge;
        girl(girl < 0) = 0;
        R.time0 = max(boy, girl);

        daysPerYear = spTools('daysPerYear');
        R.tBCC = (datenum(P.campaign_start_date) - ...
            datenum(SDS.start_date))/daysPerYear;
        t0 = R.time0(P0.subset);    % age limit
        t1 = R.tBCC - P0.now;       % BCC roll-out time, from now
        t2 = t1 + P.campaign_roll_out_duration;

        %P0.current_relations_factorMean(P0.subset)
        % ******* Hazard Parameters *******
        R.alpha(R.subset) = repmat(R.baseline_factor*P0.partnering(P0.subset) + ...
        P0.current_relations_factorMin(P0.subset).*P0.relationCount(P0.subset) + ...
        R.current_relations_difference_factor*P0.relationCountDifference(P0.subset) + ...
        R.mean_age_factor*(P0.meanAge(P0.subset) - R.age_limit) + ...
        R.last_change_factor*P0.timeSinceLast(P0.subset) + ...
        R.age_difference_factor*(exp(abs(P0.ageDifference(P0.subset) - ...
        R.preferred_age_difference)/5)-1) + ...
        R.transaction_sex_factor*P0.transactionSex(P0.subset) + ...
        R.community_difference_factor*abs(P0.communityDifference(P0.subset)), [1 1 3]);  % 3D matrix

        % R.individual_behavioural_factor*P0.riskyBehaviour(P0.subset)+...
        % R.alpha(R.subset2) = R.alpha(R.subset2) - ...   alpha 2
        %     R.behavioural_change_factor*P0.relationCount(P0.subset)*R.tBCC;
        R.alpha(:, :, 2) = R.alpha(:, :, 1) - ...       alpha 2
            P.behavioural_change_factor.*P0.relationCount.*t1.*P0.BCCexposureMean/...
            P.campaign_roll_out_duration;
        R.alpha(R.subset3) = R.alpha(R.subset3) + ...   alpha 3
        P.behavioural_change_factor.*P0.relationCount(P0.subset).*...
        P.campaign_roll_out_duration.*P0.BCCexposureMean(P0.subset);
        R.beta2(P0.subset) = R.beta + ...
        P.behavioural_change_factor.*P0.relationCount(P0.subset).*P0.BCCexposureMean(P0.subset)/...
        P.campaign_roll_out_duration;   % 2D matrix


        % ******* Vectors *******
        alpha1 = R.alpha(P0.subset);        % <== no typo
        alpha2 = R.alpha(R.subset2);
        alpha3 = R.alpha(R.subset3);
        beta2 = R.beta2(P0.subset);
        Pt = R.rand(P0.subset);

        % Phase 2 (during BCC)
        t = R.expLinear(alpha2, beta2, t0, Pt);

        %         idx3 = t > t2;         % event times during phase 3
        %         if any(idx3)
        %         T2 = R.intExpLinear(alpha2(idx3), beta2(idx3), min(t2, t0(idx3)), t2);
        %         t(idx3) = R.expLinear(alpha3(idx3), R.beta, max(t2, t0(idx3)), Pt(idx3) - T2);
        %         end
        eventTimes = R.eventTimes;
        eventTimes(P0.subset) = t;
    end

    function eventTimes = eventBCC_Phase3Hazard(SDS,P0,R)
        P0.subset(~P0.aliveMales, :) = false;
        P0.subset(:, ~P0.aliveFemales) = false;
        R.subset = repmat(P0.subset, [1 1 3]);  % 3D logical index matrix
        R.subset2(:, :, 2) = P0.subset; % alpha2 3D index matrix
        R.subset3(:, :, 3) = P0.subset; % alpha3 3D index matrix


        % ******* Age Limit *******
        boy = R.age_limit - P0.maleAge;
        boy(boy < 0) = 0;
        girl = R.age_limit - P0.femaleAge;
        girl(girl < 0) = 0;
        R.time0 = max(boy, girl);

        daysPerYear = spTools('daysPerYear');
        R.tBCC = (datenum(P.campaign_start_date) - ...
            datenum(SDS.start_date))/daysPerYear;
        t0 = R.time0(P0.subset);    % age limit
        t1 = R.tBCC - P0.now;       % BCC roll-out time, from now
        t2 = t1 + P.campaign_roll_out_duration;

        %P0.current_relations_factorMean(P0.subset)
        % ******* Hazard Parameters *******
        R.alpha(R.subset) = repmat(R.baseline_factor*P0.partnering(P0.subset) + ...
        P0.current_relations_factorMin(P0.subset).*P0.relationCount(P0.subset) + ...
        R.current_relations_difference_factor*P0.relationCountDifference(P0.subset) + ...
        R.mean_age_factor*(P0.meanAge(P0.subset) - R.age_limit) + ...
        R.last_change_factor*P0.timeSinceLast(P0.subset) + ...
        R.age_difference_factor*(exp(abs(P0.ageDifference(P0.subset) - ...
        R.preferred_age_difference)/5)-1) + ...
        R.transaction_sex_factor*P0.transactionSex(P0.subset) + ...
        R.community_difference_factor*abs(P0.communityDifference(P0.subset)), [1 1 3]);  % 3D matrix

        % R.individual_behavioural_factor*P0.riskyBehaviour(P0.subset)+...
        % R.alpha(R.subset2) = R.alpha(R.subset2) - ...   alpha 2
        %     R.behavioural_change_factor*P0.relationCount(P0.subset)*R.tBCC;
        R.alpha(:, :, 2) = R.alpha(:, :, 1) - ...       alpha 2
            P.behavioural_change_factor.*P0.relationCount.*t1.*P0.BCCexposureMean/...
            P.campaign_roll_out_duration;
        R.alpha(R.subset3) = R.alpha(R.subset3) + ...   alpha 3
        P.behavioural_change_factor.*P0.relationCount(P0.subset).*...
        P.campaign_roll_out_duration.*P0.BCCexposureMean(P0.subset);
        R.beta2(P0.subset) = R.beta + ...
        P.behavioural_change_factor.*P0.relationCount(P0.subset).*P0.BCCexposureMean(P0.subset)/...
        P.campaign_roll_out_duration;   % 2D matrix


        % ******* Vectors *******
        %alpha1 = R.alpha(P0.subset);        % <== no typo
        %alpha2 = R.alpha(R.subset2);
        alpha3 = R.alpha(R.subset3);
        %beta2 = R.beta2(P0.subset);
        Pt = R.rand(P0.subset);

        % Phase 3 (after BCC)
        t = R.expLinear(alpha3, R.beta, t0, Pt);
        eventTimes = R.eventTimes;  
        eventTimes(P0.subset) = t;
        R.eventTimes = eventTimes;
    end

end


%% properties
function [props,msg] = eventBCC_properties
msg = '';
props.campaign_start_date = datestr('01-Jan-2050');
props.baseline_factor = log(40/200);
props.current_relations_factor = log(0.2);
props.current_relations_difference_factor = log(0.5);
props.individual_behavioural_factor = 0;
props.behavioural_change_factor = 0;    % The effect of relations becomes larger during BCC;
props.mean_age_factor = -log(5)/40; %-log(hazard ration)/(age2-age1);
props.last_change_factor = log(1.005);         % NOTE: intHazard = Inf for d = -c !!!
props.age_limit = 15;                 % no couple formation below this age
props.age_difference_factor =-log(5)/40;
props.preferred_age_difference = 4.5;
props.community_difference_factor = 0;
props.transaction_sex_factor = log(2);
props.communities = {
    'lower exposure limit', 'upper exposure limit', 'exposure peak'
    0   .2  0
    .8  1   1
    };
props.BCC_exposure_function = JComponent('javax.swing.JComboBox', {
    'min'
    'max'
    'mean'}, 3);
props.partnering_function = JComponent('javax.swing.JComboBox', {
    'min'
    'max'
    'mean'}, 1);
props.campaign_roll_out_duration = 2;
props.time_vector_resolution = .5;
end


%% name
function name = eventBCC_name

name = 'BCC'; %behavioural change campaign
end

