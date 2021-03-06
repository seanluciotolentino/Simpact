new=load('testSDS175.mat');
daysPerYear = spTools('daysPerYear');
duration =(datenum(new.SDS.end_date) - datenum(new.SDS.start_date))/daysPerYear;

new.SDS.start_date = new.SDS.end_date;
new.SDS.end_date = datestr(addtodate(new.SDS.start_date, 20, 'year'));

new.SDS.initial_number_of_males = find(isnan(new.SDS.males.born),1)-1;
new.SDS.initial_number_of_females = find(isnan(new.SDS.females.born),1)-1;

new.SDS.number_of_males = new.SDS.initial_number_of_males*1.75;
new.SDS.number_of_females = new.SDS.initial_number_of_females*1.75;

infectedChance = rand(1,SDS.initial_number_of_males) <=1;
infectedAge = new.SDS.males.born > -35 & new.SDS.males.born <= -15;
infectedPartnering = new.SDS.males.partnering< 0.5; % the active males are infected first;
infectedIdx = infectedChance & infectedAge & infectedPartnering; 
new.SDS.males.HIV_positive(infectedIdx) = 0; 

infectedChance = rand(1,SDS.initial_number_of_females) <=1;
infectedAge = new.SDS.females.born > -35 & new.SDS.females.born <= -15;
infectedPartnering = new.SDS.females.partnering< 0.5; % the active males are infected first;
infectedIdx = infectedChance & infectedAge & infectedPartnering; %infectedIdx = SDS.males.born <= -70; %SDS.males.born > -29 & SDS.males.born <= -24;
new.SDS.females.HIV_positive(infectedIdx) = 0; 

new.SDS.males.birth = new.SDS.males.birth - duration;
new.SDS.males.deceased = new.SDS.males.deceased - duration;
new.SDS.males.circumcision = new.SDS.males.circumcision - duration;
new.SDS.females.birth = new.SDS.females.birth - duration;
new.SDS.females.deceased = new.SDS.females.deceased - duration;

new.SDS.males.HIV_positive = new.SDS.males.HIV_positive -duration;
new.SDS.females.HIV_positive = new.SDS.females.HIV_positive -duration;

new.SDS.relations.time(:,1:2)=new.SDS.relations.time(:,1:2) - duration;

save('testSDS175tweaked.mat','new.SDS');

