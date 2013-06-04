function varargout = eventAgeMixingChange(fcn, varargin)
%eventAgeMixingChange SIMPACT event function: 
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
    function [elements, msg] = eventAgeMixingChange_init(SDS, event)
        
        elements = 6;
        % 1 = changing mean of preferred age difference
        % 2 = changing standard deviation of preferred age difference
        % 3 = changing mean of the age difference factor
        % 4 = changing range of the age difference factor
        % 5 = changing slope of the age mixing regression line
        % 6 = changing the dispersion parameter of the age mixing pattern
        msg = '';
        P = event;

        P.starts = spTools('dateTOsimtime',P.start_agemix(:,1),SDS.start_date); %gives the start time in sim time <-- doesn't get updated
 
        P.eventTimes = P.starts; %gives the start time in sim time
        [P.updateFormation, msg] = spTools('handle', 'eventFormation', 'update');
        
    end


%% eventTimes
    function eventTimes = eventAgeMixingChange_eventTimes(SDS,P0)        
        eventTimes = P.eventTimes;
    end

%% advance
    function eventAgeMixingChange_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end

%% fire (main)
    function [SDS,P0] = eventAgeMixingChange_fire(SDS, P0)
        [~,am] = min(P.eventTimes); %find the Age Mixing intervention that is being fired now
        [SDS,P0] = eval(sprintf('eventAgeMixingChange%i_fire(SDS,P0)',am));
        P.eventTimes(am) = Inf;
        %After firing the eventTimes should be set to infinity
    end

%% fire1
% changing mean of preferred age difference for a certain fraction of the population
    function [SDS,P0] = eventAgeMixingChange1_fire(SDS, P0)    
		pop = sum(P0.aliveMales) + sum(P0.aliveFemales); %only in the case where nobody is born
        percentage_changed = (P.start_agemix{1,2}/pop);    
        if percentage_changed<= 0 %this Age Mixing intervention is not being implemented
            return
        end
        
        SDS.males.am1 = rand(1,SDS.number_of_males)<percentage_changed;  % for these males, the age mixing parameters change
        SDS.females.am1 = rand(1,SDS.number_of_females)<percentage_changed; % for these females, the age mixing parameters change
        sumMales.am1 = sum(SDS.males.am1);
        sumFemales.am1 = sum(SDS.females.am1);

        P0.pref_age_diffMales(SDS.males.am1,:) = repmat(cast(normrnd(P.new_mu_individ_age,SDS.sigma_individ_age,sumMales.am1,1), SDS.float),1,SDS.number_of_females);
        P0.pref_age_diffFemales(:,SDS.females.am1) = repmat(cast(normrnd(P.new_mu_individ_age,SDS.sigma_individ_age,1,sumFemales.am1), SDS.float),SDS.number_of_males,1);

        % update formation hazards
        P0.male = SDS.males.am1;
        P0.female = SDS.females.am1;

        [SDS, P0] = P.updateFormation(SDS, P0); % uses P0.male and P0.female  
        
    end


%% fire2
% changing standard deviation of preferred age difference for a certain fraction of the population
    function [SDS,P0] = eventAgeMixingChange2_fire(SDS, P0)    
		pop = sum(P0.aliveMales) + sum(P0.aliveFemales); %only in the case where nobody is born
        percentage_changed = (P.start_agemix{2,2}/pop);    
        if percentage_changed<= 0 %this Age Mixing intervention is not being implemented
            return
        end
        
        if ~isfield(SDS.males, 'am1')
            SDS.males.am1 = rand(1,SDS.number_of_males)<percentage_changed;  % for these males, the age mixing parameters change
            SDS.females.am1 = rand(1,SDS.number_of_females)<percentage_changed; % for these females, the age mixing parameters change
        end
        SDS.males.am2 = SDS.males.am1;
        SDS.females.am2 = SDS.females.am1;
        sumMales.am2 = sum(SDS.males.am2);
        sumFemales.am2 = sum(SDS.females.am2);

        P0.pref_age_diffMales(SDS.males.am2,:) = repmat(cast(normrnd(P.new_mu_individ_age,P.new_sigma_individ_age,sumMales.am2,1), SDS.float),1,SDS.number_of_females);
        P0.pref_age_diffFemales(:,SDS.females.am2) = repmat(cast(normrnd(P.new_mu_individ_age,P.new_sigma_individ_age,1,sumFemales.am2), SDS.float),SDS.number_of_males,1);

        % update formation hazards
        P0.male = SDS.males.am2;
        P0.female = SDS.females.am2;

        [SDS, P0] = P.updateFormation(SDS, P0); % uses P0.male and P0.female
        
    end


