function varargout = eventTransmission(fcn, varargin)
%EVENTTRANSMISSION SIMPACT event function: HIV transmission
%
% See also spGui, spRun, spModel, spTools.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

persistent P

if nargin == 0
    eventTransmission_test
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
    function [elements, msg] = eventTransmission_init(SDS, event)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        infections = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        
        % ******* Function Handles *******
        [P.enableAIDSmortality, msg] = spTools('handle', 'eventAIDSmortality', 'enable');
        [P.enableTest, msg] = spTools('handle', 'eventTest', 'enable');
        [P.fireTest, msg] = spTools('handle', 'eventTest', 'fire');
        [P.enableMTCT, msg] = spTools('handle', 'eventMTCT', 'enable');
        
        % ******* Variables & Constants *******
        P.rand = spTools('rand0toInf', SDS.number_of_males, SDS.number_of_females);
        
        sexActsPerYear =event.sexual_behaviour_parameters{2,1}*52;%*(unprotected+(1-unprotected)*(1-condomEffect));
        P.ARVeffect = 1- event.infectiousness_decreased_by_ARV;
        P.probabilityChange = ones(SDS.number_of_males, SDS.number_of_females);
        P.eventTimes = inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        
        varWeibull = event.AIDS_mortality_distribution{2, 1};
        P.shape = event.AIDS_mortality_distribution{2, 2};
        P.scale = event.AIDS_mortality_distribution{2, 3};
        P.timeDeath = [SDS.males.AIDSdeath, SDS.females.AIDSdeath];
        
        %P.timeDeath = spTools('weibull', P.scale, P.shape, rand(1, infections));
        P.false = false(SDS.number_of_males, SDS.number_of_females);
        P.update = false;
        
        P.probability = [event.infectiousness{2:end, end}]';
        P.loglogP =  log(-log(1-P.probability/100));
        % random weibull
        P.riskReduction = event.risk_behaviour_reduction;
        P.alpha = sexActsPerYear*ones(SDS.number_of_males,SDS.number_of_females);%.*(-log(rand(SDS.number_of_males,SDS.number_of_females))).^(1/4);
        P.alpha = log(P.alpha);
        P.beta = event.sexual_behaviour_parameters{2,end};
        P.t = nan(4, infections, SDS.float);
        
        P.algebraicSystem = [
            event.infectiousness(2:end, 1:2)
            {varWeibull, ''}
            ];
        debugState = false;
        if isme
            debugState = he('-debug');
        end
        if debugState
            he('-debug')
        end
        tic
        for ii = 1 : infections
            P.algebraicSystem{4, 2} = sprintf('%g', P.timeDeath(ii));
            P.algebraicSystem = solvesys(P.algebraicSystem);
            P.t(:, ii) = [P.algebraicSystem{:, 3}]';
        end
        %toc    % ~1/200 sec/infection
        if debugState
            he('-debug')
        end
        
        % ******* Integrated Hazards for Entire Population *******
        %***********************************%
        % CD4 count at infection
        P.ageFactor =  event.CD4_distribution_at_infection{2,2};
        P.genderDifference = event.CD4_distribution_at_infection{2,3};
        P.CD4shape= event.CD4_distribution_at_infection{2,4};
        logMedian = log(event.CD4_distribution_at_infection{2,1});
        %P.C0 = lognrnd(logMedian, P.CD4shape, 1, SDS.number_of_males+SDS.number_of_females);
        P.C0 = 600*ones(1,SDS.number_of_males+SDS.number_of_females);
        P.lastChange = nan(SDS.number_of_males,SDS.number_of_females, SDS.float);
    end

%% get
    function X = eventTransmission_get(t)
        X = P;
    end

