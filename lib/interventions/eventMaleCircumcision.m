function varargout = eventMaleCircumcision(fcn, varargin)
%EVENTTRANSMISSION SIMPACT event function: HIV transmission
%
% See also spGui, spRun, spModel, spTools.

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
function [elements,msg] = eventMaleCircumcision_init(SDS,event)
    msg = '';   %I'm not sure this is necessary-- we might need it?
    elements = 1;
    if ~SDS.events.male_circumcision.enable; return ; end
    
    P = event;
    P.executed = false;
    [P.updateCircumcision, msg] = spTools('handle', 'eventCircumcision', 'update');
    [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
    
    %initialize things within circumcision event
    SDS.events.male_circumcision.campaign_start_date = P.start_date; %this is changing the event
    SDS.events.male_circumcision.campaign_roll_out_duration = P.duration;
    SDS.events.male_circumcision.campaign_scale_factor = P.scale;
    SDS.events.male_circumcision.Cauchy_peak_age = 15;

end


%% eventTime
    function eventTimes = eventMaleCircumcision_eventTimes(SDS,P0)
        eventTimes = Inf;
    end

%% advance
    function eventMaleCircumcision_advance(P0)
        return;
    end
	

%% execute
function [SDS, P0] = eventMaleCircumcision_execute(SDS, P0)
    if P.executed || ~SDS.male_circumcision.enable
        return
    else
        %nothing needs to actually happen here because it was implemented
        %in the event
        
        
        % SDS.male_circumcision.campaign_start_date = P.start_date; %this is changing the event
        % SDS.male_circumcision.campaign_roll_out_duration = P.duration;
        % SDS.male_circumcision.campaign_scale_factor = P.scale;
        % 
        % new_date = P0.now;
        % feval(P.updateCircumcision,new_date,P.duration,P.scale)
        
        
        % PICK RANDOM MALES AND CIRCUMCISE THEM:
        % updated = (rand(1,SDS.number_of_males) < P.percentage_reached) * P0.now; %find a random subset than set their circumcision time to now
        % SDS.males.circumcision(updated>0) = updated(updates>0); %circumcise a fraction of males now
        % for m = find(SDS.males.condom)%all the males we influenced
        %     %Code stolen from eventMortality for finding all relationships
        %     P0.male = m;
        %     activeRelationships = SDS.relations.time(:, SDS.index.stop) == Inf;
        %     for r = find(activeRelationships & (SDS.relations.ID(:, SDS.index.male) == P0.male))'
        %         P0.female = SDS.relations.ID(r, SDS.index.female);
        %         [SDS, P0] = P.updateTransmission(SDS, P0);% uses P0.male; P0.female
        %     end
        % 
        % end
        
        %disp('CIRCUMCISION INTERVENTION IMPLEMENTED')
        P.executed = true;
    end %end else
    
end %end execute function
        

%% properties
function [props, msg] = eventMaleCircumcision_properties

msg = '';

props.start_date = '26-Jun-2050'; %default is off
props.duration = 5;
props.scale = 1;

props.percentage_reached = .1; %is this h


end


%% name
function name = eventMaleCircumcision_name
name = 'Male_Circumcision_Campaign';
end

end

