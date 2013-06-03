
% (1)
% add the current folder to MatLab Path
% generates a new SDS (Simpact Data Structure)
addpath(genpath('/Simpact'))

[SDS,msg] = modelHIV('new'); 

% (2)
%set parameters of the population
SDS.number_of_males = 100; 
SDS.number_of_females = 100;
SDS.initial_number_of_females = 50;
SDS.initial_number_of_males = 50;
SDS.number_of_relations = 10^2;
% etc...
% set parameters of events
SDS0.formation.baseline_factor = log(0.5);
SDS0.formation.preferred_age_difference = 4;
% etc...

% (3)
% actually run the model
[SDS, ~] = spRun('start',SDS); 

% (4)
% export result as .csv files
% or generate graphs from the
exportCSV(SDS,'Simpact',1,'example');
concurrencyPrevalence(SDS);
demographicGraphs(SDS);


