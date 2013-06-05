addpath( [fileparts(fileparts(which(mfilename))) '/lib'] );

%%%%%%%%%%%%%%%%%%%
%% POPULATION
%%%%%%%%%%%%%%%%%%%

% 10 HIV positive men aged 25-35 are introduced after 10 years of
% simulation time

[SDS,msg] = modelHIV('new');
SDS.number_of_males = 100; %set parameters of the model manually
SDS.number_of_females = SDS.number_of_males;
SDS.initial_number_of_males = SDS.number_of_males/3; %/4;%50;%
SDS.initial_number_of_females = SDS.number_of_females/3; %/4;%50;%
SDS.number_of_relations = SDS.number_of_males^2;
SDS.start_date = '01-Jan-1970'; % HIV introduced in 1980; age mixing altered in 2010;
SDS.end_date = '01-Jan-1980';   % HIV epidemic observed for 50 years; last 20 years after age mixing alteration

% disable some events
SDS.events.ARV_treatment.enable = 0;
SDS.events.HIV_test.enable = 0;
SDS.events.debut.enable = 0;

% mortality and age mixing interventions are enabled
SDS.events.non_AIDS_mortality.enable = 1;
SDS.events.AIDS_mortality.enable = 1;
SDS.interventions.AgeMixingChange.enable = 0;


% Conception: women between 15 and 50 can give birth. They have 35 years to
% produce 2 children, hence, conception rate would be 2/35 if women were 
% continuously in 1 relationship during these 35 years
SDS.events.conception.enable = 1;
SDS.events.conception.fertility_rate_parameter = 0.11;
SDS.events.birth.enable = 1;
SDS.events.ANC.enable = 1;

% Relationship dissolution
SDS.events.dissolution.baseline_factor = log(0.5); % relationships last for an average of 2 years

SDS.events.formation.baseline_factor = 1; % relationships last for an average of 2 years
SDS.events.formation.age_limit = 15;

% Age mixing parameters to begin with
SDS.mu_individ_age = 1;       % population average of preferred age difference
SDS.sigma_individ_age = 0;    % variability around this population average;

SDS.mean_age_diff_factor = -0.5; %-0.25; % -0.15; % the average age difference factor is -1;
SDS.range_age_diff_factor = 0; % it ranges between mean_age_diff_factor +/- (1/2) range_age_diff_factor; 

SDS.mu_mean_age_growth = 0; %0.15; % the population average of the mean age growth factor;
SDS.sigma_mean_age_growth = 0; % variability around this population average;
SDS.events.formation.dispersion_base = 1; % 1 means no dispersion effect
SDS.mu_mean_age_dispersion_growth = 0; %0.04; %0.01; % >0 means dispersion grows with a candidate couple's mean age
SDS.sigma_mean_age_dispersion_growth = 0; % variability around this population average

% New age mixing parameters under am1
SDS.interventions.AgeMixingChange.new_mu_individ_age = 0;
% New age mixing parameters under am2
SDS.interventions.AgeMixingChange.new_sigma_individ_age = 0;
% New age mixing parameters under am3
SDS.interventions.AgeMixingChange.fire3_mean_age_diff_factor = 0;
% New age mixing parameters under am4
SDS.interventions.AgeMixingChange.fire4_range_age_diff_factor = 0;
% New age mixing parameters under am5
SDS.interventions.AgeMixingChange.fire5_mu_mean_age_growth = 0;
SDS.interventions.AgeMixingChange.fire5_sigma_mean_age_growth = 0;
% New age mixing parameters under am6
SDS.interventions.AgeMixingChange.fire6_mu_mean_age_dispersion_growth = 0;
SDS.interventions.AgeMixingChange.fire6_sigma_mean_age_dispersion_growth = 0;

%actually run the model
[SDSnarrowagemixing, ~] = spRun('start',SDS);

spGraphs('formationScatter',SDSnarrowagemixing)


% 
% 
% spGraphs('Demographics',SDSnarrowagemixing)
spGraphs('formedRelations',SDSnarrowagemixing)
% spGraphs('prevalenceIncidence',SDSnarrowagemixing)
% 
% 
% % spGraphs('concurrencyPrevalence',SDS2)
% % 
% % 
% % 
% % 
% spGraphs('demoAndTrans',SDSnarrowagemixing) 
% 
% [ok,msg] = spTools('exportCSV', SDSnarrowagemixing);


% prevalence = zeros(1,20);
% for i = 1:20
% 	HIVpos = length([ find(SDS2.males.HIV_positive<i)  find(SDS2.females.HIV_positive<i)]); %infected before this round
% 	HIVmaledeath = find(SDS2.males.deceased.*SDS2.males.AIDS_death>0); %times of HIV deaths
% 	HIVfemaledeaths = find(SDS2.females.deceased.*SDS2.females.AIDS_death>0);
% 	HIVdeath = length([find(HIVmaledeath<i)  find(HIVfemaledeaths<i)]);%HIV death this round
% 	prevalence(i) = HIVpos - HIVdeath;
% end