%%
run = 1;
n = 500;
rng((run + 17)*2213)
shape= 4;scale = 72;
SDS0 = modelHIV('new');
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2015';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.ARV_treatment.enable = 0;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.06*n);
SDS0.formation.baseline_factor = log(45/n);
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale-15, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale-15, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0 = spRun('start',SDS0);
exportCSV(SDS0,'output',run,'basic')
%% age mixing
SDS0 = modelHIV('new');
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2013';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.ARV_treatment.enable = 0;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.06*n);
SDS0.formation.baseline_factor = log(45/n);
SDS0.formation.age_difference_factor = 0;
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale-15, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale-15, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0 = spRun('start',SDS0);
exportCSV(SDS0,'output',run,'age')

% current relations factor
%
run = 1;
n = 500;
rng((run + 17)*2213)
shape= 4;scale = 72;
SDS0 = modelHIV('new');
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2015';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.ARV_treatment.enable = 0;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.06*n);
SDS0.formation.baseline_factor = log(45/n);
SDS0.formation.current_relations_factor = 0;
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale-15, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale-15, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0 = spRun('start',SDS0);
exportCSV(SDS0,'output',run,'concurrent')
% art
%
run = 1;
n = 500;
rng((run + 17)*2213)
shape= 4;scale = 72;
SDS0 = modelHIV('new');
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2015';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.2;
SDS0.number_of_females = n*1.2;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
SDS0.ARV_treatment.enable = 1;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.06*n);
SDS0.formation.baseline_factor = log(45/n);
SDS0.non_AIDS_mortality.Weibull_shape_parameter = shape;
SDS0.non_AIDS_mortality.Weibull_scale_parameter = scale;
maleRange = 1:SDS0.initial_number_of_males;
femaleRange = 1:SDS0.initial_number_of_females;
ageMale = empiricalage(SDS0.initial_number_of_males, scale-15, shape);
SDS0.males.born(maleRange) = cast(-ageMale, SDS0.float);    % -years old
ageFemale = empiricalage(SDS0.initial_number_of_females, scale-15, shape);
SDS0.females.born(femaleRange) = cast(-ageFemale, SDS0.float);% -years old
adjust = round(SDS0.initial_number_of_males*0.03);
SDS0.males.born((SDS0.initial_number_of_males+1):(SDS0.initial_number_of_males+adjust)) = -rand(1,adjust)*3;
SDS0.females.born((SDS0.initial_number_of_females+1):(SDS0.initial_number_of_females+adjust)) = -rand(1,adjust)*3;
SDS0 = spRun('start',SDS0);
exportCSV(SDS0,'output',run,'art')