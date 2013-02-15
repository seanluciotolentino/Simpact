function varargout = spGraphs(fcn, varargin)
%SPTOOLS SIMPACT tools.
%
%   See also SIMPACT, spRun, modelHIV.

% File settings:
%#function spGraphs_handle, spGraphs_menu, spGraphs_edit, spGraphs_intExpLinear
%#function spGraphs_expLinear, spGraphs_meshgrid, spGraphs_interp1
%#function spGraphs_resetRand, spGraphs_rand0toInf
%#function spGraphs_weibull, spGraphs_weibullEventTime
%#ok<*DEFNU>
%#ok<*UNRCH>

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    spGraphs_test
    return
end

[varargout{1:nargout}] = eval([mfilename, '_', fcn, '(varargin{:})']);


%% handle
    function [handle, msg] = spGraphs_handle(varargin)
        
        msg = '';
        if nargin == 1
            handle = eval(sprintf('@%s_%s', mfilename, varargin{1}));
            return
        end
        if exist(varargin{1}, 'file') ~= 2
            msg = sprintf('Warning: can''t find file "%s"', varargin{1});
            handle = @spGraphs_handle_dummy;
            return
        end
        handle = feval(varargin{1}, 'handle', varargin{2});
        
        
        %% handle_dummy
        function varargout = spGraphs_handle_dummy(varargin)
            % dummy function returning the input
            if nargin == nargout
                [varargout{1:nargout}] = deal(varargin{:});
            end
        end
    end


%% menu
    function modelMenu = spGraphs_menu(handlesFcn)
        
        import java.awt.event.ActionEvent
        import java.awt.event.KeyEvent
        import javax.swing.JMenu
        import javax.swing.JMenuItem
        import javax.swing.KeyStroke
        
        modelMenu = JMenu('Graphs');
        modelMenu.setMnemonic(KeyEvent.VK_T)
        
        menuItem = JMenuItem('Formed Relations', KeyEvent.VK_F);
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('HIV Prevalence & Incidence', KeyEvent.VK_H);
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('Partnership Formation Scatter', KeyEvent.VK_S);
        menuItem.setDisplayedMnemonicIndex(22)
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('Concurrency Point Prevalence', KeyEvent.VK_C);
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('Demographics', KeyEvent.VK_D);
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('Condom-Use Fraction', KeyEvent.VK_C);
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('Partnership Network', KeyEvent.VK_N);
        menuItem.setDisplayedMnemonicIndex(12)
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('HIV Transmission Network', KeyEvent.VK_T);
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('Demographic and Transmission Overview', KeyEvent.VK_O);
        jset(menuItem, 'ActionPerformedCallback', @spGraphs_menu_callback)
        modelMenu.add(menuItem);
        
        %modelMenu.addSeparator()
        
        %menuItem.setDisplayedMnemonicIndex(5)
        %menuItem.setToolTipText('')
        
        
        %% menu_callback
        function spGraphs_menu_callback(~, actionEvent)
            
            handles = handlesFcn();
            SDS = handles.data();
            handles.state('busy')
            
            try
                command = get(actionEvent, 'ActionCommand');
                switch command
                    case 'Formed Relations'
                        [ok, msg] = spGraphs_formedRelations(SDS);
                        if ~ok
                            handles.fail(msg)
                        end
                        
                    case 'HIV Prevalence & Incidence'
                        [ok, msg] = spGraphs_prevalenceIncidence(SDS);
                        if ~ok
                            handles.fail(msg)
                        end
                    
                    case 'Partnership Formation Scatter'
                        [ok, msg] = spGraphs_formationScatter(SDS);
                        if ~ok
                            handles.fail(msg)
                        end
                        
                    case 'Concurrency Point Prevalence'
                        [ok, msg] = spGraphs_concurrencyPrevalence(SDS);
                        if ~ok
                            handles.fail(msg)
                        end
                        
                    case 'Demographics'
                        [ok, msg] = spGraphs_Demographics(SDS);
                        if ~ok
                            handles.fail(msg)
                        end
                        
                     case 'Demographic and Transmission Overview'
                        [ok, msg] = spGraphs_demoAndTrans(SDS);
                        if ~ok
                            handles.fail(msg)
                        end
                        
                    otherwise
                        handles.fail('Warning: %s not implemented yet.', command)
                        return
                end
                
            catch Exception
                handles.fail(Exception)
                return
            end
            
            handles.state('ready')
        end
    end
end


%% test
function spGraphs_test

global SDSG

debugMsg -on
debugMsg

if isempty(SDSG)
    error 'NO DATA'
end


