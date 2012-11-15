function varargout = eventCondom(fcn, varargin)
% This is the most basic version of a condom distribution in which we just
% attempt to reach a random subset of the population -- no targeting at
% all.
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
    function [elements, msg] = eventCondom_init(SDS, event)
        elements = 5;
        msg = '';
        P = event;
        
        %god forgive me for the hack I am about to do:
        P.starts = [spTools('dateTOsimtime',P.start_spend{1,1},SDS.start_date); %gives the start time in sim time <-- doesn't get updated
                    spTools('dateTOsimtime',P.start_spend{2,1},SDS.start_date);
                    spTools('dateTOsimtime',P.start_spend{3,1},SDS.start_date);
                    spTools('dateTOsimtime',P.start_spend{4,1},SDS.start_date);
                    spTools('dateTOsimtime',P.start_spend{5,1},SDS.start_date)];
        
        P.eventTimes = P.starts; %gives the start time in sim time
        [P.updateTransmission, msg] = spTools('handle', 'eventTransmission', 'update');
    
		%eventually this will be a cost to condoms function -- currently costs are 
		%calculated after we decide how many condoms we want to distribute
        P.num_condoms = P.start_spend(:,2); 
        
    end


%% eventTime
    function eventTimes = eventCondom_eventTimes(SDS,P0)
        eventTimes = P.eventTimes;
    end

%% advance
    function eventCondom_advance(P0)
        P.eventTimes = P.eventTimes - P0.eventTime;
    end
	
%% fire (main)
	function [SDS,P0] = eventCondom_fire(SDS,P0)
        [~,cd] = min(P.eventTimes); %find the CD that is being fired now
        [SDS,P0] = eval(sprintf('eventCondom%i_fire(SDS,P0)',cd));
        P.eventTimes(cd) = Inf;
	end

%% fire1
    function [SDS,P0] = eventCondom1_fire(SDS, P0)    
		pop = SDS.initial_number_of_males + SDS.initial_number_of_females; %only in the case where nobody is born
        percentage_reached = (P.start_spend{1,2}/pop);    
        if percentage_reached<= 0 %if you run out of condoms this campaign is over
            return
        end
        
        SDS.males.condom = rand(1,SDS.number_of_males)<percentage_reached;
        SDS.females.condom = rand(1,SDS.number_of_females)<percentage_reached;
                
        malesfound = rand(1,SDS.number_of_males) < P.finding_effectiveness;
        femalesfound = rand(1,SDS.number_of_females) < P.finding_effectiveness;
        
        SDS.males.condom = SDS.males.condom & malesfound;
        SDS.females.condom = SDS.females.condom & femalesfound;
                
        %update relationships
        activeRelationships = SDS.relations.time(:, SDS.index.stop) == Inf;
        for r =find(activeRelationships)'
            P0.male = SDS.relations.ID(r, SDS.index.male);
            P0.female = SDS.relations.ID(r, SDS.index.female);
            if SDS.males.condom(P0.male) || SDS.females.condom(P0.female)
                [SDS, P0] = P.updateTransmission(SDS, P0);% uses P0.male; P0.female
            end
        end
        
        if (isfield(SDS,'unused_condoms'))
            SDS.unused_condoms = SDS.unused_condoms + 0;
        end
    end

