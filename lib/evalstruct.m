function [subS, msg] = evalstruct(S, Schar)
%EVALSTRUCT
%   Why not: subS = eval(Schar)
%   Because it falls-back to parent when result is not a struct?
%   Schar = regexprep(Schar, '([^)])\.', '$1(1).')

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    evalstruct_test
    return
end

subS = S;
%subS = eval(Schar);
msg = '';
%return


% ******* Main *******
enumC = regexp(Schar, '\.(\w+)\(?(\d*)\)?', 'tokens');

level = numel(enumC);
enumC = [enumC{:}];

for ii = 2*(1 : level)
    if isempty(enumC{ii})
        enumC{ii} = '1';
    end
    
    if isfield(subS, enumC{ii - 1})
        subS = subS.(enumC{ii - 1})(str2double(enumC{ii}));
        
    else
        subS = [];
        msg = sprintf('structure %s doesn''t contain a field named ''%s''', inputname(1), enumC{ii - 1});
        return
    end
    enumC{ii} = {str2double(enumC{ii})};
end

subType = {'.' '()'};
subC = [
    subType(repmat([1 2], 1, level))
    enumC
    ];

if numel(subC) < 4
   subS = S;
   return
end

try
    subS = subsref(S, substruct(subC{:}));
end

if ~isstruct(subS)
    subS = subsref(S, substruct(subC{1 : end - 2}));
end
end


%% test
function evalstruct_test

debugMsg

S.field.sub = 'test1';
S.field(2).sub = 'test2b';
S.field(2).sup = 'test2p';
[subS, msg] = evalstruct(S, 'S.field(2).sup')
end
