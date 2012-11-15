function out = solvesys(algSystem)
%SOLVESYS

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    out = solvesys_test;
    return
end

out = algSystem;
N = size(algSystem, 1);

for ii = repmat(1 : N, 1, N)
    try
        eval(sprintf('%s = %s;', algSystem{ii,1}, algSystem{ii,2}))
    end
end

for ii = 1 : N
    out{ii, 3} = eval(algSystem{ii,1});
end
end


%%
function algSol = solvesys_test

debugMsg

algSystem = {
    'p'     '9 + s'
    'q'     '3*s'
    'r'     'p+q'
    's'     '5'
    };
algSol = solvesys(algSystem)
end


%%
function solvesys_

end
