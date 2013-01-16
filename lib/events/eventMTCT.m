function varargout = eventMTCT(fcn, varargin)
%eventMTCT SIMPACT event function: MTCTransmission
%
%   See also modelHIV, birth.

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
    function [elements, msg] = eventMTCT_init(SDS, event)
        
        elements = SDS.number_of_males+SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        
        
        % ******* Function Handles *******
        P.weibullEventTime = spTools('handle', 'weibullEventTime');
        [P.enableAIDSmortality, thisMsg] = spTools('handle', 'AIDSmortality', 'enable');
       % [P.fireTest, thisMsg] = spTools('handle', 'Test', 'fire');
        
        % ******* Variables & Constants *******
        P.randBreastfeeding = rand(1, SDS.number_of_females);
        P.rand = rand(1,elements);
        
        prenatalRate = event.probability_of_MTCT{2, 2};
        postnatalRate = event.probability_of_MTCT{3, 2};
        survival = 12; % assuming ave. survival = 12 yrs
        % assuming longest breastfeeding time = 2 yrs
        prenatalRate = (prenatalRate*survival*52/40)/(0.25/0.35*3.2+0.9*(survival-0.25)+0.1*(survival-0.25)*1.52/0.35);
        postnatalRate = (postnatalRate*survival/2)/(0.25/0.35*3.2+0.9*(survival-0.25)+0.1*(survival-0.25)*1.52/0.35);
        P.prenatalRate = [prenatalRate*3.2/0.35 prenatalRate prenatalRate*1.52/0.35];
        P.postnatalRate = [postnatalRate*3.2/0.35 postnatalRate postnatalRate*1.52/0.35];
        
        breastfeed = event.probability_of_breastfeeding;
        P.breastfeeding = [0, breastfeed*0.5, breastfeed*0.8,breastfeed];
        P.breastfeedingTime = [2, 0.75, 0.5, 0];
        P.scale = event.HIV_positive_infants_survival_time{2,1};
        P.shape = event.HIV_positive_infants_survival_time{2,2};
        P.lastChange = zeros(1,elements);
        
        P.eventTimes = inf(1, elements);
        
    end


%% get
    function X = eventMTCT_get(t)
        X = P;
    end
%% restore
    function [elements,msg] = eventMTCT_restore(SDS,X)
        
        
        
        P = X;
        P.enable = SDS.MTCT_transmission.enable;
        
        elements = SDS.number_of_males+SDS.number_of_females;
        msg = '';
        

        % ******* Function Handles *******
        P.weibullEventTime = spTools('handle', 'weibullEventTime');
        [P.enableAIDSmortality, thisMsg] = spTools('handle', 'AIDSmortality', 'enable');
        [P.fireTest, thisMsg] = spTools('handle', 'Test', 'fire');
    end

%% eventTime
    function eventTimes = eventMTCT_eventTimes(~, ~)
        
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventMTCT_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventMTCT_fire(SDS, P0)
        if ~P.enable
            return
        end
        
        if P0.index<=SDS.number_of_males
            P0.male = P0.index;
            SDS.males.HIV_positive(P0.male) = P0.now;
            SDS.males.HIV_source(P0.male) = SDS.males.mother(P0.male)+SDS.number_of_males;
            P0.serodiscordant(P0.male, :) = ~P0.serodiscordant(P0.male, :);
            P0.subset(P0.male, :) = true;
            
        else
            P0.female = P0.index-SDS.number_of_males;
            SDS.females.HIV_positive(P0.female) = P0.now;
            SDS.females.HIV_source(P0.female) = SDS.females.mother(P0.female)+SDS.number_of_females;
            P0.serodiscordant(:,P0.female) = ~P0.serodiscordant(:,P0.female);
            P0.subset(:,P0.female) = true;
        end
        
        timeDeath = P.weibullEventTime(P.scale, P.shape, rand,0);
        P.enableAIDSmortality(P0, timeDeath);
        P.lastChange(P0.index) = P0.now;
        P.eventTimes(P0.index) = Inf;
    end


