function table = tablesum(SDS)
daysPerYear = spTools('daysPerYear');
t =floor((datenum(SDS.end_date)-datenum(SDS.start_date))/daysPerYear);
      
born = [SDS.males.born, SDS.females.born];
death = [SDS.males.deceased, SDS.females.deceased];
life = death-born;
life = life(~isnan(life));
table.initial = sum(born<=0);
table.total = sum(~isnan(born));
table.ave_life = mean(life);
table.med_life = median(life);
table.newborns_per_yr = sum([SDS.males.born, SDS.females.born]>=0)/t;
timeHIVpos = [SDS.males.HIV_positive, SDS.females.HIV_positive];
sortHIVpos = sort(timeHIVpos(~isnan(timeHIVpos)));

initialHIV = max(1,sum(sortHIVpos<=0));
table.newHIV = length(sortHIVpos) - initialHIV;
if initialHIV*2<=length(sortHIVpos)
table.doubleTime = sortHIVpos(initialHIV*2);
end
table.initialPrevalence = initialHIV/(SDS.initial_number_of_males+SDS.initial_number_of_females);

death(isnan(death)) = t+1;
alive = zeros(1,t*2+1);
prev = zeros(1,t*2+1);
prev(1) = table.initialPrevalence;
adultPrev = zeros(1,t*2+1);
adultPrev(1) = initialHIV/sum(born<=-15);
relations = zeros(1,t*2+1);
ti = 0.5:0.5:t;

for i = ti

alive(i*2+1) = sum(born<i&death>i);
prev(i*2+1) = sum(timeHIVpos<i&death>i)/alive(i*2);
adult = sum(born<(i-15)&death>i);
adultPrev(i*2+1) =  sum(timeHIVpos<i&death>i)/adult;
relations(i*2+1) = sum(SDS.relations.time(:,1)<i&SDS.relations.time(:,2)>i)/adult;

end
table.population_change = alive(end);
table.prevalence = prev;
table.adult_prev = adultPrev;
table.alive = alive;
table.concurrency = relations;
table.time = [0 ti];

pop = SDS.initial_number_of_males+SDS.initial_number_of_females;

newborns = born(born>0);
mothers = [SDS.males.mother SDS.females.mother];
mothers = mothers(mothers>0);
table.pregnant_age = zeros(1,length(mothers));
for i = 1:length(mothers)
   table.pregnant_age(i) = newborns(i) - SDS.females.born(mothers(i));
end

table.age_at_infection = [SDS.males.HIV_positive SDS.females.HIV_positive] - ...
    [SDS.males.born SDS.females.born];
table.age_at_infection = table.age_at_infection(table.age_at_infection>=0);




name = sprintf('Pop_%d_Time_%d_yrs.pdf', pop,t );
subplot(4,2,1); plot(table.time,table.alive); title('Population Size');
subplot(4,2,2); plot(table.time,table.concurrency); title('Average Concurrent Relationships');
subplot(4,2,3); plot(table.time,table.prevalence); title('Prevalence');
subplot(4,2,4); plot(table.time,table.adult_prev); title('Prevalence in Adults (>= 15 yrs)');
subplot(4,2,5); hist(table.pregnant_age); title('Age at children delivery');
subplot(4,2,6); hist(t-born,20); title('Age distribution at the end of simulation');
subplot(4,2,7); hist(table.age_at_infection,20);title('Age distribution at infection');
subplot(4,2,8);hist([SDS.males.HIV_positive SDS.females.HIV_positive],30); title('New infections');
waitTime = Inf(1, SDS.number_of_males+SDS.number_of_females);
newIndex = born<=t-15&born>=-15;
newAdult = sum(newIndex);
count = 0;
for i = 1:SDS.number_of_males
    ti = min(SDS.relations.time(SDS.relations.ID(:,1)==i,1)) - (born(i)+15);
    if isempty(ti)
        ti = min(death(i),t) - born(i)-15;
    else count = count+1;
    end
    if newIndex(i)
        waitTime(i)=ti;
    end
end



for i = 1:SDS.number_of_females
    ti = min(SDS.relations.time(SDS.relations.ID(:,2)==i,1))- born(i+SDS.number_of_males)-15;
    
    if isempty(ti)
        ti = min(death(i+SDS.number_of_males),t) - born(i+SDS.number_of_males)-15;
    else count = count+1;
    end
    if newIndex(i+SDS.number_of_males)
        waitTime(i+SDS.number_of_males)=ti;
    end
end

table.waitTime = sum(waitTime(~isinf(waitTime)))/newAdult;
table.isolate = count;

tfree = zeros(1, SDS.number_of_males+SDS.number_of_females);
for i =1:SDS.number_of_males
    times = SDS.relations.time(SDS.relations.ID(:,1)==i,1:2);
    times(isinf(times(:,2)),2) = t;
    endTime = min(death(i),t).*[1 1];
    times = [times; endTime];
    for i = 1:(length(times(:,1))-1)
        tstop = times(i,2);
        tnext = times(i+1,1);
        if tnext>= tstop
            tfree(i) = tfree(i)+tnext-tstop;
        end
    end
      
end

for i =1:SDS.number_of_females
    times = SDS.relations.time(SDS.relations.ID(:,2)==i,1:2);
    times(isinf(times(:,2)),2) = t;
    endTime = min(death(i+SDS.number_of_males),t).*[1 1];
    times = [times; endTime];
    for i = 1:(length(times(:,1))-1)
        tstop = times(i,2);
        tnext = times(i+1,1);
        if tnext>= tstop
            tfree(i+SDS.number_of_males) = tfree(i+SDS.number_of_males)+tnext-tstop;
        end
    end
      
end

table.average_isolate_time = sum(tfree)/sum(born>=-15);

relations = sum(SDS.relations.ID(:,1)>0);
in = 0;
out =0;
for i = 1: relations
   male = int16(SDS.relations.ID(i,1));
   female = int16(SDS.relations.ID(i,2));
   if SDS.males.community(male)==SDS.females.community(female)
       in = in+1;
   else out = out +1;
   end
    
end

community = max(SDS.males.community);

table.in_community_relations =[in in/community];
table.out_community_relations = [out out/(community*(community-1)/2)/2];
endedRelations = ~isinf(SDS.relations.time(:,2))&~isnan(SDS.relations.time(:,2));
table.average_relations_duration = sum(SDS.relations.time(endedRelations,2)-SDS.relations.time(endedRelations,1))/relations;


end