%% fire3
% changing mean of the age difference factor for a certain fraction of the population
    function [SDS,P0] = eventAgeMixingChange3_fire(SDS, P0)    
		pop = sum(P0.aliveMales) + sum(P0.aliveFemales); %only in the case where nobody is born
        percentage_changed = (P.start_agemix{3,2}/pop);    
        if percentage_changed<= 0 %this Age Mixing intervention is not being implemented
            return
        end
        
        if ~isfield(SDS.males, 'am1')
            SDS.males.am1 = rand(1,SDS.number_of_males)<percentage_changed;  % for these males, the age mixing parameters change
            SDS.females.am1 = rand(1,SDS.number_of_females)<percentage_changed; % for these females, the age mixing parameters change
        end
        SDS.males.am3 = SDS.males.am1;
        SDS.females.am3 = SDS.females.am1;
        sumMales.am3 = sum(SDS.males.am3);
        sumFemales.am3 = sum(SDS.females.am3);
        
  
        ageDiffFactorFcn = P.fire3_ageDiffFactorFcn;
        mean_age_diff_factor = P.fire3_mean_age_diff_factor;
        range_age_diff_factor = SDS.range_age_diff_factor;
        
        SDS.males.ageDiffFactor(SDS.males.am3) = cast(ones(1, sumMales.am3, SDS.float).*mean_age_diff_factor + (rand(1,sumMales.am3)-0.5)*range_age_diff_factor, SDS.float); % here the ageDiffFactor gets updated
        SDS.females.ageDiffFactor(SDS.females.am3) = cast(ones(1, sumFemales.am3, SDS.float).*mean_age_diff_factor + (rand(1,sumFemales.am3)-0.5)*range_age_diff_factor, SDS.float); % here the ageDiffFactor gets updated
        
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
        
        
        % update formation hazards
        P0.male = SDS.males.am3;
        P0.female = SDS.females.am3;

        [SDS, P0] = P.updateFormation(SDS, P0); % uses P0.male and P0.female
    end


%% fire4
% changing range around the mean age difference factor for a certain fraction of the population
    function [SDS,P0] = eventAgeMixingChange4_fire(SDS, P0)    
		pop = sum(P0.aliveMales) + sum(P0.aliveFemales); %only in the case where nobody is born
        percentage_changed = (P.start_agemix{4,2}/pop);    
        if percentage_changed<= 0 %this Age Mixing intervention is not being implemented
            return
        end
        
        if ~isfield(SDS.males, 'am1')
            SDS.males.am1 = rand(1,SDS.number_of_males)<percentage_changed;  % for these males, the age mixing parameters change
            SDS.females.am1 = rand(1,SDS.number_of_females)<percentage_changed; % for these females, the age mixing parameters change
        end
        SDS.males.am4 = SDS.males.am1;
        SDS.females.am4 = SDS.females.am1;
        sumMales.am4 = sum(SDS.males.am4);
        sumFemales.am4 = sum(SDS.females.am4);
        
  
        ageDiffFactorFcn = P.fire3_ageDiffFactorFcn;
        mean_age_diff_factor = P.fire3_mean_age_diff_factor;
        range_age_diff_factor = P.fire4_range_age_diff_factor;
        
        SDS.males.ageDiffFactor(SDS.males.am4) = cast(ones(1, sumMales.am4, SDS.float).*mean_age_diff_factor + (rand(1,sumMales.am4)-0.5)*range_age_diff_factor, SDS.float); % here the ageDiffFactor gets updated
        SDS.females.ageDiffFactor(SDS.females.am4) = cast(ones(1, sumFemales.am4, SDS.float).*mean_age_diff_factor + (rand(1,sumFemales.am4)-0.5)*range_age_diff_factor, SDS.float); % here the ageDiffFactor gets updated
        
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
        
        
        % update formation hazards
        P0.male = SDS.males.am4;
        P0.female = SDS.females.am4;

        [SDS, P0] = P.updateFormation(SDS, P0); % uses P0.male and P0.female
    end


