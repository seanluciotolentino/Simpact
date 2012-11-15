function structStr = treepath2struct(treePath)
%TREEPATH2STRUCT Converts a Java Swing TreePath to structure notation.
% 
%   See also struct2tree, treepath2cell.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

structStr = regexprep(char(treePath), ', ', '.');
structStr = strrep(structStr, ' ', '_');
structStr = regexprep(structStr, '[\[\]]', '');
end
