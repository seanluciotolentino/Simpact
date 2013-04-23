
function TasP_IAS(n,run)
%run = i1 ~ i2; n = number of initial males;
% n = 400;
% run = 2;
if ~isdeployed

  path(path,'lib')
  path(path,'MATLAB')
  path(path,'fei/pre_post_process')
%  run = str2num(run); 
%   i1 = str2num(i1);
%   i2 = str2num(i2);
%   n  = str2num(n);
end

mkdir('TasP_IAS');

    %%%=======SDS0: year 1998 - 2012===========%%%
%%
rng((run + 17)*2213)
initial = modelHIV('new');

shape = 4.2;
scale = 70;
SDS0 = initial;
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '01-Jan-2013';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.6;
SDS0.number_of_females = n*1.6;
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
SDS0 = spRun('start',SDS0);
%%
    %%%=======SDS: year 2014-2034;============%%%
    
    % 3 access schemes: SQ(coverage=40/40), PE(40/80), UE1(60/60),UE2(80/80);
    % 8 target groups: non, pos, cd4, sero, fsw, preg, old;
    % 21 scenarios in total;
  
    
    % I. access scheme SQ
    SDS0.P0.event(15).P.targetCoverage = 0.5;
    SDS0.P0.event(15).P.targetCoverageSubpop = 0.5;
    
    % SQ_NON
    SDS = SDS0;
    SDS = spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'SQ','NON');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'SQ_NON');
    %
    % SQ.POS
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1;
    SDS.P0.event(4).threshold(1) = 5000;
    SDS.P0.event(4).coverage(1) = 40;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'SQ','POS');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'SQ_POS');
    
    % SQ.CD4
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1;
    SDS.P0.event(4).threshold(1) = 500;
    SDS.P0.event(4).coverage(1) = 40;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'SQ','CD4');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'SQ_CD4');
    % SQ.PREG
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(2) = 1;
    SDS.P0.event(4).threshold(2) = 5000;
    SDS.P0.event(4).coverage(2) = 40;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'SQ','PREG');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'SQ_PREG');
    % SQ.SERO ?3 months?
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(3) = 1;
    SDS.P0.event(4).threshold(3) = 5000;
    SDS.P0.event(4).coverage(3) = 40;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'SQ','SERO3');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'SQ_SERO3');
    
    % SQ.SERO ?1 months?
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(3) = 1;
    SDS.P0.event(4).threshold(3) = 5000;
    SDS.P0.event(4).coverage(3) = 40;
    SDS0.P0.event(15).P.longterm_relationship_threshold = 1/12;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'SQ','SERO');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'SQ_SERO1');
   
    % SQ.FSW
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(4) = 1;
    SDS.P0.event(4).threshold(4) = 5000;
    SDS.P0.event(4).coverage(4) = 40;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'SQ','FSW');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'SQ_FSW');
    
    % SQ.OLD
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(5) = 1;
    SDS.P0.event(4).threshold(5) = 5000;
    SDS.P0.event(4).coverage(5) = 40;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'SQ','OLD');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'SQ_OLD');
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % I. access scheme PE
%    
%     % PE.PREG
%     SDS = SDS0;
%     SDS.P0.event(4).P.eventTimes(3) = 1;
%     SDS.P0.event(4).threshold(3) = 5000;
%     SDS.P0.event(4).coverage(3) = 80;
%     SDS =spRun('restart',SDS);
%     file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'PE','PREG');
%     save(file,'-struct','SDS');
%     exportCSV(SDS,'TasP_IAS',run,'PE_PREG');
%     % PE.SERO
%     SDS = SDS0;
%     SDS.P0.event(4).P.eventTimes(4) = 1;
%     SDS.P0.event(4).threshold(4) = 5000;
%     SDS.P0.event(4).coverage(4) = 80;
%     SDS =spRun('restart',SDS);
%     file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'PE','SERO');
%     save(file,'-struct','SDS');
%     exportCSV(SDS,'TasP_IAS',run,'PE_SERO');
%    
%     % PE.FSW
%     SDS = SDS0;
%     SDS.P0.event(4).P.eventTimes(5) = 1;
%     SDS.P0.event(4).threshold(5) = 5000;
%     SDS.P0.event(4).coverage(5) = 80;
%     SDS =spRun('restart',SDS);
%     file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'PE','FSW');
%     save(file,'-struct','SDS');
%     exportCSV(SDS,'TasP_IAS',run,'PE_FSW');
%     % PE.OLD
%     SDS = SDS0;
%     SDS.P0.event(4).P.eventTimes(6) = 1;
%     SDS.P0.event(4).threshold(6) = 5000;
%     SDS.P0.event(4).coverage(6) = 40;
%     SDS =spRun('restart',SDS);
%     file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'PE','OLD');
%     save(file,'-struct','SDS');
%     exportCSV(SDS,'TasP_IAS',run,'PE_OLD');
%       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % I. access scheme UE1
    SDS0.P0.event(15).P.targetCoverage = 0.6;
    SDS0.P0.event(15).P.targetCoverageSubpop = 0.6;
    SDS0.P0.event(15).P.critria(2) = 1;
    % UE1_NON
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 60;
    SDS = spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','NON');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_NON');
    % UE1.POS
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 60;
    SDS.P0.event(4).P.eventTimes(1) = 1;
    SDS.P0.event(4).threshold(1) = 5000;
    SDS.P0.event(4).coverage(1) = 60;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','POS');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_POS');
    
    % UE1.CD4
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 60;
    SDS.P0.event(4).P.eventTimes(1) = 1;
    SDS.P0.event(4).threshold(1) = 500;
    SDS.P0.event(4).coverage(1) = 60;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','CD4');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_CD4');
    % UE1.PREG
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 60;
    SDS.P0.event(4).P.eventTimes(3) = 1;
    SDS.P0.event(4).threshold(3) = 5000;
    SDS.P0.event(4).coverage(3) = 60;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','PREG');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_PREG');
    % UE1.SERO3
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 60;
    SDS.P0.event(4).P.eventTimes(4) = 1;
    SDS.P0.event(4).threshold(4) = 5000;
    SDS.P0.event(4).coverage(4) = 60;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','SERO3');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_SERO3');
    
    % UE1.SERO1
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 60;
    SDS.P0.event(4).P.eventTimes(4) = 1;
    SDS.P0.event(4).threshold(4) = 5000;
    SDS.P0.event(4).coverage(4) = 60;
    SDS0.P0.event(15).P.longterm_relationship_threshold = 1/12;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','SERO1');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_SERO1');
   
    % UE1.FSW
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 60;
    SDS.P0.event(4).P.eventTimes(5) = 1;
    SDS.P0.event(4).threshold(5) = 5000;
    SDS.P0.event(4).coverage(5) = 60;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','FSW');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_FSW');
    % UE1.OLD
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 60;
    SDS.P0.event(4).P.eventTimes(6) = 1;
    SDS.P0.event(4).threshold(6) = 5000;
    SDS.P0.event(4).coverage(6) = 60;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','OLD');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_OLD');
   
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % I. access scheme UE2
    SDS0.P0.event(15).P.targetCoverage = 0.8;
    SDS0.P0.event(15).P.targetCoverageSubpop = 0.8;
    SDS0.P0.event(15).P.critria(2) = 1;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    % UE2_NON
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 80;
    SDS = spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE2','NON');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE2_NON');
    % UE2.POS
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 80;
    SDS.P0.event(4).P.eventTimes(1) = 1;
    SDS.P0.event(4).threshold(1) = 5000;
    SDS.P0.event(4).coverage(1) = 80;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE2','POS');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE2_POS');
    
    % UE2.CD4
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 80;
    SDS.P0.event(4).P.eventTimes(1) = 1;
    SDS.P0.event(4).threshold(1) = 500;
    SDS.P0.event(4).coverage(1) = 80;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE2','CD4');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE2_CD4');
    % UE2.PREG
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 80;
    SDS.P0.event(4).P.eventTimes(3) = 1;
    SDS.P0.event(4).threshold(3) = 5000;
    SDS.P0.event(4).coverage(3) = 80;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE2','PREG');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE2_PREG');
    % UE2.SERO3
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 80;
    SDS.P0.event(4).P.eventTimes(4) = 1;
    SDS.P0.event(4).threshold(4) = 5000;
    SDS.P0.event(4).coverage(4) = 80;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE2','SERO3');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE2_SERO3');
    
    % UE2.SERO1
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 80;
    SDS.P0.event(4).P.eventTimes(4) = 1;
    SDS.P0.event(4).threshold(4) = 5000;
    SDS.P0.event(4).coverage(4) = 60;
    SDS0.P0.event(15).P.longterm_relationship_threshold = 1/12;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE1','SERO1');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE1_SERO1');
   
    % UE2.FSW
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 80;
    SDS.P0.event(4).P.eventTimes(5) = 1;
    SDS.P0.event(4).threshold(5) = 5000;
    SDS.P0.event(4).coverage(5) = 80;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE2','FSW');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE2_FSW');
    % UE2.OLD
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1) = 1.5;
    SDS.P0.event(4).threshold(1) = 350;
    SDS.P0.event(4).coverage(1) = 80;
    SDS.P0.event(4).P.eventTimes(6) = 1;
    SDS.P0.event(4).threshold(6) = 5000;
    SDS.P0.event(4).coverage(6) = 80;
    SDS =spRun('restart',SDS);
    file = sprintf('TasP_IAS/sds_%04d_%s_%s.mat', run, 'UE2','OLD');
    save(file,'-struct','SDS');
    exportCSV(SDS,'TasP_IAS',run,'UE2_OLD');
end 