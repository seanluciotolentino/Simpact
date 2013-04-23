function ages = MonteCarloAge(n,gender,filename)
%%
if strcmp(gender(1),'m')||strcmp(gender,'M')
    col = 1;
else
    col = 2;
end
tbl = csvread(filename,1,0);
agesBin = tbl(:,1);
agesBin = [0; agesBin];
cumDistribution = cumsum(tbl(:,col+1));
cumDistribution = [0;cumDistribution]/100;
agesBin = agesBin(diff(cumDistribution)~=0);
cumDistribution = cumDistribution(diff(cumDistribution)~=0);
cumDistribution = cumDistribution/cumDistribution(length(cumDistribution));
randAge = rand(1,n);
ages = interp1(cumDistribution,agesBin,randAge);
end