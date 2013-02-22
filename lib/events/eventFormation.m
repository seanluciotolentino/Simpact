function varargout = eventFormation(fcn, varargin)
%EVENTFORMATION SIMPACT event function: partnership formation with BCC
%effect
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
    function [elements, msg] = eventFormation_init(SDS, event)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
        
        P = event;                      % copy event parameters

        
        % ******* Function Handles *******
        P.rand0toInf = spTools('handle', 'rand0toInf');
        P.expLinear = spTools('handle', 'expLinear');
        P.intExpLinear = spTools('handle', 'intExpLinear');
        [P.enableConception, conMsg] = spTools('handle', 'eventConception', 'enable');
        [P.enableDissolution, disMsg] = spTools('handle', 'eventDissolution', 'enable');
        [P.enableTransmission, traMsg] = spTools('handle', 'eventTransmission', 'enable');
        [P.updateTest, tesMsg] = spTools('handle', 'eventTest', 'update');
        msg = [conMsg disMsg traMsg tesMsg]; 
        
        
        % ******* Indices *******
        P.indexStartStop = SDS.index.start | SDS.index.stop;
        P.relation = max( [0 find(SDS.relations.ID(:,1), 1, 'last')] ); %relationship index: 0 if no relationships yet
        
        
        % ******* Variables & Constants *******
        daysPerYear = spTools('daysPerYear');
        P.tEnd = (datenum(SDS.end_date) - datenum(SDS.start_date))/...
            daysPerYear;
        
        P.alpha = -inf(SDS.number_of_males, SDS.number_of_females);
        P.subset = false(size(P.alpha));
        
        P.beta = P.mean_age_factor + P.last_change_factor;
        P.rand = P.rand0toInf(SDS.number_of_males, SDS.number_of_females);
        P.time0 = zeros(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.eventTimes = inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.false = false(SDS.number_of_males, SDS.number_of_females);
    end

%% get
    function X = eventFormation_get()
	X = P;
    end

%% eventTimes
    function eventTimes = eventFormation_eventTimes(SDS, P0)
        if ~P.enable 
            eventTimes = inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
            P.eventTimes = eventTimes;
        else
            eventTimes = P.hazard(SDS,P0); %uses default hazard until BCC
            P.eventTimes = eventTimes;
        end
    end


%% advance
    function eventFormation_advance(P0)
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventFormation_fire(SDS, P0)
        % ******* Indices *******
        P.relation = P.relation + 1;
        P0.male = rem(P0.index - 1, SDS.number_of_males) + 1;
        P0.female = ceil(P0.index/SDS.number_of_males);
        
        
        % ******* Formation of Relation *******
        SDS.relations.ID(P.relation, :) = [P0.male, P0.female];
        SDS.relations.time(P.relation, P.indexStartStop) = [P0.now, Inf];
        SDS.relations.proximity(P.relation) = P0.communityDifference(P0.male,P0.female);
        P0.maleRelationCount(P0.male) = P0.maleRelationCount(P0.male) + 1;
        P0.femaleRelationCount(P0.female) = P0.femaleRelationCount(P0.female) + 1;        
        P0.relationCount(P0.male, :) = P0.relationCount(P0.male, :) + 1;
        P0.relationCount(:, P0.female) = P0.relationCount(:, P0.female) + 1;
        
        P0.relationCountDifference = abs(...
            repmat(P0.maleRelationCount, 1, SDS.number_of_females) - ...
            repmat(P0.femaleRelationCount, SDS.number_of_males, 1));        
        
        P0.timeSinceLast(P0.male, :) = 0;
        P0.timeSinceLast(:, P0.female) = 0;
        P0.current(P0.index) = true;

        % ******* Enable other events *******
        P.enableConception(SDS, P0)          % uses P0.male; P0.female
        P.enableDissolution(P0)         % uses P0.index
        P.enableTransmission(SDS,P0);
        
        % ******* Prepare Next *******
        P.eventTimes(P0.index) = Inf;   % block formation
        P.rand(P0.current) = Inf;
        
        
        % ******* Update other Events ******* --what does update do
        P0.index = P0.male;
        P.updateTest(SDS, P0)
        P0.index = P0.female + SDS.number_of_males;
        P.updateTest(SDS, P0)
        
    end


%% enable
    function eventFormation_enable(P0)
        % Invoked by eventDissolution_fire, eventBirth_fire
        
        if ~P.enable
            return
        end
        
        P.rand(P0.index) = P.rand0toInf(numel(P0.index), 1);
    end


%% block
    function eventFormation_block(P0)        
        P.eventTimes(P0.subset) = Inf;
    end

%% default hazard (with no BCC)
function eventTimes = eventFormation_defaultHazard(SDS, P0)
    %simple migration from event times here.  eventBCC will now change the
    %default hazard function 
    
    % ******* Subsets *******
    P0.subset = P0.true;
    P0.subset(~P0.aliveMales, :) = false;
    P0.subset(:, ~P0.aliveFemales) = false;
    P.subset = repmat(P0.subset, [1 1 3]);  % 3D logical index matrix
    P.subset2(:, :, 2) = P0.subset; % alpha2 3D index matrix
    P.subset3(:, :, 3) = P0.subset; % alpha3 3D index matrix


    % ******* Age Limit *******
    boy = P.age_limit - P0.maleAge;
    boy(boy < 0) = 0;
    girl = P.age_limit - P0.femaleAge;
    girl(girl < 0) = 0;
    P.time0 = max(boy, girl);

    t0 = P.time0(P0.subset);    
    
    alpha = P.baseline_factor*P0.partnering(P0.subset) + ...
        P.current_relations_factor*P0.relationCount(P0.subset) + ...
        P.current_relations_difference_factor*P0.relationCountDifference(P0.subset) + ...
        P.mean_age_factor*(P0.meanAge(P0.subset) - P.age_limit) + ... 
        P.last_change_factor*P0.timeSinceLast(P0.subset) + ...
        P.age_difference_factor*(abs(P0.ageDifference(P0.subset) ...
            - (P.preferred_age_difference*P0.meanAge(P0.subset)*P.mean_age_growth)...
                )./ (P.preferred_age_difference*P0.meanAge(P0.subset)*P.mean_age_dispersion) ) + ...
        P.transaction_sex_factor*P0.transactionSex(P0.subset) + ...
        P.community_difference_factor*abs(P0.communityDifference(P0.subset));
    
    Pt = P.rand(P0.subset);

    t = P.expLinear(alpha, P.beta, t0, Pt); %Returns time till event given cum. haz + t0 for P0.subset
    
    eventTimes = P.eventTimes;
    eventTimes(P0.subset) = t; %grab the event times for the subset we want

end

end


%% name
function name = eventFormation_name
   name = 'formation';
end


%% properties
function [props, msg] = eventFormation_properties

msg = '';

%These values were found using a genetic algorithm with the 
%output compared to the VLIR Cape Town Sexual Survey
props.baseline_factor 						= 2;
props.current_relations_factor 				= -0.1;
props.current_relations_difference_factor 	= 0;
props.individual_behavioural_factor 		= 0;
props.behavioural_change_factor 			= 0;    
props.mean_age_factor 						= -0.00452; 
props.last_change_factor 					= 0.0138;        
props.age_limit 							= 15;                 
props.age_difference_factor 				= 0.1;
props.preferred_age_difference 				= -0.1812;
props.mean_age_growth 						= 0.4; 
props.mean_age_dispersion 					= 0.1544; 
props.community_difference_factor 			= 0;
props.transaction_sex_factor 				= 0;
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
props.time_vector_resolution = .5;
props.hazard = spTools('handle','eventFormation','defaultHazard');

end
