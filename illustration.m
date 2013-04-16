%% common settings 
run =1;
mkdir('output')
n = 500;
rng((run + 17)*2213)

initial = modelHIV('new');
% initial.HIV_test.enable = false;
% initial.antenatal_care.enable = false;
%%
% part 2: comparisons
% age mixing : preferred age gap
run = 201;
for preferage = [1 2]
shape = 4.2;
scale = 72;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '01-Jan-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.6;
SDS0.number_of_females = n*1.6;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.02;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.08*n);
SDS0.formation.baseline_factor = log(50/n);

if preferage ==1
    SDS0.formation.age_difference_factor = -log(5)/5;
else
    SDS0.formation.age_difference_factor = 0;
end

SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
SDS0.formation.current_relations_factor = log(0.2);
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = MonteCarloAge(SDS0.initial_number_of_males, 'man', 'sa_2003.csv');
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = MonteCarloAge(SDS0.initial_number_of_females, 'woman', 'sa_2003.csv');
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS = spRun('start',SDS0);
SDS = rmfield(SDS, 'P0');
scen = sprintf('age_%s',num2str(preferage));
exportCSV(SDS,'output',run,scen)
run = run+1;
end
%%
% age mixing : fix_turn_over_rate = false;
run = 301;
for preferage = [1 2]
shape = 4;
scale = 72;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '01-Jan-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.02;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.08*n);
SDS0.formation.baseline_factor = log(50/n);
SDS0.fix_turn_over_rate = false;

if preferage ==1
    SDS0.formation.age_difference_factor = -log(5)/5;
else
    SDS0.formation.age_difference_factor = 0;
end

SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
SDS0.formation.current_relations_factor = log(0.2);
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale-10, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale-10, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS = spRun('start',SDS0);
SDS = rmfield(SDS, 'P0');
scen = sprintf('age_%s',num2str(preferage));
exportCSV(SDS,'output',run,scen)
run = run+1;
end
%
%% current relations factor
run = 401;
for concur = [0.1,0.4]
shape= 4;scale = 72;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.02;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.08*n);
SDS0.formation.baseline_factor = log(50/n);
SDS0.formation.preferred_age_difference = 4;
SDS0.formation.current_relations_factor = log(concur);
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0.formation.current_relations_factor = log(concur);
SDS0 = spRun('start',SDS0);
scenario = sprintf('concurrent_%s',num2str(concur));
SDS0 = rmfield(SDS0,'P0');
save(scenario,'SDS0')
exportCSV(SDS0,'output',run,scenario)
run = run+1;
end
% current relations factor 
%fix_turn_over_rate = false;
run = 501;
for concur = [0.1,0.4]
shape= 4;scale = 72;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.02;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.08*n);
SDS0.formation.baseline_factor = log(50/n);
SDS0.formation.preferred_age_difference = 4;
SDS0.formation.current_relations_factor = log(concur);
SDS0.fix_turn_over_rate = false;
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0.formation.current_relations_factor = log(concur);
SDS0 = spRun('start',SDS0);
scenario = sprintf('concurrent_%s',num2str(concur));
SDS0 = rmfield(SDS0,'P0');
save(scenario,'SDS0')
exportCSV(SDS0,'output',run,scenario)
run = run+1;
end

%% degree mixing
%fix_turn_over_rate = false;
run = 601;
for current_relations_difference_factor = [0.5,2]
shape= 4;scale = 72;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.02;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.08*n);
SDS0.formation.baseline_factor = log(50/n);
SDS0.formation.preferred_age_difference = 4;
SDS0.formation.current_relations_difference_factor = log(current_relations_difference_factor);

SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0.formation.current_relations_factor = log(concur);
SDS0 = spRun('start',SDS0);
scenario = sprintf('dgmixing_%s',num2str(current_relations_difference_factor));
SDS0 = rmfield(SDS0,'P0');
save(scenario,'SDS0')
exportCSV(SDS0,'output',run,scenario)
run = run+1;
end

%% degree mixing
%fix_turn_over_rate = false;
run = 701;
for current_relations_difference_factor = [0.5,2]
shape= 4;scale = 72;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.02;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.08*n);
SDS0.formation.baseline_factor = log(50/n);
SDS0.formation.preferred_age_difference = 4;
SDS0.formation.current_relations_difference_factor = log(current_relations_difference_factor);
SDS0.fix_turn_over_rate = false;
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0.formation.current_relations_factor = log(concur);
SDS0 = spRun('start',SDS0);
scenario = sprintf('dgmixing_%s',num2str(current_relations_difference_factor));
SDS0 = rmfield(SDS0,'P0');
save(scenario,'SDS0')
exportCSV(SDS0,'output',run,scenario)
run = run+1;
end
%%
ages = [];
i = 1;
for shape = [4,4.2,4.4]
    for scale = [60, 65, 70, 75]
        ages(i,1) = scale;
        ages(i,2) = shape;
        ages(i,3:1002) = empiricalage(1000,scale,shape);
        i = i+1;
    end
end
