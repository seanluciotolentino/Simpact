function calibrate_simpact(n,run)
%run = i1 ~ i2; n = number of initial males;

if ~isdeployed

  path(path,'lib')
  path(path,'MATLAB')
  path(path,'fei/pre_post_process')
%  run = str2num(run); 
%   i1 = str2num(i1);
%   i2 = str2num(i2);
%   n  = str2num(n);
end

mkdir('calibration');

%%
rng((run + 17)*2213)
initial = modelHIV('new');


%%
% south africa
shape = 4.2;
scale = 70;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '01-Jan-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.6;
SDS0.number_of_females = n*1.6;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.01;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.05*n);
SDS0.formation.baseline_factor = log(50/n);
SDS0.formation.preferred_age_difference = 4;
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
SDS0.formation.current_relations_factor = log(0.1);
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = MonteCarloAge(SDS0.initial_number_of_males, 'man', 'sa_2003.csv');
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = MonteCarloAge(SDS0.initial_number_of_females, 'woman', 'sa_2003.csv');
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.01);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0 = spRun('start',SDS0);
file = sprintf('calibration/%s.mat', run, 'sa');
save(file,'-struct','SDS0');
exportCSV(SDS,'calibration',run,'sa');

%%
% united states
shape = 4.4;
scale = 80;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '01-Jan-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.6;
SDS0.number_of_females = n*1.6;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.01;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.005*n);
SDS0.formation.baseline_factor = log(50/n);
SDS0.formation.preferred_age_difference = 4;
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
SDS0.formation.current_relations_factor = log(0.05);
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = MonteCarloAge(SDS0.initial_number_of_males, 'man', 'usa_2003.csv');
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = MonteCarloAge(SDS0.initial_number_of_females, 'woman', 'usa_2003.csv');
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.01);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0.fertility_rate_from_data_file = false;
SDS0.constant_fertility_parameter = 1.9;
SDS0.HIV_test.CD4_baseline_for_ARV{2,4} = 60;
SDS0.HIV_test.CD4_baseline_for_ARV{2,6} = 80;
SDS0.MTCT_transmission.probability_of_MTCT{2,2}=0.05;
SDS0.MTCT_transmission.probability_of_MTCT{2,3}=0.1;
SDS0 = spRun('start',SDS0);
file = sprintf('calibration/%s.mat', 'us');
save(file,'-struct','SDS0');
exportCSV(SDS,'calibration',run,'us');
    
end