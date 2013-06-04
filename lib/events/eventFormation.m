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
    function [elements, msg, P0] = eventFormation_init(SDS, event, P0)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
        
        P = event;                      % copy event parameters
        
        
        % ******* Function Handles *******
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
        [P.updateDissolution, thisMsg] = spTools('handle', 'eventDissolution', 'update');
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
        %NIU P.repmat = @eventFormation_repmat;
        %NIU P.meshgrid = @eventFormation_meshgrid;
        % ******* Indices *******
        P.indexStartStop = SDS.index.start | SDS.index.stop;
        P.relation = find(SDS.relations.ID(:,1), 1, 'last');
        if isempty(P.relation)
            P.relation = 0;
        end
        
        P.alpha = -inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.beta = - P.mean_age_factor + P.last_change_factor;
        P.beta = P.beta*ones(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.rand = Inf(SDS.number_of_males, SDS.number_of_females);
        P.time0 = zeros(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.eventTimes = inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        
        P.fix_PTR = event.fix_turn_over_rate;
        P.PTR = event.turn_over_rate;
        
        % ******* Checks *******
        if P.beta == 0
            P.expLinear = spTools('handle', 'expConstant');
            P.intExpLinear = spTools('handle', 'intExpConstant');
        end
        
        P0.subset(SDS.males.born<-15,SDS.females.born<-15) = true;
        P0.birth = false;
        P0 = eventFormation_enable(P0);
        
    end

%% get
    function X = eventFormation_get(t)
        
        X = P;
    end


%% restore
    function [elements,msg] = eventFormation_restore(SDS,X)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
        
        P = X;
        P.enable = SDS.formation.enable;
        P.rand0toInf = spTools('handle', 'rand0toInf');
        P.expLinear = spTools('handle', 'expLinear');
        P.intExpLinear = spTools('handle', 'intExpLinear');
        [P.enableConception, thisMsg] = spTools('handle', 'eventConception', 'enable');
        [P.enableDissolution, thisMsg] = spTools('handle', 'eventDissolution', 'enable');
        [P.updateDissolution, thisMsg] = spTools('handle', 'eventDissolution', 'update');
        [P.enableTransmission, thisMsg] = spTools('handle', 'eventTransmission', 'enable');
        
        [P.updateTest, thisMsg] = spTools('handle', 'eventTest', 'update');
        
    end

%% eventTimes
    function eventTimes = eventFormation_eventTimes(~, ~)
        
        eventTimes = P.eventTimes;
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
        P0.current(P0.male, P0.female) = true;
        
        % ******* Formation of Relation *******
        SDS.relations.ID(P.relation, :) = [P0.male, P0.female];
        SDS.relations.time(P.relation, P.indexStartStop) = [P0.now, Inf];
        SDS.relations.proximity(P.relation) = P0.communityDifference(P0.male,P0.female);
        
        P.enableConception(SDS, P0)          % uses P0.male; P0.female
        P.enableDissolution(P0)         % uses P0.index
        
        P.enableTransmission(SDS,P0);
        
        % ******* Prepare Next *******
        P.eventTimes(P0.index) = Inf;   % block formation
        P.rand(P0.index) = Inf;
        
        % ******* Influence on All Events: Cross *******
        P0 = eventFormation_update(SDS, P0, 1);
        P0 = P.updateDissolution(P0);
        
        P0.index = P0.male;
        P.updateTest(SDS, P0)
        P0.index = P0.female + SDS.number_of_males;
        P.updateTest(SDS, P0)
        
        P0.timeSinceLast(P0.male,:) = 0;
        P0.timeSinceLast(:,P0.female) = 0;
    end


%% enable
    function P0 = eventFormation_enable(P0)
        % Invoked by eventDissolution_fire, eventBirth_fire
        % Use P0.subset
        if ~P.enable
            return
        end
        
        P0.subset = P0.subset&~P0.current&~isfinite(P.eventTimes);
        P0.subset(~P0.aliveMales, :) = false;
        P0.subset(:,~P0.aliveFemales) = false;
        P.rand(P0.subset) = P.rand0toInf(1,sum(sum(P0.subset)));
        subsetRelationsCount=repmat(P0.femaleRelationCount, size(P0.subset, 1), 1);
        P.alpha(P0.subset) = P.baseline_factor*P0.partnering(P0.subset) + ...
            P.current_relations_factor.*P0.relationCount(P0.subset) + ...
            P.current_relations_difference_factor*P0.relationCountDifference(P0.subset) + ...
            P.female_current_relations_factor*subsetRelationsCount(P0.subset)+...
            P.mean_age_factor*(P0.meanAge(P0.subset) - P.age_limit) + ...
            P.last_change_factor*P0.timeSinceLast(P0.subset) + ...
            P.age_difference_factor*(exp(abs(P0.ageDifference(P0.subset) - ...
            P.preferred_age_difference)/8)-1) + ...
            P.transaction_sex_factor*P0.transactionSex(P0.subset) + ...
            P.community_difference_factor*abs(P0.communityDifference(P0.subset));
        P.beta(P0.subset) = P.beta(P0.subset) + ...
            P.behavioural_change_factor.*P0.relationCount(P0.subset);
        %.*P0.BCCexposureMean(P0.subset)/P.campaign_roll_out_duration;
        
        if P.fix_PTR
        active = isfinite(P.alpha);
        A = exp(P.alpha(active));
        CFH = sum(sum(A));  % cumulative formation hazard
        activeMales = P0.aliveMales'&(P.age_limit - P0.maleAge(:,1))<=0;
        activeFemales = P0.aliveFemales & (P.age_limit - P0.femaleAge(1,:))<=0;
        actives = sum(activeMales)+sum(activeFemales);
        PTR = P.PTR;
        CFHtarget = (actives/2) * PTR;
        CFHcorrectionfactor = CFHtarget/CFH;
        A = A * CFHcorrectionfactor;
        activeAlpha = log(A);    
        P.alpha(active) = activeAlpha;
        
        end
        P.eventTimes(P0.subset) = ...
            P.expLinear(P.alpha(P0.subset),P.beta(P0.subset),0,P.rand(P0.subset));
        P.time0(P0.subset) = P0.now; % time when the event is enabled
        P0.subset(P0.subset) = false;
    end


%% update (FROM FEI 07/10/2012)
    function P0 = eventFormation_update(SDS, P0, type)
        % updated by formation, dissolution
        % use P0.male, P0.female
        P0.subset(P0.male,:) = true;
        P0.subset(:,P0.female) = true;
        P0.subset = P0.subset&~P0.current&isfinite(P.eventTimes);
        P0.subset(~P0.aliveMales, :) = false;
        P0.subset(:,~P0.aliveFemales) = false;
        
        Pc = P.intExpLinear(P.alpha(P0.subset),P.beta(P0.subset),...
            0,min(P0.timeSinceLast(P0.subset),P0.now-P.time0(P0.subset)));
        
        P.rand(P0.subset) = P.rand(P0.subset)-Pc;
        P.rand(P.rand<0)=P.rand0toInf(1,sum(sum(P.rand<0)));
        if type ==1
            % formation
            
            P0.maleRelationCount(P0.male) = P0.maleRelationCount(P0.male) + 1;
            P0.femaleRelationCount(P0.female) = P0.femaleRelationCount(P0.female) + 1;
            P0.relationCount(P0.male,:) = P0.relationCount(P0.male,:) + 1;
            P0.relationCount(:,P0.female) = P0.relationCount(:,P0.female) + 1;
            
            femaleRelationMatrix = repmat(P0.femaleRelationCount, SDS.number_of_males, 1);
            
            P0.relationCountDifference = abs(...
                repmat(P0.maleRelationCount,1, SDS.number_of_females) - ...
                femaleRelationMatrix);
            
        end
        if type ==0
            % dissolution
            P0.maleRelationCount(P0.male) = P0.maleRelationCount(P0.male) - 1;
            P0.femaleRelationCount(P0.female) = P0.femaleRelationCount(P0.female) - 1;
            P0.relationCount(P0.male,:) = P0.relationCount(P0.male,:) - 1;
            P0.relationCount(:,P0.female) = P0.relationCount(:,P0.female) - 1;
            femaleRelationMatrix = repmat(P0.femaleRelationCount, SDS.number_of_males, 1);
            
            P0.relationCountDifference = abs(...
                repmat(P0.maleRelationCount, 1, SDS.number_of_females) - ...
                femaleRelationMatrix);
            
        end
        
        P.alpha(P0.subset) = P.baseline_factor*P0.partnering(P0.subset) + ...
            P.current_relations_factor.*P0.relationCount(P0.subset) + ...
            P.current_relations_difference_factor*P0.relationCountDifference(P0.subset) + ...
            P.female_current_relations_factor*femaleRelationMatrix(P0.subset)+...
            P.mean_age_factor*(P0.meanAge(P0.subset) - P.age_limit) + ...
            P.last_change_factor*P0.timeSinceLast(P0.subset) + ...
            P.age_difference_factor*(exp(abs(P0.ageDifference(P0.subset) - ...
            P.preferred_age_difference)/8)-1) + ...
            P.transaction_sex_factor*P0.transactionSex(P0.subset) + ...
            P.community_difference_factor*abs(P0.communityDifference(P0.subset));
        P.beta(P0.subset) = P.beta(P0.subset) + ...
            P.behavioural_change_factor.*P0.relationCount(P0.subset);
        
        if P.fix_PTR
           active = isfinite(P.alpha);
       
                 active = isfinite(P.alpha);
        A = exp(P.alpha(active));
    CFH = sum(sum(A));  % cumulative formation hazard
    activeMales = P0.aliveMales'&(P.age_limit - P0.maleAge(:,1))<=0;
    activeFemales = P0.aliveFemales & (P.age_limit - P0.femaleAge(1,:))<=0;
    actives = sum(activeMales)+sum(activeFemales);
    PTR = P.PTR;
    CFHtarget = (actives/2) * PTR;
    CFHcorrectionfactor = CFHtarget/CFH;
    A = A * CFHcorrectionfactor;
    activeAlpha = log(A);    
    P.alpha(active) = activeAlpha;
        end
        P.eventTimes(P0.subset) = ...
            P.expLinear(P.alpha(P0.subset),P.beta(P0.subset), 0, P.rand(P0.subset));
        
        P0.subset(P0.subset) = false;
    end
%% intervene
    function eventFormation_intervene(P0,names,values,start)
        for name = names
            P = setfield(P,name,values(names ==name));
        end
    end

%% block
    function eventFormation_block(P0)
        
        P.eventTimes(P0.subset) = Inf;
    end
end


%% name
function name = eventFormation_name

%name = 'partnership formation BCC';
name = 'formation';
end


%% properties
function [props, msg] = eventFormation_properties

msg = '';

props.baseline_factor = log(0.1);
props.current_relations_factor =log(0.18);
props.male_current_relations_factor =log(1);
props.female_current_relations_factor =log(0.9);
props.current_relations_difference_factor =log(1);
props.individual_behavioural_factor = 0;
props.behavioural_change_factor = 0;    % The effect of relations becomes larger during BCC;
props.mean_age_factor = 0;% -log(5)/50; %-log(hazard ration)/(age2-age1);
props.last_change_factor =0;% log(1);         % NOTE: intHazard = Inf for d = -c !!!
props.age_limit = 15;                 % no couple formation below this age
props.age_difference_factor = -log(5)/5;
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
props.fix_turn_over_rate = false;
props.turn_over_rate = 0.6;
props.campaign_roll_out_duration = 2;
props.time_vector_resolution = .5;

end


%% repmat
function B = eventFormation_repmat(A, M, N)
% included for performance ==> might move to spTools

[m, n] = size(A);
mind = (1 : m)';
nind = (1 : n)';
B = A(mind(:, ones(1, M)), nind(:, ones(1, N)));
end


%% meshgrid
function [xx, yy] = eventFormation_meshgrid(x, y)
% included for performance ==> might move to spTools

xx = x(ones(numel(y), 1), :);
yy = y(:, ones(numel(x), 1));
end

%%
function eventFormation_

debugMsg

end
