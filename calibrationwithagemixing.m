function calibrationwithagemixing

if ~isdir('calibration')
     mkdir('calibration');
end
%%
n = 100; % 200;
%%
runs = 1;%81; % This is the number of scenarios (3^4)
reps = 1; % This is the number of times each scenario is repeated

repvector = repmat(1:reps, 1, runs);
%%
% Behaviour exploration: 1. Concurrency level, 2. mean age difference effect
% (penalty), 3. mean age dispersion growth (funnel), 4. mean age growth
% (increasing age differences)

% We are running 10*3^4 (=810) simulations

% 1. Concurrency level (current_relations_factor)
concurrlevel = {'high', 'medium', 'low'
                log(2), 0, log(0.1)
                };
concurrlevel = repmat(concurrlevel, 27,1);
concurrlevel = reshape(concurrlevel,2,81);
% concurrlevel = {'high', 'medium', 'low', 'high', 'medium', 'low', 'high', 'medium', 'low'
%                 log(2), log(2), log(2), log(2), log(2), log(2), log(2), log(2), log(2)
% %                log(2), 0, log(0.1)
%                 };


% 2. mean age difference effect (penalty)
meanagediffeffect = 0.2*log(0.3:0.2:0.7);
meanagediffeffect = repmat(meanagediffeffect,9,3);
meanagediffeffect = reshape(meanagediffeffect,1,81);

% 3. mean age dispersion growth (funnel)
mumeanagedispersiongrowth = 0:0.02:0.04;
mumeanagedispersiongrowth = repmat(mumeanagedispersiongrowth,3,9);
mumeanagedispersiongrowth = reshape(mumeanagedispersiongrowth,1,81);

% 4. mean age growth (increasing preferred age difference)
mumeanagegrowth = {'none', 'little', 'more'
                    0, 0.2, 0.4
                    };

mumeanagegrowth = repmat(mumeanagegrowth,1,27);
                
current_relations_factor = zeros(1,runs);
mean_age_diff_factor = zeros(1,runs);
mu_mean_age_growth = zeros(1,runs);
mu_mean_age_dispersion_growth = zeros(1,runs);

%%
for run = 0:runs*reps - 1; 
%%
rng(run)%rng((run + 17)*2213)

rep = repvector(run+1);
scenario=ceil((run+1)/reps);

current_relations_factor(run+1) = concurrlevel{2, ceil((run+1)/reps)};
mean_age_diff_factor(run+1) = meanagediffeffect(ceil((run+1)/reps));
mu_mean_age_growth(run+1) = mumeanagegrowth{2, ceil((run+1)/reps)};
mu_mean_age_dispersion_growth(run+1) = mumeanagedispersiongrowth(ceil((run+1)/reps));

initial = modelHIV('new');

shape = 4.2;
scale = 70;
%shape = 4.3;
%scale = 75;
SDS0 = initial;
SDS0.start_date = '01-Jan-0000'; % This is when relationship dynamics start
SDS0.end_date = '01-Jan-0040';   % Run for 50 years after HIV introduction
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*3;
SDS0.number_of_females = n*3;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0; %0.015;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.events.HIV_introduction.number_of_introduced_HIV=round(2*n*0.01); % 1% of population is introduced as HIV+
SDS0.events.HIV_introduction.period_of_introduced_HIV{2,1}=5; % HIV is introduced after 5 years
SDS0.events.HIV_introduction.period_of_introduced_HIV{2,2}=5; % HIV is introduced after 5 years
SDS0.events.ARV_treatment.enable = 0;
SDS0.events.male_circumcision.enable = 0;
SDS0.events.birth.enable = 1;
SDS0.events.conception.enable = 1;
SDS0.events.conception.fertility_rate_from_data_file = 0;
SDS0.events.conception.constant_fertility_parameter = 0.5;


SDS0.events.ARV_treatment.ARV_program_start_time = 99999;  % These simulations don't involve ART
SDS0.events.HIV_transmission.sexual_behaviour_parameters{2,8} = log(1); % Time does not affect sex frequency
SDS0.events.HIV_transmission.sexual_behaviour_parameters{2,1} = 3; % sex frequency is 3/week for all relationships at all times
SDS0.events.formation.baseline_factor = log(1/n);
SDS0.events.formation.preferred_age_difference = 4;
SDS0.events.formation.current_relations_factor = current_relations_factor(run+1);

SDS0.events.formation.fix_turn_over_rate = 1;   
SDS0.events.formation.turn_over_rate = 0.5; % Keeping partner turnover rate fixed at 0.5 partner per person per year

SDS0.events.non_AIDS_mortality.mortality_reference_year = 2002;
SDS0.events.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.events.non_AIDS_mortality.Weibull_scale_parameter = scale;
SDS0.events.formation.current_relations_factor = log(0.5);

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
SDS0.mu_individ_age = 0;       % population average of preferred age difference
SDS0.sigma_individ_age = 0;    % variability around this population average;

SDS0.mean_age_diff_factor = mean_age_diff_factor(run+1); %-0.5; %-0.25; % -0.15; % the average age difference factor is -1;
SDS0.range_age_diff_factor = 0; % it ranges between mean_age_diff_factor +/- (1/2) range_age_diff_factor; 

SDS0.mu_mean_age_growth = mu_mean_age_growth(run+1); %0; %0.15; % the population average of the mean age growth factor;
SDS0.sigma_mean_age_growth = 0; % variability around this population average;
SDS0.formation.dispersion_base = 1; % 1 means no dispersion effect
SDS0.mu_mean_age_dispersion_growth = mu_mean_age_dispersion_growth(run+1);%0; %0.04; %0.01; % >0 means dispersion grows with a candidate couple's mean age
SDS0.sigma_mean_age_dispersion_growth = 0; % variability around this population average

% % New age mixing parameters under am1
% SDS0.interventions.AgeMixingChange.new_mu_individ_age = 0;
% % New age mixing parameters under am2
% SDS0.interventions.AgeMixingChange.new_sigma_individ_age = 0;
% % New age mixing parameters under am3
% SDS0.interventions.AgeMixingChange.fire3_mean_age_diff_factor = 0;
% % New age mixing parameters under am4
% SDS0.interventions.AgeMixingChange.fire4_range_age_diff_factor = 0;
% % New age mixing parameters under am5
% SDS0.interventions.AgeMixingChange.fire5_mu_mean_age_growth = 0;
% SDS0.interventions.AgeMixingChange.fire5_sigma_mean_age_growth = 0;
% % New age mixing parameters under am6
% SDS0.interventions.AgeMixingChange.fire6_mu_mean_age_dispersion_growth = 0;
% SDS0.interventions.AgeMixingChange.fire6_sigma_mean_age_dispersion_growth = 0;

% Running the simulation
SDS = spRun('start',SDS0);

filename = sprintf('SDS%d04July.mat',run);

save(filename, 'SDS')

% Plotting the age mixing scatter
spGraphs('formationScatter',SDS)

% Plotting the concurrency time trend
%spGraphs('concurrencyPrevalence',SDS)

%spGraphs('prevalenceIncidence', SDS)
spGraphs('formedRelations',SDS)

spGraphs('Demographics',SDS)


% Exporting the simulation output
exportCSV(SDS,'calibration',100*scenario+rep,'4July');
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





