function varargout = modelHIVrestart(fcn, varargin)
%MODELHIV SIMPACT HIV model function which controls the data structure.
%   This function implements new, nextEvent, preprocess, initialise, menu.
%
%   See also SIMPACT, spRun, spTools.

% File settings:
%#ok<*DEFNU>

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

persistent P0

if nargin == 0
    modelHIVrestart_test
    return
end

switch fcn
    case 'handle'
        cmd = sprintf('@%s_%s', mfilename, varargin{1});
        
    otherwise
        cmd = sprintf('%s_%s(varargin{:})', mfilename, fcn);
end

[varargout{1:nargout}] = eval(cmd);


%% preprocess
    function [SDS,msg] = modelHIVrestart_preprocess(SDS)
        % Invoked by spRun('start') during initialisation
        
        msg = '';
        
        empiricalCRF = spTools('handle', 'empiricalCRF');
        
        P0 = SDS.P0start;
        
        %NIU populationCount = SDS.number_of_males + SDS.number_of_females;
        maleRange = 1 : length(~isnan(SDS.males.born));
        femaleRange = 1 : length(~isnan(SDS.females.born));
        malesInt = zeros(1, SDS.number_of_males, SDS.integer);
        femalesInt = zeros(1, SDS.number_of_females, SDS.integer);
        malesZeros = zeros(1, SDS.number_of_males, SDS.float);
        femalesZeros = zeros(1, SDS.number_of_females, SDS.float);
        malesOnes = ones(1, SDS.number_of_males, SDS.float);
        femalesOnes = ones(1, SDS.number_of_females, SDS.float);
        %NIU femalesZeros = zeros(1, SDS.number_of_females, SDS.float);
        malesNaN = nan(1, SDS.number_of_males, SDS.float);
        femalesNaN = nan(1, SDS.number_of_females, SDS.float);
        malesFalse = false(1, SDS.number_of_males);     % boolean/uint8 = 8 bit
        %malesFalse = zeros(1, SDS.number_of_males, 'uint8');
        femalesFalse = false(1, SDS.number_of_females);
        falseMatrix = false(SDS.number_of_males, SDS.number_of_females);
        
        % ******* Influence Subset *******
        P0.true = true(SDS.number_of_males, SDS.number_of_females);
        %maleRange = ones(1, SDS.integer) : SDS.number_of_males;
        %femaleRange = ones(1, SDS.integer) : SDS.number_of_females;
        %P0.subset = true(SDS.number_of_males, SDS.number_of_females);

        P0.subset = falseMatrix;
        P0.subset(maleRange, femaleRange) = true;
        %P0.alive = true(1, populationCount);     % WIP
        %P0.alive = P0.subset;       % initially alive population
        %P0.aliveRange = false(1, populationCount);
        %P0.aliveRange(1 : populationCount) = true;
        P0.aliveMales = malesFalse;
        P0.aliveMales(maleRange) = true;
        P0.aliveFemales = femalesFalse;
        P0.aliveFemales(femaleRange) = true;
        P0.pregnant = femalesFalse;
        
       %P0.ANCtest = false; % false for general type testing, true for test at ANC
        
        % ******* Population *******
        new = SDS;
        new.P0start = [];
        new.males.father = malesInt;
        new.females.father = femalesInt;
        new.males.mother = SDS.males.father;
        new.females.mother = SDS.females.father;
        new.males.born = malesNaN;
        new.females.born = femalesNaN;
        new.males.deceased = malesNaN;
        new.females.deceased = femalesNaN;
        new.males.community = malesInt;
        new.females.community = femalesInt;
        new.males.partnering = malesOnes;
        new.females.partnering = femalesOnes;
        new.males.BCC_exposure = malesNaN;
        new.females.BCC_exposure = femalesNaN;
        new.males.current_relations_factor = malesNaN;
        new.females.current_relations_factor = femalesNaN;
        
        new.males.father(maleRange) = SDS.males.father;
        new.females.father(femaleRange) = SDS.females.father;
        new.males.mother(maleRange) = SDS.males.mother;
        new.females.mother(femaleRange) = SDS.females.mother;
        new.males.born(maleRange) = SDS.males.born;
        new.females.born(femaleRange) = SDS.females.born;
        new.males.deceased(maleRange) = SDS.males.deceased;
        new.females.deceased(femaleRange) = SDS.females.deceased;
        new.males.community(maleRange) = SDS.males.community;
        new.females.community(femaleRange) = SDS.females.community;
        new.males.partnering(maleRange) = SDS.males.partnering;
        new.females.partnering(femaleRange) = SDS.females.partnering;
        new.males.BCC_exposure(maleRange) = SDS.males.BCC_exposure;
        new.females.BCC_exposure(femaleRange) = SDS.females.BCC_exposure;
        new.males.current_relations_factor(maleRange) = SDS.males.current_relations_factor;
        new.females.current_relations_factor(femaleRange) = SDS.females.current_relations_factor;

        
                
        % ******* Communities TEMP!!! *******
        
        communityMale = empiricalCommunity(SDS.number_of_males - SDS.initial_number_of_males, SDS.number_of_community_members);
        communityFemale = empiricalCommunity(SDS.number_of_females-SDS.initial_number_of_females, SDS.number_of_community_members);
        new.males.community((SDS.initial_number_of_males+1):SDS.number_of_males) = cast(communityMale, SDS.integer);
        new.females.community((SDS.initial_number_of_females+1):SDS.number_of_females) = cast(communityFemale, SDS.integer);
        

         new.males.current_relations_factor((SDS.initial_number_of_males+1):SDS.number_of_males) = SDS.formation_BCC.current_relations_factor;
           new.females.current_relations_factor((SDS.initial_number_of_females+1):SDS.number_of_males) = SDS.formation_BCC.current_relations_factor;          
        
        betaPars = [0.5, 0.7];
        partneringFcn = 'mean';
        %SDS.males.partnering = cast(betainv(rand(1, SDS.number_of_males, SDS.float), betaPars(1), betaPars(2)), SDS.float);
        %SDS.females.partnering = cast(betainv(rand(1, SDS.number_of_females, SDS.float), betaPars(1), betaPars(2)), SDS.float);
        
        [partMales, pathFemales] = ndgrid(SDS.males.partnering, SDS.females.partnering);
        formationBCCfield = str2field(eventFormation('name'));
        if isfield(SDS, formationBCCfield)
            partneringFcn = SDS.(formationBCCfield).partnering_function.SelectedItem;
        end
        switch partneringFcn
            case 'min'
                P0.partnering = min(partMales, pathFemales);
            case 'max'
                P0.partnering = max(partMales, pathFemales);
            case 'mean'
                P0.partnering = (partMales + pathFemales)/2;
            case 'product'
                P0.partnering = partMales.*pathFemales;
        end
        
        
        % ******* Aging TEMP!!! *******
        new.males.born(maleRange) = SDS.males.born;    % -years old
        new.females.born(femaleRange) =SDS.females.born;% -years old
        
        
        % ******* HIV Properties *******
        new.males.HIV_source = malesInt;
        new.females.HIV_source = femalesInt;
        new.males.HIV_positive = malesNaN;
        new.females.HIV_positive = femalesNaN;
        new.males.AIDS_death = malesFalse;
        new.females.AIDS_death = femalesFalse;
        new.males.ARV_eligible = malesNaN;
        new.females.ARV_eligible = femalesNaN;
        new.males.ARV_start = malesNaN;
        new.females.ARV_start = femalesNaN;
        new.males.ARV_stop = malesNaN;
        new.females.ARV_stop = femalesNaN;
        new.males.circumcision = malesNaN;
        new.males.condom = malesZeros;
        new.females.conception = femalesFalse;
        new.males.ARV = malesFalse;
        new.females.ARV = femalesFalse;

        new.males.HIV_test = malesNaN;
        new.females.HIV_test = femalesNaN;
        new.males.HIV_test_change = malesNaN;
        new.females.HIV_test_change= femalesNaN;
        % SDS.females.ANC = femalesNaN;
        new.males.CD4Infection = malesNaN;
        new.females.CD4Infection = femalesNaN;
        new.males.CD4ARV = malesNaN;
        new.females.CD4ARV = femalesNaN;
        new.males.CD4Death = malesNaN;
        new.females.CD4Death = femalesNaN;
        new.females.conceptions = femalesZeros;
        new.males.AIDSdeath = malesNaN; %since infection
        new.females.AIDSdeath = femalesNaN;
        new.person_years_aquired = 0;
        new.males.behaviour_factor = malesNaN;
        new.females.behaviour_factor = femalesNaN;
        
        % ******* HIV Properties *******
        new.males.HIV_source(maleRange) = SDS.males.HIV_source;
        new.females.HIV_source(femaleRange) = SDS.females.HIV_source;
        new.males.HIV_positive(maleRange) = SDS.males.HIV_positive;
        new.females.HIV_positive(femaleRange) = SDS.females.HIV_positive;
        new.males.AIDS_death(maleRange) = SDS.males.AIDS_death;
        new.females.AIDS_death(femaleRange) = SDS.females.AIDS_death;
        new.males.ARV_eligible(maleRange) = SDS.males.ARV_eligible;
        new.females.ARV_eligible(femaleRange) = SDS.females.ARV_eligible;
        new.males.ARV_start(maleRange) = SDS.males.ARV_start;
        new.females.ARV_start(femaleRange) = SDS.females.ARV_start;
        new.males.ARV_stop(maleRange) = SDS.males.ARV_stop;
        new.females.ARV_stop(femaleRange) = SDS.females.ARV_stop;
        new.males.circumcision(maleRange) = SDS.males.circumcision;
        new.males.condom(maleRange) = SDS.males.condom;
        new.females.conception(femaleRange) = SDS.females.conception;
        new.males.ARV(maleRange) = SDS.males.ARV;
        new.females.ARV(femaleRange) = SDS.females.ARV;

        new.males.HIV_test(maleRange) = SDS.males.HIV_test;
        new.females.HIV_test = SDS.males.HIV_test;
        new.males.HIV_test_change(maleRange) = malesNaN;
        new.females.HIV_test_change= femalesNaN;
        % SDS.females.ANC = femalesNaN;
        new.males.CD4Infection(maleRange) = SDS.males.CD4Infection;
        new.females.CD4Infection(femaleRange) = SDS.females.CD4Infection;
        new.males.CD4ARV(maleRange) = SDS.males.CD4ARV;
        new.females.CD4ARV(femaleRange) = SDS.females.CD4ARV;
        new.males.CD4Death(maleRange) = SDS.males.CD4Death;
        new.females.CD4Death(femaleRange) = SDS.females.CD4Death;
        new.females.conceptions(femaleRange) = SDS.females.conceptions;
        new.males.AIDSdeath =  spTools('weibull', 12, 2.25, rand(1, SDS.number_of_males));
        new.females.AIDSdeath =  spTools('weibull', 12, 2.25, rand(1, SDS.number_of_females));
        new.males.AIDSdeath(maleRange) = SDS.males.AIDSdeath; %since infection
        new.females.AIDSdeath(femaleRange) = SDS.females.AIDSdeath;
        new.person_years_aquired = 0;
        new.males.behaviour_factor(maleRange) = SDS.males.behaviour_factor;
        new.females.behaviour_factor(femaleRange) = SDS.females.behaviour_factor;
        
        new.females.sex_worker = rand(1, SDS.number_of_females)<= SDS.sex_worker_proportion;
        new.females.sex_worker(femaleRange) =SDS.females.sex_worker;
        
        new.tests = SDS.tests;
        
        new.ARV = SDS.ARV;
        
        P0.birth = false;
        P0.conception = false;
        P0.ANC= false;
       
        % ******* Initialise Relations *******
        new.relations = SDS.relations;
        previous_number_of_males = SDS.number_of_males;
        SDS = new;
        
        P0.transactionSex = repmat(SDS.females.sex_worker, SDS.number_of_males, 1);
        
        P0.maleAge = -repmat(SDS.males.born(:), 1, SDS.number_of_females);
        P0.femaleAge = -repmat(SDS.females.born(:)', SDS.number_of_males, 1);
        P0.meanAge = (P0.maleAge + P0.femaleAge)/2;
        
        %%%%%%%%
        P0.maleCommunity = repmat(SDS.males.community(:), 1, SDS.number_of_females);
        P0.femaleCommunity = repmat(SDS.females.community(:)', SDS.number_of_males, 1);
        
        
        P0.maleBCCexposure = repmat(SDS.males.BCC_exposure(:), 1, SDS.number_of_females);%
        P0.femaleBCCexposure = repmat(SDS.females.BCC_exposure(:)', SDS.number_of_males, 1);%

        P0.malecurrent_relations_factor = repmat(SDS.males.current_relations_factor(:), 1, SDS.number_of_females);%
        P0.femalecurrent_relations_factor = repmat(SDS.females.current_relations_factor(:)', SDS.number_of_males, 1);%
        
        P0.timeSinceLast = min(...
            repmat(-SDS.males.born(:), 1, SDS.number_of_females), ...
            repmat(-SDS.females.born(:)', SDS.number_of_males, 1));
        
        P0.ageDifference = P0.maleAge - P0.femaleAge;
        
        %%%%%%%
        P0.communityDifference = cast(P0.maleCommunity - P0.femaleCommunity, SDS.float);
        P0.BCCexposureMax = max(P0.maleBCCexposure,P0.femaleBCCexposure);%
        P0.BCCexposureMin = min(P0.maleBCCexposure,P0.femaleBCCexposure);%
        P0.BCCexposureMean = (P0.maleBCCexposure+P0.femaleBCCexposure)./2;%
        
        P0.current_relations_factorMax = max(P0.malecurrent_relations_factor,P0.femalecurrent_relations_factor);%
        P0.current_relations_factorMin = min(P0.malecurrent_relations_factor,P0.femalecurrent_relations_factor);%
        P0.current_relations_factorMean = (P0.malecurrent_relations_factor+P0.femalecurrent_relations_factor)./2;%        
        
        P0.current = falseMatrix;
        
        maleHIVpos = falseMatrix;
        maleHIVpos(~isnan(SDS.males.HIV_positive), :) = true;
        femaleHIVpos = falseMatrix;
        femaleHIVpos(:, ~isnan(SDS.females.HIV_positive)) = true;
        P0.serodiscordant = xor(maleHIVpos, femaleHIVpos);
        P0.HIVpos = [
            SDS.males.HIV_positive, SDS.females.HIV_positive
            ]';
        P0.introduce = false;
        P0.optionB = false;
   
        % ******* Event Functions *******
        P0.numberOfEvents = 0;
        startElements = P0.elements;
        startEventTimes = P0.eventTimes;
        P0.elements = [];
        P0.event = struct('eventTime', {}, 'fire', {}, 'advance', {}, 'time', {});
        modelHIVrestart_preprocess_trace('SDS')    % ********
        P0.eventTimes = [];
        startpoint =1;
        for i = 1:length(startElements)
            if startElements(i) == previous_number_of_males
                thisEventTimes = Inf(1, SDS.number_of_males);
                thisEventTimes(1:previous_number_of_males) = startEventTimes(startpoint:(startpoint+previous_number_of_males-1));
                P0.eventTimes =[P0.eventTimes, thisEventTimes];
                startpoint = length(P0.eventTimes)+1;
            end
            if startElements(i) == previous_number_of_males*2
                thisEventTimes = Inf(1, SDS.number_of_males*2);
                thisEventTimes(1:previous_number_of_males*2) = startEventTimes(startpoint:(startpoint+previous_number_of_males*2-1));
                P0.eventTimes =[P0.eventTimes, thisEventTimes];
                startpoint = length(P0.eventTimes)+1;
            end
            if startElements(i) == previous_number_of_males^2
                thisEventTimes = Inf(1, SDS.number_of_males^2);
                times = startEventTimes(startpoint:(startpoint+previous_number_of_males^2-1));
                times = reshape(times,previous_number_of_males,previous_number_of_males);
                gap = SDS.number_of_males-previous_number_of_males;
                times = [times, Inf(previous_number_of_males,gap)];
                times = [times
                Inf(gap,SDS.number_of_males)    
                ];
                thisEventTimes = reshape(times,1,SDS.number_of_males^2);
                P0.eventTimes =[P0.eventTimes, thisEventTimes];
                startpoint = length(P0.eventTimes)+1;
            end
        end
        
        P0.cumsum = [0, cumsum(P0.elements)];
        P0.firedEvent = [];
        P0.now = 0;
        
        
        % ******* Warnings *******
        if P0.numberOfEvents == 0
            msg = 'Warning: no (enabled) events, nothing to simulate';
        end
        if max([SDS.number_of_males, SDS.number_of_females]) > intmax(SDS.integer)
            msg = sprintf('Warning: Insufficient integer type: %s', SDS.integer);
        end  % == maleRange???
        if SDS.number_of_males*SDS.number_of_females > SDS.number_of_relations
            msg = sprintf('Warning: Insufficient relations size: %d', SDS.number_of_relations);
        end
        
        
        %% preprocess_trace
       function modelHIVrestart_preprocess_trace(Schar)
            
            subS = eval(Schar);

            % ******* Initialise Events *******
            if isstruct(subS) && isfield(subS, 'object_type') && ...
                    strcmp(subS.object_type, 'event')% && subS.enable
                
                if exist(subS.event_file, 'file') ~= 2
                    msg = sprintf('%sError: can''t find %s\n', msg, subS.event_file);
                    return
                end
                P0.numberOfEvents = P0.numberOfEvents + 1;
                [elements, initMsg] = feval(subS.event_file, 'init', SDS, subS);
                if ~isempty(initMsg)
                    msg = sprintf('%s%s\n', msg, initMsg);
                end
                P0.event(P0.numberOfEvents).index = (1 : elements) + sum(P0.elements);
                P0.elements(P0.numberOfEvents) = elements;
                
                
                % ******* Function Handles for Calculation Performance *******
                P0.event(P0.numberOfEvents).eventTimes = feval(subS.event_file, 'handle', 'eventTimes');
                P0.event(P0.numberOfEvents).advance = feval(subS.event_file, 'handle', 'advance');
                P0.event(P0.numberOfEvents).fire = feval(subS.event_file, 'handle', 'fire');
            end
            
            for thisField = fieldnames(subS)'
                if ~isstruct(subS.(thisField{1}))
                    continue
                end
                
                % recurrence
                modelHIVrestart_preprocess_trace([Schar, '.', thisField{1}])
            end
        end
    end


%% nextEvent
    function [SDS, t] = modelHIVrestart_nextEvent(SDS)
        
        % ******* 1: Fetch Event Times *******
        if P0.now>0
        for ii = 1 : P0.numberOfEvents
            %P0.event(ii).time = P0.event(ii).eventTime(SDS);  % earliest per event
            P0.eventTimes(P0.event(ii).index) = P0.event(ii).eventTimes(SDS, P0);
        end
        end
        
        
        % ******* 2: Find First Event & Its Entry *******
        [P0.eventTime, firstIdx] = min(P0.eventTimes);  % index into event times
        if P0.eventTime <= 0
%             problem = find(P0.cumsum >= firstIdx, 1) - 1
%             time = P0.eventTime
            %debugMsg 'eventTime == 0' %you can ignore this mention as present -Fei  08/17/2012
            P0.eventTime = 0.0001;
            %keyboard
        end
        if ~isfinite(P0.eventTime)
            t = Inf;
            return
        end
        eventIdx = find(P0.cumsum >= firstIdx, 1) - 1;  % index of event
        P0.index = firstIdx - P0.cumsum(eventIdx);      % index into event
        
        
        % ******* 3: Update Time *******
        %SDS.now(end + 1, 1) = SDS.now(end) + P0.eventTime;
        P0.now = P0.now + P0.eventTime;
        P0.maleAge = P0.maleAge + P0.eventTime;
        P0.femaleAge = P0.femaleAge + P0.eventTime;
        P0.meanAge = P0.meanAge + P0.eventTime;
        P0.timeSinceLast = P0.timeSinceLast + P0.eventTime;
        % P0.riskyBehaviour =  P0.meanAge + P0.ageDifference + P0.relationCount + P0.relationsTerm + P0.serodiscordant;        
        %{
        P0.meanAgeSex 
        P0.ageDifferenceSex
        P0.relationTypeSex
        P0.relationCountSex
        P0.serodiscordantSex
        P0.disclosureSex 
            %}
        
        P0.subset = P0.true;
        P0.subset(~P0.aliveMales, :) = false;
        P0.subset(:, ~P0.aliveFemales) = false;
        
        
        % ******* 4: Advance All Events *******
        for ii = 1 : P0.numberOfEvents
            P0.event(ii).advance(P0)
        end
        
        
        % ******* 5: Fire First Event *******
        [SDS, P0] = P0.event(eventIdx).fire(SDS, P0);
        
        P0.firedEvent(end + 1) = eventIdx;
        t = P0.now;
        
    end
end


%% postprocess
function [SDS, msg] = modelHIVrestart_postprocess(SDS)

msg = '';

if any(diff(SDS.relations.time(:, SDS.index.start)) < 0)
    msg = 'Warning: decreasing relation formation';
end

if isfinite(SDS.males.born(end))
    msg = 'Warning: male population limit reached, increase number of males';
end
if isfinite(SDS.females.born(end))
    msg = 'Warning: female population limit reached, increase number of females';
end

SDS.relations.time = roundd(SDS.relations.time, 8);
end


%% new
function [SDS, msg] = modelHIVrestart_new

msg = '';

% ******* Defaults *******
time = now;
SDS = [];
SDS.user_name = getenv('USERNAME');
SDS.file_date = datestr(time);
SDS.data_file = sprintf('data%s.m', datestr(time, 30));
SDS.model_function = mfilename;
SDS.population_function = '';

SDS.start_date = '01-Jan-1985';
SDS.end_date = '31-Dec-2010';
SDS.number_of_communities = 2;

SDS.iteration_limit = 10000;
SDS.number_of_males = 300;
SDS.number_of_females = 300;
SDS.initial_number_of_males = 200;
SDS.initial_number_of_females = 200;
SDS.number_of_community_members = floor(SDS.initial_number_of_males/2); % 4 communities
SDS.sex_worker_proportion = 0.04;
SDS.number_of_relations = SDS.number_of_males*SDS.number_of_females;
SDS.number_of_tests =  (SDS.number_of_males+SDS.number_of_females);
SDS.number_of_ARV = (SDS.number_of_males+SDS.number_of_females);

%SDS.float = 'single';           % e.g. 3.14 (32 bit floating point)
SDS.float = 'double';           % e.g. 3.14 (64 bit floating point)
SDS.integer = 'uint16';         % e.g. 3 (16 bit positive integer)
%SDS.now = 0;        % [years]

item = [' ', char(183), ' '];

SDS.comments = {
    'Population properties:'
    [item, 'father           ID of father, 0 for initial population']
    [item, 'mother           ID of mother, 0 for initial population']
    [item, 'born             time of birth w.r.t. start date [date]']
    [item, 'deceased         time of death w.r.t. start date [date]']
    [item, 'community        community ID']
    [item, 'exposure         exposure to BCC']
    [item, 'HIV source       ID of HIV source']
    [item, 'HIV positive     time of HIV transmission [date]']
    [item, 'AIDS death       time of AIDS caused death [date]']
    [item, 'HIV test         time of HIV-test [date]']
    [item, 'ARV start        start of antiretroviral treatment [date]']
    [item, 'ARV stop         stop of antiretroviral treatment [date]']
    [item, 'circumcision     time of circumcision [date]']
    [item, 'condom duration  duration of condom use (can be 0)']
    [item, 'conception       time of conception [date]']
    };


% ******* Index Keys *******
SDS.index.male   = logical([1, 0]);
SDS.index.female = logical([0, 1]);
SDS.index.start  = logical([1, 0, 0]);
SDS.index.stop   = logical([0, 1, 0]);
SDS.index.condom = logical([0, 0, 1]);


% ******* Population *******
commonPrp = struct('father',[], 'mother',[], ...
    'born',[], 'deceased',[], ...
    'HIV_source',[], ...                % source of the HIV [ID]
    'HIV_positive',[], ...              % time of HIV transmission [date]
    'AIDS_death',[], ...                % death by AIDS [boolean]
    'HIV_test',[], ...                  % time of HIV-test [date]
    'ARV_start',[], 'ARV_stop',[], ...  % antiretroviral treatment [date]
    'community',[], ...                 % currently integer
    'BCC_exposure',[], ...              % behavioural change camp. [0...1]
    'partnering', []);                  % sexual activity scale [0...1]
SDS.males = mergeStruct(commonPrp, struct(...
    'circumcision',[], ...              % time of circumcision [date]
    'condom',[]));             % duration of condom use (can be 0)
SDS.females = mergeStruct(commonPrp, struct(...
    'conception',[]));                  % time conception [date]


% ******* Relations *******
SDS.relations = struct('ID', [], 'time', []);


% ******* Fetch Available Events *******
folder = [fileparts(which(mfilename)) '/events'];
addpath(folder)
for thisFile = dir(fullfile(folder , 'event*.m'))'
    if strcmp(thisFile.name, 'eventTemplate.m')
        continue
    end    
    [~, eventFile] = fileparts(thisFile.name);
    thisField = str2field(feval(eventFile, 'name'));
    SDS.(thisField) = modelHIVrestart_eventProps(modelHIVrestart_event(eventFile));
    %SDS.(thisField).comments = {''};
end
end


%% add
function [SDS, msg] = modelHIVrestart_add(objectType, Schar, handles)

import javax.swing.ImageIcon
import javax.swing.JOptionPane

msg = '';
SDS = handles.data();
%WHY??? subS = evalstruct(SDS, Schar);
subS = eval(Schar);

Prefs = handles.prefs('retrieve');
object = char(JOptionPane.showInputDialog(handles.frame, ...
    sprintf('%s File:', capitalise(objectType)), Prefs.appName, ...
    JOptionPane.QUESTION_MESSAGE, ImageIcon(which(Prefs.appIcon)), [], objectType));
if isempty(object)
    msg = 'Cancelled by user';
    return
end

% objectField = genvarname(strrep(object, ' ', '_'));
% if isfield(subS, objectField)
%     msg = sprintf('The %s ''%s'' already exists', objectType, object);
%     return
% end
if isempty(which(object))
    msg = sprintf('Warning: can''t find %s file ''%s.m''', objectType, object);
    return
end

switch objectType
    case 'event'
        objectField = str2field(feval(object, 'name'));
        [subS.(objectField), msg] = modelHIVrestart_eventProps(modelHIVrestart_event(object));
        if ~isempty(msg)
            return
        end
        eval(sprintf('%s = subS;', Schar))
        
    otherwise
        error '.'
end
end


%% event
function event = modelHIVrestart_event(eventFile)

event = struct('object_type', 'event', ...
    'enable', true, ...    'comments', {{''}}, ...
    'event_file', eventFile);
end


%% eventProps
function [subS, msg] = modelHIVrestart_eventProps(subS)

msg = '';

% ******* Checks *******
if ~isfield(subS, 'event_file')
    msg = 'Warning: not a valid event object';
    return
end

if isempty(subS.event_file)
    subS.enable = false;
    msg = 'Warning: not all events have an event file set';
    return
end

if exist(subS.event_file, 'file') ~= 2
    msg = sprintf('Warning: can''t find event function ''%s''', ...
        subS.event_file);
    return
end

subFields = fieldnames(subS);
eventFields = fieldnames(modelHIVrestart_event(''));
handleEvent = str2func(subS.event_file);
[propS, propMsg] = handleEvent('properties');
propFields = fieldnames(propS);


% ******* Remove Obsolete Properties *******
for thisField = subFields'
    
    eventIdx = strcmp(thisField{1}, eventFields);
    propIdx = strcmp(thisField{1}, propFields);
    
    if any(eventIdx) || any(propIdx) || isstruct(subS.(thisField{1}))
        continue
    end
    
    subS = rmfield(subS, thisField{1});
end


% ******* Add Event Properties *******
%subS = mergeStruct(subS, propS);
for thisField = propFields'
    
    if any(strcmp(thisField{1}, subFields))
        % property already present, don't overrule
        continue
    end
    subS.(thisField{1}) = propS.(thisField{1});
end

if ~isfield(subS, 'comments')
    subS.comments = {propMsg};
end
end


%% popupMenu
function modelHIVrestart_popupMenu(Schar, SDS, popupMenu, handles)

import javax.swing.JMenu
import javax.swing.JMenuItem

if isempty(Schar)
    return
end

%WHY??? subS = evalstruct(SDS, Schar);
subS = eval(Schar);
isObject = isfield(subS, 'object_type');

if strcmp(Schar, 'SDS')% || isObject
    menuItem = JMenuItem('Add New Event');
    jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_popupMenu_add, 'event'});
    popupMenu.add(menuItem);
end

% ******* Remove Objects from Data Structure *******
if ~isObject
    return
end

enumC = regexp(Schar, '\.(\w+)\(?(\d*)\)?', 'tokens');
name = sprintf('%s: <i>%s</i>', capitalise(subS.object_type), field2str(enumC{end}{1}));

% if strcmp(subS.object_type, 'event') && ~isempty(subS.event_file)
%     popupMenu.addSeparator()
%
%     %menuItem = JMenuItem('Initialise Event');
%     menuItem = JMenuItem(sprintf('<html>Add Properties: <i>%s</i></html>', subS.event_file));
%     %doesnt work menuItem.setEnabled(~isempty(subS.event_file))
%     jset(menuItem, 'ActionPerformedCallback', @modelHIVrestart_popupMenu_eventProps);
%     popupMenu.add(menuItem);
% end
% popupMenu.addSeparator()

if ~isempty(subS.event_file)
    menuItem = JMenuItem(sprintf('<html>Open %s</html>', name));
    jset(menuItem, 'ActionPerformedCallback', @modelHIVrestart_popupMenu_open);
    popupMenu.add(menuItem);
    
    popupMenu.addSeparator()
end

menuItem = JMenuItem(sprintf('<html>Remove %s</html>', name));
jset(menuItem, 'ActionPerformedCallback', @modelHIVrestart_popupMenu_removeField);
popupMenu.add(menuItem);


%% popupMenu_add
    function modelHIVrestart_popupMenu_add(~, ~, objectType)
        
        %handles.msg('Adding %s...', objectType)
        [SDS, msg] = modelHIVrestart_add(objectType, Schar, handles);
        
        if ~isempty(msg)
            handles.fail(msg)
            return
        end
        
        handles.update(SDS)
        %handles.msg(' ok\n')
    end


%% popupMenu_eventProps CODE DUPL!!!
    function modelHIVrestart_popupMenu_eventProps(~, ~)
        
        [subS, msg] = modelHIVrestart_eventProps(subS);
        if ~isempty(msg)
            handles.fail(msg)
            return
        end
        eval([Schar, ' = subS;'])
        handles.update(SDS, '-restore')
    end


%% popupMenu_open
    function modelHIVrestart_popupMenu_open(~, ~)
        
        file = which(subS.event_file);
        [ok, msg] = backup(file);
        if ok
            handles.msg('Backup: %s\n', msg)
        else
            handles.fail(msg)
        end
        open(file)
    end


%% popupMenu_removeField
    function modelHIVrestart_popupMenu_removeField(~, ~)
        
        import javax.swing.ImageIcon
        import javax.swing.JOptionPane
        
        remC = regexp(Schar, '(.+)\.(.+)', 'tokens', 'once');
        action = sprintf('<html>Remove %s <i>%s</i>?</html>', ...
            subS.object_type, field2str(remC{2}));
        %handles.msg([action, '...'])
        
        Prefs = handles.prefs('retrieve');
        choice = JOptionPane.showConfirmDialog(handles.frame, ...
            [action, '?'], Prefs.appName, JOptionPane.OK_CANCEL_OPTION, ...
            JOptionPane.QUESTION_MESSAGE, ImageIcon(which(Prefs.appIcon)));
        
        if choice ~= JOptionPane.OK_OPTION
            %handles.fail('Cancelled by user')
            return
        end
        
        subS = rmfield(eval(remC{1}), remC{2});
        eval([remC{1}, ' = subS;'])
        
        handles.update(SDS)
        %handles.msg(' ok\n')
    end
end


%% menu
function modelMenu = modelHIVrestart_menu(handlesFcn)

import java.awt.event.ActionEvent
import java.awt.event.KeyEvent
import javax.swing.JMenu
import javax.swing.JMenuItem
import javax.swing.KeyStroke

handles = handlesFcn();

modelMenu = JMenu('Model');
modelMenu.setMnemonic(KeyEvent.VK_M)

menuItem = JMenuItem('Start Simulation', KeyEvent.VK_S);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_T, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Start simulation')
jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
modelMenu.add(menuItem);

if strcmp(getenv('USERNAME'), 'ralph')
    menuItem = JMenuItem('Pre Process');
    jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
    modelMenu.add(menuItem);
    
    menuItem = JMenuItem('Post Process');
    jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
    modelMenu.add(menuItem);
end

modelMenu.addSeparator()

menuItem = JMenuItem('Open Project Folder', KeyEvent.VK_P);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_P, ActionEvent.CTRL_MASK))
menuItem.setDisplayedMnemonicIndex(5)
menuItem.setToolTipText('Open project folder in Windows Explorer')
jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
modelMenu.add(menuItem);

menuItem = JMenuItem('Open Data File', KeyEvent.VK_D);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Open data script -if available- in editor')
jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
modelMenu.add(menuItem);

modelMenu.addSeparator()

% menuItem = JMenuItem('Add Event', KeyEvent.VK_A);
% menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_A, ActionEvent.CTRL_MASK))
% menuItem.setToolTipText('Add an event to this model')
% jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
% modelMenu.add(menuItem);
% modelMenu.addSeparator()

