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
    end


%% eventTime
    function eventTime = eventTemplate_eventTime(SDS)
        
        eventTime = Inf;
    end


%% fire
    function SDS = eventTemplate_fire(SDS, leader, event)
        
    end


%% internalClock
    function eventTemplate_internalClock(time)
        
    end
end


%% properties
function props = eventTemplate_properties

props.something = NaN;
end


%% name
function name = eventTemplate_name

name = 'TEMPLATE';
end