% ******* Tests *******
spGraphs_individualData(SDSG, 'male', 1)
end


%% edit OBS
function [ok, msg] = spGraphs_editOBS(file)

ok = false;
msg = '';

if exist(file, 'file') ~= 2
    msg = sprintf('Error: can''t find %s', file);
    return
end

ok = true;
file = which(file);
[~, ~, extension] = fileparts(file);

switch extension
    case '.m'
        edit(file)
        
    case '.mat'
        msg = 'Warning: load MAT-file to Command Window';
        
    otherwise
        open(file)
        msg = sprintf('Warning: unknown extension %s', extension);
end
end


%% individualData
function [ok, msg] = spGraphs_individualData(SDS, sex, idx)

ok = false;
msg = '';

S = SDS.([sex, 's']);
fields = fieldnames(S);
idx = min(idx, numel(S.(fields{end})));
if idx == 0
    msg = 'Warning: no individual data available';
    return
end

figPrp.Color = 'w';
figPrp.Name = capitalise(sprintf('Individual %s Data', sex));
figPrp.ToolBar = 'figure';
hFig = fig(figPrp);

axesPrp.Parent = hFig;
axesPrp.Visible = 'off';
hAxes = axes(axesPrp);

%textPrp.FontName = 'FixedWidth';
textPrp.Parent = hAxes;
boldPrp = textPrp;
boldPrp.FontWeight = 'bold';
text(1, 0, sprintf('%s %d', sex, idx), boldPrp)

daysPerYear = spTools('daysPerYear');

for ii = 1 : numel(fields)
    text(0, -ii, field2str(fields{ii}), boldPrp)
    
    value = double(S.(fields{ii})(idx));
    if ~isfinite(value)
        text(2, -ii, 'unknown', textPrp)
        continue
    end
    
    switch fields{ii}
        case {'born', 'deceased'}
            text(2, -ii, datestr(datenum(SDS.start_date) + value*daysPerYear), textPrp)
        otherwise
            text(2, -ii, num2str(value), textPrp)
    end
end


% ******* Number of Relations *******
relationCount = sum(SDS.relations.ID(:, SDS.index.(sex)) == idx);
ii = ii + 1;
text(0, -ii, 'number of relations', boldPrp)
text(2, -ii, num2str(relationCount), textPrp)


% ******* Secondary Infections *******
switch sex
    case 'male'
        secondaryInfections = sum(SDS.females.HIV_source == idx);
    case 'female'
        secondaryInfections = sum(SDS.males.HIV_source == idx);
end
ii = ii + 1;
text(0, -ii, 'secondary infections', boldPrp)
text(2, -ii, num2str(secondaryInfections), textPrp)


set(hAxes, 'XLim', [0 4], 'YLim', [-ii 0])


% ******* Controls *******
sexPrp.Callback = @spGraphs_individualData_callback;
sexPrp.Parent = hFig;
sexPrp.Position = [4 24 60 24];
sexPrp.String = {'male', 'female'};
sexPrp.Style = 'popupmenu';
sexPrp.Value = find(strcmp(sexPrp.String, sex));
hSex = uicontrol(sexPrp);

idxPrp = sexPrp;
idxPrp.Position = [4 0 60 24];
idxPrp.String = num2cell(1 : numel(S.(fields{1})));
idxPrp.Value = idx;
hIdx = uicontrol(idxPrp);

figure(hFig)

ok = true;


%% individualData_callback
    function spGraphs_individualData_callback(~, ~)
        
        sexIdx = get(hSex, 'Value');
        switch sex
            case 'male'
                set(hSex, 'Value', 1)
            otherwise
                set(hSex, 'Value', 2)
        end
        spGraphs_individualData(SDS, ...
            sexPrp.String{sexIdx}, get(hIdx, 'Value'));
    end
end


%% formedRelations
function [ok, msg] = spGraphs_formedRelations(SDS)

ok = false;
msg = '';

if isempty(SDS.relations.ID)
    msg = 'Warning: no relations available';
    return
end

timeRange = ceil((datenum(SDS.end_date) - datenum(SDS.start_date))/spTools('daysPerYear'));

figPrp.Name = 'Formed Relations';
figPrp.ToolBar = 'figure';
hFig = fig(figPrp);


% ******* Relation Duration *******
axesPrp.Box = 'on';
axesPrp.Parent = hFig;
axesPrp.Position = [.1 .6 .85 .35];
axesPrp.Units = 'normalized';
% axesPrp.XGrid = 'on';
% axesPrp.YGrid = 'on';
hAxes = axes(axesPrp);


