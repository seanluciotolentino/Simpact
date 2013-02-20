function HMC(run)
%run = i1 ~ i2; n = number of initial males;

if ~isdeployed

  path(path,'lib')
  path(path,'MATLAB')
  path(path,'fei/pre_post_process')
  run = str2num(run); 
%   i1 = str2num(i1);
%   i2 = str2num(i2);
%   n  = str2num(n);
end

mkdir('HMC');
n = 500;

    %%%=======SDS0: year 1998 - 2012===========%%%
    %%
  rng((run + 17)*2213)
shape= 4;scale = 76;
SDS0 = modelHIV('new');
SDS0.start_date = '01-Jan-2003';
SDS0.end_date = '31-Dec-2013';
SDS0.initial_number_of_males = n;
SDS0.initial_number_of_females = n;
SDS0.number_of_males = n*1.6;
SDS0.number_of_females = n*1.6;
SDS0.number_of_community_members = floor(SDS0.initial_number_of_males/2); % 4 communities
SDS0.sex_worker_proportion = 0.03;
SDS0.number_of_relations = SDS0.number_of_males*SDS0.number_of_females;
SDS0.number_of_tests =  (SDS0.number_of_males+SDS0.number_of_females);
SDS0.number_of_ARV = (SDS0.number_of_males+SDS0.number_of_females)*0.3;
%SDS0.male_circumcision.enable = 0;
SDS0.HIV_introduction.number_of_introduced_HIV=round(0.065*n);
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

    %%%=======SDS: year 2013-2035;============%%%
    
    % 3 access schemes: SQ, PE, UE;
    % 8 target groups: G0, G1, G2, G3, G4, G4*, G5, G10;
    % 21 scenarios in total;
  
    
    % I. access scheme SQ
    % SQ.G0
    
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS = spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'SQ','G0');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'SQ_G0');
    %%
    % SQ.G1
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.threshold(1) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'SQ','G1');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'SQ_G1');
    %%
    % SQ.G2
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.threshold(1)= 500;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'SQ','G2');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'SQ_G2');
    % SQ.G3
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(3)=0.51;
    SDS.P0.event(4).P.coverage(3)=0.75;
    SDS.P0.event(4).P.threshold(3) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'SQ','G3');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'SQ_G3');
    % SQ.G4
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(2)=0.51;
    SDS.P0.event(4).P.coverage(2)=0.75;
    SDS.P0.event(4).P.threshold(2) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'SQ','G4');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'SQ_G4');
   
    % SQ.G5
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(4)=0.51;
    SDS.P0.event(4).P.coverage(4)=0.75;
    SDS.P0.event(4).P.threshold(4) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'SQ','G5');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'SQ_G5');
    % SQ.G10
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(5)=0.51;
    SDS.P0.event(4).P.coverage(5)=0.75;
    SDS.P0.event(4).P.threshold(5) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'SQ','G10');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'SQ_G10');
    
    % I. access scheme PE
    % PE.G3
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(3)=2;
    SDS.P0.event(4).P.coverage(3)=0.8;
    SDS.P0.event(4).P.threshold(3) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'PE','G3');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'PE_G3');
    % PE.G4
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(2)=2;
    SDS.P0.event(4).P.coverage(2)=0.8;
    SDS.P0.event(4).P.threshold(2) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'PE','G4');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'PE_G4');
    
    % PE.G5
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(4)=2;
    SDS.P0.event(4).P.coverage(4)=0.8;
    SDS.P0.event(4).P.threshold(4) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'PE','G5');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'PE_G5');
    % PE.G10
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(5)=2;
    SDS.P0.event(4).P.coverage(5)=0.8;
    SDS.P0.event(4).P.threshold(5) = 5000;
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'PE','G10');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'PE_G10');
    
      
     % III. access scheme UE
    % UE.G0
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=0.5;
    SDS.P0.event(4).P.coverage(1)=0.75;
    SDS.P0.event(4).P.eventTimes(1)=2.01;
    SDS.P0.event(4).P.coverage(1)=0.8;
    SDS.P0.event(15).P.targetCoverage = 0.8;
    
    SDS = spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'UE','G0');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'UE_G0');
    % UE.G1
    SDS = SDS0;
    
    SDS.P0.event(4).P.eventTimes(1)=2.01;
    SDS.P0.event(4).P.coverage(1)=0.8;
    SDS.P0.event(4).P.threshold(1) = 5000;
    SDS.P0.event(15).P.targetCoverage = 0.8;
    
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'UE','G1');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'UE_G1');
    % UE.G2
    SDS = SDS0;
    
    SDS.P0.event(4).P.eventTimes(1)=2;
    SDS.P0.event(4).P.coverage(1)=0.8;
    SDS.P0.event(4).P.threshold(1) = 500;
    SDS.P0.event(15).P.targetCoverage = 0.8;
    
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'UE','G2');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'UE_G2');
    % UE.G3
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=2.01;
    SDS.P0.event(4).P.coverage(1)=0.8;
    SDS.P0.event(4).P.eventTimes(3)=2;
    SDS.P0.event(4).P.coverage(3)=0.8;
    SDS.P0.event(4).P.threshold(3) = 5000;
    SDS.P0.event(15).P.targetCoverage=1;
    
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'UE','G3');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'UE_G3');
    % UE.G4
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=2.01;
    SDS.P0.event(4).P.coverage(1)=0.8;
    SDS.P0.event(4).P.eventTimes(2)=2;
    SDS.P0.event(4).P.coverage(2)=0.8;
    SDS.P0.event(4).P.threshold(3) = 5000;
    SDS.P0.event(15).P.targetCoverage=1;
    
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'UE','G4');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'UE_G4');
    
    % UE.G5
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=2.01;
    SDS.P0.event(4).P.coverage(1)=0.8;
    SDS.P0.event(4).P.eventTimes(4)=2;
    SDS.P0.event(4).P.coverage(4)=0.8;
    SDS.P0.event(4).P.threshold(4) = 5000;
    SDS.P0.event(15).P.targetCoverage = 0.8;
    
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'UE','G5');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'UE_G5');
    % UE.G10
    SDS = SDS0;
    SDS.P0.event(4).P.eventTimes(1)=2.01;
    SDS.P0.event(4).P.coverage(1)=0.8;
    SDS.P0.event(4).P.eventTimes(5)=2;
    SDS.P0.event(4).P.coverage(5)=0.8;
    SDS.P0.event(4).P.threshold(5) = 5000;
    SDS.P0.event(15).P.targetCoverage = 0.8;
    
    SDS =spRun('restart',SDS);
    file = sprintf('HMC/sds_%04d_%s_%s.mat', run, 'UE','G10');
    save(file,'-struct','SDS');
    exportCSV(SDS,'HMC',run,'UE_G10');
   
    
end 