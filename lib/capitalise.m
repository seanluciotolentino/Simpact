function out = capitalise(str)
%CAPITALISE Make first letter of words in sentence upper-case.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

str = regexprep(str, '(^.)', '${upper($1)}');
out = regexprep(str, '(?<=\s\s*)([a-z])','${upper($1)}');
end