idx = isfinite(SDS.relations.time(:, SDS.index.start));
relStart = SDS.relations.time(idx, SDS.index.start);
relStop = SDS.relations.time(idx, SDS.index.stop);
entryCount = numel(relStart);
stoppedIdx = relStop ~= Inf;
rel = [
    ones(entryCount, 1)
    -ones(sum(stoppedIdx), 1)
    ];
[time, sortIdx] = sort([
    relStart
    relStop(stoppedIdx)
    ]);
%stoppedIdx = relStop ~= Inf;

duration = relStop - relStart;
duration(duration == Inf) = [];

relStop(relStop == Inf) = 2*timeRange;

plot(hAxes, [find(idx), find(idx)]', [relStart, relStop]', '.-')
xlabel(hAxes, 'relation')
ylabel(hAxes, 'duration [years]')
set(hAxes, 'YLim', [0, timeRange])
grid(hAxes, 'on')


%txtPrp.BackgroundColor = 'w';
txtPrp.HorizontalAlign = 'right';
txtPrp.Margin = 2;
txtPrp.Parent = hAxes;
txtPrp.Units = 'normalized';
text(1, -.18, sprintf('mean %g years', mean(duration)), txtPrp)


% ******* Number of Relations *******
axesPrp.Position(2) = .1;
hAxes = axes(axesPrp);
relationCount = cumsum(rel(sortIdx));

linePrp.Color = [12 14 12]/15;
linePrp.Marker = '.';
linePrp.MarkerEdgeColor = [0 10 0]/15;
linePrp.Parent = hAxes;
line(time, relationCount, linePrp)
xlabel(hAxes, 'time [years]')
ylabel(hAxes, 'number of relations')
set(hAxes, 'XLim', [0, timeRange])
grid(hAxes, 'on')


txtPrp.Parent = hAxes;

text(1, -.18, sprintf('mean %g', mean(relationCount)), txtPrp)


zoom(hFig, 'on')


% ******* Add Print Buttons *******
spGraphs_print(hFig)


figure(hFig)

ok = true;
end

%% demoAndTrans
function [ok, msg] =spGraphs_demoAndTrans(SDS)

ok = false;
msg = '';


figPrp.Name = 'Demographic and Transmission Overview';
hFig = fig(figPrp);

daysPerYear = spTools('daysPerYear');
t =floor((datenum(SDS.end_date)-datenum(SDS.start_date))/daysPerYear);
      
born = [SDS.males.born, SDS.females.born];
death = [SDS.males.deceased, SDS.females.deceased];
life = death-born;
life = life(~isnan(life));
table.initial = sum(born<=0);
table.total = sum(~isnan(born));
table.ave_life = mean(life);
table.med_life = median(life);
table.newborns_per_yr = sum([SDS.males.born, SDS.females.born]>=0)/t;
timeHIVpos = [SDS.males.HIV_positive, SDS.females.HIV_positive];
sortHIVpos = sort(timeHIVpos(~isnan(timeHIVpos)));

death(isnan(death)) = t+1;
alive = zeros(1,t*2+1);
prev = zeros(1,t*2+1);
adultPrev = zeros(1,t*2+1);
relations = zeros(1,t*2+1);
ti = 0.5:0.5:t;

for i = ti

alive(i*2+1) = sum(born<i&death>i);
prev(i*2+1) = sum(timeHIVpos<i&death>i)/alive(i*2);
adult = sum(born<(i-15)&death>i);
adultPrev(i*2+1) =  sum(timeHIVpos<i&death>i)/adult;
relations(i*2+1) = sum(SDS.relations.time(:,1)<i&SDS.relations.time(:,2)>i)/adult;

end
table.population_change = alive(end);
table.prevalence = prev;
table.adult_prev = adultPrev;
table.alive = alive;
table.concurrency = relations;
table.time = [0 ti];

pop = SDS.initial_number_of_males+SDS.initial_number_of_females;

newborns = born(born>0);
mothers = [SDS.males.mother SDS.females.mother];
mothers = mothers(mothers>0);
table.pregnant_age = zeros(1,length(mothers));
for i = 1:length(mothers)
   table.pregnant_age(i) = newborns(i) - SDS.females.born(mothers(i));
end

table.age_at_infection = [SDS.males.HIV_positive SDS.females.HIV_positive] - ...
    [SDS.males.born SDS.females.born];
table.age_at_infection = table.age_at_infection(table.age_at_infection>=0);




