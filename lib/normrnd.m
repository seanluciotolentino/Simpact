function output = normrnd(mu,sigma,m,n)
%Substitute for the normrnd function 
output = (rand(m,n)*sigma) + mu;
end