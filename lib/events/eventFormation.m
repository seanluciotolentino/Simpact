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
        % maleRange = 1 : SDS.initial_number_of_males;
        % femaleRange = 1 : SDS.initial_number_of_females;
        % malesNaN = nan(1, SDS.number_of_males, SDS.float);
        % femalesNaN = nan(1, SDS.number_of_females, SDS.float);
        
        P = event;                      % copy event parameters
        if ~P.enable
            return
        end
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
        
        
        % ******* Variables & Constants *******
        daysPerYear = spTools('daysPerYear');
        %P.tBCC = (datenum(P.campaign_start_date) - ...
        %    datenum(SDS.start_date))/daysPerYear;
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
        P.eventTimes = inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        P.false = false(SDS.number_of_males, SDS.number_of_females);
        
        
%         P.P1in = event.partner_type_parameters{2,2};
%         P.P1out = event.partner_type_parameters{2,3};
%         P.P3in = event.partner_type_parameters{4,2};
%         P.P3out = event.partner_type_parameters{4,3};
        
        % SDS.males.commID = malesNaN;
        % SDS.females.commID = femalesNaN;
        % communityMale = empiricalCommunity(SDS.initial_number_of_males, SDS.number_of_communities);
        % communityFemale = empiricalCommunity(SDS.initial_number_of_females, SDS.number_of_communities);
        % SDS.males.commID(maleRange) = communityMale;
        % SDS.females.commID(femaleRange) = communityFemale;
        %P0.subset(~P0.aliveMales, :) = false;
        %P0.subset(:, ~P0.aliveFemales) = false;
        
               
    end

%% get
    function X = eventFormation_get()
	X = P;
    end

	
%% restore
    function [elements,msg] = eventFormation_restore(SDS,X)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
	
        P = X;
        P.enable = SDS.events.formation_BCC.enable;
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

        
        %This is what was here before Aaron modified the code
        
      %{  
        % ******* Consumed Internal Clock Time *******
        t0 = min(P0.eventTime, P.time0(P0.current));    % age limit
        t1 = P.tBCC - P0.now;       % BCC roll-out time, from now
        t2 = t1 + P.campaign_roll_out_duration;
        
        if t1 > 0
            % 1. before BCC
            alpha = P.alpha(:, :, 1);
            beta = P.beta;
            
        elseif t2 > 0
            % 2. during BCC
            alpha = P.alpha(:, :, 2);
            beta = P.beta2(P0.current);
            
        else
            % 3. after BCC
            alpha = P.alpha(:, :, 3);
            beta = P.beta;
        end
%}
       
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
  