%% fire2
    function [SDS,P0] = eventCondom2_fire(SDS, P0)  
		num_condoms = P.num_condoms{2};
        if num_condoms<= 0 %if you run out of condoms this campaign is over
            return
        end
        
        %give condoms to high risk males:
        for m = 1:SDS.number_of_males %for all males
            r = rand;
            %if (he is in concurrent relationships)                         %&& (we find him)
            if (sum(SDS.relations.ID(:,SDS.index.male)==m)>P.risk_threshold) && (r < P.finding_effectiveness)
                SDS.males.condom(m) = 1; %give this guy one of your condoms
                P0.male = m;
                num_condoms = num_condoms-1;
                if num_condoms<= 0 %if you run out of condoms this campaign is over
                    break
                end
                
                
            end
        end
        
        %given condoms to high risk females  %does it matter that this goes second?
        for f = 1:SDS.number_of_females %for all females
            r = rand;
            %if (she is in concurrent relationships)                         %&& (we find her)
            if (sum(SDS.relations.ID(:,SDS.index.male)==f)>P.risk_threshold) && (r < P.finding_effectiveness)
                SDS.females.condom(f) = 1; %give this guy one of your condoms
                P0.female = f;
                num_condoms = num_condoms-1;
                if num_condoms<= 0 %if you run out of condoms this campaign is over
                    break
                end
            end
        end
        
        %update relationships
        activeRelationships = SDS.relations.time(:, SDS.index.stop) == Inf;
        for r =find(activeRelationships)'
            P0.male = SDS.relations.ID(r, SDS.index.male);
            P0.female = SDS.relations.ID(r, SDS.index.female);
            if SDS.males.condom(P0.male) || SDS.females.condom(P0.female)
                [SDS, P0] = P.updateTransmission(SDS, P0);% uses P0.male; P0.female
            end
        end
        
        if (isfield(SDS,'unused_condoms'))
            SDS.unused_condoms = SDS.unused_condoms + num_condoms;
        end
        %disp(num_condoms);
    end
	
%% fire3
    function [SDS,P0] = eventCondom3_fire(SDS, P0)   
		num_condoms = P.num_condoms{3};
        if num_condoms<= 0 %if you run out of condoms this campaign is over
            return
        end
        
        %give condoms to HIV pos males:
        for m = 1:SDS.number_of_males %for all males
            r = rand;
            %if (he is HIV positive)               && (we find him)
            if (SDS.males.HIV_positive(m)<=P0.now) && (r < P.finding_effectiveness)
                SDS.males.condom(m) = 1; %give this guy one of your condoms
                num_condoms = num_condoms-1;
                if num_condoms<= 0 %if you run out of condoms this campaign is over
                    break
                end
        
        
            end
        end
        
        %given condoms to HIV pos females 
        for f = 1:SDS.number_of_females %for all females
            r = rand;
            %if (she is HIV positive)               && (we find her)
            if (SDS.females.HIV_positive(f)<=P0.now) && (r < P.finding_effectiveness)
                SDS.females.condom(f) = 1; %give this guy one of your condoms
                num_condoms = num_condoms-1;
                if num_condoms<= 0 %if you run out of condoms this campaign is over
                    break
                end
            end
        end
        
        %update relationships
        activeRelationships = SDS.relations.time(:, SDS.index.stop) == Inf;
        for r =find(activeRelationships)'
            P0.male = SDS.relations.ID(r, SDS.index.male);
            P0.female = SDS.relations.ID(r, SDS.index.female);
            if SDS.males.condom(P0.male) || SDS.females.condom(P0.female)
                [SDS, P0] = P.updateTransmission(SDS, P0);% uses P0.male; P0.female
            end
        end
        
        if (isfield(SDS,'unused_condoms'))
            SDS.unused_condoms = SDS.unused_condoms + num_condoms;
        end
        %disp(num_condoms);
    end
	
%% fire4
    function [SDS,P0] = eventCondom4_fire(SDS, P0)   
		num_condoms = P.num_condoms{4};
        if num_condoms<= 0 %if you run out of condoms this campaign is over
            return
        end
        
        %give condoms to age group of males:
        for m = 1:SDS.number_of_males %for all males
            r = rand;
            age = P0.now - SDS.males.born(m);
            %if (he is in our age brackets)    %&& (we find him)
            if (age<P.groupUB && age>P.groupLB) && (r < P.finding_effectiveness)
                SDS.males.condom(m) = 1; %give this guy one of your condoms
                P0.male = m;
                num_condoms = num_condoms-1;
                if num_condoms<= 0 %if you run out of condoms this campaign is over
                    break
                end 
            end
        end
        
        %given condoms to age group of females 
        for f = 1:SDS.number_of_females %for all females
            r = rand;
            age = P0.now - SDS.males.born(f);
            if (age<P.groupUB && age>P.groupLB) && (r < P.finding_effectiveness)
                SDS.females.condom(f) = 1; %give this guy one of your condoms
                P0.female = f;
                num_condoms = num_condoms-1;
                if num_condoms<= 0 %if you run out of condoms this campaign is over
                    break
                end
            end
        end
        
        %update relationships
        activeRelationships = SDS.relations.time(:, SDS.index.stop) == Inf;
        for r =find(activeRelationships)'
            P0.male = SDS.relations.ID(r, SDS.index.male);
            P0.female = SDS.relations.ID(r, SDS.index.female);
            if SDS.males.condom(P0.male) || SDS.females.condom(P0.female)
                [SDS, P0] = P.updateTransmission(SDS, P0);% uses P0.male; P0.female
            end
        end
        
        if (isfield(SDS,'unused_condoms'))
            SDS.unused_condoms = SDS.unused_condoms + num_condoms;
        end
        %disp(num_condoms);
    end
	
