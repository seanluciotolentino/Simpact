function [ok, msg] = exportCSV(SDS, folder, index, scen)

ok = false; %#ok<NASGU>
msg = ''; %#ok<NASGU>

malesID = 1:SDS.number_of_males;
femalesID=1:SDS.number_of_females;
femalesID=femalesID+SDS.number_of_males;
ID=[malesID,femalesID]';
gender = [zeros(1, SDS.number_of_males) ones(1,SDS.number_of_females)]';
born=[SDS.males.born, SDS.females.born]';
deceased=[SDS.males.deceased, SDS.females.deceased]';
father=[SDS.males.father, SDS.females.father]';
mother=[SDS.males.mother,SDS.females.mother]'+SDS.number_of_males;
mother(mother==SDS.number_of_males)=0;
HIV_positive=[SDS.males.HIV_positive,SDS.females.HIV_positive]';

male_source = SDS.males.HIV_source + SDS.number_of_males;
male_source(male_source==SDS.number_of_males)=0;
HIV_source = [male_source, SDS.females.HIV_source]';
sex_worker = [false(1, SDS.number_of_males), SDS.females.sex_worker]';
AIDS_death = [SDS.males.AIDS_death,SDS.females.AIDS_death]';
CD4_infection = [SDS.males.CD4Infection, SDS.females.CD4Infection]';
CD4_death = [SDS.males.CD4Death, SDS.females.CD4Death]';
ARV_eligible=[SDS.males.ARV_eligible, SDS.females.ARV_eligible]';
CD4_500 = [SDS.males.CD4_500, SDS.females.CD4_500]';
CD4_350 = [SDS.males.CD4_350, SDS.females.CD4_350]';
CD4_200 = [SDS.males.CD4_200, SDS.females.CD4_200]';

ID=single(ID);
father=single(father);
mother=single(mother);
HIV_source = single(HIV_source);

allC=[ID,gender, born, deceased, father, mother, HIV_positive, HIV_source, ...
    sex_worker, AIDS_death, CD4_infection,CD4_death, ARV_eligible,CD4_500,CD4_350,CD4_200];
allC=allC(~isnan(born),:);
head={'id','gender','born','deceased','father','mother','hiv.positive','hiv.source',...
    'sex.worker', 'aids.death','cd4.infection','cd4.death','arv.eligible','cd4.500','cd4.350','cd4.200'};
allC=[head
    num2cell(allC)];

% ******* Seperate file for relations *******
relations = [single([SDS.relations.ID]), SDS.relations.time(:,1:2),single(SDS.relations.proximity)];
relations(:,2)=relations(:,2)+SDS.number_of_males;
relations=relations(relations(:,1)~=0,:);
header = {'male.id' 'female.id' 'start.time' 'end.time','proximity'};
relations = [header
num2cell(relations)   
];

%********Seperate file for test*********
test = [single(SDS.tests.ID),SDS.tests.time];%,SDS.tests.enter];
test = test(test(:,1)~=0,:);
header = {'id','time'};%,'enter'};
test = [header
    num2cell(test)];

%********Seperate file for ARV*********
ARV = [single(SDS.ARV.ID),SDS.ARV.time, single(SDS.ARV.CD4), SDS.ARV.life_year_saved];
ARV = ARV(ARV(:,1)~=0,:);
header = {'id','arv.start','arv.stop','cd4','life.year.saved'};
ARV = [header
    num2cell(ARV)];

% ******* Store *******
% folder ='/Users/feimeng/Documents/SIMPACTexp/result'; 
file=sprintf('%04d', index);
%save(fullfile(folder, ['sds_', file, '.mat']), 'SDS');
[ok, msg] = exportCSV_print(fullfile(folder, ['pop_', file, '_',scen, '.csv']), allC);
[ok, msg] = exportCSV_print(fullfile(folder,['relation_', file, '_',scen, '.csv']),relations);
[ok, msg] = exportCSV_print(fullfile(folder, ['test_', file, '_',scen,  '.csv']), test);
[ok, msg] = exportCSV_print(fullfile(folder, ['arv_', file,  '_',scen, '.csv']), ARV);
    
    end
