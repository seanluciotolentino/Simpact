%% OverlayPrevalenceIncidence


timeRange = 15;%ceil((datenum(SDS.end_date) - datenum(SDS.start_date))/spTools_daysPerYear);

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


for S = 10:12
    s = sprintf('SDS = SDS%d.SDS', S);
    eval(s)
    

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

linePrp.Color = [1 S-9 0]/10 + (1/10); %[0 10 0]/15; %[12 14 12]/15;
linePrp.Marker = 'none'; %'.';
linePrp.MarkerEdgeColor = [1 S-9 0]/10 + (1/10); %[0 10 0]/15;
linePrp.Parent = hAxes;
line(posTime, prevalence*100, linePrp)
hold on


end
xlabel(hAxes, 'time [years]')
ylabel(hAxes, 'HIV prevalence [%]')





% ******* HIV Incidence *******
axesPrp.Position(2) = .1;
hAxes = axes(axesPrp);

timeRange = 15;%ceil((datenum(SDS.end_date) - datenum(SDS.start_date))/spTools_daysPerYear);

% To estimate the incidence at fixed 'reporting times', with
% fixed time windows

ReportingInterval = 1; % Yearly HIV incidence estimates;
ReportingTimes = ReportingInterval:ReportingInterval:timeRange;

HIVincidence = NaN(1,length(ReportingTimes));
HIVincidenceLL = NaN(1,length(ReportingTimes));
HIVincidenceUL = NaN(1,length(ReportingTimes));
alpha = 0.05;

for S = 10:12
    s = sprintf('SDS = SDS%d.SDS', S);
    eval(s)
    

Allpositives = sort([SDS.males.HIV_positive, SDS.females.HIV_positive]);

for i = 1:length(ReportingTimes)
    StockTaking=ReportingTimes(i);
    ScaledInfectionTimes = sort(StockTaking - Allpositives);
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
    
    HIVincidence(i) = Cases / ExposureTime;
    CasesLL = (1/2)*chi2inv(alpha/2, 2*Cases);
    CasesUL = (1/2)*chi2inv(1-(alpha/2), 2*(Cases+1));
    HIVincidenceLL(i) = CasesLL / ExposureTime;
    HIVincidenceUL(i) = CasesUL / ExposureTime;

end

% [posTime, posIdx] = sort([
%     SDS.males.HIV_positive(malePosIdx)'
%     SDS.females.HIV_positive(femalePosIdx)'
%     ]);
% %[posYear, ~] = datevec(datenum(SDS.start_date) + posTime*spTools_daysPerYear);
% posYear = floor(posTime);
% [newYear, ~, uniqueIdx] = unique(posYear);
% N = numel(newYear);
% newPos = nan(N, 1);
% for ii = 1 : N
%     newPos(ii) = sum(uniqueIdx == ii);
% end
% initPos = sum(posTime == 0);
% newPos(1) = newPos(1) - initPos;
% 
% mortTime = sort([
%     maleMort(maleMortIdx)'
%     femaleMort(femaleMortIdx)'
%     ]);
% [mortYear, ~, mortIdx] = unique(floor(mortTime) + 1970);
% 
% mort = nan(N, 1);
% for ii = 1 : N
%     mort(ii) = sum(mortIdx == ii);
% end
% 
% risk = SDS.number_of_males + SDS.number_of_females - cumsum(mort) - ...
%     cumsum(newPos);
% 
% incidence = newPos./risk;

linePrp.Parent = hAxes;
% line(newYear, incidence*100, linePrp)


linePrp.Color = [1 S-9 0]/10 + (1/10); %'red';%[12 14 12]/15;
linePrp.Marker = '.';
linePrp.MarkerEdgeColor = [1 S-9 0]/10 + (1/10); %'red';%[0 10 0]/15;

line(ReportingTimes, [HIVincidence*100], linePrp)
hold on 
%line(ReportingTimes, [HIVincidenceLL*100], linePrp)  
%line(ReportingTimes, [HIVincidenceUL*100], linePrp)  
end

xlabel(hAxes, 'time [years]')
ylabel(hAxes, 'HIV incidence [%]')
set(hAxes, 'XLim', [0, timeRange])


zoom(hFig, 'on')


% ******* Add Print Buttons *******
%spTools_print(hFig)


figure(hFig)

%ok = true;


