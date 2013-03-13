%% common settings 
run = 1;
n = 500;
rng((run + 17)*2213)

% part 1 : variety in demographics
initial = modelHIV('new');
scales= [63 72 80];
shapes = [3.8 4 4.1];

%% part 2: comparisons
% transmission rate

run = 101;
n = 500;
initial = modelHIV('new');
for r = [0.5 1 2]
SDS0 = initial;
shape = 4;
scale = 72;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2033';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.6;
SDS0.number_of_females = n*1.6;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.08*n);
SDS0.HIV_transmission.infectiousness(2,3) = {3.2*r};
SDS0.HIV_transmission.infectiousness(3,3) = {0.35*r};
SDS0.HIV_transmission.infectiousness(4,3) = {1.53*r};
SDS0.formation.baseline_factor = log(50/n);
SDS0.formation.current_relations_factor = log(0.2);
SDS0.formation.preferred_age_difference = 4;
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.02);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0 = spRun('start',SDS0);
scen = sprintf('rate_%s',num2str(r));
SDS0 = rmfield(SDS0,'P0');
exportCSV(SDS0,'output',run,scen)
run = run+1;
end
%%
run = 201;
n = 200;
% part 2: comparisons
% age mixing : preferred age gap
initial = modelHIV('new');
for preferage = [0 4]
shape = 4;
scale = 72;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '01-Jan-2023';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.4;
SDS0.number_of_females = n*1.4;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.05*n);
SDS0.formation.baseline_factor = log(50/n);
SDS0.formation.preferred_age_difference = preferage;
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
%%
% current relations factor
%
run = 301;
for concur = [0.1,0.2,0.3,0.4]
shape= 4;scale = 72;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2033';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.6;
SDS0.number_of_females = n*1.6;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
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
save(scenario,'SDS0')
exportCSV(SDS0,'output',run,scenario)
run = run+1;
end
%%
% art
%
run = 401;
n = 500;
shape= 4;scale = 72;
SDS0 = modelHIV('new');
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2015';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.6;
SDS0.number_of_females = n*1.6;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.ARV_treatment.enable = 1;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.05*n);
SDS0.formation.baseline_factor = log(50/n);
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
SDS0 = spRun('start',SDS0);
exportCSV(SDS0,'output',run,'art')