%         P.subset = repmat(P0.subset, [1 1 3]);  % 3D logical index matrix
%         P.subset2(:, :, 2) = P0.subset; % alpha2 3D index matrix
%         P.subset3(:, :, 3) = P0.subset; % alpha3 3D index matrix
%         
%         
%         % ******* Consumed Internal Clock Time *******
%         t0 = min(P0.eventTime(:), P.time0(P0.subset));    % age limit
%         t1 = P.tBCC - P0.now;       % BCC roll-out time, from now
%         t2 = t1 + P.campaign_roll_out_duration;        
% 
%  
%          % ******* Vectors *******
%         alpha1 = P.alpha(P0.subset);        % <== no typo
%         alpha2 = P.alpha(P.subset2);
%         alpha3 = P.alpha(P.subset3);
%         beta2 = P.beta2(P0.subset);
%  
%          % ******* Integrated Hazards *******
%          %If BCC hasn't hit yet
%          % Phase 1 (before BCC)
%          % h is hazard of P0.eventTime
%         if t1 > P0.eventTime
%             h = P.intExpLinear(alpha1, P.beta, t0, P0.eventTime); 
%             
%         else
%             %If event is past start of BCC  
%             if t2 > P0.eventTime
%                 h1 = P.intExpLinear(alpha1, P.beta, min(t0,t1), t1); %Cum. haz from 0 to t1 using before BCC haz. params
%                 h = h1 + P.intExpLinear(alpha2, beta2, max(t0,t1), P0.eventTime); 
%             else
%             %event times during phase 3
%                 h1 = P.intExpLinear(alpha1, P.beta, min(t0,t1), t1); %Hazard used up until BCC
%                 h2 = P.intExpLinear(alpha2, beta2, min(max(t0,t1),t2), t2); %Hazard used up until end of BCC
%                 h = h1 + h2 + P.intExpLinear(alpha3, P.beta, max(t0,t2), P0.eventTime); %Given above, time till event
%             end
%         end
%         
%             
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % P - dT
%         P.rand(P0.subset) = P.rand(P0.subset) - h;
%         
%         %P.rand = P.rand - P.intExpLinear(alpha, beta, t0, P0.eventTime);
%         %P.rand(P0.current) = P.rand(P0.current) - ...
%         %   exp(alpha(P0.current)).*(exp(beta*P0.eventTime) - exp(beta.*t0))./beta;
%         if any(P.rand < 0)
%             1;
%         end
        
        % ******* Shift Event Times *******
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventFormation_fire(SDS, P0)
        
        persistent ave_tbe tbe
        
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
%         averageAge = (P0.now - SDS.males.born(P0.male)+P0.now - SDS.females.born(P0.female))/2;
%         shortTermIn = interp1q([0,20,65]',[0,P.P3in,0]',averageAge);
%         shortTermOut = interp1q([0,20,65]',[0,P.P3out,0]',averageAge);
%         if isempty(find(P0.relationsTerm(P0.male,:)==1))&&isempty(find(P0.relationsTerm(:,P0.female)==1))
%             if (P0.communityDifference(P0.male, P0.female)==0&&rand<=averageAge*P.P1in/65)||...
%                 (P0.communityDifference(P0.male, P0.female)~=0&&rand<=averageAge*P.P1out/65)
%             P0.relationsTerm(P0.male, P0.female)=1;
%             else
%                 if (P0.communityDifference(P0.male, P0.female)==0&&rand<=shortTermIn)||...
%                 (P0.communityDifference(P0.male, P0.female)~=0&&rand<=shortTermOut)
%                 P0.relationsTerm(P0.male, P0.female)=3;
%                 else
%                  P0.relationsTerm(P0.male, P0.female)=2;
%                 end
%             end
%         else
%             if (P0.communityDifference(P0.male, P0.female)==0&&rand<=shortTermIn)||...
%                 (P0.communityDifference(P0.male, P0.female)~=0&&rand<=shortTermOut)
%             P0.relationsTerm(P0.male, P0.female)=3;
%             else
%                  P0.relationsTerm(P0.male, P0.female)=2;
%             end
%         end
%         SDS.relations.type(P.relation) = P0.relationsTerm(P0.male, P0.female);
% 
%         
        P.enableConception(SDS, P0)          % uses P0.male; P0.female
        P.enableDissolution(P0)         % uses P0.index

   
        P.enableTransmission(SDS,P0);
        
        % ******* Prepare Next *******
        P.eventTimes(P0.index) = Inf;   % block formation
        P.rand(P0.current) = Inf;
        
        
        % ******* Influence on All Events: Cross *******
        P0.subset = P.false;
        P0.subset(P0.male, :) = true;
        P0.subset(:, P0.female) = true;
        %? P0.subset = P0.subset & P0.alive;       % maybe not necessary

        if (~exist('tbe','var')) & (~exist('ave_tbe','var'))
            tbe = P0.eventTime;
            ave_tbe =sum(tbe)/length(tbe);
        else
            if size(tbe) == 1
                tbe = P0.eventTime;
                ave_tbe =sum(tbe)/length(tbe); 
            else
                tbe = vertcat(tbe,P0.eventTime);
                ave_tbe = vertcat(ave_tbe,sum(tbe)/length(tbe));
            end
        end
        
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

    %P0.current_relations_factorMean(P0.subset)
    % ******* Hazard Parameters *******
    P.alpha(P.subset) = repmat(P.baseline_factor*P0.partnering(P0.subset) + ...
        P0.current_relations_factorMin(P0.subset).*P0.relationCount(P0.subset) + ...
        P.current_relations_difference_factor*P0.relationCountDifference(P0.subset) + ...
        P.mean_age_factor*(P0.meanAge(P0.subset) - P.age_limit) + ...
        P.last_change_factor*P0.timeSinceLast(P0.subset) + ...
        P.age_difference_factor*(exp(abs(P0.ageDifference(P0.subset) - ...
        P.preferred_age_difference)/5)-1) + ...
        P.transaction_sex_factor*P0.transactionSex(P0.subset) + ...
        P.community_difference_factor*abs(P0.communityDifference(P0.subset)), [1 1 3]);  % 3D matrix

    % P.individual_behavioural_factor*P0.riskyBehaviour(P0.subset)+...
    % P.alpha(P.subset2) = P.alpha(P.subset2) - ...   alpha 2
    %     P.behavioural_change_factor*P0.relationCount(P0.subset)*P.tBCC;
    %P.alpha(:, :, 2) = P.alpha(:, :, 1) - ...       alpha 2
    %    P.behavioural_change_factor.*P0.relationCount.*t1.*P0.BCCexposureMean/...
    %    P.campaign_roll_out_duration;
    %P.alpha(P.subset3) = P.alpha(P.subset3) + ...   alpha 3
    %    P.behavioural_change_factor.*P0.relationCount(P0.subset).*...
    %    P.campaign_roll_out_duration.*P0.BCCexposureMean(P0.subset);
    %P.beta2(P0.subset) = P.beta + ...
    %    P.behavioural_change_factor.*P0.relationCount(P0.subset).*P0.BCCexposureMean(P0.subset)/...
    %    P.campaign_roll_out_duration;   % 2D matrix


    % ******* Vectors *******
    alpha1 = P.alpha(P0.subset);        % <== no typo
    %alpha2 = P.alpha(P.subset2);
    %alpha3 = P.alpha(P.subset3);
    %beta2 = P.beta2(P0.subset);
    Pt = P.rand(P0.subset);

    %If BCC hasn't hit yet
    % Phase 1 (before BCC)
    t = P.expLinear(alpha1, P.beta, t0, Pt); %Returns time till event given cum. haz + t0 for P0.subset
            
    %     idx2 = t > t1;              
    %     % event times during phase 2 or 3
    %     if any(idx2)                %If time till event is past start of BCC
    %         T1 = P.intExpLinear(alpha1(idx2), P.beta, min(t1, t0(idx2)), t1); %Cum. haz from time min(t1,t0) to t1 using before BCC haz. params
    %         t(idx2) = P.expLinear(alpha2(idx2), beta2(idx2), max(t1, t0(idx2)), Pt(idx2) - T1); %Time till event given (cum. haz - above) + max(t1, t0)
    %                                                                                             %using BCC params
    % 
    %         idx3 = t > t2;         % event times during phase 3
    %         if any(idx3)
    %             T1 = P.intExpLinear(alpha1(idx3), P.beta, min(t1, t0(idx3)), t1); %Hazard used up until BCC
    %             T2 = P.intExpLinear(alpha2(idx3), beta2(idx3), min(t2, max(t1, t0(idx3))), t2) + T1; %Hazard used up until end of BCC
    %             t(idx3) = P.expLinear(alpha3(idx3), P.beta, max(t2, t0(idx3)), Pt(idx3) - T2); %Given above, time till event
    %         end
    %     end
    
    eventTimes = P.eventTimes;
    eventTimes(P0.subset) = t; %grab the event times for the subset we want
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

%props.campaign_start_date = datestr('01-Jan-2050');
props.baseline_factor = log(40/200);
props.current_relations_factor = log(0.2);
props.current_relations_difference_factor = log(0.5);
props.individual_behavioural_factor = 0;
%props.behavioural_change_factor = 0;    % The effect of relations becomes larger during BCC;
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
%props.campaign_roll_out_duration = 2;
props.time_vector_resolution = .5;
props.hazard = spTools('handle','eventFormation','defaultHazard');
% props.partner_type_parameters={
% '' 'in-community' 'inter-community' 'baselin age'    
% 'long term' 0.5 0.2 65
% 'regular' '' '' ''
% 'casual' 0.2 0.3 20 
% };
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