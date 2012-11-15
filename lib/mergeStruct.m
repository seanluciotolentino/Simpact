function out = mergeStruct(varargin)
%MERGESTRUCT

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    mergeStruct_test
    return
end

out = varargin{1};
varargin(1) = [];
%fields = fieldnames(out);

for thisStructC = varargin
    thisStruct = thisStructC{1};
    
    for thisFieldC = fieldnames(thisStruct)'
        thisField = thisFieldC{1};
        idx = 1;
        
        if isfield(out, thisField)
        %if any(strcmp(thisField, fields))
            for thisIdx = 1 : numel(out)
                idx = thisIdx;
                if isempty(out(thisIdx).(thisField))
                    break
                end
            end
        end
        out(idx).(thisField) = thisStruct.(thisField);
    end
end


%%
    function mergeStruct_
        
        debugMsg
        
        % ******* *******
        
    end
end


%% test
function mergeStruct_test

debugMsg

S1.a = 123;
S2.b = 456;
S3.b = 789;
S3.c = 'qwe';

S = mergeStruct(S1, S2, S3);
S(1)
S(2)
end
