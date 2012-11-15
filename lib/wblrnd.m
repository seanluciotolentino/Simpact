function r = wblrnd(A,B,n,m)
%
r = A .* (-log(rand(n,m))) .^ (1./B); % == wblinv(u, A, B)