name = sprintf('Pop_%d_Time_%d_yrs.pdf', pop,t );
subplot(4,2,1); plot(table.time,table.alive); title('Population Size');
subplot(4,2,2); plot(table.time,table.concurrency); title('Average Concurrent Relationships');
subplot(4,2,3); plot(table.time,table.prevalence); title('Prevalence');
subplot(4,2,4); plot(table.time,table.adult_prev); title('Prevalence in Adults (>= 15 yrs)');
subplot(4,2,5); hist(table.pregnant_age); title('Age at children delivery');
subplot(4,2,6); hist(t-born,20); title('Age distribution at the end of simulation');
subplot(4,2,7); hist(table.age_at_infection,20);title('Age distribution at infection');
subplot(4,2,8);hist([SDS.males.HIV_positive SDS.females.HIV_positive],30); title('New infections');



waitTime = Inf(1, SDS.number_of_males+SDS.number_of_females);
newIndex = born<=t-15&born>=-15;
newAdult = sum(newIndex);
count = 0;
for i = 1:SDS.number_of_males
    ti = min(SDS.relations.time(SDS.relations.ID(:,1)==i,1)) - (born(i)+15);
    if isempty(ti)
        ti = min(death(i),t) - born(i)-15;
    else count = count+1;
    end
    if newIndex(i)
        waitTime(i)=ti;
    end
end



for i = 1:SDS.number_of_females
    ti = min(SDS.relations.time(SDS.relations.ID(:,2)==i,1))- born(i+SDS.number_of_males)-15;
    
    if isempty(ti)
        ti = min(death(i+SDS.number_of_males),t) - born(i+SDS.number_of_males)-15;
    else count = count+1;
    end
    if newIndex(i+SDS.number_of_males)
        waitTime(i+SDS.number_of_males)=ti;
    end
end

table.waitTime = sum(waitTime(~isinf(waitTime)))/newAdult;
table.isolate = count;

tfree = zeros(1, SDS.number_of_males+SDS.number_of_females);
for i =1:SDS.number_of_males
    times = SDS.relations.time(SDS.relations.ID(:,1)==i,1:2);
    times(isinf(times(:,2)),2) = t;
    endTime = min(death(i),t).*[1 1];
    times = [times; endTime];
    for i = 1:(length(times(:,1))-1)
        tstop = times(i,2);
        tnext = times(i+1,1);
        if tnext>= tstop
            tfree(i) = tfree(i)+tnext-tstop;
        end
    end
      
end

for i =1:SDS.number_of_females
    times = SDS.relations.time(SDS.relations.ID(:,2)==i,1:2);
    times(isinf(times(:,2)),2) = t;
    endTime = min(death(i+SDS.number_of_males),t).*[1 1];
    times = [times; endTime];
    for i = 1:(length(times(:,1))-1)
        tstop = times(i,2);
        tnext = times(i+1,1);
        if tnext>= tstop
            tfree(i+SDS.number_of_males) = tfree(i+SDS.number_of_males)+tnext-tstop;
        end
    end
      
end

table.average_isolate_time = sum(tfree)/sum(born>=-15);

relations = sum(SDS.relations.ID(:,1)>0);
in = 0;
out =0;
for i = 1: relations
   male = int16(SDS.relations.ID(i,1));
   female = int16(SDS.relations.ID(i,2));
   if SDS.males.community(male)==SDS.females.community(female)
       in = in+1;
   else out = out +1;
   end
    
end

community = max(SDS.males.community);

table.in_community_relations =[in in/community];
table.out_community_relations = [out out/(community*(community-1)/2)/2];
endedRelations = ~isinf(SDS.relations.time(:,2))&~isnan(SDS.relations.time(:,2));
table.average_relations_duration = sum(SDS.relations.time(endedRelations,2)-SDS.relations.time(endedRelations,1))/relations;

figure(hFig)

ok = true;

end
%% prevalenceIncidence
function [ok, msg] = spGraphs_prevalenceIncidence(SDS)

ok = false;
msg = '';

if isempty(SDS.males.HIV_positive)
    msg = 'Warning: no population available';
    return
end

%NIU timeRange = ceil((datenum(SDS.end_date) - datenum(SDS.start_date))/spTools('daysPerYear'));

figPrp.Name = 'HIV Prevalence & Incidence';
figPrp.ToolBar = 'figure';
hFig = fig(figPrp);


% ******* HIV Prevalence *******
axesPrp.Box = 'on';
axesPrp.Parent = hFig;
axesPrp.Position = [.1 .6 .85 .35];
axesPrp.Units = 'normalized';
% axesPrp.XGrid = 'on';
% axesPrp.YGrid = 'on';
hAxes = axes(axesPrp);

