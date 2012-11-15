function varargout = eventTemplate(fcn, varargin)
%eventTemplate SIMPACT event function: 
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
    function [elements, msg] = eventTemplate_init(SDS, event)
        
        elements = 0;
        msg = '';
        P = event;
    end


%% eventTimes
    function eventTimes = eventTemplate_eventTimes(SDS,P0)        
        P.eventTimes = Inf;
        eventTimes = P.eventTimes;
    end

%% advance
    function eventTemplate_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end

%% fire
    function [SDS,P0] = eventTemplate_fire(SDS, P0)
        %After firing the eventTimes should be set to infinity
    end

end


%% properties
function [props,msg] = eventTemplate_properties
msg = '';
props.something = NaN;
end


%% name
function name = eventTemplate_name

name = 'TEMPLATE';
end
