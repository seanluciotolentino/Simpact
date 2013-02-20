function output = lognrnd(mu,sigma,m,n);
%substitute lognrnd written by Lucio because I don't have access to the
%stats toolbox
 output = log(normrnd(mu,sigma,m,n));
end