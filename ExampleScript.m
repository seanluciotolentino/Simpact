%Example script of how to run simpact without GUI:
%addpath('lib') %use the line below when running in a subfolder (i.e. SDS, fei, wim)
addpath( [fileparts(fileparts(which(mfilename))) '/lib'] ); %this line necessary when running in a subfolder (not main directory)
warning off


%One run of the modelHIV
[SDS,msg] = modelHIV('new'); %generates a new SDS with all the required stuff

SDS.number_of_males = 10; %set parameters of the model manually
SDS.number_of_females = 10;
SDS.initial_number_of_females = SDS.number_of_females/2;
SDS.initial_number_of_males = SDS.number_of_males/2;
SDS.number_of_relations = 10^2;

[SDS2, ~] = spRun('start',SDS); %actually run the model
fprintf(1,'\n')

prevalence = zeros(1,20);
for i = 1:20
	HIVpos = length([ find(SDS2.males.HIV_positive<i)  find(SDS2.females.HIV_positive<i)]); %infected before this round
	HIVmaledeath = find(SDS2.males.deceased.*SDS2.males.AIDS_death>0); %times of HIV deaths
	HIVfemaledeaths = find(SDS2.females.deceased.*SDS2.females.AIDS_death>0);
	HIVdeath = length([find(HIVmaledeath<i)  find(HIVfemaledeaths<i)]);%HIV death this round
	prevalence(i) = HIVpos - HIVdeath;
end