%% restore
    function [elements,msg] = eventTransmission_restore(SDS,X)
        
        elements = SDS.number_of_males * SDS.number_of_females;
        msg = '';
        
        P = X;
        P.enable = SDS.HIV_transmission.enable;
        
        [P.enableAIDSmortality, msg] = spTools('handle', 'eventAIDSmortality', 'enable');
        [P.enableTest, msg] = spTools('handle', 'eventTest', 'enable');
        [P.fireTest, msg] = spTools('handle', 'eventTest', 'fire');
        [P.enableMTCT, msg] = spTools('handle', 'eventMTCT', 'enable');
        
        % ******* Variables & Constants *******
        P.rand = spTools('rand0toInf', SDS.number_of_males, SDS.number_of_females);
        
    end

%% eventTimes
    function eventTimes = eventTransmission_eventTimes(~, ~)
        eventTimes = P.eventTimes;
    end


%% advance
    function eventTransmission_advance(P0)
        % Also invoked when this event isn't fired.
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventTransmission_fire(SDS, P0)
        
        % ******* Indices *******
        if P0.introduce % use P0.male/P0.female
            P0.introduce = false;
        else
            P0.male = rem(P0.index - 1, SDS.number_of_males) + 1;
            P0.female = ceil(P0.index/SDS.number_of_males);
            % ******* Prepare Next *******
            P.eventTimes(P0.male, P0.female) = Inf;
            
        end
        
        currentIdx = SDS.relations.time(:, SDS.index.stop) == Inf;  % indexing the ongoing relationships
        P0.subset = P.false;
        
        % ******* Infection *******
        if (P0.male~=0&&isnan(SDS.males.HIV_positive(P0.male)))||P0.female==0
            % female infecting male
            P0.serodiscordant(P0.male, :) = ~P0.serodiscordant(P0.male, :);
            P0.subset(P0.male, :) = true;
            SDS.males.HIV_source(P0.male) = P0.female;
            SDS.males.HIV_positive(P0.male) = P0.now;
            P0.index = P0.male;
            P.eventTimes(P0.male, ~P0.serodiscordant(P0.male,:)) = Inf;
            
            SDS.males.CD4Infection(P0.male) = P.C0(P0.male) + P.ageFactor*(P0.now-SDS.males.born(P0.male)) + P.genderDifference*0;
            SDS.males.CD4Death(P0.male) = SDS.males.CD4Infection(P0.male)*(1-(1-rand)^.5)/15;
            [SDS.males.CD4_500(P0.male),SDS.males.CD4_350(P0.male),SDS.males.CD4_200(P0.male)]=...
                CD4Interp(SDS.males.CD4Infection(P0.male),SDS.males.CD4Death(P0.male),SDS.males.AIDSdeath(P0.male),P0.now);
            SDS.males.AIDSdeath(P0.male) = P.timeDeath(P0.male);
            P.enableTest(SDS,P0) %uses P0.index
            for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.male) == P0.male) &...
                    ismember(SDS.relations.ID(:, SDS.index.female),find(isnan(SDS.females.HIV_positive))))'
                % ******* Enable Transmission for His Other Relations *******
                P0.female = SDS.relations.ID(relIdx, SDS.index.female);
                eventTransmission_enable(SDS, P0)   % uses P0.male; P0.female
                P0.subset(:, P0.female) = true;
            end
            
        else
            % male infecting female
            P0.serodiscordant(:, P0.female) = ~P0.serodiscordant(:, P0.female);
            P0.subset(:, P0.female) = true;
            SDS.females.HIV_source(P0.female) = P0.male;
            SDS.females.HIV_positive(P0.female) = P0.now;
            P0.index = SDS.number_of_males + P0.female;
            P.eventTimes(~P0.serodiscordant(:,P0.female), P0.female) = Inf;
            SDS.females.CD4Infection(P0.female) = P.C0(P0.index) + P.ageFactor*(P0.now-SDS.females.born(P0.female)) + P.genderDifference*1;
            SDS.females.CD4Death(P0.female) = SDS.females.CD4Infection(P0.female)*(1-(1-rand)^.5)/15;
            SDS.females.AIDSdeath(P0.female) = P.timeDeath(P0.index);
            [SDS.females.CD4_500(P0.female),SDS.females.CD4_350(P0.female),SDS.females.CD4_200(P0.female)]=...
                CD4Interp(SDS.females.CD4Infection(P0.female),SDS.females.CD4Death(P0.female),SDS.females.AIDSdeath(P0.female),P0.now);
            P.enableTest(SDS,P0) %uses P0.index
            for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.female) == P0.female) &...
                    ismember(SDS.relations.ID(:, SDS.index.male),find(isnan(SDS.males.HIV_positive))))'
                % ******* Enable Transmission for Her Other Relations *******
                P0.male = SDS.relations.ID(relIdx, SDS.index.male);
                eventTransmission_enable(SDS, P0)   % uses P0.male; P0.female
                P0.subset(P0.male, :) = true;
            end
            P.enableMTCT(SDS, P0, P0.female);
        end
        
        if P0.now>10
            P0.now
        end
        
        P.enableAIDSmortality(P0, P.timeDeath(P0.index))    % uses P0.index
        
        if P0.male~=0&&P0.female~=0
            P.lastChange(P0.male, P0.female) = P0.now;
        end
        
        % ******* Influence on All Events: Points *******
        P0.subset = P0.subset & P0.current;
    end


