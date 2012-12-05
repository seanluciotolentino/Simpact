function varargout = eventDissolution(fcn, varargin)
%EVENTDISSOLUTION SIMPACT event function: partnership dissolution
%
%   Implements init, eventTimes, advance, fire, update, properties, name.
%
%   See also modelHIV, eventFormation.

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
    function [elements, msg] = eventDissolution_init(SDS, event)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        
        
        % ******* Function Handles *******
        P.rand0toInf = spTools('handle', 'rand0toInf');
        P.expLinear = spTools('handle', 'expLinear');
        P.intExpLinear = spTools('handle', 'intExpLinear');
        [P.enableFormation, thisMsg] = spTools('handle', 'eventFormation', 'enable');
        %[P.enableFormation, thisMsg] = spTools('handle', 'eventFormationBCC', 'enable');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockConception, thisMsg] = spTools('handle', 'eventConception', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockTransmission, thisMsg] = spTools('handle', 'eventTransmission', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.updateTest, thisMsg] = spTools('handle', 'eventTest', 'update');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        
        % ******* Variables & Constants *******
        P.alpha = -inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.beta = P.mean_age_factor + P.last_change_factor;
        %P.rand = inf(SDS.number_of_males, SDS.number_of_females);
        P.rand = P.rand0toInf(SDS.number_of_males, SDS.number_of_females);
        %P.time0 = zeros(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.eventTimes = inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.false = false(SDS.number_of_males, SDS.number_of_females);
        
        %         P.long_term_factor = event.relations_type_factor{2,1};
        %         P.regular_factor = event.relations_type_factor{2,2};
        %         P.casual_factor = event.relations_type_factor{2,3};
        %
        % ******* Checks *******
        if P.beta == 0
            P.expLinear = spTools('handle', 'expConstant');
            P.intExpLinear = spTools('handle', 'intExpConstant');
        end
    end


%% get
    function X = eventDissolution_get()
        X = P;
    end

%% restore
    function [elements,msg] = eventDissolution_restore(SDS,X)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
        
        P = X;
        P.enable = SDS.dissolution.enable;
        P.rand0toInf = spTools('handle', 'rand0toInf');
        P.expLinear = spTools('handle', 'expLinear');
        P.intExpLinear = spTools('handle', 'intExpLinear');
        %[P.enableFormation, thisMsg] = spTools('handle', 'eventFormation', 'enable');
        [P.enableFormation, thisMsg] = spTools('handle', 'eventFormationBCC', 'enable');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockConception, thisMsg] = spTools('handle', 'eventConception', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockTransmission, thisMsg] = spTools('handle', 'eventTransmission', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.updateTest, thisMsg] = spTools('handle', 'eventTest', 'update');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        
        
        % ******* Checks *******
        if P.beta == 0
            P.expLinear = spTools('handle', 'expConstant');
            P.intExpLinear = spTools('handle', 'intExpConstant');
        end
    end
%% eventTimes
    function eventTimes = eventDissolution_eventTimes(~, ~)
        %{
        % ******* Current Relations *******
        subset = P0.current & P0.subset;
        
        
        % ******* Integrated Hazard *******
        % P.alpha(subset) = P.baseline_factor + ...
        %     P.current_relations_factor*P0.relationCount(subset) + ...
        %     P.mean_age_factor*(P0.meanAge(subset) - P.age_limit) + ...
        %     P.last_change_factor*P0.timeSinceLast(subset) + ...
        %     P.age_difference_factor*abs(P0.ageDifference(subset) - ...
        %     P.preferred_age_difference);
        P.alpha = P.baseline_factor + ...
            P.current_relations_factor*P0.relationCount + ...
            P.mean_age_factor*(P0.meanAge - P.age_limit) + ...
            P.last_change_factor*P0.timeSinceLast + ...
            P.age_difference_factor*abs(P0.ageDifference - ...
            P.preferred_age_difference);
        %eventDissolution_updateAlpha(P0, subset)
        P.eventTimes(subset) = P.expLinear(P.alpha(subset), P.beta, 0, P.rand(subset));
        %}
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventDissolution_advance(P0)
        % Also invoked when this event isn't fired.
        
        %P.rand = P.rand - P.intExpLinear(P.alpha, P.beta, P.time0, P0.eventTime);   % P - dT
        %P.time0 = max(0, P.time0 - P0.eventTime);
        P.rand = P.rand - P.intExpLinear(P.alpha, P.beta, 0, P0.eventTime);   % P - dT
        
        % P.eventTimes = ...                       % worry for later: update eventTimes if haz function has changed
        % P.expLinear(P.alpha, P.beta, 0, P.rand);
        
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventDissolution_fire(SDS, P0)
        
        % ******* Indices *******
        P0.male = rem(P0.index - 1, SDS.number_of_males) + 1;
        P0.female = ceil(P0.index/SDS.number_of_males);
        
        
        % ******* Dissolution of Relation *******
        [SDS, P0] = eventDissolution_dump(SDS, P0); % uses P0.male; P0.female
        
        
        % ******* Prepare Next *******
        %P.rand(P0.index) = P.rand0toInf(1, 1);
        P.enableFormation(P0)           % uses P0.male; P0.female
        P.blockConception(P0)
        
        % ******* Influence on All Events: Cross *******
        P0.subset = P.false;
        P0.subset(P0.male, :) = true;
        P0.subset(:, P0.female) = true;
        P0.index = P0.male;
        P.updateTest(SDS, P0)
        P0.index = P0.female + SDS.number_of_males;
        P.updateTest(SDS, P0)
        
        
    end


