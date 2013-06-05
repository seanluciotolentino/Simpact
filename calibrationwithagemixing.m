function calibrationwithagemixing

if ~isdir('calibration')
     mkdir('calibration');
end
%%
n = 10;
%%
for run = 0:0 %3
%%
rng((run + 17)*2213)
initial = modelHIV('new');
initial.events.formation.fix_turn_over_rate = 0;
initial.events.formation.turn_over_rate = 1;
shape = 4.2;
scale = 70;
%shape = 4.3;
%scale = 75;
SDS0 = initial;
SDS0.start_date = '01-Jan-1986';
SDS0.end_date = '01-Jan-2012';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*2;
SDS0.number_of_females = n*2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.015;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.events.HIV_introduction.number_of_introduced_HIV=5;
SDS0.events.ARV_treatment.ARV_program_start_time = 15;
SDS0.events.HIV_transmission.sexual_behaviour_parameters{8} = log(1);
SDS0.events.HIV_transmission.sexual_behaviour_parameters{1} = 3;
SDS0.events.formation.baseline_factor = log(50-run/n);
SDS0.events.formation.preferred_age_difference = 4;
SDS0.events.non_AIDS_mortality.mortality_reference_year = 2002;
SDS0.events.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.events.non_AIDS_mortality.Weibull_scale_parameter = scale;
SDS0.events.formation.current_relations_factor = log(0.2);

maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = MonteCarloAgeSA(SDS0.initial_number_of_males, 'man',SDS0.age_file);%, '/Simpact/empirical_data/sa_2003.csv');
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = MonteCarloAgeSA(SDS0.initial_number_of_females, 'woman',SDS0.age_file);%, '/Simpact/empirical_data/sa_2003.csv');
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.004);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*2;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
%


% Age mixing parameters to begin with
SDS0.mu_individ_age = 1;       % population average of preferred age difference
SDS0.sigma_individ_age = 0;    % variability around this population average;

SDS0.mean_age_diff_factor = -0.5; %-0.25; % -0.15; % the average age difference factor is -1;
SDS0.range_age_diff_factor = 0; % it ranges between mean_age_diff_factor +/- (1/2) range_age_diff_factor; 

SDS0.mu_mean_age_growth = 0; %0.15; % the population average of the mean age growth factor;
SDS0.sigma_mean_age_growth = 0; % variability around this population average;
SDS0.events.formation.dispersion_base = 1; % 1 means no dispersion effect
SDS0.mu_mean_age_dispersion_growth = 0; %0.04; %0.01; % >0 means dispersion grows with a candidate couple's mean age
SDS0.sigma_mean_age_dispersion_growth = 0; % variability around this population average

% New age mixing parameters under am1
SDS0.interventions.AgeMixingChange.new_mu_individ_age = 0;
% New age mixing parameters under am2
SDS0.interventions.AgeMixingChange.new_sigma_individ_age = 0;
% New age mixing parameters under am3
SDS0.interventions.AgeMixingChange.fire3_mean_age_diff_factor = 0;
% New age mixing parameters under am4
SDS0.interventions.AgeMixingChange.fire4_range_age_diff_factor = 0;
% New age mixing parameters under am5
SDS0.interventions.AgeMixingChange.fire5_mu_mean_age_growth = 0;
SDS0.interventions.AgeMixingChange.fire5_sigma_mean_age_growth = 0;
% New age mixing parameters under am6
SDS0.interventions.AgeMixingChange.fire6_mu_mean_age_dispersion_growth = 0;
SDS0.interventions.AgeMixingChange.fire6_sigma_mean_age_dispersion_growth = 0;

% Running the simulation
SDS = spRun('start',SDS0);

% Plotting the age mixing scatter
spGraphs('formationScatter',SDS)


% Exporting the simulation output
exportCSV(SDS,'calibration',run,'sa');
end
%%
% SDS0.formation.current_relations_factor = log(0.5);
% SDS = spRun('start',SDS0);
% exportCSV(SDS,'illustration',run,'concurrent');
% 
% SDS0.formation.current_relations_factor = log(0.1);
% SDS0.formation.age_difference_factor =0;
% SDS = spRun('start',SDS0);
% exportCSV(SDS,'illustration',run,'assort');

end