%% enable
    function  eventTransmission_enable(SDS, P0)
        % Invoked by eventFormation_fire
        
        if ~P.enable||~P0.serodiscordant(P0.male, P0.female)||~P0.aliveMales(P0.male)||~P0.aliveFemales(P0.female)
            return
        end
        
        timeHIVpos = SDS.males.HIV_positive(P0.male);
        idx = P0.male;
        ARV = SDS.males.ARV(P0.male);
        condom = SDS.males.condom(P0.male); %added by Lucio
        pregnant = false;
        circumcision = ~isnan(SDS.males.circumcision(P0.male));
        if isnan(timeHIVpos)
            % female is HIV+
            timeHIVpos = SDS.females.HIV_positive(P0.female);
            idx = SDS.number_of_males + P0.female;
            ARV = SDS.females.ARV(P0.female);
            pregnant = P0.pregnant(P0.female);
            %circumcision = false;
        end
        
        if ~P.update % enabled by eventTransmission
            % determining alpha by
            % 'baseline' 'mean age' 'age difference' 'relation type' 'relations count' 'serodiscordant' 'HIV disclosure'
            % P.alpha(P0.male, P0.female)=
            
            if condom %added by Lucio 08/30
                P.probabilityChange(P0.male,P0.female) = 1-P.infectiousness_decreased_by_condom;
            end
            
            if ARV
                P.probabilityChange(P0.male,P0.female) = 1-P.infectiousness_decreased_by_ARV;
            end
            
            if pregnant
                P.probabilityChange(P0.male,P0.female) = P.probabilityChange(P0.male,P0.female)*P.infectiousness_increased_during_conception;
            end
            
            if circumcision&&idx>SDS.number_of_males;
                P.probabilityChange(P0.male,P0.female) = P.probabilityChange(P0.male,P0.female)* (1-P.infectiousness_decreased_by_circumcision);
            end
        end
        
        probability = P.probability * P.probabilityChange(P0.male,P0.female);
        loglogP =  log(-log(1- probability/100));
        %loglogP = log(probability/100);
        a = P.alpha(P0.male, P0.female) + loglogP + (P0.now>12)*(P0.now-12)*log(1-P.riskReduction);       
        T = [timeHIVpos, P.t(2:end, idx)'+timeHIVpos];
        %         T = [timeHIVpos, P.t(2:end, idx)'];
        %         T = cumsum(T);
        relationID = intersect(find(SDS.relations.ID(:,1)==P0.male),find(SDS.relations.ID(:,2)==P0.female));
        relationID = relationID(end);
        Tformation = SDS.relations.time(relationID,1);
        
        P.eventTimes(P0.male, P0.female) = ...
            transmissionTime(P.rand(P0.male,P0.female), P0.now, Tformation, T, a, P.beta);
        
        P.lastChange(P0.male, P0.female) = P0.now;
        
        
        
    end

%% update
    function [SDS,P0] = eventTransmission_update(SDS, P0)
        % called by eventARV, eventARVstop, eventConception, eventBirth,
        % eventCircumcision, eventCondom
        
        timeHIVpos = SDS.males.HIV_positive(P0.male);
        idx = P0.male;
        condom = SDS.males.condom(P0.male); %added by Lucio
        circumcision = SDS.males.circumcision(P0.male) ==P0.now;
        ARVstart = SDS.males.ARV_start(P0.male) == P0.now;
        ARVstop = SDS.males.ARV_stop(P0.male) == P0.now;
        timeDeath = SDS.males.AIDSdeath(P0.male);
        if isnan(timeHIVpos)
            % female is HIV+
            timeHIVpos = SDS.females.HIV_positive(P0.female);
            idx = SDS.number_of_males + P0.female;
            ARVstart = SDS.females.ARV_start(P0.female) == P0.now;
            ARVstop = SDS.females.ARV_stop(P0.female) == P0.now;
            timeDeath = SDS.females.AIDSdeath(P0.female);
            %circumcision = false;
        end
        probability = P.probability * P.probabilityChange(P0.male,P0.female);
        loglogP =  log(-log(1- probability/100));
        %loglogP = log(probability/100);
        lastChange = P.lastChange(P0.male, P0.female);
        T = [timeHIVpos, P.t(2:end, idx)'+timeHIVpos];
        %         T = [timeHIVpos, P.t(2:end, idx)'];
        %         T = cumsum(T);
        relationID = intersect(find(SDS.relations.ID(:,1)==P0.male),find(SDS.relations.ID(:,2)==P0.female));
        relationID = relationID(end);
        Tformation = SDS.relations.time(relationID,1);
        a = P.alpha(P0.male, P0.female) + loglogP+ (P0.now>12)*(P0.now-12)*log(1-P.riskReduction);
        P.rand(P0.male,P0.female) = P.rand(P0.male,P0.female) ...
            - consumedRand(P0.now, Tformation, T, lastChange, a, P.beta);
        
        if condom %added by Lucio 08/30
            P.probabilityChange(P0.male,P0.female) = 1-P.infectiousness_decreased_by_condom;
        end
        
        if P0.conception;
            P.probabilityChange(P0.male,P0.female) = P.probabilityChange(P0.male,P0.female)*P.infectiousness_increased_during_conception;
        end
        
        if P0.birth;
            P.probabilityChange(P0.male,P0.female) = P.probabilityChange(P0.male,P0.female)/P.infectiousness_increased_during_conception;
        end
        
        if circumcision&&idx>SDS.number_of_males;
            P.probabilityChange(P0.male,P0.female) = P.probabilityChange(P0.male,P0.female)*(1-P.infectiousness_decreased_by_circumcision);
        end
        
        if ARVstart
            % transmission hazard shift with ARV  start
            P.algebraicSystem{4, 2} = sprintf('%g', timeDeath);
            P.algebraicSystem = solvesys(P.algebraicSystem);
            P.t(3, idx) = P.algebraicSystem{3, 3};
            P.t(4, idx) = P.algebraicSystem{4, 3};
            P.probabilityChange(P0.male,P0.female) = P.probabilityChange(P0.male,P0.female)*(1-P.infectiousness_decreased_by_ARV);
        end
        
        if ARVstop
            P.algebraicSystem{4, 2} = sprintf('%g', timeDeath);
            P.algebraicSystem = solvesys(P.algebraicSystem);
            P.t(3, idx) = P.algebraicSystem{3, 3};
            P.t(4, idx) = P.algebraicSystem{4, 3};
            P.probabilityChange(P0.male,P0.female) = P.probabilityChange(P0.male,P0.female)/(1- P.infectiousness_decreased_by_ARV);
        end
        
        %monitor
        
        P.update = true;
        eventTransmission_enable(SDS,P0)
        P.update = false;
    end


%% setup

    function SDS = eventTransmission_setup(SDS, P0)
        
        if P0.index<=SDS.number_of_males;
            SDS.males.CD4Infection(P0.index) = P.C0(P0.index) + P.ageFactor*(P0.now-SDS.males.born(P0.index)) + P.genderDifference*0;
            SDS.males.CD4Death(P0.index) = SDS.males.CD4Infection(P0.index)*(1-(1-rand)^.5)/15;
            SDS.males.AIDSdeath(P0.index) = P.timeDeath(P0.index);
            
        else
            SDS.females.CD4Infection(P0.female) = P.C0(P0.index) + P.ageFactor*(P0.now-SDS.females.born(P0.female)) + P.genderDifference;
            SDS.females.CD4Death(P0.female) = SDS.females.CD4Infection(P0.female)*(1-(1-rand)^.5)/15;
            SDS.females.AIDSdeath(P0.female) = P.timeDeath(P0.index);
            
        end
        
    end

%% abolish
    function eventTransmission_abolish(SDS, P0)
        if P0.index>SDS.number_of_males;
            P.eventTimes(:, P0.index-SDS.number_of_males) = Inf;
            P.rand(:, P0.index-SDS.number_of_males) = Inf;
        else
            P.eventTimes(P0.index,:) = Inf;
            P.rand(P0.index,:) = Inf;
        end
    end

%% block
    function eventTransmission_block(SDS, P0)
        % Invoked by eventDissolution_dump
        
        if isempty(P)
            debugMsg('isempty(P)')
            return
        end
        timeHIVpos = SDS.males.HIV_positive(P0.male);
        idx = P0.male;
        
        if isnan(timeHIVpos)
            % female is HIV+
            timeHIVpos = SDS.females.HIV_positive(P0.female);
            idx = SDS.number_of_males + P0.female;
        end
        probability = P.probability * P.probabilityChange(P0.male,P0.female);
        loglogP = - log(log(1- probability/100));
        T = [timeHIVpos, P.t(2:end, idx)'+timeHIVpos];
        
        relationID = intersect(find(SDS.relations.ID(:,1)==P0.male),find(SDS.relations.ID(:,2)==P0.female));
        relationID = relationID(end);
        
        Tformation = SDS.relations.time(relationID,1);
        alpha = P.alpha(P0.male, P0.female) + loglogP;
        P.rand(P0.male, P0.female) = P.rand(P0.male,P0.female) ...
            - consumedRand(P0.now, Tformation, T, P.lastChange(P0.male,P0.female), alpha, P.beta);
        P.eventTimes(P0.male, P0.female) = Inf;
    end
end


%% properties
function [props, msg] = eventTransmission_properties

msg = '';

props.infectiousness = {
    'variable'  'time [year]'       'transmission probability [%]'
    't0'        '0'                 3.2
    't1'        'min(t, 0.25)'      .35
    't2'        't1 + (t - t1)*.9'  1.52
    };
props.AIDS_mortality_distribution = {
    'variable'  'Weibull shape [year]'  'Weibull scale [year]'
    't'         2.25                    11
    };
props.infectiousness_decreased_by_condom = 0;
props.infectiousness_decreased_by_ARV = .96;
props.infectiousness_increased_during_conception = 2;
props.infectiousness_decreased_by_circumcision = 0.3;
props.CD4_distribution_at_infection = {
    'baseline' 'age factor' 'gender difference' 'shape'
    600         5            40                          0.1
    };

props.sexual_behaviour_parameters = {'baseline' 'mean age' 'age difference' 'relation type' 'relations count' 'serodiscordant' 'HIV disclosure' 'time'
    3 0 0 0 0 0 0 log(0.88)};
props.risk_behaviour_reduction = 0.025;

end


%% name
function name = eventTransmission_name

name = 'HIV transmission';
end


%% test
function eventTransmission_test

global SDSG

%SDSG = [];
if isempty(SDSG)
    [SDSG, msg] = spModel('new');
    [SDSG, msg] = spModel('update', SDSG);
    eventFormation('init', SDSG, SDSG.event(1))
    %SDSG.now(end + 1) = SDSG.now(end) + eventFormation('eventTime', SDSG);
    SDSG = eventFormation('fire', SDSG);
end

eventTransmission('init', SDSG, SDSG.event(3))
time = eventTransmission('eventTime', SDSG);
end
