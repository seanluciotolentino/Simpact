function varargout = eventKickstart(fcn, varargin)
%eventKickstart SIMPACT event function: 
%
%   Implements init, eventTime, fire, internalClock, properties, name.
%   
%   See also SIMPACT, spRun, modelHIV, spTools.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

persistent P

switch fcn
    case 'handle'
        cmd = sprintf('@%s_%s', mfilename, varargin{1});
    otherwise
        cmd = sprintf('%s_%s(varargin{:})', mfilename, fcn);
end
[varargout{1:nargout}] = eval(cmd);


%% init
    function [elements, msg] = eventKickstart_init(SDS, event)
        
        elements = 1;
        msg = '';
        P = event;
        P.eventTimes = 0;
    end


%% eventTimes
    function eventTimes = eventKickstart_eventTimes(SDS,P0)        
        %P.eventTimes = Inf;
        eventTimes = P.eventTimes;
    end

%% advance
    function eventKickstart_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end

%% fire
    function [SDS,P0] = eventKickstart_fire(SDS, P0)
        %Nothing actually happens, formation just needs an event to occur
        %before it starts
        P.eventTimes = Inf;
    end

%% get
    function X = eventKickstart_get(t)
        X = P;
    end
end


%% properties
function [props,msg] = eventKickstart_properties
msg = '';
props.something = NaN;
end


%% name
function name = eventKickstart_name

name = 'kickstart';
end
