function ages = MonteCarloAge(n,gender,filename)
%%
if strcmp(gender(1),'m')||strcmp(gender,'M')
    col = 0;
else
    col = 1;
end
tbl = csvread(filename,1,col);
agesBin = tbl(:,1);
agesBin = agesBin';
cumDistribution = cumsum(tbl(:,col+1));
cumDistribution = [0;cumDistribution]/100;
agesBin = agesBin(diff(cumDistribution)~=0);
cumDistribution = cumDistribution(diff(cumDistribution)~=0);
randAge = rand(1,n);
ages = interp1(cumDistribution,agesBin,randAge);
end