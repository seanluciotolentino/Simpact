function out = filedate(filenames)
%FILEDATE Returns serial file date

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if ischar(filenames)
    out = filedate_this(filenames);
    return
end

out = nan(size(filenames));
for ii = 1 : numel(filenames)
    out(ii) = filedate_this(filenames{ii});
end
end


%% this
function thisDate = filedate_this(filename)

thisDate = NaN;

if exist(filename, 'file') ~= 2
    return
end

filepath = which(filename);
D = dir(filepath);
thisDate = D.datenum;
end
