function X = discreteinvrnd(p,m,n)
%DISCRETEINVRND
% ref. [Statistics Toolbox | Probability Distributions | Random Number
% Generation | Common Generation Methods]

X = zeros(m,n); % Preallocate memory
for i = 1:m*n
    u = rand;
    I = find(u < cumsum(p));
    X(i) = min(I);
end

end
