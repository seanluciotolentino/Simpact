function varargout = eventARVstop(fcn, varargin)
%eventARVstop SIMPACT event function: ARVstop
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
    function [elements, msg] = eventARVstop_init(SDS, event)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        
        P = event;                  % copy event parameters
       
        P.scale = P.lifetime_extension_by_ARV{2,1};
        P.shape =P.lifetime_extension_by_ARV{2,2};
        P.weibullEventTime = spTools('handle','weibullEventTime');

        P.randLife = rand(1,elements);
        P.rand = rand(1,elements, SDS.float);
        P.optionB  = false(1, SDS.number_of_females);
       
        % parameters for hazard function of ARV drop out
        P.dropOutRate = event.drop_out_rate;
        P.eventTimes = inf(1, elements, SDS.float);
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        [P.updateMTCT, msg] = spTools('handle', 'eventMTCT', 'update');
        [P.enableTest, msg] = spTools('handle', 'eventTest', 'enable');
        [P.fireTest, msg] = spTools('handle', 'eventTest', 'fire');
        [P.setupMTCT,msg] = spTools('handle','eventMTCT','setup');
        [P.enableAIDSmortality, msg] = spTools('handle', 'eventAIDSmortality', 'enable');


    end

%% get
    function X = eventARVstop_get(t)
	X = P;
    end

%% restore
    function [elements,msg] = eventARVstop_restore(SDS,X)
        
        elements = SDS.number_of_males + SDS.number_of_females;
        msg = '';
        P = X;
        P.weibullEventTime = spTools('handle','weibullEventTime');
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
        [P.updateMTCT, msg] = spTools('handle', 'eventMTCT', 'update');
        [P.enableTest, msg] = spTools('handle', 'eventTest', 'enable');
        [P.fireTest, msg] = spTools('handle', 'eventTest', 'fire');
        [P.setupMTCT,msg] = spTools('handle','eventMTCT','setup');
        [P.enableAIDSmortality, msg] = spTools('handle', 'eventAIDSmortality', 'enable');

    end
%% eventTimes
    function eventTimes = eventARVstop_eventTimes(~, ~)
        
        
        eventTimes = P.eventTimes;
    end


%% advance
    function eventARVstop_advance(P0)
        % Also invoked when this event isn't fired.
        % 

        P.eventTimes = P.eventTimes - P0.eventTime;
    end


%% fire
    function [SDS, P0] = eventARVstop_fire(SDS, P0)
        if ~P.enable
            return
        end
        P0.ARV(P0.index) = false;
        if P0.index<=SDS.number_of_males
            P0.male = P0.index;
            P0.female = NaN;
            SDS.males.ARV_stop(P0.male) = P0.now;   
            SDS.males.ARV(P0.index) = false;
        else
            P0.female = P0.index - SDS.number_of_males;
            P0.male = NaN;
            SDS.females.ARV_stop(P0.female) = P0.now;
            SDS.females.ARV(P0.female) = false;
        end
         ARVs = max(find(SDS.ARV.ID==P0.index));
         SDS.ARV.time(ARVs, 2) = P0.now;
         eventARVstop_block(P0); %uses P0.index
         
        currentIdx = SDS.relations.time(:, SDS.index.stop) == Inf; 
          if P0.index<= SDS.number_of_males
              P0.male = P0.index;
              timeDeath = SDS.males.AIDSdeath(P0.male);
              timeHIVpos = SDS.males.HIV_positive(P0.male);
            
              SDS.males.AIDSdeath(P0.male) = spTools('weibullEventTime', (timeDeath+timeHIVpos-P0.now)/P.scale, P.shape, P.rand(P0.index),0) + P0.now-timeHIVpos;
              P.enableAIDSmortality(P0,SDS.males.AIDSdeath(P0.male)) 
              SDS.males.ARV(P0.male) = false;
              SDS.ARV.life_year_saved(ARVs) = SDS.ARV.life_year_saved(ARVs) - timeDeath + SDS.males.AIDSdeath(P0.male);
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
          for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.male) == P0.male) &...
                  ismember(SDS.relations.ID(:, SDS.index.female),find(isnan(SDS.females.HIV_positive))))'              
                P0.female = SDS.relations.ID(relIdx, SDS.index.female);
                if P0.serodiscordant(P0.male, P0.female)
                [SDS,P0] = P.updateTransmission(SDS, P0);   % uses P0.male; P0.female
                end
          end
          else
              P0.female = P0.index - SDS.number_of_males;
              timeDeath = SDS.females.AIDSdeath(P0.female);
              timeHIVpos = SDS.females.HIV_positive(P0.female);
              SDS.females.AIDSdeath(P0.female) = spTools('weibullEventTime', (timeDeath+timeHIVpos-P0.now)/P.scale, P.shape, P.rand(P0.index),0) + P0.now-timeHIVpos;
              P.enableAIDSmortality(P0,SDS.females.AIDSdeath(P0.female)) 
              SDS.ARV.life_year_saved(ARVs) = SDS.ARV.life_year_saved(ARVs) - timeDeath + SDS.females.AIDSdeath(P0.female);
              SDS.females.ARV(P0.female) = false;
              P.updateMTCT(SDS, P0);
              
              CD4Infection = SDS.females.CD4Infection(P0.female);
              CD4Death = SDS.females.CD4Death(P0.female);
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
              
              
              if P0.optionB(P0.female)
                  [SDS, P0] = P.fireTest(SDS,P0);
                  P0.optionB(P0.female) = false;
              end
             
               for relIdx = find(currentIdx & (SDS.relations.ID(:, SDS.index.female) == P0.female) &...
                  ismember(SDS.relations.ID(:, SDS.index.male),find(isnan(SDS.males.HIV_positive))))'              
                P0.male = SDS.relations.ID(relIdx, SDS.index.male);
                if P0.serodiscordant(P0.male, P0.female)
                [SDS,P0] = P.updateTransmission(SDS, P0);    % uses P0.male; P0.female
                end
                end
          end
        
%           P.enableARV(P0,t); 
          
    end


%% enable
    function eventARVstop_enable(SDS, P0)
        if ~P.enable
            return
        end
        optionB = false;
        if P0.index>SDS.number_of_males
            optionB = P0.optionB(P0.index-SDS.number_of_males);
        end
        if optionB
            breastfeedingTime = P.setupMTCT(P0.female);
            P.eventTime(P0.index)  = P0.thisPregnantTime(P0.female) + breastfeedingTime + 41/52 - P0.now;            
        else
        P.eventTimes(P0.index) = log(1-rand)/log(1-P.dropOutRate);
        end
    end


%% block
    function eventARVstop_block(P0)
        % Invoked by event
      P.eventTimes(P0.index) = Inf;

    end
end


%% properties
function [props, msg] = eventARVstop_properties

props.drop_out_rate = .05;
props.lifetime_extension_by_ARV = {
'scale factor' 'shape'
2                    4
};

msg = 'Treatment implemented by ARVstop event.';
end


%% name
function name = eventARVstop_name

name = 'ARV stop';
end