malePosIdx = ~isnan(SDS.males.HIV_positive);
femalePosIdx = ~isnan(SDS.females.HIV_positive);
maleMort = SDS.males.deceased(malePosIdx);
femaleMort = SDS.females.deceased(femalePosIdx);
maleMortIdx = ~isnan(maleMort);
femaleMortIdx = ~isnan(femaleMort);
[posTime, posIdx] = sort([
    SDS.males.HIV_positive(malePosIdx)'
    SDS.females.HIV_positive(femalePosIdx)'
    maleMort(maleMortIdx)'
    femaleMort(femaleMortIdx)'
    ]);
posCount = [
    ones(sum(malePosIdx), 1)
    ones(sum(femalePosIdx), 1)
    -ones(sum(maleMortIdx), 1)
    -ones(sum(femaleMortIdx), 1)
    ];
posCumSum = cumsum(posCount(posIdx));

[popTime, popIdx] = sort([
    0
    maleMort(maleMortIdx)'
    femaleMort(femaleMortIdx)'
    ]);
popCount = [
    SDS.number_of_males + SDS.number_of_females
    -ones(sum(maleMortIdx), 1)
    -ones(sum(femaleMortIdx), 1)
    ];
popCumSum = cumsum(popCount(popIdx));

prevalence = posCumSum./interp1(popTime, popCumSum, posTime, 'nearest', popCumSum(end));    % TEMP!!!

linePrp.Color = [12 14 12]/15;
linePrp.Marker = '.';
linePrp.MarkerEdgeColor = [0 10 0]/15;
linePrp.Parent = hAxes;
line(posTime, prevalence*100, linePrp)
xlabel(hAxes, 'time [years]')
ylabel(hAxes, 'HIV prevalence [%]')



% ******* HIV Incidence *******
axesPrp.Position(2) = .1;
hAxes = axes(axesPrp);

timeRange = ceil((datenum(SDS.end_date) - datenum(SDS.start_date))/spTools('daysPerYear'));

% To estimate the incidence at fixed 'reporting times', with
% fixed time windows

ReportingInterval = 1; % Yearly HIV incidence estimates;
ReportingTimes = ReportingInterval:ReportingInterval:timeRange;

HIVincidence = NaN(1,length(ReportingTimes));
HIVincidenceLL = NaN(1,length(ReportingTimes));
HIVincidenceUL = NaN(1,length(ReportingTimes));
alpha = 0.05;

%NIU Allpositives = sort([SDS.males.HIV_positive, SDS.females.HIV_positive]);

for ii = 1 : numel(ReportingTimes)
    StockTaking=ReportingTimes(ii);
    %NIU ScaledInfectionTimes = sort(StockTaking - Allpositives);
    SW = StockTaking - ReportingInterval; % SW is start of window;
    EW = StockTaking; % EW is end of window;
    
    eligibleM = (SDS.males.born <= EW) & (SDS.males.HIV_positive > SW | isnan(SDS.males.HIV_positive))...
        & (SDS.males.deceased > SW | isnan(SDS.males.deceased));
    eligibleF = (SDS.females.born <= EW) & (SDS.females.HIV_positive > SW | isnan(SDS.females.HIV_positive))...
        & (SDS.females.deceased > SW | isnan(SDS.females.deceased));

    birthsM = SDS.males.born(eligibleM);
    birthsF = SDS.females.born(eligibleF);
    conversionM = SDS.males.HIV_positive(eligibleM);
    conversionF = SDS.females.HIV_positive(eligibleF);
    deathM = SDS.males.deceased(eligibleM);
    deathF = SDS.females.deceased(eligibleF);
    
    startM = max(SW,birthsM);
    startF = max(SW,birthsF);
    
    endMintermed = min(conversionM, deathM);
    endFintermed = min(conversionF, deathF);
    endM = min(EW, endMintermed);
    endF = min(EW, endFintermed);
    
    ExposureTimeM = sum(endM - startM);
    ExposureTimeF = sum(endF - startF);
    ExposureTime = ExposureTimeM + ExposureTimeF;
    
    Cases = (conversionM > SW & conversionM <= EW);
    Cases = sum(Cases);
    
    HIVincidence(ii) = Cases / ExposureTime;
    CasesLL = (1/2)*chi2inv(alpha/2, 2*Cases);
    CasesUL = (1/2)*chi2inv(1-(alpha/2), 2*(Cases+1));
    HIVincidenceLL(ii) = CasesLL / ExposureTime;
    HIVincidenceUL(ii) = CasesUL / ExposureTime;

end

