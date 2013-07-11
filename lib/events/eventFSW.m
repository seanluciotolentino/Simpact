function varargout = eventFSW(fcn, varargin)
%eventFSW SIMPACT event function: FSW
%
% See also spGui, spRun, spModel, spTools.

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
    function [elements, msg] = eventFSW_init(SDS, event)
        
        elements = SDS.number_of_females;
        msg = '';
        
        P = event; % copy event parameters
        
        % ******* Function Handles *******
        [P.updateFormation, msg] = spTools('handle', 'eventFormation', 'update');
        [P.updateDissolution, msg] = spTools('handle', 'eventDissolution', 'update');
        P.rand0toInf = spTools('handle', 'rand0toInf');
        P.expLinear = spTools('handle', 'expLinear');
        P.intExpLinear = spTools('handle', 'intExpLinear');
        P.expLinearStop = spTools('handle', 'expLinear');
        P.alpha = event.baseline_factor*ones(1,elements);
        P.beta = event.time_factor*ones(1,elements);
        P.age_factor = event.age_factor;
        P.alphaStop = event.baseline_factor_stop_working*ones(1,elements);
        P.betaStop = event.time_factor_stop_working*ones(1,elements);
        if P.beta == 0
            P.expLinear = spTools('handle', 'expConstant');
            P.intExpLinear = spTools('handle', 'intExpConstant');
        end
        if P.betaStop == 0
            P.expLinearStop = spTools('handle', 'expConstant');
        end
        
        P.eventTimes = Inf(1,elements);
        % ******* Variables & Constants *******
        
        P.max = event.maximal_number_of_fsw;
        P.rand = P.rand0toInf(1,elements);
        P.randStop = P.rand0toInf(1,elements);
        ageSince15 = -SDS.females.born -15;
        ageSince15(ageSince15<=0) = Inf;
        P.eventTimes = P.expLinear(P.alpha,P.beta,ageSince15,P.rand);
        
    end

%% get
    function X = eventFSW_get(t)
        
        X = P;
    end

%% restore
    function [elements,msg] = eventFSW_restore(SDS,X)
        
        elements = SDS.number_of_females;
        msg = '';
        
        P = X;
        P.enable = SDS.FSW.enable;
        [P.updateFormation, msg] = spTools('handle', 'eventFormation', 'update');
        [P.updateDissolution, msg] = spTools('handle', 'eventDissolution', 'update');
    end

%% eventTimes
    function eventTimes = eventFSW_eventTimes(~, ~)
        eventTimes = P.eventTimes;
    end


%% advance
    function eventFSW_advance(P0)
        % Also invoked when this event isn't fired.
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventFSW_fire(SDS, P0)
        if ~P0.fsw(P0.index)
            % becoming fsw
            if sum(P0.fsw)>=P.max
                P.rand(P0.index)=P.rand0toInf(1,1);
                eventFSW_enable(SDS,P0,P0.index);
                return
            end
            SDS.females.sex_worker(P0.index) = true;
            P0.fsw(P0.index) = true;
            P0.transactionSex(:,P0.index) =1;
            for male = find(P0.aliveMales)
                P0.male = male;
                P0.female = P0.index;
                P0 = P.updateFormation(SDS,P0,3);
                P0 = P.updateDissolution(P0);
            end
            eventFSW_retire(P0);
        else
            % stop being fsw
            P0.fsw(P0.index)=false;
            P0.transactionSex(:,P0.index) =0;
            for male = find(P0.aliveMales)
                P0.male = male;
                P0.female = P0.index;
                P0 = P.updateFormation(SDS,P0,3);
                P0 = P.updateDissolution(P0);
            end
            P.rand(P0.index)=P.rand0toInf(1,1);
            eventFSW_enable(SDS,P0,P0.index);
        end
        
    end


%% enable
    function eventFSW_enable(SDS, P0, index)
        ageSince15 = P0.femaleAge(1,index)-15;
            P.alpha(index) = P.alpha(index)+P.age_factor*ageSince15;
            P.eventTimes(index) = P.expLinear(P.alpha(index),P.beta(index),0,P.rand(index));

    end

%% retire
    function eventFSW_retire(P0)
        %P.eventTimes(P0.index) = 1;
        P.eventTimes(P0.index) = P.expLinearStop(P.alphaStop(P0.index),P.betaStop(P0.index),0,P.randStop(P0.index));
        
    end
end


%% properties
function [props, msg] = eventFSW_properties

msg = '';

props.baseline_factor = log(0.1);
props.time_factor = 0;
props.age_factor = log(0.2);
props.baseline_factor_stop_working = log(0.1);
props.time_factor_stop_working = 0;
props.maximal_number_of_fsw = 3;

end


%% name
function name = eventFSW_name

name = 'FSW';
end
