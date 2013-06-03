function calibration

if ~isdir('calibration')
     mkdir('calibration');
end
%%
n = 500;
%%
for run = 0:3
%%
rng((run + 17)*2213)
initial = modelHIV('new');
initial.formation.fix_turn_over_rate = 0;
initial.formation.turn_over_rate = 1;
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
SDS0.HIV_introduction.number_of_introduced_HIV=20;
SDS0.ARV_treatment.ARV_program_start_time = 15;
SDS0.HIV_transmission.sexual_behaviour_parameters{8} = log(1);
SDS0.HIV_transmission.sexual_behaviour_parameters{1} = 3;
SDS0.formation.baseline_factor = log(50-run/n);
SDS0.formation.preferred_age_difference = 4;
SDS0.non_AIDS_mortality.mortality_reference_year = 2002;
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
SDS0.formation.current_relations_factor = log(0.2);
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
SDS = spRun('start',SDS0);
%
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