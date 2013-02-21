function varargout = modelHIV(fcn, varargin)
%modelHIV SIMPACT HIV model function which controls the data structure.
%   This function implements new, nextEvent, preprocess, initialise, menu.
%
%   See also SIMPACT, spRun, spTools.

% File settings:
%#ok<*DEFNU>

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

persistent P0

if nargin == 0
    modelHIV_test
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
    function [SDS, msg] = modelHIV_preprocess(SDS)
        % Invoked by spRun('start') during initialisation
        
        msg = '';
        
        %spTools('resetRand')	% reset random number generator
        
        % ******* Function Handles *******
        %empiricalExposure = spTools('handle', 'empiricalExposure');
        %empiricalCommunity = spTools('handle', 'empiricalCommunity');
        empiricalCRF = spTools('handle', 'empiricalCRF');
        
        %NIU populationCount = SDS.number_of_males + SDS.number_of_females;
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
        
        P0.now = 0;
        
        
        % ******* Influence Subset *******
        P0.true = true(SDS.number_of_males, SDS.number_of_females);
        %maleRange = ones(1, SDS.integer) : SDS.number_of_males;
        %femaleRange = ones(1, SDS.integer) : SDS.number_of_females;
        %P0.subset = true(SDS.number_of_males, SDS.number_of_females);
        maleRange = 1 : SDS.initial_number_of_males;
        femaleRange = 1 : SDS.initial_number_of_females;
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
        SDS.males.father = malesInt;
        SDS.females.father = femalesInt;
        SDS.males.mother = SDS.males.father;
        SDS.females.mother = SDS.females.father;
        SDS.males.born = malesNaN;
        SDS.females.born = femalesNaN;
        SDS.males.deceased = malesNaN;
        SDS.females.deceased = femalesNaN;
        SDS.males.community = malesInt;
        SDS.females.community = femalesInt;
        SDS.males.partnering = malesOnes;
        SDS.females.partnering = femalesOnes;
        SDS.males.BCC_exposure = malesNaN;
        SDS.females.BCC_exposure = femalesNaN;
        SDS.males.current_relations_factor = malesNaN;
        SDS.females.current_relations_factor = femalesNaN;

        
                
        % ******* Communities TEMP!!! *******
        
        communityMale = empiricalCommunity(SDS.initial_number_of_males, SDS.number_of_community_members);
        communityFemale = empiricalCommunity(SDS.initial_number_of_females, SDS.number_of_community_members);
        SDS.males.community(maleRange) = cast(communityMale, SDS.integer);
        SDS.females.community(femaleRange) = cast(communityFemale, SDS.integer);
        
        
        
        
        
        % ******* BCC Exposure TEMP!!! *******
        %{
        llimit =[0.99, 0.99];
        ulimit = [1, 1];
        peak = [1, 1];  % community 1 low exposure, community 2 high exposure;
        BCCexposureMale = empiricalExposure(SDS.initial_number_of_males, llimit, ulimit, peak, communityMale);
        BCCexposureFemale = empiricalExposure(SDS.initial_number_of_females, llimit, ulimit, peak, communityFemale);
        SDS.males.BCC_exposure(maleRange) = BCCexposureMale;
        SDS.females.BCC_exposure(femaleRange) = BCCexposureFemale;
        %}
