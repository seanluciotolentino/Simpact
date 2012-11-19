function varargout = spData(fcn, varargin)
%spData was developed my Lucio (not Ralph) to pull out the important
%features of a particular SDS.  

if nargin == 0
    spData_test
    return
end

[varargout{1:nargout}] = eval([mfilename, '_', fcn, '(varargin{:})']);
   
end

function cumincidence = spData_CumulativeIncidence(SDS)
    %Cumulative incidence -- the total number of cases that occured before each
    %year

    numyears = ceil((datenum(SDS.end_date) - datenum(SDS.start_date))/365);
    cumincidence = zeros(1,numyears);
    for i = 1:numyears
        cumincidence(i) = length([ find(SDS.males.HIV_positive<i)  find(SDS.females.HIV_positive<i)]);
    end
end

function totalLYL = spData_LYL(SDS)
    infected_life = [SDS.males.born(SDS.males.AIDS_death) 
                     SDS.males.deceased(SDS.males.AIDS_death)];
    uninfected_life = [SDS.males.born(SDS.males.deceased>0 & ~SDS.males.AIDS_death) 
                    SDS.males.deceased( SDS.males.deceased>0 & ~SDS.males.AIDS_death)];
    LYL = median(diff(uninfected_life)) - median(diff(infected_life)); %median life years lost
    totalLYL = length(infected_life)*LYL; %total LYL then should be the number of people that didn't reached that
end

function IA = spData_InfectionsAverted(SDS1, SDS2)
    infections1 = spData_CumulativeIncidence(SDS1); %w/o
    infections2 = spData_CumulativeIncidence(SDS2); %with some intervetion
    
    IA = sum(infections1(end) - infections2(end));
end

function OYA = spData_OrphanYearsAverted(SDS1,SDS2)
    OYA = OY(SDS1)-OY(SDS2);

    function orphan_years = OY(SDS)
        %for this to work I have to change deceased from NaN to Inf-- I'll
        %change it back I promise.
        SDS.males.deceased(isnan(SDS.males.deceased))=Inf;
        SDS.females.deceased(isnan(SDS.females.deceased))=Inf;
        
        eighteenthBday = [SDS.males.born(SDS.males.born>0)+18  SDS.females.born(SDS.females.born>0)+18] ;
        time_of_last_parent_death = max([SDS.females.deceased(SDS.males.mother(SDS.males.born>0)) SDS.females.deceased(SDS.females.mother(SDS.females.born>0)); 
                                        SDS.males.deceased(SDS.males.father(SDS.males.born>0))   SDS.females.deceased(SDS.females.father(SDS.females.born>0))]);
        orphan_years = sum( max( [eighteenthBday-time_of_last_parent_death ; zeros(size(eighteenthBday)) ]) );

        %changing it back
        SDS.males.deceased(isinf(SDS.males.deceased))=NaN;
        SDS.females.deceased(isinf(SDS.females.deceased))=NaN;
    end

end

function LYS = spData_LifeYearsSaved(SDS1,SDS2)
    LYL1 = spData_LYL(SDS1);
    LYL2 = spData_LYL(SDS2);
    LYS = LYL1 - LYL2 ; 
end

function [ss,matout] = spData_SummaryStatistics(SDS,flag)
%function to produce summary statistics (ss) given an SDS
%outputs summary statistics structure (ss), and 
%vector (matout). Additionally, flag input allows user to display 
%vector to screen for easier export.

yearsimulated = ceil(spTools('dateTOsimtime',SDS.end_date,SDS.start_date));
samplesize = 40; %WHY ? 
bornmin = 10;%-10; %include only the individuals that came of age within in the simulation
SDS.relations.time(SDS.relations.time(:,SDS.index.stop)==Inf,SDS.index.stop) = ...
    yearsimulated*ones(size( SDS.relations.time(SDS.relations.time(:,SDS.index.stop)==Inf,SDS.index.stop) ));


