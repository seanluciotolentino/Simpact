function varargout = eventIntroduction(fcn, varargin)
%eventIntroduction SIMPACT event function: HIV introduction
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
    function [elements, msg] = eventIntroduction_init(SDS, event)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        P.intro = event.number_of_introduced_HIV;
        P.intro_time = event.period_of_introduced_HIV;
        % ******* Function Handles *******
        [P.fireTransmission, msg] = spTools('handle', 'eventTransmission', 'fire');
       % ******* Variables & Constants *******
        P.rand = rand(1, P.intro)*(P.intro_time{2,2}-P.intro_time{2,1})+P.intro_time{2,1};
        P.eventTimes = inf(1, SDS.number_of_males + SDS.number_of_females, SDS.float);
        
       if P.enable
           eventIntroduction_enable(SDS);
       end
        
    end

%% get
    function X = eventIntroduction_get(t)
	X = P;
    end

%% restore
    function [elements,msg] = eventIntroduction_restore(SDS,X)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
      
	P = X;
	P.enable = false;
    [P.fireTransmission, msg] = spTools('handle', 'eventTransmission', 'fire');
    end

%% eventTimes
    function eventTimes = eventIntroduction_eventTimes(~, ~)
        eventTimes = P.eventTimes;        
    end


%% advance
    function eventIntroduction_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
       
    end


%% fire
    function [SDS, P0] = eventIntroduction_fire(SDS, P0)
        
        % ******* Indices *******
        if P0.index<=SDS.number_of_males;
            P0.male=P0.index;
            P0.female=0;
        else
            P0.female=P0.index-SDS.number_of_males;
            P0.male=0;
        end
        
        P0.introduce = true;
        [SDS, P0]=P.fireTransmission(SDS, P0);
        P0.introduce = false;
        P.eventTimes(P0.index)=Inf;
    end


%% enable
    function  eventIntroduction_enable(SDS)
        % Invoked by eventFormation_fire
                
        if ~P.enable
            return
        end
        maleBorn =  SDS.males.born;
        femaleBorn = SDS.females.born;
        ratio = P.gender_ratio/(P.gender_ratio+1);
        
        for ti = P.rand
            if rand<=ratio
                age = ti-maleBorn;
                prob = (interp1q([15 32 50]',[0 0.26 0]',age(1:SDS.initial_number_of_males)'))';
                prob(isnan(prob)) = 0;
                prob = cumsum(prob/sum(prob));
                infectedIdx = min(find(prob>rand));
                P.eventTimes(infectedIdx) = ti;
            else
                age = ti-femaleBorn;
                prob = (interp1q([15 27 55]',[0 0.33 0]',age(1:SDS.initial_number_of_females)'))';
                prob(isnan(prob)) = 0;
                prob = cumsum(prob/sum(prob));
                infectedIdx = min(find(prob>rand));
                P.eventTimes(infectedIdx+SDS.number_of_females) = ti;
            end          
        end      
        
    end

%% block
    function eventIntroduction_block(P0)
        % Invoked by eventDissolution_dump
        P.eventTimes(1, P0.index) = Inf;
    end


    end




%% properties
function [props, msg] = eventIntroduction_properties

msg = '';

props.number_of_introduced_HIV=10;
props.period_of_introduced_HIV = {'start' 'end'
    0, 3};
props.gender_ratio = 0.5;
end


%% name
function name = eventIntroduction_name

name = 'HIV introduction';
end

