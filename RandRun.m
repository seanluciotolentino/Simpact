function RandRun
addpath( [fileparts(which(mfilename)) '/lib'] );
warning off

if exist('matlabpool') && matlabpool('size')<=0
	matlabpool %grab some processors
end

%% define bounds of parameter
bounds = [  0.001   0.05    %PTSA
            0.001   0.999   %partnering beta1
            0.001   0.999   %partnering beta2
            
            -5      5       %formation baseline
            -0.5    0.5     %current relations factor
            -0.5    0.5     %current relations difference
            -0.05   0.05    %mean age
            0       0.1     %age difference factor
            0.01    10      %age difference growth w/ mean age
            0.1     5       %age dispersion growth w/ mean age
            -2      -0.01   %preferred age difference
            
            -5      5       %dissolution baseline
            -0.5    0.5     %current relations 
            -0.5    0.5     %current relations difference
            -0.05   0.05    %mean age
            -0.1    0.1 ];  %age difference factor
        
%choose parameter from latin hypercube
%sample = lhsdesign(1,16); %16 parameter
for population = [500 1000 1500]
    sample = rand(1,16);
    parameter = bounds(:,1)' + sample.*diff(bounds');
    parfor repeat =1:5
        %% set the parameter
        [SDS,~] = modelHIV('new'); 
        SDS.number_of_males = population; 
        SDS.number_of_females = population;
        SDS.initial_number_of_males = SDS.number_of_males/2;
        SDS.initial_number_of_females = SDS.number_of_females/2;
        SDS.number_of_relations = SDS.number_of_males.^2;
        SDS.start_date = '01-Jan-1970';
        SDS.end_date = '31-Dec-2000';
        numyears = ceil(spTools('dateTOsimtime',SDS.end_date,SDS.start_date));

        %% event parameter
        SDS.events.HIV_transmission.infectiousness{2,3} = parameter(1);
        SDS.events.HIV_transmission.infectiousness{3,3} = parameter(1); 
        SDS.events.HIV_transmission.infectiousness{4,3} = parameter(1);

        SDS.betaPars = [parameter(2) parameter(3)];
        SDS.events.formation.baseline_factor = parameter(4);
        SDS.events.formation.current_relations_factor = parameter(5); 
        SDS.events.formation.current_relations_difference_factor = parameter(6);
        SDS.events.formation.mean_age_factor=parameter(7);
        SDS.events.formation.last_change_factor=0;
        SDS.events.formation.age_difference_factor=parameter(8);
        SDS.events.formation.mean_age_growth = parameter(9); 
        SDS.events.formation.mean_age_dispersion = parameter(10); 
        SDS.events.formation.preferred_age_difference = parameter(11);
        SDS.events.formation.transaction_sex_factor=0;

        SDS.events.dissolution.baseline_factor= parameter(12);
        SDS.events.dissolution.community_factor=0; %isn't implemented
        SDS.events.dissolution.current_relations_factor=parameter(13);
        SDS.events.dissolution.current_relations_difference_factor=parameter(14);
        SDS.events.dissolution.individual_behavioural_factor=0;
        SDS.events.dissolution.mean_age_factor=parameter(15);
        SDS.events.dissolution.last_change_factor=0;
        SDS.events.dissolution.age_difference_factor=parameter(16);
        SDS.events.dissolution.mean_age_growth = parameter(9); %set these to be the ones from before
        SDS.events.dissolution.mean_age_dispersion = parameter(10); 
        SDS.events.dissolution.preferred_age_difference = parameter(11);

        %% constants
        SDS.events.birth.gestation = 0.001; %people are born (almost) right away
        SDS.events.non_AIDS_mortality.replace = 0.55;
        SDS.events.HIV_introduction.period_of_introduced_HIV{2,1} = 10; 
        SDS.events.HIV_introduction.number_of_introduced_HIV = population*0.01;


        %% turn off unused events:
        SDS.events.antenatal_care.enable = 0;
        SDS.events.ARV_treatment.enable = 0;
        SDS.events.ARV_intervention.enable = 0;
        SDS.events.ARV_stop.enable = 0;
        SDS.events.birth.enable = 0;
        SDS.events.male_circumcision.enable =0;
        SDS.events.conception.enable= 0;
        SDS.events.debut.enable = 0;
        SDS.events.MTCT_transmission.enable = 0;
        SDS.events.HIV_test.enable = 0;


        [SDS,~] = spRun('start',SDS);
        %fprintf(1,'\n')

        %% summary statistics and writing to files
        SDS.bornmin = -10;
        [ss,matout] = spData('SummaryStatistics',SDS,0);

        if isfield(ss,'ERROR')
            results = zeros(5,1);
        else
            results = [ ss.concurrent_relationships / ss.samplesize
                    mean(ss.partner_turnover(~isnan(ss.partner_turnover)) )
                    mean(ss.total_lifetime_partners.num_partners)
                    mean(ss.age_difference.agedifferences)
                    ss.duration_of_relationships.mean];
        end

        number_of_infections = sum(SDS.males.HIV_positive>0) + sum(SDS.females.HIV_positive>0);


        filename =  sprintf('run %i parameter %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f.mat',repeat,parameter);
        csvwrite(sprintf('MonteCarloResults/%s',filename), [parameter results' number_of_infections]);
        mainstruct(repeat).SDS = SDS;
    end %end repeats

    %save the repeat SDS after the fact
    for i=1:length(mainstruct)
        filename =  sprintf('run %i parameter %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f.mat',i,parameter);
        SDS = mainstruct(i).SDS;
        save(sprintf('SDSResults/%s',filename),'SDS') %the function variable needs to be a string!
    end
end %end population
fprintf(1,'\n')
end





