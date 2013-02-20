function agevector=empiricalage(n,ladu,kadu)
% Generates a vector agevector of length n with the age of the individuals,
% according to 2 Weibull distributions with parameters set in the function
% "testje2".

% Wim Delva

measures=0:0.01:200;

% linf and kinf are the 2 parameters of the weibull distribution for
% infants (kinf < 1 ~ decreasing hazard);
% ladu and kadu are the 2 parameters of the weibull distribution for
% adults (kadu > 1 ~ increasing hazard);

%2003 KDHS: 6% mortality after 1 year; 9% mortality after 5 years;

% To find the linf and kinf: (kinf=solution2); (linf=l);

solution2 = fzero(@myfunction,1);

l=1/((nthroot(-log(1), solution2)));

linf= l;
kinf= solution2;

answer = testje2(measures,linf, kinf, ladu, kadu);
agevector=[];
empiricalmatrix = [measures; answer]';
for i=1:n,
    random=rand;
    cumsumA=[answer random];
    B=sort(cumsumA);
    pos=find(B==random,1);
    agevector(i)=empiricalmatrix(pos,1);
end

%figure(1)
%hist(agevector)


function F = myfunction(k)

% PRE-epidemic child survival;

Q6 = 1;  % 6% infant mortality after 1 year;
Q9 = 5;  % 9% child mortality after 5 years;

F=1-exp(-((Q9*(nthroot(-log(1), k)))^k));


function answer = testje2(time,linf,kinf,ladu,kadu)  % time is a vector of the form time = [0:0.01:200];

cutoff=3;
answer=[];
for i=1:length(time),
    if time(i) <= cutoff,        % The density of dying in the first year;
        answer(i) = exp(-((time(i)./linf).^kinf));
        if time(i) == cutoff,
            j=i;
        end
    else
        answer(i) = exp(-((time(i-j)./ladu).^kadu)) .* exp(-((cutoff./linf).^kinf));  % The density of dying after the first year;
    end
end

timestep=time(2)-time(1);
Q=cumsum(answer*timestep);
result=Q(length(answer));

answer=timestep*answer*(1/result);
if 0
plot(time,answer./answer(1))
hold on
grid on
xlabel('Age')
ylabel('Survival')
end

answer=cumsum(answer);
