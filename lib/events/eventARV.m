function varargout = eventARV(fcn, varargin)
%eventARV SIMPACT event function: ARV
%
% See also SIMPACT, spRun, spTools, modelHIV.

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
    function [elements, msg] = eventARV_init(SDS, event)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
        % CD4 distribution at infection
        P.eventTimes = Inf(1, elements, SDS.float);
        [P.setupTransmission, msg] = spTools('handle', 'eventTransmission', 'setup');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        [P.updateMTCT, msg] = spTools('handle', 'eventMTCT', 'update');

        [P.enableAIDSmortality, msg] = spTools('handle', 'eventAIDSmortality', 'enable');
        [P.enableARVstop, msg] = spTools('handle', 'eventARVstop', 'enable');
        P.scale = P.lifetime_extension_by_ARV{2,1};
        P.shape =P.lifetime_extension_by_ARV{2,2};
        P.weibullEventTime = spTools('handle','weibullEventTime');

        P.rand = rand(1,elements);
         P.ARVs = find(SDS.ARV.ID, 1, 'last');
        if isempty(P.ARVs)
            P.ARVs = 0;
        end
    end

%% get
    function X = eventARV_get(t)
	X = P;
    end

%% restore
    function [elements,msg] = eventARV_restore(SDS, X)
       
 
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = X;
        P.enable = SDS.ARV_treatment.enable;
        [P.setupTransmission, msg] = spTools('handle', 'eventTransmission', 'setup');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        [P.updateMTCT, msg] = spTools('handle', 'eventMTCT', 'update');

        [P.enableAIDSmortality, msg] = spTools('handle', 'eventAIDSmortality', 'enable');
        [P.enableARVstop, msg] = spTools('handle', 'eventARVstop', 'enable');
        P.weibullEventTime = spTools('handle','weibullEventTime');
    end