%% enable
    function [SDS, P0] = eventMTCT_enable(SDS, P0, mother)
        % Invoked by eventBirth_fire
        % P0.female = mother, P0.male = father, sex = newborn sex, ID = newborn ID
        
        if ~P.enable
            return
        end
        tempMale = P0.male;
        tempFemale = P0.female;
        
        idx = P0.thisChild(mother);
        if isnan(idx)
            return
        end
        if idx<=SDS.number_of_males
            latestBorn = SDS.males.born(idx);
        else
            latestBorn = SDS.females.born(idx-SDS.number_of_males);
        end
        
        time = interp1q(P.breastfeeding', P.breastfeedingTime',P.randBreastfeeding(mother)); % feeding time
        if isnan(time)
            time = 0;
        end
        
        P0.breastfeedingStop(mother) = min(latestBorn,P0.now)+time;
        
        survival = SDS.females.AIDSdeath(mother);
        timeHIVpos = SDS.females.HIV_positive(mother);
        timeConception = P0.now - 40/52;
        ARVstatus = SDS.females.ARV(mother);
        t = [0 0.25 0.25+(survival-0.25)*0.9 (survival-0.25)*0.1]; % HIV stages
        prenatalHazard = [0 t(2:4).*P.prenatalRate];
        prenatalHazard = cumsum(prenatalHazard);
        postnatalHazard = [0 t(2:4).*P.postnatalRate];
        postnatalHazard = cumsum(postnatalHazard);
        t = cumsum(t);
        
        if P0.now==latestBorn %invoked by birth
            % go back to time of conception
            if timeConception >= timeHIVpos % conception after mother infected
                tc = timeConception-timeHIVpos; % time of conception since mother's infection
                if ~ARVstatus % mother not on arv
                    H0 = interp1q(t',prenatalHazard',tc); %H before conception
                    Hc = interp1q(t'-tc,prenatalHazard'-H0,40/52); % consumed randomness
                else % mother on arv
                    timeARV = max(SDS.ARV.time(SDS.ARV.ID==mother +SDS.number_of_males,1));
                    postnatalHazard = postnatalHazard*(1-P.infectiousness_decreased_by_ARV);
                    if timeARV<=timeConception  %arv before conception
                        prenatalHazard = prenatalHazard*(1-P.infectiousness_decreased_by_ARV);
                        H0 = interp1q(t',prenatalHazard',tc);
                        Hc = interp1q(t'-tc,prenatalHazard'-H0, 40/52);
                    else % arv initiation during pregnant
                        H01 = interp1q(t',prenatalHazard',tc);
                        Hc1 = interp1q(t'-tc,prenatalHazard'-H01,timeARV-timeConception);
                        H02 = interp1q(t',prenatalHazard'*(1-P.infectiousness_decreased_by_ARV),timeARV-timeHIVpos);
                        Hc2 = interp1q(t'-(timeARV-timeHIVpos), ...
                            prenatalHazard'*(1-P.infectiousness_decreased_by_ARV)-H02,P0.now-timeARV);
                        Hc = Hc1+Hc2;
                    end
                end
            else % mother infected after conception
                if ~ARVstatus % mother not on arv
                    tc = timeHIVpos - timeConception;
                    Hc = interp1q(t'+tc, prenatalHazard',P0.now - timeConception);
                else % mother on arv
                    postnatalHazard = postnatalHazard*(1-P.infectiousness_decreased_by_ARV);
                    timeARV = max(SDS.ARV.time(SDS.ARV.ID==mother +SDS.number_of_males,1));
                    H0 = interp1q(t',prenatalHazard',timeARV-timeHIVpos);
                    Hc = interp1q(t'-(timeARV-timeHIVpos),prenatalHazard'*(1-P.infectiousness_decreased_by_ARV)-H0, P0.now-timeARV);
                end
            end
            
            if Hc>=P.rand(idx) % infection before/during delivery
                P0.index = idx;
                [SDS, P0] = eventMTCT_fire(SDS,P0);
            else
                P.rand(P0.index) = P.rand(P0.index) - Hc;
                H0 = interp1q(t', postnatalHazard', P0.now - timeHIVpos);
                P.eventTimes(idx) = interp1q(postnatalHazard'-H0, t'-(P0.now-timeHIVpos),P.rand(idx));
            end
        else % invoked by mother's infection during breastfeeding
            if latestBorn + time>=P0.now
                return
            end
            H0 = interp1q(t',postnatalHazard',P0.now-timeHIVpos);
            P.eventTimes(idx) = interp1q(postnatalHazard'-H0, t'-(P0.now-timeHIVpos), P.rand(idx));
        end
        
        if P.eventTimes(idx) > latestBorn + time - P0.now;
            P.eventTimes(idx) = Inf;
        end
        P.lastChange(idx) = P0.now;
        
        P0.male =  tempMale;
        P0.female = tempFemale;
    end

%% update
    function eventMTCT_update(SDS, P0)
        % breastfeeding mother initiates/dropouts from ARV
        if ~P.enable
            return
        end
        
        idx = P0.thisChild(P0.female);
        if isnan(idx)
            return
        end
        if idx<=SDS.number_of_males
            latestBorn = SDS.males.born(idx);
            positiveChild = ~isnan(SDS.males.HIV_positive(idx));
        else
            latestBorn = SDS.females.born(idx-SDS.number_of_males);
            positiveChild = ~isnan(SDS.females.HIV_positive(idx-SDS.number_of_males));
        end
        
        if isempty(latestBorn)||positiveChild
            return
        end
        
        time = interp1q(P.breastfeeding', P.breastfeedingTime',P.randBreastfeeding(P0.female)); % feeding time
        if isnan(time)
            time = 0;
        end
        
        if latestBorn+time<=P0.now% not breastfeeding
            return
        else
            
            %breastfeeding
            
            survival = SDS.females.AIDSdeath(P0.female);
            timeHIVpos = SDS.females.HIV_positive(P0.female);
            t = [0 0.25 0.25+(survival-0.25)*0.9 (survival-0.25)*0.1]; % HIV stages
            postnatalHazard = [0 t(2:4).*P.postnatalRate];
            postnatalHazard = cumsum(postnatalHazard);
            t = cumsum(t);
            if SDS.females.ARV(P0.female) % ARV start

                timeHIVpos = SDS.females.HIV_positive(P0.female);
                H01 = interp1q(t',postnatalHazard',P.lastChange(idx)-timeHIVpos);
                Hc = interp1q(t'- (P.lastChange(idx)-timeHIVpos),postnatalHazard'-H01,P0.now-P.lastChange(idx));
                P.rand(idx) = P.rand(idx)-Hc;
                postnatalHazard = postnatalHazard*(1- P.infectiousness_decreased_by_ARV);
                H02 = interp1q(t',postnatalHazard',P0.now-timeHIVpos);
                P.eventTimes(idx) = interp1q(postnatalHazard-H02, t'-(P0.now-timeHIVpos), P.rand(idx));
            else % ARV stop
                timeHIVpos = SDS.females.HIV_positive(P0.female);
                H01 = interp1q(t',postnatalHazard'*(1- P.infectiousness_decreased_by_ARV),P.lastChange(idx)-timeHIVpos);
                Hc = interp1q(t'- (P.lastChange(idx)-timeHIVpos),...
                    postnatalHazard'*(1- P.infectiousness_decreased_by_ARV)-H01,P0.now-P.lastChange(idx));
                P.rand(idx) = P.rand(idx)-Hc;
                H02 = interp1q(t',postnatalHazard',P0.now-timeHIVpos);
                P.eventTimes(idx) = interp1q(postnatalHazard-H02, t'-(P0.now-timeHIVpos), P.rand(idx));
            end
            P.lastChange(idx) = P0.now;
            if P.eventTimes(idx)+P0.now > latestBorn+time
                P.eventTimes(idx) = Inf;
            end
        end
    end

%% setup
    function time = eventMTCT_setup(mother)
        time = interp1q(P.breastfeeding', P.breastfeedingTime',P.randBreastfeeding(mother)); % feeding time
        if isnan(time)
            time = 0;
        end
    end

%% block
    function eventMTCT_block(SDS,mother)
        % Invoked by eventMTCT_fire
        % Invoked by eventMortality_fire
        for idx = find(SDS.males.mother==mother)
            P.eventTimes(idx) = Inf;
        end
        for idx = find(SDS.females.mother==mother)
            P.eventTimes(idx+SDS.number_of_males) = Inf;
        end
    end
end


%% name
function name = eventMTCT_name

name = 'MTCT transmission';
end


%% properties
function [props, msg] = eventMTCT_properties

props.probability_of_MTCT = {
    'HIV/AIDS stage'  'probability'
    'prenatal and delivery'  0.2
    'postnatal' 0.4
    };
props.infectiousness_decreased_by_ARV = 0.5;
props.probability_of_breastfeeding = 0.9;
props.HIV_positive_infants_survival_time={
    'scale' 'shape'
    5   1
    };
msg = 'HIV can be transmitted from infected mothers to children.';
end