%         SDS.males.BCC_exposure(maleRange) = 1;  UNUSED?
%         SDS.females.BCC_exposure(femaleRange) = 1; UNUSED?
        % ******* BCC Current Relations Factor ********
        %Using Discrete Value for 2 communities
        %LUCIO -- in changing to SDS.events I had to change this, though
        %I don't know what it does 2012/09/19
        SDS.males.current_relations_factor(:) = SDS.events.formation.current_relations_factor;
        SDS.females.current_relations_factor(:) = SDS.events.formation.current_relations_factor;          

        %Using Beta Distribution for 2 communities
        %{
        betaPars.alpha = [100, 100];
        betaPars.beta = [1, 1];
        current_relations_factorMale = empiricalCRF(SDS.initial_number_of_males,betaPars,communityMale, SDS);
        current_relations_factorFemale = empiricalCRF(SDS.initial_number_of_males,betaPars,communityFemale, SDS);
        SDS.males.current_relations_factor(maleRange) = current_relations_factorMale;
        SDS.females.current_relations_factor(femaleRange) = current_relations_factorFemale;       
        %}
           
        % ******* Partnering TEMP!!! *******
        betaPars(1) = SDS.betaPars1;
        betaPars(2) = SDS.betaPars2;

        partneringFcn = 'mean';
        SDS.males.partnering = cast(betainv(rand(1, SDS.number_of_males, SDS.float), betaPars(1), betaPars(2)), SDS.float);
        SDS.females.partnering = cast(betainv(rand(1, SDS.number_of_females, SDS.float), betaPars(1), betaPars(2)), SDS.float);
        
        [partMales, pathFemales] = ndgrid(SDS.males.partnering, SDS.females.partnering);
        formationfield = str2field(eventFormation('name'));
        if isfield(SDS, formationfield)
            partneringFcn = SDS.(formationfield).partnering_function.SelectedItem;
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
        
        % ******* Individual age mixing parameters *******
        % individual age difference preference (optimum)
        mu_individ_age = SDS.mu_individ_age;
        sigma_individ_age = SDS.sigma_individ_age;
        SDS.males.preferred_age_difference = cast(normrnd(mu_individ_age,sigma_individ_age,SDS.number_of_males,1), SDS.float);
        SDS.females.preferred_age_difference = cast(normrnd(mu_individ_age,sigma_individ_age,SDS.number_of_females,1), SDS.float);
        [P0.pref_age_diffMales, P0.pref_age_diffFemales] = ndgrid(SDS.males.preferred_age_difference, SDS.females.preferred_age_difference);
        
        % individual age difference factor
        mean_age_diff_factor = SDS.mean_age_diff_factor;
        range_age_diff_factor = SDS.range_age_diff_factor;
        
        ageDiffFactorFcn = SDS.interventions.AgeMixingChange.ageDiffFactorFcn;
        SDS.males.ageDiffFactor = cast(malesOnes.*mean_age_diff_factor + (rand(1,SDS.number_of_males)-0.5)*range_age_diff_factor, SDS.float);
        SDS.females.ageDiffFactor = cast(femalesOnes.*mean_age_diff_factor + (rand(1,SDS.number_of_females)-0.5)*range_age_diff_factor, SDS.float);
        
        [ageDiffFactMales, ageDiffFactFemales] = ndgrid(SDS.males.ageDiffFactor, SDS.females.ageDiffFactor);
        agedifffield = str2field(eventFormation('name'));
        if isfield(SDS, agedifffield)
            ageDiffFactorFcn = SDS.(agedifffield).agediff_function.SelectedItem;
        end
        switch ageDiffFactorFcn
            case 'min'
                P0.agediff = min(ageDiffFactMales, ageDiffFactFemales);
            case 'max'
                P0.agediff = max(ageDiffFactMales, ageDiffFactFemales);
            case 'mean'
                P0.agediff = (ageDiffFactMales + ageDiffFactFemales)/2;
            case 'product'
                P0.agediff = -(ageDiffFactMales.*ageDiffFactFemales);
        end
        
        % individual mean age growth factor
        mu_mean_age_growth = SDS.mu_mean_age_growth;
        sigma_mean_age_growth = SDS.sigma_mean_age_growth;
        
        meanAgeGrowthFactorFcn = SDS.interventions.AgeMixingChange.meanAgeGrowthFactorFcn;
        
        SDS.males.meanAgeGrowthFactor = cast(normrnd(mu_mean_age_growth,sigma_mean_age_growth,SDS.number_of_males,1), SDS.float);
        SDS.females.meanAgeGrowthFactor = cast(normrnd(mu_mean_age_growth,sigma_mean_age_growth,SDS.number_of_females,1), SDS.float);
        
        [meanAgeGrowthFactMales, meanAgeGrowthFactFemales] = ndgrid(SDS.males.meanAgeGrowthFactor, SDS.females.meanAgeGrowthFactor);
        meanAgeGrowthfield = str2field(eventFormation('name'));
        if isfield(SDS, meanAgeGrowthfield)
            meanAgeGrowthFactorFcn = SDS.(meanAgeGrowthfield).meanagegrowth_function.SelectedItem;
        end
        switch meanAgeGrowthFactorFcn
            case 'min'
                P0.meanagegrowth = min(meanAgeGrowthFactMales, meanAgeGrowthFactFemales);
            case 'max'
                P0.meanagegrowth = max(meanAgeGrowthFactMales, meanAgeGrowthFactFemales);
            case 'mean'
                P0.meanagegrowth = (meanAgeGrowthFactMales + meanAgeGrowthFactFemales)/2;
            case 'product'
                P0.meanagegrowth = meanAgeGrowthFactMales.*meanAgeGrowthFactFemales;
        end
        
        % individual mean age dispersion growth factor
        mu_mean_age_dispersion_growth = SDS.mu_mean_age_dispersion_growth;
        sigma_mean_age_dispersion_growth = SDS.sigma_mean_age_dispersion_growth;
        
        meanAgeDispersionGrowthFactorFcn = SDS.interventions.AgeMixingChange.meanAgeDispersionGrowthFactorFcn;
        
        SDS.males.meanAgeDispersionGrowthFactor = cast(normrnd(mu_mean_age_dispersion_growth,sigma_mean_age_dispersion_growth,SDS.number_of_males,1), SDS.float);
        SDS.females.meanAgeDispersionGrowthFactor = cast(normrnd(mu_mean_age_dispersion_growth,sigma_mean_age_dispersion_growth,SDS.number_of_females,1), SDS.float);
        
        [meanAgeDispersionGrowthFactMales, meanAgeDispersionGrowthFactFemales] = ndgrid(SDS.males.meanAgeDispersionGrowthFactor, SDS.females.meanAgeDispersionGrowthFactor);
        meanAgeDispersionGrowthfield = str2field(eventFormation('name'));
        if isfield(SDS, meanAgeDispersionGrowthfield)
            meanAgeDispersionGrowthFactorFcn = SDS.(meanAgeDispersionGrowthfield).meanagedispersiongrowth_function.SelectedItem;
        end
        switch meanAgeDispersionGrowthFactorFcn
            case 'min'
                P0.meanagedispersiongrowth = min(meanAgeDispersionGrowthFactMales, meanAgeDispersionGrowthFactFemales);
            case 'max'
                P0.meanagedispersiongrowth = max(meanAgeDispersionGrowthFactMales, meanAgeDispersionGrowthFactFemales);
            case 'mean'
                P0.meanagedispersiongrowth = (meanAgeDispersionGrowthFactMales + meanAgeDispersionGrowthFactFemales)/2;
            case 'product'
                P0.meanagedispersiongrowth = meanAgeDispersionGrowthFactMales.*meanAgeDispersionGrowthFactFemales;
        end
        
        % ******* Aging TEMP!!! *******
        agesMale = empiricalage(SDS.initial_number_of_males);
        SDS.males.born(maleRange) = cast(-agesMale, SDS.float);    % -years old
        agesFemale = empiricalage(SDS.initial_number_of_females);
        SDS.females.born(femaleRange) = cast(-agesFemale, SDS.float);% -years old
        
        
        % ******* HIV Properties *******
        SDS.males.HIV_source = malesInt;
        SDS.females.HIV_source = femalesInt;
        SDS.males.HIV_positive = malesNaN;
        SDS.females.HIV_positive = femalesNaN;
        SDS.males.AIDS_death = malesFalse;
        SDS.females.AIDS_death = femalesFalse;
        SDS.males.ARV_eligible = malesNaN;
        SDS.females.ARV_eligible = femalesNaN;
        SDS.males.ARV_start = malesNaN;
        SDS.females.ARV_start = femalesNaN;
        SDS.males.ARV_stop = malesNaN;
        SDS.females.ARV_stop = femalesNaN;
        SDS.males.circumcision = malesNaN;
        SDS.males.condom = malesZeros;
        SDS.females.condom = femalesZeros;
        SDS.females.conception = femalesFalse;
        SDS.males.ARV = malesFalse;
        SDS.females.ARV = femalesFalse;
        %---------------------------------------------------------%
        SDS.males.HIV_test = malesNaN;
        SDS.females.HIV_test = femalesNaN;
        SDS.males.HIV_test_change = malesNaN;
        SDS.females.HIV_test_change= femalesNaN;
        % SDS.females.ANC = femalesNaN;
        SDS.males.CD4Infection = malesNaN;
        SDS.females.CD4Infection = femalesNaN;
        SDS.males.CD4ARV = malesNaN;
        SDS.females.CD4ARV = femalesNaN;
        SDS.males.CD4Death = malesNaN;
        SDS.females.CD4Death = femalesNaN;
        SDS.females.conceptions = femalesZeros;
        SDS.males.AIDSdeath = malesNaN; %since infection
        SDS.females.AIDSdeath = femalesNaN;
        SDS.person_years_aquired = 0;
        SDS.males.behaviour_factor = malesNaN;
        SDS.females.behaviour_factor = femalesNaN;
        
        SDS.females.sex_worker = rand(1, SDS.number_of_females)<= SDS.sex_worker_proportion;
        
        SDS.tests.ID= zeros(SDS.number_of_tests,1, SDS.integer);
        SDS.tests.time = nan(SDS.number_of_tests,1, SDS.float);
        
        SDS.ARV.ID = zeros(SDS.number_of_ARV, 1, SDS.integer);
        SDS.ARV.CD4 = zeros(SDS.number_of_ARV, 1, SDS.integer);
        SDS.ARV.time = nan(SDS.number_of_ARV, 2, SDS.float);
        SDS.ARV.life_year_saved = nan(SDS.number_of_ARV, 1, SDS.float);
        
        P0.birth = false;
        P0.conception = false;
        %%%%%%%%%%%%%%%%%
        P0.ANC= false;
        SDS.tests.typeANC = false(SDS.number_of_tests,1);
       
        SDS.males.AIDSdeath =  spTools('weibull', 12, 2.25, rand(1, SDS.number_of_males));
        SDS.females.AIDSdeath =  spTools('weibull', 12, 2.25, rand(1, SDS.number_of_females));
       
        % ******* Initialise Relations *******
        SDS.relations.ID = zeros(SDS.number_of_relations, 2, SDS.integer);
        SDS.relations.type = zeros(SDS.number_of_relations, 2, SDS.integer);
        %SDS.relations.condom_use = zeros(SDS.number_of_relations,1,SDS.integer);
        SDS.relations.proximity = zeros(SDS.number_of_relations,1,SDS.integer);
        % single requires relative time (dt) for accuracy,
        % for base 1/1/00 datenum results in 1.5 hrs resolution
        SDS.relations.time = [
            nan(SDS.number_of_relations, 1, SDS.float), ...
            nan(SDS.number_of_relations, 1, SDS.float), ...
            zeros(SDS.number_of_relations, 1, SDS.float)
            ];
        
        
        % ******* Common Parameters for Population of Singles *******
        P0.maleRelationCount = zeros(SDS.number_of_males, 1, SDS.float);
        P0.femaleRelationCount = zeros(1, SDS.number_of_females, SDS.float);
        P0.relationCount = ...
            repmat(P0.maleRelationCount, 1, SDS.number_of_females) + ...
            repmat(P0.femaleRelationCount, SDS.number_of_males, 1);
        %P0.maleRelationCountmat = repmat(P0.maleRelationCount, 1, SDS.number_of_females);
        %P0.femaleRelationCountmat = repmat(P0.femaleRelationCount, SDS.number_of_males, 1);
        P0.relationCountDifference = abs(...
            repmat(P0.maleRelationCount, 1, SDS.number_of_females) - ...
            repmat(P0.femaleRelationCount, SDS.number_of_males, 1));
        
        P0.transactionSex = repmat(SDS.females.sex_worker, SDS.number_of_males, 1);
        
        P0.maleAge = -repmat(SDS.males.born(:), 1, SDS.number_of_females);
        P0.femaleAge = -repmat(SDS.females.born(:)', SDS.number_of_males, 1);
        P0.meanAge = (P0.maleAge + P0.femaleAge)/2;
        
        %%%%%%%%
        P0.maleCommunity = repmat(SDS.males.community(:), 1, SDS.number_of_females);
        P0.femaleCommunity = repmat(SDS.females.community(:)', SDS.number_of_males, 1);
        
        
        % P0.maleBCCexposure = repmat(SDS.males.BCC_exposure(:), 1, SDS.number_of_females); % UNUSED?
        % P0.femaleBCCexposure = repmat(SDS.females.BCC_exposure(:)', SDS.number_of_males, 1); % UNUSED?

        P0.malecurrent_relations_factor = repmat(SDS.males.current_relations_factor(:), 1, SDS.number_of_females);%
        P0.femalecurrent_relations_factor = repmat(SDS.females.current_relations_factor(:)', SDS.number_of_males, 1);%
        
        P0.timeSinceLast = min(...
            repmat(-SDS.males.born(:), 1, SDS.number_of_females), ...
            repmat(-SDS.females.born(:)', SDS.number_of_males, 1));
        
        P0.ageDifference = P0.maleAge - P0.femaleAge;
        
        %%%%%%%
        P0.communityDifference = cast(P0.maleCommunity - P0.femaleCommunity, SDS.float);
%         P0.BCCexposureMax = max(P0.maleBCCexposure,P0.femaleBCCexposure);%
%         P0.BCCexposureMin = min(P0.maleBCCexposure,P0.femaleBCCexposure);%
%         P0.BCCexposureMean = (P0.maleBCCexposure+P0.femaleBCCexposure)./2;%
        
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
        P0.eligible = [malesFalse, femalesFalse];
        P0.introduce = false;
        P0.optionB = false;
        P0.thisPregnantTime = nan(1, SDS.number_of_females);
        P0.thisChild = nan(1, SDS.number_of_females);
        % 'baseline' 'mean age factor' 'age difference factor' 'relation
        % type' 'relations count' 'serodiscordant' 'HIV disclosure'
   
        % ******* Event Functions *******
        P0.numberOfEvents = 0;
        P0.elements = [];
        P0.event = struct('eventTime', {}, 'fire', {}, 'advance', {}, 'time', {}, 'get', {},'restore',{},'P',{});
        modelHIV_preprocess_trace('SDS')    % ********
        P0.eventTime = 0; %[];
        P0.eventTimes = inf(1, sum(P0.elements));
        P0.cumsum = [0, cumsum(P0.elements)];
        P0.firedEvent = [];
        
        
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
        function modelHIV_preprocess_trace(Schar)
            
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
                modelHIV_preprocess_trace([Schar, '.', thisField{1}])
            end
        end
    end


%% nextEvent
    function [SDS, t] = modelHIV_nextEvent(SDS)        
        % ******* 1: Fetch Event Times *******
        for ii = 1 : P0.numberOfEvents
            %P0.event(ii).time = P0.event(ii).eventTime(SDS);  % earliest per event
            P0.eventTimes(P0.event(ii).index) = P0.event(ii).eventTimes(SDS, P0);
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
        %P0.meanAge = P0.meanAge + P0.eventTime;
        P0.meanAge = (P0.maleAge + P0.femaleAge)/2;
        P0.ageDifference = P0.maleAge - P0.femaleAge;
        
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
        %if P0.now >= 5
            %save P0.mat P0
        %end
    end
end


%% postprocess
function [SDS, msg] = modelHIV_postprocess(SDS)

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
function [SDS, msg] = modelHIV_new

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


% ******* Partnering parameters ********
SDS.betaPars1 = 0.5;
SDS.betaPars2 = 0.5;

% ******* Individual age mixing parameters ********
SDS.mu_individ_age = 10;       % population average of preferred age difference
SDS.sigma_individ_age = 1;    % variability around this population average;

SDS.mean_age_diff_factor = 0; % the average age difference factor is -1;
SDS.range_age_diff_factor = 0; % it ranges between mean_age_diff_factor +/- (1/2) range_age_diff_factor; 

SDS.mu_mean_age_growth = 1; % the population average of the mean age growth factor;
SDS.sigma_mean_age_growth = 0; % variability around this population average;


% ******* Fetch Available Events *******
folder = [fileparts(which(mfilename)) '/events'];
addpath(folder)
for thisFile = dir(fullfile(folder , 'event*.m'))'
    if strcmp(thisFile.name, 'eventTemplate.m')
        continue
    end    
    [~, eventFile] = fileparts(thisFile.name);
    thisField = str2field(feval(eventFile, 'name'));
    SDS.events.(thisField) = modelHIV_eventProps(modelHIV_event(eventFile));
    %SDS.(thisField).comments = {''};
end

% ******* Fetch Available Interventions *******
folder = [fileparts(which(mfilename)) '/interventions'];
addpath(folder)
for thisFile = dir(fullfile(folder , 'event*.m'))'
    if strcmp(thisFile.name, 'eventTemplate.m')
        continue
    end    
    [~, eventFile] = fileparts(thisFile.name);
    thisField = str2field(feval(eventFile, 'name'));
    SDS.interventions.(thisField) = modelHIV_eventProps(modelHIV_event(eventFile));
end

end


%% add
function [SDS, msg] = modelHIV_add(objectType, Schar, handles)

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
        [subS.(objectField), msg] = modelHIV_eventProps(modelHIV_event(object));
        if ~isempty(msg)
            return
        end
        eval(sprintf('%s = subS;', Schar))
        
    otherwise
        error '.'
end
end


%% event
function event = modelHIV_event(eventFile)

event = struct('object_type', 'event', ...
    'enable', true, ...    'comments', {{''}}, ...
    'event_file', eventFile);
end


%% eventProps
function [subS, msg] = modelHIV_eventProps(subS)

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
eventFields = fieldnames(modelHIV_event(''));
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
function modelHIV_popupMenu(Schar, SDS, popupMenu, handles)

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
    jset(menuItem, 'ActionPerformedCallback', {@modelHIV_popupMenu_add, 'event'});
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
%     jset(menuItem, 'ActionPerformedCallback', @modelHIV_popupMenu_eventProps);
%     popupMenu.add(menuItem);
% end
% popupMenu.addSeparator()

if ~isempty(subS.event_file)
    menuItem = JMenuItem(sprintf('<html>Open %s</html>', name));
    jset(menuItem, 'ActionPerformedCallback', @modelHIV_popupMenu_open);
    popupMenu.add(menuItem);
    
    popupMenu.addSeparator()
end

menuItem = JMenuItem(sprintf('<html>Remove %s</html>', name));
jset(menuItem, 'ActionPerformedCallback', @modelHIV_popupMenu_removeField);
popupMenu.add(menuItem);


%% popupMenu_add
    function modelHIV_popupMenu_add(~, ~, objectType)
        
        %handles.msg('Adding %s...', objectType)
        [SDS, msg] = modelHIV_add(objectType, Schar, handles);
        
        if ~isempty(msg)
            handles.fail(msg)
            return
        end
        
        handles.update(SDS)
        %handles.msg(' ok\n')
    end


%% popupMenu_eventProps CODE DUPL!!!
    function modelHIV_popupMenu_eventProps(~, ~)
        
        [subS, msg] = modelHIV_eventProps(subS);
        if ~isempty(msg)
            handles.fail(msg)
            return
        end
        eval([Schar, ' = subS;'])
        handles.update(SDS, '-restore')
    end


%% popupMenu_open
    function modelHIV_popupMenu_open(~, ~)
        
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
    function modelHIV_popupMenu_removeField(~, ~)
        
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
function modelMenu = modelHIV_menu(handlesFcn)

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
jset(menuItem, 'ActionPerformedCallback', {@modelHIV_callback, handles})
modelMenu.add(menuItem);

if strcmp(getenv('USERNAME'), 'ralph')
    menuItem = JMenuItem('Pre Process');
    jset(menuItem, 'ActionPerformedCallback', {@modelHIV_callback, handles})
    modelMenu.add(menuItem);
    
    menuItem = JMenuItem('Post Process');
    jset(menuItem, 'ActionPerformedCallback', {@modelHIV_callback, handles})
    modelMenu.add(menuItem);
end

modelMenu.addSeparator()

menuItem = JMenuItem('Open Project Folder', KeyEvent.VK_P);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_P, ActionEvent.CTRL_MASK))
menuItem.setDisplayedMnemonicIndex(5)
menuItem.setToolTipText('Open project folder in Windows Explorer')
jset(menuItem, 'ActionPerformedCallback', {@modelHIV_callback, handles})
modelMenu.add(menuItem);

menuItem = JMenuItem('Open Data File', KeyEvent.VK_D);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Open data script -if available- in editor')
jset(menuItem, 'ActionPerformedCallback', {@modelHIV_callback, handles})
modelMenu.add(menuItem);

modelMenu.addSeparator()

% menuItem = JMenuItem('Add Event', KeyEvent.VK_A);
% menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_A, ActionEvent.CTRL_MASK))
% menuItem.setToolTipText('Add an event to this model')
% jset(menuItem, 'ActionPerformedCallback', {@modelHIV_callback, handles})
% modelMenu.add(menuItem);
% modelMenu.addSeparator()

menuItem = JMenuItem('To MATLAB Workspace', KeyEvent.VK_W);
menuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_W, ActionEvent.CTRL_MASK))
menuItem.setToolTipText('Assign SDS data structure to MATLAB workspace (Command Window)')
jset(menuItem, 'ActionPerformedCallback', {@modelHIV_callback, handles})
modelMenu.add(menuItem);
end


%% callback
function modelHIV_callback(~, actionEvent, handles)

SDS = handles.data();
handles.state('busy')

try
    action = get(actionEvent, 'ActionCommand');
    
    switch action
        case 'Pre Process'
            handles.msg('Pre processing... ')
            [SDS, msg] = modelHIV('preprocess', SDS);    % modelHIV_preprocess
            if ~isempty(msg)
                handles.fail(msg)
                return
            end
            handles.update(SDS, '-restore')
            handles.msg(' ok\n')
            
        case 'Post Process'
            handles.msg('Post processing... ')
            [SDS, msg] = modelHIV_postprocess(SDS);
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
            [ok, msg] = spTools('edit', modelHIV_dataFile(SDS));
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
function dataFile = modelHIV_dataFile(SDS)

dataFile = SDS.data_file;
end


%% test
function modelHIV_test

debugMsg -on
debugMsg

% ******* Relay to GUI Test *******
SIMPACT
end


%%
function modelHIV_

end
