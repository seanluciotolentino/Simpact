function prob2stat
%PROB2STAT

% Jan 2009, Ralph Hummeling

if nargin == 0
  prob2stat_test
end

% ******* _ *******


% ******* *******



%%
  function prob2stat_2
	
  end


%%
  function prob2stat_
	
  end


end


%%
function prob2stat_test

debugMsg

N = 21;
maxAge = 100;
popCount = 2e3;
pop = 1 : popCount;
ages = linspace(0,maxAge,N);
dx = ages(2) - ages(1); % assuming monotonically increasing ages
agesInterp = linspace(0,maxAge,popCount);
%prob = ones(1,N);
prob = ones(1,N); prob(1:N/2) = 0;
%prob = linspace(0,1,N);
%prob = sin(linspace(0,pi,N)).^2;
pdf = prob/sum(prob*dx); % probability density function
%sum(pdf*dx) % check: should be unity

probInterp = interp1(ages, cumsum(pdf), agesInterp);
stat = probInterp*dx;
stat = maxAge*stat/max(stat);
%stat = maxAge*(1 - stat/max(stat));
%conv

dist = [0, diff(stat)];
dist = popCount*dist/sum(dist);
%sum(dist) % check: 


% ******* Plotting *******
figPrp = [];
figPrp.Name = mfilename;
fig = findall(0, 'Name',figPrp.Name);
if isempty(fig)
  fig = figure(figPrp);
else
  figure(fig)
  clf(fig)
end
xLimProb = [-dx/2, 100 + dx/2];
ax = subplot(3,1,1, 'Parent',fig, 'XLim',xLimProb);
hold on
bar(ax, ages,pdf)
xlabel age
ylabel probability

xLimStat = [0 popCount];
ax = subplot(3,1,2, 'Parent',fig, 'YLim',xLimStat);
hold on
plot(ax, stat,pop,'.')
xlabel population
ylabel statistics

ax = subplot(3,1,3, 'Parent',fig, 'XLim',xLimProb);
hold on
bar(ax, agesInterp,dist)
xlabel age
ylabel 'distribution check'

end