%% enable
    function eventDissolution_enable(P0)
        % Invoked by eventFormation_fire or eventFormationBCC_fire
        
        if ~P.enable
            return
        end
        
        P0.subset = P0.subset & P0.current; %I'm curious why this is different -Lucio 11/27
        P.rand(P0.index) = P.rand0toInf(1, 1);
        
        
        % ******* Integrated Hazard *******
        alpha = P.baseline_factor + ...
            P.current_relations_factor*P0.relationCount(P0.subset) + ...
            P.current_relations_difference_factor*P0.relationCountDifference(P0.subset) + ...
            P.mean_age_factor*(P0.meanAge(P0.subset) - P.age_limit) + ... 
            P.last_change_factor*P0.timeSinceLast(P0.subset) + ...
            P.age_difference_factor*(abs(P0.ageDifference(P0.subset) ...
                - (P.preferred_age_difference*P0.meanAge(P0.subset)*P.mean_age_growth)...
                    )./ (P.preferred_age_difference*P0.meanAge(P0.subset)*P.mean_age_dispersion) ) + ...
            P.transaction_sex_factor*P0.transactionSex(P0.subset) + ...
            P.community_difference_factor*abs(P0.communityDifference(P0.subset));
        %             P.long_term_factor*(P0.relationsTerm(subset)==1) +...
        %             P.regular_factor*(P0.relationsTerm(subset)==2)+...
        %             P.casual_factor*(P0.relationsTerm(subset)==3) ;...
        % + P.individual_behavioural_factor*P0.riskyBehaviour(subset);
        % P.eventTimes(P0.index) = ...
        %     P.expLinear(P.alpha(P0.index), P.beta, 0, P.rand0toInf(1, 1));
        P.eventTimes(P0.subset) = ...
            P.expLinear(alpha, P.beta, 0, P.rand(P0.subset));
    end


%% dump
    function [SDS, P0] = eventDissolution_dump(SDS, P0)
        % Invoked by eventDissolution_fire
        % Invoked by eventMortality_fire
        
        P.alpha(P0.male, P0.female) = -Inf;
        P.eventTimes(P0.male, P0.female) = Inf;
        
        relation = ...
            SDS.relations.ID(:, SDS.index.male) == P0.male & ...
            SDS.relations.ID(:, SDS.index.female) == P0.female;
        SDS.relations.time(find(relation, 1, 'last'), SDS.index.stop) = P0.now;
        P0.relationCount(P0.male, :) = P0.relationCount(P0.male, :) - 1;
        P0.relationCount(:, P0.female) = P0.relationCount(:, P0.female) - 1;
        P0.maleRelationCount(P0.male) = P0.maleRelationCount(P0.male) - 1;
        P0.femaleRelationCount(P0.female) = P0.femaleRelationCount(P0.female) - 1;
        P0.relationCountDifference = abs(...
            repmat(P0.maleRelationCount, 1, SDS.number_of_females) - ...
            repmat(P0.femaleRelationCount, SDS.number_of_males, 1));
        
        P0.timeSinceLast(P0.male, :) = 0;
        P0.timeSinceLast(:, P0.female) = 0;
        P0.current(P0.male, P0.female) = false;
        
        P.blockConception(P0)
        P.blockTransmission(SDS, P0)
    end
end


%% name
function name = eventDissolution_name

%name = 'partnership dissolution';
name = 'dissolution';
end


%% properties
function [props, msg] = eventDissolution_properties

msg = '';

props.baseline_factor = 0; %log(2);
props.community_factor = -1;
props.current_relations_factor = log(1.2); %log(4);
props.current_relations_difference_factor = log(0.5);
props.individual_behavioural_factor = 0;
props.mean_age_factor = -log(5)/40; %-log(hazard ration)/(age2-age1);
props.last_change_factor = log(0.7);
props.age_limit = 15;
props.age_difference_factor = 4.5;
props.mean_age_growth = 0.1; %how preferred age difference grows with mean age
props.mean_age_dispersion = 0.001; %how preferred age is dispersed with mean age (see documentation)
props.community_difference_factor = 0;
props.transaction_sex_factor = 1;
props.preferred_age_difference = 3;
% props.relations_type_factor = {
%   'long term' 'regular' 'casual'
%   -log(2) -log(1.5) -log(0.5)
%
% };

end