%% eventTimes
    function eventTimes = eventARV_eventTimes(~, ~)
        
        %subset = P0.subset & P0.current;    % what about relations braking up?
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventARV_advance(P0)
        % Also invoked when this event isn't fired.
        
        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventARV_fire(SDS, P0)
      
        
        if P0.index<=SDS.number_of_males
            alive = P0.aliveMales(P0.index);
        else
            alive = P0.aliveFemales(P0.index-SDS.number_of_males);
        end
        if ~P.enable||P0.now<P.ARV_program_start_time||~alive
            return
        end
        
       P0.ARV(P0.index)=true;
        
        P.ARVs = P.ARVs +1;
        SDS.ARV.ID(P.ARVs) = P0.index;
        SDS.ARV.time(P.ARVs,1) = P0.now;
        currentIdx = SDS.relations.time(:, SDS.index.stop) == Inf;
          P.enableARVstop(SDS, P0)      
          
          if P0.index<= SDS.number_of_males
              P0.male = P0.index;
              P0.female=NaN;
              SDS.males.ARV_start(P0.male)= P0.now;
              SDS.males.ARV(P0.male) = true;
              if isnan(SDS.males.AIDSdeath(P0.male))
                  SDS = P.setupTransmission(SDS,P0);
              end
              timeDeath = SDS.males.AIDSdeath(P0.male);
              timeHIVpos = SDS.males.HIV_positive(P0.male);
              
              SDS.males.AIDSdeath(P0.male) = spTools('weibullEventTime', (timeDeath+timeHIVpos-P0.now)*P.scale, P.shape, P.rand(P0.index),0) + P0.now-timeHIVpos;         
               CD4Infection = SDS.males.CD4Infection(P0.male);
              CD4Death = SDS.males.CD4Death(P0.male);
              if P0.now<= SDS.males.CD4_500(P0.male)
                  [SDS.males.CD4_500(P0.male),SDS.males.CD4_350(P0.male),SDS.males.CD4_200(P0.male)]=...
                  CD4Interp(CD4Infection,CD4Death,SDS.males.AIDSdeath(P0.male),P0.now);
              else
                  if P0.now<= SDS.males.CD4_350(P0.male)
                      [~,SDS.males.CD4_350(P0.male),SDS.males.CD4_200(P0.male)]=...
                  CD4Interp(CD4Infection,CD4Death,SDS.males.AIDSdeath(P0.male),P0.now);
                  else
                      if P0.now<= SDS.males.CD4_200(P0.male)
                          [~,~,SDS.males.CD4_200(P0.male)]=...
                  CD4Interp(CD4Infection,CD4Death,SDS.males.AIDSdeath(P0.male),P0.now);
                      end
                  end                                                 
              end
              
              
              P.enableAIDSmortality(P0,SDS.males.AIDSdeath(P0.male)-(P0.now-timeHIVpos)) 
              SDS.ARV.life_year_saved(P.ARVs) = SDS. person_years_aquired - timeDeath + SDS.males.AIDSdeath(P0.male);
              
              for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.male) == P0.male) &...
                  ismember(SDS.relations.ID(:, SDS.index.female),find(isnan(SDS.females.HIV_positive))))'
              P0.female = SDS.relations.ID(relIdx, SDS.index.female);  
              if P0.serodiscordant(P0.male, P0.female)
                  [SDS, P0] = P.updateTransmission(SDS, P0);
              end
              end
             
          else
              P0.female = P0.index - SDS.number_of_males;
              P0.male = NaN;
              SDS.females.ARV_start(P0.female)= P0.now;
              SDS.females.ARV(P0.female) = true;
              P.updateMTCT(SDS, P0);
            
              if isnan(SDS.females.AIDSdeath(P0.female))
                  SDS = P.setupTransmission(SDS,P0);
              end
              timeDeath = SDS.females.AIDSdeath(P0.female);
              timeHIVpos = SDS.females.HIV_positive(P0.female);
              CD4Infection = SDS.females.CD4Infection(P0.female);
              CD4Death = SDS.females.CD4Death(P0.female);
              SDS.females.AIDSdeath(P0.female) = spTools('weibullEventTime', (timeDeath+timeHIVpos-P0.now)*P.scale, P.shape, P.rand(P0.index),0) + P0.now-timeHIVpos;
              P.enableAIDSmortality(P0,SDS.females.AIDSdeath(P0.female)-(P0.now-timeHIVpos)) 
              SDS.ARV.life_year_saved(P.ARVs) = SDS. person_years_aquired - timeDeath + SDS.females.AIDSdeath(P0.female);
              
              if P0.now<= SDS.females.CD4_500(P0.female)
                  [SDS.females.CD4_500(P0.female),SDS.females.CD4_350(P0.female),SDS.females.CD4_200(P0.female)]=...
                  CD4Interp(CD4Infection,CD4Death,SDS.females.AIDSdeath(P0.female),P0.now);
              else
                  if P0.now<= SDS.females.CD4_350(P0.female)
                      [~,SDS.females.CD4_350(P0.female),SDS.females.CD4_200(P0.female)]=...
                  CD4Interp(CD4Infection,CD4Death,SDS.females.AIDSdeath(P0.female),P0.now);
                  else
                      if P0.now<= SDS.females.CD4_200(P0.female)
                          [~,~,SDS.females.CD4_200(P0.female)]=...
                  CD4Interp(CD4Infection,CD4Death,SDS.females.AIDSdeath(P0.female),P0.now);
                      end
                  end                                                 
              end
              
              for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.female) == P0.female) &...
                  ismember(SDS.relations.ID(:, SDS.index.male),find(isnan(SDS.males.HIV_positive))))'
              P0.male = SDS.relations.ID(relIdx, SDS.index.male);
              if P0.serodiscordant(P0.male, P0.female)
                  [SDS, P0] = P.updateTransmission(SDS, P0);
              end
              end
          end    
          if timeDeath<=0.25
              SDS.ARV.CD4(P.ARVs) = interp1q([0 timeDeath]',[CD4Infection CD4Death]', P0.now-timeHIVpos);
          else
              SDS.ARV.CD4(P.ARVs) = interp1q([0 0.25 timeDeath]', [CD4Infection 0.75*CD4Infection CD4Death]',P0.now-timeHIVpos);
          end
          
          if SDS.ARV.CD4(P.ARVs) ==0
         SDS.ARV.CD4(P.ARVs)  ==0
          end
          eventARV_block(P0); %uses P0.index               
    end


%% enable
    function eventARV_enable(P0,t)
        % Invoked by eventTest
        if ~P.enable
            return
        end
        if P0.now>=P.ARV_program_start_time
        P.eventTimes(P0.index) = t;
        else
         % temp !!!
        P.eventTimes(P0.index) = t + P.ARV_program_start_time - P0.now;  
        end

    end


%% block
    function eventARV_block(P0)
        % Invoked by event
       P.rand(P0.index) = Inf;
      P.eventTimes(P0.index) = Inf;
     
    end
end


%% properties
function [props, msg] = eventARV_properties
props.ARV_program_start_time = 2;
props.lifetime_extension_by_ARV = {
'scale factor' 'shape'
2                  4
};
msg = 'Treatment implemented by ARV event.';
end


%% name
function name = eventARV_name

name = 'ARV treatment';
end