%% get a sample of men
clear sample
males = 1:SDS.number_of_males; 
sample(randperm(length(males(SDS.males.born>bornmin)))) = males(SDS.males.born>bornmin) ; %possible males randomly mixed
if samplesize>length(sample)
    ss.ERROR='NOT ENOUGH IN THE SAMPLE';
    matout = zeros(26,1);
    return
end
men = sample(1:samplesize); %this will throw an error if not enough males found

%% find the women in relationships with these men
women = [];
for m=men
    %hisrelationships = find(SDS.relations.ID(:,SDS.index.male)==m); %the relationships of this male
    women = unique([women SDS.relations.ID(SDS.relations.ID(:,SDS.index.male)==m,SDS.index.female)']);
end
if isempty(women)
    disp('MEN NOT IN RELATIONSHIPS')
    ss.ERROR = 'MEN NOT IN RELATIONSHIPS';
    matout = zeros(26,1);
    return
end

%% summary statistics (SS)
%age of partner (1) 
ages = sort(yearsimulated - SDS.females.born(women));
ss.age_of_partner.median = median(ages) ;
ss.age_of_partner.uq = ages(ceil(.75*length(ages)));
ss.age_of_partner.lq = ages(ceil(.25*length(ages)));

%age of partner (2) 
ss.age_breakdown.level1 = sum(ages<=24)/length(ages);
ss.age_breakdown.level2 = sum(ages>24 & ages <=35)/length(ages);
ss.age_breakdown.level3 = sum(ages>35 & ages <=44)/length(ages);
ss.age_breakdown.level4 = sum(ages>45)/length(ages);

%age difference
agedifferences = [];
for m=men
    man = yearsimulated - SDS.males.born(m);
    hisrelationships = find(SDS.relations.ID(:,SDS.index.male)==m); %the relationships of this male
    women = yearsimulated - SDS.females.born(unique(SDS.relations.ID(hisrelationships,SDS.index.female)));
    agedifferences = sort([agedifferences abs(man-women)]);
end
ss.age_difference.median = median(agedifferences);
ss.age_difference.lq = agedifferences(ceil(.25*length(agedifferences)));
ss.age_difference.uq = agedifferences(ceil(.75*length(agedifferences)));

%age disparate
ss.age_disparate.non_disparate = sum(agedifferences<=4)/length(agedifferences);
ss.age_disparate.age_disparate = sum(agedifferences>4 & agedifferences <10)/length(agedifferences);
ss.age_disparate.intergenerational = sum(agedifferences>=10)/length(agedifferences);

%total lifetime partners
num_partners = zeros(1,samplesize);
for m=1:samplesize
    num_partners(m) = sum(SDS.relations.ID(:,SDS.index.male)==men(m));
end
ss.total_lifetime_partners.level1 = sum(num_partners<=1);
ss.total_lifetime_partners.level2 = sum(num_partners>1 & num_partners<=5);
ss.total_lifetime_partners.level3 = sum(num_partners>5 & num_partners<=14);
ss.total_lifetime_partners.level4 = sum(num_partners>14);

%concurrent relationships in the past year
concurrent = false(1,samplesize); %set everyone to false
for mm=1:samplesize
    hisrelationships = find(SDS.relations.ID(:,SDS.index.male)==men(mm)); %the relationships of this male
    for r=hisrelationships'
        start = SDS.relations.time(r,SDS.index.start);
        for rr = hisrelationships'
            if start>SDS.relations.time(rr,SDS.index.start) && start<SDS.relations.time(rr,SDS.index.stop);
               concurrent(mm) = true;
               break 
            end
        end
        
    end
end
ss.concurrent_relationships = sum(concurrent);

%duration of relation
num_rela = sum(~isnan(SDS.relations.time(:,1)));
durations = SDS.relations.time(1:num_rela,SDS.index.stop) - SDS.relations.time(1:num_rela,SDS.index.start);
durations = sort(durations.*52); %convert years to weeks
ss.duration_of_relationships.mean = mean(durations);
ss.duration_of_relationships.median = median(durations);
ss.duration_of_relationships.lq = durations(floor(.25*length(durations)));
ss.duration_of_relationships.uq = durations(ceil(.75*length(durations)));

ss.duration_of_relationships.level1 = (sum(durations<1)/length(durations))*100;
ss.duration_of_relationships.level2 = (sum(durations>=1 & durations<=39)) /length(durations)*100;
ss.duration_of_relationships.level3 = (sum(durations>40)) /length(durations)*100;

%set parameters for later
ss.samplesize = samplesize;
ss.men = men;

%% Generate vector version:
matout = [ss.age_of_partner.median
ss.age_of_partner.lq
ss.age_of_partner.uq

ss.age_breakdown.level1*100
ss.age_breakdown.level2*100
ss.age_breakdown.level3*100
ss.age_breakdown.level4*100

ss.age_difference.median
ss.age_difference.lq
ss.age_difference.uq

ss.age_disparate.non_disparate*100
ss.age_disparate.age_disparate*100
ss.age_disparate.intergenerational*100

((ss.total_lifetime_partners.level1)/ss.samplesize)*100
((ss.total_lifetime_partners.level2)/ss.samplesize)*100
((ss.total_lifetime_partners.level3)/ss.samplesize)*100
((ss.total_lifetime_partners.level4)/ss.samplesize)*100

(ss.concurrent_relationships/ss.samplesize)*100
(1 - (ss.concurrent_relationships/ss.samplesize))*100

ss.duration_of_relationships.mean
ss.duration_of_relationships.median
ss.duration_of_relationships.lq
ss.duration_of_relationships.uq 

ss.duration_of_relationships.level1
ss.duration_of_relationships.level2
ss.duration_of_relationships.level3];

%% print to screen
if exist('flag') && flag
	fprintf('\n%f',ss.age_of_partner.median)
	fprintf('\n%f',ss.age_of_partner.lq)
	fprintf('\n%f\n',ss.age_of_partner.uq)

	fprintf('\n%f',ss.age_breakdown.level1*100)
	fprintf('\n%f',ss.age_breakdown.level2*100)
	fprintf('\n%f',ss.age_breakdown.level3*100)
	fprintf('\n%f\n',ss.age_breakdown.level4*100)

	fprintf('\n%f',ss.age_difference.median)
	fprintf('\n%f',ss.age_difference.lq)
	fprintf('\n%f\n',ss.age_difference.uq)

	fprintf('\n%f   %f',ss.age_disparate.non_disparate*100)
	fprintf('\n%f',ss.age_disparate.age_disparate*100)
	fprintf('\n%f\n\n',ss.age_disparate.intergenerational*100)

	fprintf('\n%f',((ss.total_lifetime_partners.level1)/ss.samplesize)*100)
	fprintf('\n%f',((ss.total_lifetime_partners.level2)/ss.samplesize)*100)
	fprintf('\n%f',((ss.total_lifetime_partners.level3)/ss.samplesize)*100)
	fprintf('\n%f\n',((ss.total_lifetime_partners.level4)/ss.samplesize)*100)

	fprintf('\n%f',(ss.concurrent_relationships/ss.samplesize)*100)
	fprintf('\n%f\n',(1 - (ss.concurrent_relationships/ss.samplesize))*100)

	fprintf('\n%f',ss.duration_of_relationships.mean)
	fprintf('\n%f',ss.duration_of_relationships.median)
	fprintf('\n%f',ss.duration_of_relationships.lq )
	fprintf('\n%f',ss.duration_of_relationships.uq )
	fprintf('\n')
	fprintf('\n%f',ss.duration_of_relationships.level1)
	fprintf('\n%f',ss.duration_of_relationships.level2)
	fprintf('\n%f\n',ss.duration_of_relationships.level3) 
end




end



%%
function spData_

end
