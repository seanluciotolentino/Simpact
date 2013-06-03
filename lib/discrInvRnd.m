function X = discrInvRnd(pmf,N)
%DISCRINVRND Discrete inverse N random variable generator based on
%   probability mass function pmf.

% Jan 2009, Hummeling Engineering

if nargin == 0
    discrInvRnd_test
    return
end

X = nan(N,1); % Preallocate memory
U = rand(N,1);
%pmfInterp = interp1(pmf,1:N);
pmfInterp = interp1(pmf,linspace(1,length(pmf),N));
pmf = pmfInterp/sum(pmfInterp); % normalise
cdf = cumsum(pmf);

for ii = 1 : N
    X(ii) = find(U(ii) < cdf, 1, 'first');
end

end


function discrInvRnd_test
%% test

debugMsg

data = [1 5 9 2 10 9 1 1 2 1];
dataCount = length(data);
xLim = [0 100];
x = linspace(xLim(1), xLim(2), dataCount);

N = 1e2;
xInterp = linspace(xLim(1), xLim(2), N);
dataInterp = interp1(x, sort(data), xInterp);
pmf = dataInterp/sum(dataInterp);
X = discrInvRnd(pmf, N);

hFig = fig;

ax(1) = subplot(2,2,1, 'Parent',hFig, 'XLim',[0 dataCount]+.5);
hold(ax(1),'on')
bar(ax(1), sort(data))
%hist(ax(1), data)

ax(2) = subplot(2,2,2, 'Parent',hFig);
plot(ax(2), sort(X), '.')

ax(3) = subplot(2,2,3, 'Parent',hFig);
hist(ax(3), X)

ax(4) = subplot(2,2,4, 'Parent',hFig);
plot(ax(4), X, '.')

end
