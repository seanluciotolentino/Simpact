function varargout = eventARVtemp(fcn, varargin)
% This is a temporary ARV intervention to use while Fei is finishing her
% implementation which is probably much better. This intervention finds
% HIV_postive people and starts them on ART. 
%
% PARAMETERS:
%   start_date
%   spend

persistent P

switch fcn
    case 'handle'
        cmd = sprintf('@%s_%s', mfilename, varargin{1});
    otherwise
        cmd = sprintf('%s_%s(varargin{:})', mfilename, fcn);
end
[varargout{1:nargout}] = eval(cmd);


%% init
    function [elements, msg] = eventARVtemp_init(SDS, event)
        elements = 1;
        msg = '';
        P = event;
        P.eventTimes = spTools('dateTOsimtime',P.start_date,SDS.start_date); %gives the start time in sim time
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        P.num_arv = P.coverage;
    end


%% eventTime
    function eventTimes = eventARVtemp_eventTimes(SDS,P0)
        eventTimes = P.eventTimes;
    end

%% advance
    function eventARVtemp_advance(P0)
        P.eventTimes = P.eventTimes - P0.eventTime;
    end

%% fire
    function [SDS,P0] = eventARVtemp_fire(SDS, P0)        
        if P.num_arv<= 0 %if you run out of condoms this campaign is over
            P.eventTimes = Inf;
            return
        end
        %disp('FIRE!')
        %give ARV to HIV pos males:
        for m = 1:SDS.number_of_males %for all males
            r = rand;
            %if (he is HIV positive)               && (we find him)
            if (SDS.males.HIV_positive(m)<=P0.now) && (r < P.finding_effectiveness) && ~SDS.males.ARV(m)
                SDS.males.ARV(m) = 1; %give this guy one of your arvs
                P.num_arv = P.num_arv-1;
                if P.num_arv<= 0 %if you run out of ARV this campaign is over
                    break
                end
            end
        end
        
        %given ARV to HIV pos females 
        for f = 1:SDS.number_of_females %for all females
            r = rand;
            %if (she is HIV positive)               && (we find her)
            if (SDS.females.HIV_positive(f)<=P0.now) && (r < P.finding_effectiveness)&& ~SDS.females.ARV(f)
                SDS.females.ARV(f) = 1; %give this guy one of your ARV
                P.num_arv = P.num_arv-1;
                if P.num_arv<= 0 %if you run out of ARV this campaign is over
                    break
                end
            end
        end
        
        %update relationships
        activeRelationships = SDS.relations.time(:, SDS.index.stop) == Inf;
        for r =find(activeRelationships)'
            P0.male = SDS.relations.ID(r, SDS.index.male);
            P0.female = SDS.relations.ID(r, SDS.index.female);
            if SDS.males.ARV(P0.male) || SDS.females.ARV(P0.female)
                [SDS, P0] = P.updateTransmission(SDS, P0);% uses P0.male; P0.female
            end
        end
        
        P.eventTimes = Inf;
        %P.eventTimes = P.eventTimes + 1; %do this again in a year
    end

end


%% properties
function [props,msg] = eventARVtemp_properties
msg = '';

props.start_date = '26-Jun-2050'; %default is off
props.coverage = 0; %default is spending nothing
props.finding_effectiveness = 1;

end


%% name
function name = eventARVtemp_name

name = 'ARV temp';
end
