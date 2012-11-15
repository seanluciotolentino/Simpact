function [out, ok] = evalstr(argin)
%EVALSTR STR2NUM without try-catch.
%   To do: use look-around operators for numerals, e.g., EVALSTR('*') gives
%   an error

% Copyright 2009-2011 by Hummeling Engineering (www.hummeling.com)

out = argin;    % match size
ok = false;

if nargin == 0
    evalstr_test
    return
end

if iscell(argin)
    for ii = 1 : numel(out)
        [out{ii}, ok] = evalstr(out{ii});
    end
    return
end

%idx = regexp(argin(:)', '[\s\(\)*+-\./0123456789;\[\\\]\^]');
idx = regexp(argin(:)', '[\s\(\)Ee*+-\./0123456789;\[\\\]\^]');
if numel(idx) < numel(argin)
    return
end

%out = eval(['[', argin, ']']);
arginv = [argin, char(double(';')*ones(size(argin,1),1))]';
try
    out = eval(['[', arginv(:)', ']']);
catch
    %rethrow(lasterror)
    return
end

ok = true;
end


%% test
function evalstr_test

debugMsg

%ERR evalstr *
evalstr x
evalstr '(2)'
evalstr 2*3
evalstr 2+3
evalstr 2-3
evalstr 2.3
evalstr 2/3
evalstr '2;3'
evalstr '[2 3]'
evalstr 2\3
evalstr 2^3

s = [
    '1 2'
    '3 4'
    ];
evalstr(s)

end
