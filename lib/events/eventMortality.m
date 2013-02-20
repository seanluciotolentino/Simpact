function varargout = eventMortality(fcn, varargin)
%EVENTMORTALITY SIMPACT event function: (AIDS) mortality
%
%   Implements init, eventTimes, advance, fire, update, name, properties.
%
%   See also modelHIV, eventAIDSmortality, eventBirth.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

persistent P

if nargin == 0
    return
end

switch fcn
    case 'handle'
        cmd = sprintf('@%s_%s', mfilename, varargin{1});
    otherwise
        cmd = sprintf('%s_%s(varargin{:})', mfilename, fcn);
end
[varargout{1:nargout}] = eval(cmd);


%% init
    function [elements, msg] = eventMortality_init(SDS, event)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        
        P.shape = ones(1, elements, SDS.float)*event.Weibull_shape_parameter;
        P.scale = ones(1, elements, SDS.float)*event.Weibull_scale_parameter;
        
        
        % ******* Function Handles *******
        P.weibull = spTools('handle', 'weibull');
        P.weibullEventTime = spTools('handle', 'weibullEventTime');
        %[P.blockFormation, thisMsg] = spTools('handle', 'eventFormation', 'block');
        [P.blockFormation, thisMsg] = spTools('handle', 'eventFormation', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.dumpDissolution, thisMsg] = spTools('handle', 'eventDissolution', 'dump');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.abortBirth, thisMsg] = spTools('handle', 'eventBirth', 'abort');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockAIDSmortality, thisMsg] = spTools('handle', 'eventAIDSmortality', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockCircumcision, thisMsg] = spTools('handle', 'eventCircumcision', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockARV, thisMsg] = spTools('handle', 'eventARV', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockARVstop, thisMsg] = spTools('handle', 'eventARVstop', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        %??? P.blockTransmission(P0)             % row or column
        
         [P.blockTest, thisMsg] = spTools('handle', 'eventTest', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
         [P.blockANC, thisMsg] = spTools('handle', 'eventANC', 'block');
         [P.blockMTCT, thisMsg] = spTools('handle', 'eventMTCT', 'block');
         [P.blockIntroduction, thisMsg] = spTools('handle', 'eventIntroduction', 'block');
         [P.abolishTransmission, thisMsg] = spTools('handle', 'eventTransmission', 'abolish');
         [P.blockDebut, thisMsg] = spTools('handle', 'eventDebut', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        % ******* Variables & Constants *******
        P.false = false(SDS.number_of_males, SDS.number_of_females);
        age0 = -[SDS.males.born, SDS.females.born];
        P.rand = rand(1, elements, SDS.float);
        % temporary
        P.scale(age0>=30) = P.scale(age0>=30) - 15;
        P.scale(age0<30) = P.scale(age0<30)-0.5*age0(age0<30);
        P.eventTimes = inf(SDS.number_of_males, SDS.number_of_females, SDS.float);
        if ~P.enable
            return
        end
        P.eventTimes = P.weibullEventTime(P.scale, P.shape, P.rand, 0);
        P.eventTimes = P.eventTimes-age0;
        P.eventTimes(isnan(age0)) = Inf;
    end
%% get
    function X = eventMortality_get(t)
	X = P;
    end

%% restore
    function [elements,msg] = eventMortality_restore(SDS,X)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
	P = X;
	P.enable = SDS.non_AIDS_mortality.enable;
        P.weibull = spTools('handle', 'weibull');
        P.weibullEventTime = spTools('handle', 'weibullEventTime');
        %[P.blockFormation, thisMsg] = spTools('handle', 'eventFormation', 'block');
        [P.blockFormation, thisMsg] = spTools('handle', 'eventFormation', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.dumpDissolution, thisMsg] = spTools('handle', 'eventDissolution', 'dump');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.abortBirth, thisMsg] = spTools('handle', 'eventBirth', 'abort');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockAIDSmortality, thisMsg] = spTools('handle', 'eventAIDSmortality', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockCircumcision, thisMsg] = spTools('handle', 'eventCircumcision', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockARV, thisMsg] = spTools('handle', 'eventARV', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockARVstop, thisMsg] = spTools('handle', 'eventARVstop', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        %??? P.blockTransmission(P0)             % row or column
        
         [P.blockTest, thisMsg] = spTools('handle', 'eventTest', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
         [P.blockANC, thisMsg] = spTools('handle', 'eventANC', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockMTCT, thisMsg] = spTools('handle', 'eventMTCT', 'block');
        if ~isempty(thisMsg)
            msg = sprintf('%s%s\n', msg, thisMsg);
        end
        [P.blockIntroduction, thisMsg] = spTools('handle', 'eventIntroduction', 'block');
         [P.abolishTransmission, thisMsg] = spTools('handle', 'eventTransmission', 'abolish');
         [P.blockDebut, thisMsg] = spTools('handle', 'eventDebut', 'block');
    end


%% eventTimes
    function eventTimes = eventMortality_eventTimes(~, ~)
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventMortality_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventMortality_fire(SDS, P0)
        % Invoked by eventAIDSmortality_fire
        %
        % * Set deceased time
        % * Break relations
        % * Set HIV transmission time to Inf
        % * Set AIDS mortality time to Inf
        % * Set conception time to Inf
        
        P0.subset = P.false;         
        % for formation
        P0.mortality = true;
        currentIdx = SDS.relations.time(:, SDS.index.stop) == Inf; %find relationships that haven't ended yet
        P.eventTimes(P0.index) = Inf;       % only cats have nine lifes
        P.blockAIDSmortality(P0)            % uses P0.index
        P.blockARV(P0)
        P.blockARVstop(P0)
        P.blockTest(P0)
        P.blockDebut(P0.index)
 %       P.blockIntroduction(P0)
        if P0.index <= SDS.number_of_males
            % ******* Male Passed Away *******
            P0.male = P0.index;
            P0.aliveMales(P0.male) = false;
            SDS.males.deceased(P0.male) = P0.now;
            P.blockCircumcision(P0)             % uses P0.male
            
            P0.subset(P0.male, :) = true;       % for formation
            P.blockFormation(P0)                % uses P0.subset
            
            for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.male) == P0.male))'
                % ******* end all his relations
                P0.female = SDS.relations.ID(relIdx, SDS.index.female);
                [SDS, P0] = P.dumpDissolution(SDS, P0);% uses P0.male; P0.female
            end
            
            P0.female = [];

        else
            % ******* Female Passed Away *******
            P0.female = P0.index - SDS.number_of_males;
            P0.aliveFemales(P0.female) = false;
            SDS.females.deceased(P0.female) = P0.now;
            P.abortBirth(P0)                    % uses P0.female
            P.blockANC(P0)
            P.blockMTCT(SDS,P0.female);
            P0.subset(:, P0.female) = true;     % for formation
            P.blockFormation(P0)                % uses P0.subset
            
            for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.female) == P0.female))'
                % ******* end all her relations
                P0.male = SDS.relations.ID(relIdx, SDS.index.male);
                [SDS, P0] = P.dumpDissolution(SDS, P0);% uses P0.male; P0.female
            end
            
            P0.male = [];
        end
        
        P.abolishTransmission(SDS, P0);
        
    end


%% enable
    function eventMortality_enable(P0)
        % Invoked by eventBirth_fire
        
        if ~P.enable
            return
        end        
        
        t = P.weibullEventTime(...
            P.scale(P0.index), P.shape(P0.index), P.rand(P0.index), 0);
        P.eventTimes(P0.index) = t;
        
    end
end


%% name
function name = eventMortality_name

name = 'non AIDS mortality';
end


%% properties
function [props, msg] = eventMortality_properties

msg = '';

props.Weibull_shape_parameter = 4;
props.Weibull_scale_parameter = 70;
end

