function out = bytestr(bytes)
%BYTESTR Print byte size with correct unit.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    bytestr_test
    return
end

convert = 2.^(0 : 10 : 30);
unit = {'bytes', 'KB', 'MB', 'GB'};
value = bytes./convert;
idx = find(value >= 1, 1, 'last');

decimalFormat = java.text.DecimalFormat();
decimalFormat.setGroupingUsed(false)
decimalFormat.setMaximumFractionDigits(2)
out = sprintf('%s %s', char(decimalFormat.format(value(idx))), unit{idx});
end


%% test
function bytestr_test

debugMsg

disp(bytestr(1e0))
disp(bytestr(1e1))
disp(bytestr(1e2))
disp(bytestr(1e3))
disp(bytestr(1e4))
disp(bytestr(1e5))
disp(bytestr(1e6))
disp(bytestr(1e9))
disp(bytestr(1e12))
end