%{
[posTime, posIdx] = sort([
    SDS.males.HIV_positive(malePosIdx)'
    SDS.females.HIV_positive(femalePosIdx)'
    ]);
%[posYear, ~] = datevec(datenum(SDS.start_date) + posTime*spTools('daysPerYear'));
posYear = floor(posTime);
[newYear, ~, uniqueIdx] = unique(posYear);
N = numel(newYear);
newPos = nan(N, 1);
for ii = 1 : N
    newPos(ii) = sum(uniqueIdx == ii);
end
initPos = sum(posTime == 0);
newPos(1) = newPos(1) - initPos;

mortTime = sort([
    maleMort(maleMortIdx)'
    femaleMort(femaleMortIdx)'
    ]);
[mortYear, ~, mortIdx] = unique(floor(mortTime) + 1970);

mort = nan(N, 1);
for ii = 1 : N
    mort(ii) = sum(mortIdx == ii);
end

risk = SDS.number_of_males + SDS.number_of_females - cumsum(mort) - ...
    cumsum(newPos);

incidence = newPos./risk;
%}

linePrp.Parent = hAxes;
% line(newYear, incidence*100, linePrp)

line(ReportingTimes, HIVincidence*100, linePrp, 'Color', 'r')    
line(ReportingTimes, HIVincidenceLL*100, linePrp)  
line(ReportingTimes, HIVincidenceUL*100, linePrp)  


xlabel(hAxes, 'time [years]')
ylabel(hAxes, 'HIV incidence [%]')
set(hAxes, 'XLim', [0, timeRange])


zoom(hFig, 'on')


% ******* Add Print Buttons *******
spGraphs_print(hFig)


figure(hFig)

ok = true;
end


%% formationScatter
function [ok, msg] = spGraphs_formationScatter(SDS)
% Original code by Fei Meng, modified by Ralph

ok = false;
msg = '';

if isempty(SDS.relations.ID)
    msg = 'Warning: no population available';
    return
end


count = sum(SDS.relations.ID(:, SDS.index.male) ~= 0);
maleAge = nan(1, count);
femaleAge = nan(1, count);

for ii = 1 : count
    maleAge(ii) = SDS.relations.time(ii, SDS.index.start) - ...
        SDS.males.born(SDS.relations.ID(ii, SDS.index.male));
    femaleAge(ii) = SDS.relations.time(ii, SDS.index.start) - ...
        SDS.females.born(SDS.relations.ID(ii, SDS.index.female));
end

figPrp.Name = 'Relations Formation Scatter';
figPrp.ToolBar = 'figure';
hFig = fig(figPrp);
hAxes = axes('Parent', hFig);

hScat = scatter(hAxes, femaleAge, maleAge, 4, 'HitTest', 'off');
linePrp = [];
linePrp.Color = 'r';
linePrp.HitTest = 'off';
linePrp.Parent = hAxes;
linePrp.LineWidth = 2;
lim = [0 max([get(hAxes, 'XLim'), get(hAxes, 'YLim')])];
hLine = line(lim, lim, linePrp);

textPrp = [];
textPrp.BackgroundColor = [15 15 13]/15;
textPrp.EdgeColor = [4 6 8]/15;
textPrp.HitTest = 'off';
textPrp.Parent = hAxes;
textPrp.VerticalAlignment = 'top';
textPrp.Visible = 'off';
hText = nan(1, count);

t0 = datenum(SDS.start_date);
daysPerYear = spTools('daysPerYear');

for ii = 1 : count
    tStart = SDS.relations.time(ii, SDS.index.start);
    tStop = SDS.relations.time(ii, SDS.index.stop);
    if isfinite(tStop)
        stopStr = sprintf('\n%s', datestr(t0 + tStop*daysPerYear));
    else
        stopStr = '';
    end
    hText(ii) = text(femaleAge(ii), maleAge(ii), ...
        sprintf('Relation %d\nMale %d with female %d\n%s%s', ...
        ii, SDS.relations.ID(ii, SDS.index.male), ...
        SDS.relations.ID(ii, SDS.index.female), ...
        datestr(t0 + tStart*daysPerYear), stopStr), textPrp);
end

set(hAxes, 'ButtonDownFcn', @spGraphs_formationScatter_callback, ...
    'Box', 'on', 'Children', [hText, hScat, hLine], ...
    'DataAspectRatio', [1 1 1], ...
    'XGrid', 'on', 'YGrid', 'on', 'XLim', lim, 'YLim', lim)
title(hAxes, 'Click on a data point to see its properties')
xlabel(hAxes, 'female age')
ylabel(hAxes, 'male age ')

%zoom(hFig, 'on')


% ******* Add Print Buttons *******
spGraphs_print(hFig)


figure(hFig)

ok = true;