%% fire5
	function [SDS,P0] = eventCondom5_fire(SDS, P0)   
		num_condoms = P.num_condoms{5};
		if num_condoms<= 0 %if you run out of condoms this campaign is over
			return
		end
		
		%   give condoms to high perceived risk males:
		for m = 1:SDS.number_of_males %for all males
			%if we find him
			if (rand > P.finding_effectiveness)
				continue
			end   
			
			%find relations that are ongoing of male m
			hisrelationships =  find(SDS.relations.ID(...
				SDS.relations.time(:, SDS.index.stop) == Inf,...
				SDS.index.male)==m);
			if size(hisrelationships,1)<=0
				continue %no need to check his relationships if there are none
			end
			
			%check each relationship to see if the female is risky looking
			for r = hisrelationships'
				f = SDS.relations.ID(r,SDS.index.female);
				%if (his partner is perceived as risky )     
				if (sum(SDS.relations.ID(:,SDS.index.female)==f)>P.risk_threshold) 
					SDS.males.condom(m) = 1; %give this guy one of your condoms
					num_condoms = num_condoms-1;
					break %we can go onto the next male
				end
			end
			
			if num_condoms<= 0 %if you run out of condoms this campaign is over
				break
			end
		end
		
		%   give condoms to high perceived risk females:
		for f = 1:SDS.number_of_females %for all females
			%if we find her
			if (rand > P.finding_effectiveness)
				continue
			end
			
			%find relations that are ongoing of female f
			herrelationships =  find(SDS.relations.ID(...
				SDS.relations.time(:, SDS.index.stop) == Inf,...
				SDS.index.male)==f);
			if size(herrelationships,1)<=0
				continue %no need to check her relationships if there are none
			end
			
			%check each relationship to see if the male is risky looking
			for r = herrelationships'
				m = SDS.relations.ID(r,SDS.index.male);
				%if (his partner is perceived as risky )          
				if (sum(SDS.relations.ID(:,SDS.index.male)==m)>P.risk_threshold) 
					SDS.males.condom(f) = 1; %give this guy one of your condoms
					num_condoms = num_condoms-1;     
					break %we can go onto the next female              
				end
			end
			
			if num_condoms<= 0
				break
			end
		end
		
		%update relationships
		activeRelationships = SDS.relations.time(:, SDS.index.stop) == Inf;
		for r =find(activeRelationships)'
			P0.male = SDS.relations.ID(r, SDS.index.male);
			P0.female = SDS.relations.ID(r, SDS.index.female);
			if SDS.males.condom(P0.male) || SDS.females.condom(P0.female)
				[SDS, P0] = P.updateTransmission(SDS, P0);% uses P0.male; P0.female
			end
		end
		
		if (isfield(SDS,'unused_condoms'))
			SDS.unused_condoms = SDS.unused_condoms + num_condoms;
		end
		%disp(num_condoms);
	end

end


%% properties
function [props,msg] = eventCondom_properties
msg = '';

%Condom Distribution 1 (CD1)
props.start_spend = {'26-Jun-2050'	0; %Start date of condom distribution 1
				  	  '26-Jun-2050'   	0; %2
				 	  '26-Jun-2050' 	0; %3
					  '26-Jun-2050'		0; %4
					  '26-Jun-2050'		0}; %5

props.finding_effectiveness = 0.5; %you can only find 50% of high risk
props.risk_threshold = 1;
props.groupUB = 25;
props.groupLB = 15;

end


%% name
function name = eventCondom_name
name = 'CondomDistribution';
end
