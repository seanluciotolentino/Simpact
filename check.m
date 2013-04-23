sds = load('sds_0000_SQ_OLD.mat');
%sds = sds.SDS;
deceased = [sds.males.deceased, sds.females.deceased];
alive = isnan(deceased);
born = [sds.males.born,sds.females.born];
born = born(alive);
age = 12-born;
death = sum(sds.males.AIDS_death==1&sds.males.deceased>11)+...
    sum(sds.females.AIDS_death==1&sds.females.deceased>11);
pos = sum(sds.males.HIV_positive>0)+...
    sum(sds.females.HIV_positive>0)
personyear = sum(sds.ARV.life_year_saved);
sds.ARV.time(sds.ARV.time(:,2)==0,2) = 30;
sds.ARV.time(isnan(sds.ARV.time(:,2)),2) = 30;
for i=1:sum(sds.ARV.ID>0)
    sds.ARV.time(i,2)=min(sds.ARV.time(i,2),deceased(sds.ARV.ID(i)));
end
arv = sum(sds.ARV.time(:,2)-sds.ARV.time(:,1));
effect_personyear = personyear/arv
% effect_pos = (pos-105)/arv

%display(sprintf('%d/%d',pos,effect))
%%
demographicGraphs(sds)
%%
formedRelations(sds)
%
concurrencyPrevalence(sds)
%%
deceased = [SDS.males.deceased, SDS.females.deceased];
alive = isnan(deceased);
born = [SDS.males.born,SDS.females.born];
x = deceased-born;
x = x(~isnan(x));
mean(x)

mother = [SDS.males.mother,SDS.females.mother];
born = born(mother>0);
motherborn = SDS.females.born(mother(mother>0));
%%

initial = modelHIV('new');
n = 500;
shape = 4.2;
scale = 70;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '01-Jan-2033';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.5;
SDS0.number_of_females = n*1.5;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.01;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.08*n);
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
SDS = spRun('start',SDS0);
%%

    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1;
    SDS.P0.event(4).P.threshold(1) = 5000;
    SDS.P0.event(4).P.coverage(1) = 100;
    %%