menuItem = JMenuItem('To MATLAB Workspace', KeyEvent.VK_W);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_W, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Assign SDS data structure to MATLAB workspace (Command Window)')
jset(menuItem, 'ActionPerformedCallback', {@modelHIVrestart_callback, handles})
modelMenu.add(menuItem);
end


%% callback
function modelHIVrestart_callback(~, actionEvent, handles)

SDS = handles.data();
handles.state('busy')

try
    action = get(actionEvent, 'ActionCommand');
    
    switch action
        case 'Pre Process'
            handles.msg('Pre processing... ')
            [SDS, msg] = modelHIVrestart('preprocess', SDS);    % modelHIVrestart_preprocess
            if ~isempty(msg)
                handles.fail(msg)
                return
            end
            handles.update(SDS, '-restore')
            handles.msg(' ok\n')
            
        case 'Post Process'
            handles.msg('Post processing... ')
            [SDS, msg] = modelHIVrestart_postprocess(SDS);
            if ~isempty(msg)
                handles.fail(msg)
                return
            end
            handles.update(SDS, '-restore')
            handles.msg(' ok\n')
            
        case 'Start Simulation'
            spRun('start', handles);
            
        case 'Open Project Folder'
            handles.msg('Opening project folder...')
            winopen(jproject('folder'))
            handles.msg(' ok\n')
            
        case 'Open Data File'
            handles.msg('Opening data file...')
            [ok, msg] = spTools('edit', modelHIVrestart_dataFile(SDS));
            if ok
                handles.msg(' ok\n')
            else
                handles.fail(msg)
            end
            
        case 'Add Event'
            debugMsg 'Add Event'
            
        case 'To MATLAB Workspace'
            handles.msg('Assigning data structure to MATLAB workspace...')
            base(SDS)
            handles.msg(' ok\n')
            
        otherwise
            handles.fail('Warning: unknown action ''%s''\n', action)
            return
    end
    
catch Exception
    handles.fail(Exception)
    return
end

handles.state('ready')
end


%% dataFile
function dataFile = modelHIVrestart_dataFile(SDS)

dataFile = SDS.data_file;
end


%% test
function modelHIVrestart_test

debugMsg -on
debugMsg

% ******* Relay to GUI Test *******
SIMPACT
end


%%
function modelHIVrestart_

end
