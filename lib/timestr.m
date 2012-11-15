function str = timestr(time)
%TIMESTR

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

str = '';

if nargin == 0
    timestr_test
    return
end

convert = cumprod([1 60 60 24]);
unit = {'second' 'minute' 'hour', 'day'};

value = round(time)./convert;
idx = find(value >= 1, 1, 'last');
if isempty(idx)
    str = sprintf('%g seconds', time);
    return
end

floorValue = floor(value(idx));
if floorValue > 1
    unit{idx} = [unit{idx}, 's'];
end
str = sprintf('%g %s', floorValue, unit{idx});

remainder = (value(idx) - floorValue)*convert(idx);
if remainder > 0
    % recursion
    strRem = timestr(remainder);
    str = [str, ', ', strRem];
end
end


%% test
function timestr_test

debugMsg

for time = 10.^(0 : 6)
    disp(timestr(time))
end
end