%% fire5
% changing slope of the age mixing regression line for a certain fraction of the population
    function [SDS,P0] = eventAgeMixingChange5_fire(SDS, P0)    
		pop = sum(P0.aliveMales) + sum(P0.aliveFemales); %only in the case where nobody is born
        percentage_changed = (P.start_agemix{5,2}/pop);    
        if percentage_changed<= 0 %this Age Mixing intervention is not being implemented
            return
        end
        
        if ~isfield(SDS.males, 'am1')
            SDS.males.am1 = rand(1,SDS.number_of_males)<percentage_changed;  % for these males, the age mixing parameters change
            SDS.females.am1 = rand(1,SDS.number_of_females)<percentage_changed; % for these females, the age mixing parameters change
        end
        SDS.males.am5 = SDS.males.am1;
        SDS.females.am5 = SDS.females.am1;
        sumMales.am5 = sum(SDS.males.am5);
        sumFemales.am5 = sum(SDS.females.am5);
        
        meanAgeGrowthFactorFcn = P.fire5_meanAgeGrowthFactorFcn;
        mu_mean_age_growth = P.fire5_mu_mean_age_growth;
        sigma_mean_age_growth = P.fire5_sigma_mean_age_growth;     
        
        SDS.males.meanAgeGrowthFactor(SDS.males.am5) = cast(normrnd(mu_mean_age_growth,sigma_mean_age_growth,sumMales.am5,1), SDS.float);
        SDS.females.meanAgeGrowthFactor(SDS.females.am5) = cast(normrnd(mu_mean_age_growth,sigma_mean_age_growth,sumFemales.am5,1), SDS.float);
        
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
        

        % update formation hazards
        P0.male = SDS.males.am5;
        P0.female = SDS.females.am5;

        [SDS, P0] = P.updateFormation(SDS, P0); % uses P0.male and P0.female
    end
        
     
%% fire6
% changing dispersion parameter of the age mixing pattern for a certain fraction of the population
    function [SDS,P0] = eventAgeMixingChange6_fire(SDS, P0)    
		pop = sum(P0.aliveMales) + sum(P0.aliveFemales); %only in the case where nobody is born
        percentage_changed = (P.start_agemix{6,2}/pop);    
        if percentage_changed<= 0 %this Age Mixing intervention is not being implemented
            return
        end
        
        if ~isfield(SDS.males, 'am1')
            SDS.males.am1 = rand(1,SDS.number_of_males)<percentage_changed;  % for these males, the age mixing parameters change
            SDS.females.am1 = rand(1,SDS.number_of_females)<percentage_changed; % for these females, the age mixing parameters change
        end
        SDS.males.am6 = SDS.males.am1;
        SDS.females.am6 = SDS.females.am1;
        sumMales.am6 = sum(SDS.males.am6);
        sumFemales.am6 = sum(SDS.females.am6);
        
        meanAgeDispersionGrowthFactorFcn = P.fire6_meanAgeDispersionGrowthFactorFcn;
        mu_mean_age_dispersion_growth = P.fire6_mu_mean_age_dispersion_growth;
        sigma_mean_age_dispersion_growth = P.fire6_sigma_mean_age_dispersion_growth;     
        
        SDS.males.meanAgeDispersionGrowthFactor(SDS.males.am6) = cast(normrnd(mu_mean_age_dispersion_growth,sigma_mean_age_dispersion_growth,sumMales.am6,1), SDS.float);
        SDS.females.meanAgeDispersionGrowthFactor(SDS.females.am6) = cast(normrnd(mu_mean_age_dispersion_growth,sigma_mean_age_dispersion_growth,sumFemales.am6,1), SDS.float);
        
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
        

        % update formation hazards
        P0.male = SDS.males.am6;
        P0.female = SDS.females.am6;

        [SDS, P0] = P.updateFormation(SDS, P0); % uses P0.male and P0.female
    end
        

end



%% properties
function [props,msg] = eventAgeMixingChange_properties
msg = '';
props.start_agemix = {'01-Jan-2080'     0;  %Start date of age mixing intervention 1
				  	  '01-Jan-2080'   	0;  %2
				 	  '01-Jan-2080' 	0;  %3
					  '01-Jan-2080'		0;  %4
					  '01-Jan-2080'		0;  %5
					  '01-Jan-2080'		0}; %6
                  
props.new_mu_individ_age = 3; % the new mean preferred age difference  
props.new_sigma_individ_age = 1; % the new standard deviation around the new mean.
props.ageDiffFactorFcn = 'mean'; % default function to compute age difference factor for couples
props.fire3_ageDiffFactorFcn = 'mean'; % default function to compute age difference factor for couples
props.fire3_mean_age_diff_factor = -0.5; % the new mean age difference factor
props.fire4_range_age_diff_factor = 0.1; % the new range around the mean age difference factor
props.meanAgeGrowthFactorFcn = 'mean'; % default function to compute mean age growth factor for couples
props.fire5_meanAgeGrowthFactorFcn = 'min';
props.fire5_mu_mean_age_growth = 0.4;
props.fire5_sigma_mean_age_growth = 0;
props.meanAgeDispersionGrowthFactorFcn = 'min';
props.fire6_meanAgeDispersionGrowthFactorFcn = 'min';
props.fire6_mu_mean_age_dispersion_growth = 0;
props.fire6_sigma_mean_age_dispersion_growth = 0;

end


%% name
function name = eventAgeMixingChange_name

name = 'AgeMixingChange';
end