%% formationScatter_callback
    function spGraphs_formationScatter_callback(~, ~)
        
        click = get(hAxes, 'CurrentPoint');
        [~, idx] = min((femaleAge - click(1)).^2 + (maleAge - click(1,2)).^2);
        set(hText(idx), 'Visible', onoff(~onoff(get(hText(idx), 'Visible'))))
    end
end


%% concurrencyPrevalence
function [ok, msg] = spGraphs_concurrencyPrevalence(SDS)

ok = false;
msg = '';

if isempty(SDS.males) || isempty(SDS.females)
    msg = 'Warning: no population available';
    return
end

timeRange = ceil((datenum(SDS.end_date) - datenum(SDS.start_date))/spTools('daysPerYear'));

figPrp.Name = 'Concurrency Point Prevalence';
hFig = fig(figPrp);


% ******* Male Concurrency Point Prevalence *******
axesPrp.Box = 'on';
axesPrp.Parent = hFig;
axesPrp.Position = [.1 .6 .85 .35];
axesPrp.Units = 'normalized';
% axesPrp.XGrid = 'on';
% axesPrp.YGrid = 'on';
hAxes(1) = axes(axesPrp);



ReportingInterval = .1;                  % yearly degree distibutions
ReportingTimes = ReportingInterval : ReportingInterval : timeRange;
N = numel(ReportingTimes);
x_m_outmatrix = zeros(N, 1);
x_f_outmatrix = zeros(N, 1);
histo_mmatrix = zeros(N, 1);
histo_fmatrix = zeros(N, 1);


for ii = 1 : N
    
    ST = ReportingTimes(ii);            % stock taking
    relationsIdx = ...
        (SDS.relations.time(:, SDS.index.start) < ST) & ...
        (SDS.relations.time(:, SDS.index.stop) >= ST);
    
    malePartners = SDS.relations.ID(relationsIdx, 1);
    femalePartners = SDS.relations.ID(relationsIdx, 2);
    unique_mp = unique(malePartners);
    unique_fp = unique(femalePartners);
    partners_m = nan(1, length(unique_mp));
    partners_f = nan(1, length(unique_fp));
    
    for jj = 1 : length(unique_mp)
        rel_mp = find(malePartners == unique_mp(jj));
        partners_m(jj) = length(unique(femalePartners(rel_mp)));
    end
    for jj = 1 : length(unique_fp)
        rel_fp = find(femalePartners == unique_fp(jj));
        partners_f(jj) = length(unique(malePartners(rel_fp)));
    end
    x_m = 1 : max(partners_m);
    x_f = 1 : max(partners_f);
    [histo_m, x_m_out] = hist(partners_m, x_m);
    [histo_f, x_f_out] = hist(partners_f, x_f);
    
    x_m_outmatrix(ii,1:length(x_m_out)) = x_m_out;
    x_f_outmatrix(ii,1:length(x_f_out)) = x_f_out;
    histo_mmatrix(ii,1:length(histo_m)) = histo_m / sum(histo_m);
    histo_fmatrix(ii,1:length(histo_f)) = histo_f / sum(histo_f);
    %{
    NIU
    %}
    %figure(ii)
    %bar(x_m_outmatrix{ii,:}, histo_mmatrix{ii,:})
    % It's better to make a trellis plot;
    
end

