function [meantime, vartime] = decay(startn, stopn, hazard, reps)

% reps repeated experiments of the time to go from population size startn
% till population size stopn under hazard (per element rate).

% from startn to startn-1: rate = hazard*startn;
% time1 = (-log(rand1))/(hazard*startn);

% from startn-1 to startn-2: rate = hazard*startn-1;
% time2 = (-log(rand2))/(hazard*startn-1);

% time1+ time2 = (-log(rand1))/(hazard*startn) +
% (-log(rand2))/(hazard*startn-1)


% M = matrix with reps rows and startn - stopn columns;
% r = rate matrix with reps rows and startn - stopn columns;

M = -log(rand(reps, startn-stopn));
r = repmat(hazard.*(startn:-1:stopn+1), reps, 1);

times = M./r;
time = sum(times, 2);
% meantime = sum(1./(hazard.*(startn:-1:stopn+1)));
% vartime = sum(1./((hazard.*(startn:-1:stopn+1)).^2));

meantime = mean(time);
vartime = var(time);

hist(time)
% 



