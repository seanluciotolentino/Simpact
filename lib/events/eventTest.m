function varargout = eventTest(fcn, varargin)
%eventTest SIMPACT event function: Test
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
    function [elements, msg] = eventTest_init(SDS, event)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        P.alpha = -Inf(1, elements);
        
        
        
        P.baselineAlpha = event.test_time{2,1};
        
        
        P.agePeak = event.test_time{2,2};
        P.ageFactor = event.test_time{2,4};
        P.ageWeibull = zeros(1, elements, SDS.float);
        
        P.genderFactor = event.test_time{2,5};
        P.concurrentFactor = event.test_time{2,6};
        
        P.pregnancyFactor = event.test_time{2,8};
        P.revisitFactor = event.test_time{2,9};
        P.timeFactor = event.test_time{2,10};
        P.ARVtime = inf(1,elements, SDS.float);
        P.CD4baseline = event.CD4_baseline_for_ARV{2,2};
        P.CD4baseline = ones(1,7)*P.CD4baseline;
        
        P.criteria = false(1, 7);
        P.criteria(1) = true;
        P.coverage = event.CD4_baseline_for_ARV{2,4}/100;
        P.targetCoverage = event.CD4_baseline_for_ARV{2,6}/100;
        P.currentTime = event.CD4_baseline_for_ARV{2,3};
        P.targetTime = event.CD4_baseline_for_ARV{2,5};
        P.currentTime  = (datenum(P.currentTime) - datenum(SDS.start_date))/spTools('daysPerYear');
        P.targetTime  = (datenum(P.targetTime) - datenum(SDS.start_date))/spTools('daysPerYear');
 
        P.coverageSubpop= P.coverage;
        P.targetCoverageSubpop= P.targetCoverage ;
        P.currentTimeSubpop = P.currentTime ;
        P.targetTimeSubpop = P.targetTime;
          P.optionB = event.option_B_coverage;
        
        P.randCoverage = rand(1, elements);
        P.longterm_relationship_threshold = event.longterm_relationship_threshold;
        P.beta0 = event.test_time{2, 7};
        P.rand0toInf = spTools('rand0toInf', 1, elements);
        P.rand = P.rand0toInf;
        P.expLinear = spTools('handle', 'expLinear');
        P.intExpLinear = spTools('handle', 'intExpLinear');
        P.expConstant = spTools('handle' , 'expConstant');
        P.intExpConstant = spTools('handle' , 'intExpConstant');
        P.weibullEventTime = spTools('handle','weibullEventTime');
        P.eventTimes = inf(1, elements, SDS.float);
        [P.enableARV, msg] = spTools('handle', 'eventARV', 'enable');
        [P.fireARV, msg] = spTools('handle', 'eventARV', 'fire');
        [P.setupTransmission] = spTools('handle','eventTransmission','setup');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        P.lastChange = zeros(1, elements, SDS.float);
        
        P.tests = find(SDS.tests.ID, 1, 'last');
        if isempty(P.tests)
            P.tests = 0;
        end
    end

%% get
    function X = eventTest_get(t)
        X = P;
    end

%% restore
    function [elements,msg] = eventTest_restore(SDS,X)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = X;
        P.rand0toInf = spTools('rand0toInf', 1, elements);
        P.expLinear = spTools('handle', 'expLinear');
        P.intExpLinear = spTools('handle', 'intExpLinear');
        P.expConstant = spTools('handle' , 'expConstant');
        P.intExpConstant = spTools('handle' , 'intExpConstant');
        P.weibullEventTime = spTools('handle','weibullEventTime');
        [P.enableARV, msg] = spTools('handle', 'eventARV', 'enable');
        [P.fireARV, msg] = spTools('handle', 'eventARV', 'fire');
        [P.setupTransmission] = spTools('handle','eventTransmission','setup');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        
    end

%% eventTimes
    function eventTimes = eventTest_eventTimes(~, ~)
        
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventTest_advance(P0)
        
        P.eventTimes = P.eventTimes - P0.eventTime;
        
    end