bar(hAxes(1), histo_mmatrix, 'stack')
set(hAxes(1),'YLim',[0 1],'XLim',[0 size(histo_mmatrix,1)]);
xlabel(hAxes(1), 'time [years]')
ylabel(hAxes(1), 'Fraction')
%legend(hAxes(1), '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')
legend(hAxes(1), num2cell(num2str((1 : size(histo_mmatrix, 2))')))


% ******* Female Concurrency Point Prevalence *******

axesPrp.Position(2) = .1;
axesPrp.YLim = [0 1];
hAxes(2) = axes(axesPrp);

bar(hAxes(2), histo_fmatrix,'stack')
set(hAxes(2),'YLim',[0 1],'XLim',[0 size(histo_fmatrix,1)]);
xlabel(hAxes(2), 'time [years]')
ylabel(hAxes(2), 'Fraction')
%legend(hAxes(2), '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')
legend(hAxes(2), num2cell(num2str((1 : size(histo_fmatrix, 2))')))

linkaxes(hAxes, 'x')
zoom(hFig, 'on')
figure(hFig)


% ******* Add Print Buttons *******
spGraphs_print(hFig)


ok = true;
end


%% Demographics
function [ok, msg] = spGraphs_Demographics(SDS)

ok = false;
msg = '';

if isempty(SDS.males) || isempty(SDS.females)
    msg = 'Warning: no population available';
    return
end

timeRange = ceil((datenum(SDS.end_date) - datenum(SDS.start_date))/spTools('daysPerYear'));

figPrp.Name = 'Demographics';
figPrp.ToolBar = 'figure';
hFig = fig(figPrp);

% ******* Population size *******
axesPrp.Box = 'on';
axesPrp.Parent = hFig;
axesPrp.Position = [.1 .6 .85 .35];
axesPrp.Units = 'normalized';
% axesPrp.XGrid = 'on';
% axesPrp.YGrid = 'on';
hAxes = axes(axesPrp);


ReportingInterval = .1;                  % yearly degree distibutions
ReportingTimes = ReportingInterval : ReportingInterval : timeRange;
N = numel(ReportingTimes);
population = zeros(N, 1);
%age_edges = 0:10:120;
age_edges = 0:15:120;
histo_matrix = zeros(N, 1);


for ii = 1 : N
    
    ST = ReportingTimes(ii);            % stock taking
    existM = SDS.males.born<=ST;
    existF = SDS.females.born<=ST;
    aliveM = (SDS.males.deceased>ST)|isnan(SDS.males.deceased);
    aliveF = (SDS.females.deceased>ST)|isnan(SDS.females.deceased);
    stockM = existM&aliveM;
    stockF = existF&aliveF;
    population(ii) = sum(stockM)+sum(stockF);
    
    agehist = histc(ST -[SDS.males.born(stockM) SDS.females.born(stockF)], age_edges);

    histo_matrix(ii,1:length(agehist)) = agehist / sum(agehist);
end
    
linePrp.Color = [12 14 12]/15;
linePrp.Marker = '.';
linePrp.MarkerEdgeColor = [0 10 0]/15;
linePrp.Parent = hAxes;



line(ReportingTimes, population, linePrp)
xlabel(hAxes, 'time [years]')
ylabel(hAxes, 'population size')
set(hAxes, 'XLim', [0, timeRange])
set(hAxes, 'YLim', [0, round(max(population))+10])


% Age distribution
axesPrp.Position(2) = .1;
hAxes = axes(axesPrp);

b = bar(hAxes,  ReportingTimes, histo_matrix,'stack');
set(hAxes,'YLim',[0 1],'XLim',[0 timeRange]);
xlabel(hAxes, 'time [years]')
ylabel(hAxes, 'Fraction')

%delineations = {'0-10', '10-20', '20-30', '30-40', '40-50', '50-60', '60-70', '70-80', '80-90', '90-100'};
delineations = {'0-15', '15-30', '30-45', '45-60', '60-75', '75-90', '90-105','105-120'};
order = 8:-1:1; %otherwise the legend is upside down
legend(b(order),delineations{order},'Location','BestOutside' )

%linkaxes(hAxes, 'x')
zoom(hFig, 'on')
figure(hFig)

% ******* Add Print Buttons *******
spGraphs_print(hFig)
ok = true;
end



%% print
function spGraphs_print(hObject, varargin)

if nargin == 1
    spGraphs_print_buttons
    return
end

hFig = ancestor(hObject, 'figure');
ext = get(hObject, 'String');

filename = [get(hFig, 'Name'), '.', datestr(now, 30), '.', lower(ext)];
filename = genfilename(filename);

options = {hFig, '<DRIVER>', '-noui', '-painters', filename};

switch ext
    case 'EMF'
        options{2} = '-dmeta';
        
    case 'EPS'
        options{2} = '-depsc2';
        
    case 'PDF'
        options{2} = '-dpdf';
        
    otherwise
        return
end

print(options{:})
fprintf(1, 'Saved as:\n%s\n', which(filename))


%% print_buttons
    function spGraphs_print_buttons
        
        position = [1 1 40 24];
        
        if ispc
            uicontrol(hObject, 'Callback', @spGraphs_print, ...
                'Position', position, 'String', 'EMF', 'Style', 'pushbutton', ...
                'TooltipString', 'Save as Enhanced Meta File.')
            position(1) = position(1) + position(3);
        end
        
        uicontrol(hObject, 'Callback', @spGraphs_print, ...
            'Position', position, 'String', 'EPS', 'Style', 'pushbutton', ...
            'TooltipString', 'Save as Encapsulated PostScript graphics.')
        position(1) = position(1) + position(3);
        
        uicontrol(hObject, 'Callback', @spGraphs_print, ...
            'Position', position, 'String', 'PDF', 'Style', 'pushbutton', ...
            'TooltipString', 'Save as Portable Document Format.')
    end
end


%%
function spGraphs_

end