%% fire
    function [SDS, P0] = eventTest_fire(SDS, P0)
        
        P.eventTimes(P0.index) = Inf;
        P.rand(P0.index) = Inf;
        if ~P.enable
            return
        end
        % use P0.index
        P.tests = P.tests+1;
        SDS.tests.ID(P.tests) = P0.index;
        SDS.tests.time(P.tests) = P0.now;
        if P0.ANC
            SDS.tests.typeANC(P.tests) = true;
        end
         
        if P0.index<=SDS.number_of_males
            HIVneg = isnan(SDS.males.HIV_positive(P0.index));
        else
            HIVneg = isnan(SDS.females.HIV_positive(P0.index-SDS.number_of_males));
        end
        
        if P0.ARV(P0.index)||HIVneg
            return
        end
        
        if P0.now<SDS.ARV_treatment.ARV_program_start_time
            P.eventTimes(P0.index) = 1/P.monitoring_frequency;
        else
            % P0.now>=SDS.ARV_treatment.ARV_program_start_time
            currentIdx = SDS.relations.time(:, SDS.index.stop) == Inf;
            sexwork = false;
            
            if P0.index<= SDS.number_of_males
                P0.male = P0.index;
                CD4Infection = SDS.males.CD4Infection(P0.male);
                CD4Death = SDS.males.CD4Death(P0.male);
                timeAIDS = SDS.males.CD4_200(P0.male);
                survivalTime = SDS.males.AIDSdeath(P0.male);
                infectionTime = P0.now-SDS.males.HIV_positive(P0.male);
                SDS.males.HIV_test(P0.index) = P0.now;
                serodiscordant = false;
                pregnant = false;
                pregnantPartner = false;
                old = SDS.males.born(P0.index)<=P0.now-50;
                nonbreast = false;
                for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.male) == P0.male) &...
                        ismember(SDS.relations.ID(:, SDS.index.female),find(isnan(SDS.females.HIV_positive))))'
                    P0.female = SDS.relations.ID(relIdx, SDS.index.female);
                    pregnantPartner = pregnantPartner|P0.pregnant(P0.male);
                    longterm = (P0.now - SDS.relations.time(relIdx,1))>=P.longterm_relationship_threshold;
                    serodiscordant = serodiscordant|(P0.serodiscordant(P0.male, P0.female)&longterm);
                end
            else
                P0.female = P0.index - SDS.number_of_males;
                CD4Infection = SDS.females.CD4Infection(P0.female);
                CD4Death = SDS.females.CD4Death(P0.female);
                timeAIDS = SDS.females.CD4_200(P0.female);
                survivalTime = SDS.females.AIDSdeath(P0.female);
                infectionTime = P0.now-SDS.females.HIV_positive(P0.female);
                SDS.females.HIV_test(P0.female) = P0.now;
                serodiscordant = false;
                pregnant = P0.pregnant(P0.female);
                sexwork = SDS.females.sex_worker(P0.female);
                old = SDS.females.born(P0.female)<=P0.now-50;
                nonbreast = false;
                breast = false;
                if P0.now>=(P0.thisPregnantTime(P0.female)+40/52)&&P0.now<=P0.breastfeedingStop(P0.female)
                breast = true;
                end
                if breast
                    nonbreast = true;
                end
                for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.female) == P0.female) &...
                        ismember(SDS.relations.ID(:, SDS.index.male),find(isnan(SDS.males.HIV_positive))))'
                    P0.male = SDS.relations.ID(relIdx, SDS.index.male);
                    longterm = (P0.now - SDS.relations.time(relIdx,1))>=P.longterm_relationship_threshold;
                    serodiscordant = serodiscordant|(P0.serodiscordant(P0.male, P0.female)&longterm);
                end
            end
           startTime = SDS.ARV_treatment.ARV_program_start_time;
     
            if P0.now<=P.targetTime
                coverage = interp1q([startTime,P.currentTime,P.targetTime]',[0,P.coverage,P.targetCoverage]',P0.now);
                coverageSubpop = interp1q([startTime,P.currentTime,P.targetTime]',[0,P.coverageSubpop,P.targetCoverageSubpop]',P0.now);
            else
                coverage = P.targetCoverage;
                coverageSubpop = P.targetCoverageSubpop;
            end
            
            coverage = [coverage, ones(1,6)*coverageSubpop];
            
            eligibility = [true true pregnant serodiscordant sexwork old nonbreast];
            eligibility = eligibility&P.criteria&coverage>=P.randCoverage(P0.index);
            eligible = sum(eligibility)>0;
            
            if ~eligible
                if P.randCoverage(P0.index)<=P.optionB&&pregnant
                    P0.optionB(P0.female) = true;
                    [SDS, P0] = P.fireARV(SDS,P0);
                else
                    if timeAIDS<=P0.now
                        [SDS, P0] = P.fireARV(SDS,P0);
                    else
                    P.eventTimes(P0.index) = 1/P.monitoring_frequency;
                    end
                end
            else %eligible
                
                SDS.tests.enter(P.tests)=P0.now;
                CD4baseline = max(P.CD4baseline.*eligibility);
                
                if CD4Infection <= CD4baseline
                    P.ARVtime(P0.index) = 0;
                else
                                       
                    if survivalTime<= 0.25
                        P.ARVtime(P0.index) = survivalTime-interp1q([CD4Death,CD4Infection]',[0,survivalTime],CD4baseline) - infectionTime;
                    else
                        P.ARVtime(P0.index) = survivalTime-interp1q([CD4Death,0.75*CD4Infection,CD4Infection]',[0,(survivalTime-0.25),survivalTime]',CD4baseline) -infectionTime;                        
                    end
                            
                end
                
                if P.ARVtime(P0.index)>0
                    P.eventTimes(P0.index) = 1/P.monitoring_frequency;
                else
                    [SDS, P0] = P.fireARV(SDS, P0);
                    P.eventTimes(P0.index) =Inf;
                end
            end
        end
    end
%% enable
    function eventTest_enable(SDS, P0)
        % by eventBirth, eventTransmission
        % new random number
        
        if ~P.enable
            return
        end
        
%         P.rand(P0.index) = P.rand0toInf(1,1); %new random no.
%         
%         if P0.index<=SDS.number_of_males
%             age = P0.now - SDS.males.born(P0.index);
%         else
%             index = P0.index-SDS.number_of_males;
%             age = P0.now - SDS.females.born(index);
%         end
%         ageFactor = interp1q([0 P.agePeak 100]',[0 P.ageFactor, 0 ]',age');
%         alpha= P.baselineAlpha + ageFactor';
%         P.eventTimes(P0.index) = P.expLinear(alpha, P.beta0,0, P.rand(P0.index));
P.eventTimes(P0.index) = rand;
    end


%% update
function eventTest_update(SDS, P0)
% Invoked by eventFormation, eventDissolustion
if P.eventTimes(P0.index)==Inf;
    return
else
    if P0.index<= SDS.number_of_males
        P0.male = P0.index;
        gender = 0;
        birth = SDS.males.born(P0.male);
        relationCount = P0.maleRelationCount(P0.male);
        infectionTime = SDS.males.HIV_positive(P0.male);
        testTime = SDS.males.HIV_test(P0.male);
        
    else
        P0.female = P0.index - SDS.number_of_males;
        gender = 1;
        birth = SDS.females.born(P0.female);
        relationCount = P0.femaleRelationCount(P0.female);
        infectionTime = SDS.females.HIV_positive(P0.female);
        testTime = SDS.females.HIV_test(P0.female);
        
    end
    
    
    P.rand(P0.index) =P.rand(P0.index) - P.intExpLinear(P.alpha(P0.index),P.beta0, P0.now - P.lastChange(P0.index), P0.now);
    age = P0.now - birth;
    ageFactor = interp1q([0 P.agePeak 100]',[0 P.ageFactor, 0 ]',age);
    timeFactor = min(max(0, P0.now - SDS.ARV_treatment.ARV_program_start_time),15);
    timeFactor = timeFactor * P.timeFactor;
    P.alpha(P0.index) = P.baselineAlpha + P.genderFactor*gender + ageFactor +...
        P.concurrentFactor*relationCount + P.revisitFactor*(~isnan(testTime)) + timeFactor;
    P.eventTimes(P0.index) = P.expLinear( P.alpha(P0.index) ,  P.beta0, 0, P.rand(P0.index));
    P.lastChange(P0.index) = P0.now;
end
end

%% intervene
function eventTest_intervene(policy,cd4,upscale)
switch policy
    case 'population'
        P.criteria(2) = true;
        P.targetCoverage = upscale;
        P.targetCoverageSubpop = upscale;
        P.CD4baseline(1) = cd4;
        P.CD4baseline(2) = cd4;
    case 'pregnant'
        P.criteria(3) = true;
        P.targetCoverageSubpop = upscale;
        P.CD4baseline(3) = cd4;
    case 'discordant'
        P.criteria(4) = true;
        P.targetCoverageSubpop = upscale;
        P.CD4baseline(4) = cd4;
    case 'fsw'
        P.criteria(5) = true;
        P.targetCoverageSubpop = upscale;
        P.CD4baseline(5) = cd4;
    case 'age50'
        P.criteria(6) = true;
        P.targetCoverageSubpop = upscale;
        P.CD4baseline(6) = cd4;
    case 'nonbreast'
        P.criteria(7) = true;
        P.targetCoverageSubpop = upscale;
        P.CD4baseline(7) = cd4;
end
end

%% block
function eventTest_block(P0)
P.rand(P0.index) = Inf;
P.eventTimes(P0.index) = Inf;
end

end


%% properties
function [props, msg] = eventTest_properties

props.test_time = {
    'baseline'  'peak age'  'age shape' 'age factor' 'gender factor'  'concurrent factor' 'infection factor' 'pregnancy factor' 'revisit factor' 'time factor'
    log(2)                 25                    2               0.1          0                       0                           1.5                               0                 2         log(2)
    };

props.CD4_baseline_for_ARV = {
   'variables'                  'CD4 threshold' 'current time' 'current accessability' 'target time' 'target accessability' 
    'population'                350                   '31-Dec-2013'             40              '30-Jun-2015'               50
  %  'expansion group'      350                   '31-Dec-2012'             40              '30-Jun-2015'               40
    };
props.option_B_coverage = 95;
props.monitoring_frequency = 1;
props.longterm_relationship_threshold = 0.25;
msg = 'HIV testing implemented by test event.';
end


%% name
function name = eventTest_name

name = 'HIV test';
end
