function varargout = spTools(fcn, varargin)
%SPTOOLS SIMPACT tools.
%
%   See also SIMPACT, spRun, modelHIV.

% File settings:
%#function spTools_handle, spTools_menu, spTools_edit, spTools_intExpLinear
%#function spTools_expLinear, spTools_meshgrid, spTools_interp1
%#function spTools_resetRand, spTools_rand0toInf
%#function spTools_weibull, spTools_weibullEventTime
%#ok<*DEFNU>
%#ok<*UNRCH>

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    spTools_test
    return
end

[varargout{1:nargout}] = eval([mfilename, '_', fcn, '(varargin{:})']);


%% handle
    function [handle, msg] = spTools_handle(varargin)
        
        msg = '';
        if nargin == 1
            handle = eval(sprintf('@%s_%s', mfilename, varargin{1}));
            return
        end
        if exist(varargin{1}, 'file') ~= 2
            msg = sprintf('Warning: can''t find file "%s"', varargin{1});
            handle = @spTools_handle_dummy;
            return
        end
        handle = feval(varargin{1}, 'handle', varargin{2});
        
        
        %% handle_dummy
        function varargout = spTools_handle_dummy(varargin)
            % dummy function returning the input
            if nargin == nargout
                [varargout{1:nargout}] = deal(varargin{:});
            end
        end
    end


%% menu
    function modelMenu = spTools_menu(handlesFcn)
        
        import java.awt.event.ActionEvent
        import java.awt.event.KeyEvent
        import javax.swing.JMenu
        import javax.swing.JMenuItem
        import javax.swing.KeyStroke
        
        modelMenu = JMenu('Tools');
        modelMenu.setMnemonic(KeyEvent.VK_T)
        
        menuItem = JMenuItem('Population Inspector', KeyEvent.VK_P);
        %WIP menuItem.setToolTipText('Create the initial population')
        jset(menuItem, 'ActionPerformedCallback', @spTools_menu_callback)
        modelMenu.add(menuItem);
        
        menuItem = JMenuItem('Relations Inspector', KeyEvent.VK_R);
        jset(menuItem, 'ActionPerformedCallback', @spTools_menu_callback)
        %WIP modelMenu.add(menuItem);
        
        modelMenu.addSeparator()
        
        emMenu = JMenu('Export Matrix');
        emMenu.setToolTipText('Export matrix for post-processing in R')
        emMenu.setMnemonic(KeyEvent.VK_M)
        
        menuItem = JMenuItem('CSV', KeyEvent.VK_C);
        menuItem.setToolTipText('Export matrix in comma separated values format')
        jset(menuItem, 'ActionPerformedCallback', @spTools_menu_callback)
        emMenu.add(menuItem);
        
        menuItem = JMenuItem('NetCDF', KeyEvent.VK_N);
        menuItem.setToolTipText('Export matrix in network common data format')
        jset(menuItem, 'ActionPerformedCallback', @spTools_menu_callback)
        emMenu.add(menuItem);
        
        modelMenu.add(emMenu);
        
        %modelMenu.addSeparator()
        
        %menuItem.setDisplayedMnemonicIndex(5)
        %menuItem.setToolTipText('')
        
        
        %% menu_callback
        function spTools_menu_callback(~, actionEvent)
            
            handles = handlesFcn();
            SDS = handles.data();
            handles.state('busy')
            
            try
                command = get(actionEvent, 'ActionCommand');
                switch command
                    case 'Population Inspector'
                        [ok, msg] = popGui(handles);
                        if ~ok
                            handles.fail(msg)
                        end
                        
                    case 'Relations Inspector'
                        [ok, msg] = relGui(handles);
                        if ~ok
                            handles.fail(msg)
                        end
                        
                    case 'CSV'
                        handles.msg('Exporting to CSV... ')
                        [ok, msg] = spTools_exportCSV(SDS);
                        if ~ok
                            handles.fail(msg)
                            return
                        end
                        handles.msg('ok\n%s\n', msg)
                        
                    case 'WIP NetCDF'
                        handles.msg('Exporting to NetCDF... ')
                        [ok, msg] = spTools_exportNetCDF(SDS);
                        if ~ok
                            handles.fail(msg)
                            return
                        end
                        handles.msg('ok\n')
                        
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
function spTools_test

global SDSG

debugMsg

if isempty(SDSG)
    evalin('base', 'global SDSG')
    evalin('base', 'SDSG = SDS;')
end


% ******* Tests *******
%spTools_individualData(SDSG, 'male', 1)
[ok, msg] = spTools_exportCSV(SDSG)
end


%% edit
function [ok, msg] = spTools_edit(file)

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


%% print
function spTools_print(hObject, varargin)

if nargin == 1
    spTools_print_buttons
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
    function spTools_print_buttons
        
        position = [1 1 40 24];
        
        if ispc
            uicontrol(hObject, 'Callback', @spTools_print, ...
                'Position', position, 'String', 'EMF', 'Style', 'pushbutton', ...
                'TooltipString', 'Save as Enhanced Meta File.')
            position(1) = position(1) + position(3);
        end
        
        uicontrol(hObject, 'Callback', @spTools_print, ...
            'Position', position, 'String', 'EPS', 'Style', 'pushbutton', ...
            'TooltipString', 'Save as Encapsulated PostScript graphics.')
        position(1) = position(1) + position(3);
        
        uicontrol(hObject, 'Callback', @spTools_print, ...
            'Position', position, 'String', 'PDF', 'Style', 'pushbutton', ...
            'TooltipString', 'Save as Portable Document Format.')
    end
end


%% daysPerYear
function daysPerYear = spTools_daysPerYear

daysPerYear = (datenum(2000,1,1) - datenum(1900,1,1))/100;
end

%% simtimeTOdate
function date = spTools_simtimeTOdate(sim_time,start_date)
    daysPerYear = spTools_daysPerYear;
    date = datestr((sim_time*daysPerYear)+datenum(start_date),1) ;
end

%% dateTOsimtime
function simtime = spTools_dateTOsimtime(date,start_date)
    daysPerYear = spTools_daysPerYear;
    simtime = (datenum(date)-datenum(start_date)) / daysPerYear;
end

%% intExpLinear
function integral = spTools_intExpLinear(alpha, beta, t1, t2)
% Integral belonging to hazards of the linear exponent kind:
%   h(t) = exp(alpha + beta t)
% with integral:
%   H(t1-t2) = 1/beta exp(alpha)(exp(beta t2) - exp(beta t1))

integral = exp(alpha) .* (exp(beta * t2) - exp(beta .* t1)) ./ beta;

beta0idx = beta == 0;
if ~any(beta0idx)
    return
end
integralBeta0 = spTools_intExpConstant(alpha, [], t1, t2);
integralBeta0 = integralBeta0(:).*ones(numel(integral), 1);
beta0idx = beta0idx & true(numel(integral), 1);
integral(beta0idx) = integralBeta0(beta0idx);
end


%% intExpConstant
function integral = spTools_intExpConstant(alpha, ~, t1, t2)
% Integral belonging to hazards of the constant exponent kind:
%   h(t) = exp(alpha)
% with integral:
%   H(t1-t2) = exp(alpha) (t2 - t1)

integral = exp(alpha) .* (t2 - t1);
end


%% expLinear
function eventTime = spTools_expLinear(alpha, beta, t0, P)
% Event-time for hazards of the linear exponent kind:
%   h(t) = exp(alpha + beta t)
% with integral:
%   H(t) = e^alpha/beta (e^(beta t) - e^(beta t0)) + T0 = P

x = P .* beta ./ exp(alpha) + exp(beta.*t0);
eventTime = log(x)./beta;
eventTime(x < 0) = Inf;     % hazard integral can't reach P

beta0idx = beta == 0;
if ~any(beta0idx)
    return
end
eventTimeBeta0 = spTools_expConstant(alpha, [], t0, P);
eventTimeBeta0 = eventTimeBeta0(:).*ones(numel(eventTime), 1);
beta0idx = beta0idx & true(numel(eventTime), 1);
eventTime(beta0idx) = eventTimeBeta0(beta0idx);

if 0
    % test code
    time = (0 : 10)';
    alpha = alpha(:,1);
    [exp_alpha, exp_beta_t] = meshgrid(exp(alpha), exp(beta*time));
    h = exp_alpha .* exp_beta_t;
    mesh(double(h))
    mesh(double(exp(alpha)))
    mesh(double(P))
end
end


%% expConstant
function eventTime = spTools_expConstant(alpha, ~, t0, P)
% Event-time for hazards of the constant exponent kind:
%   h(t) = exp(alpha)
% with integral:
%   H(t1-t2) = exp(alpha) (t2 - t1)

eventTime = P ./ exp(alpha) + t0;
end


%% meshgrid: x row vector, y column vector
function [xx, yy] = spTools_meshgrid(x, y)

xx = x(ones(numel(y), 1), :);
yy = y(:, ones(1, numel(x)));
end


%% interp1: stripped
function yi = spTools_interp1(x, y, xi)

%WIP yi = interp1fast(x, y, xi);    % Fortran
yi = interp1q(x(:), y(:), xi);
end


%% resetRand
function spTools_resetRand
%{
if matlab < 7.7
    rand('seed', 0)
    return
end
%}
reset(RandStream.getDefaultStream)
%reset(RandStream('mcg16807', 'Seed', 0))
end


%% rand0toInf
function P = spTools_rand0toInf(rowCount, colCount)
% range rand = [0.0 ... 1.0], mean of rand = 0.5
% while log(1/0.5) = 0.69, mean of this distribution = 1.0
% median of this distribution = 0.69

%P = log(1./rand(rowCount, colCount));
P = -log(rand(rowCount, colCount));     % better performance
end


%% weibull
function r = spTools_weibull(scale, shape, rnd)
%   Shape parameter, kappa; scale parameter, lambda

%r = scale .* (-log(rnd)) .^ (1./shape);
r = scale .* (-log(1 - rnd)) .^ (1./shape);
end


%% weibullEventTime
function t = spTools_weibullEventTime(scale, shape, rnd, t0)
%   scale: Weibull scale parameter, lambda
%   shape: Weibull shape parameter, kappa
%   rnd: should be random number between 0 and 1
%   t0: 

t = (log(1./rnd).*scale.^shape + t0.^shape).^(1./shape) - t0;
end



function CRF = spTools_empiricalCRF(populationsize, betaPars, communityID, SDS)

    factors = [-1 -1];
    CRF = cast(betainv(rand(1, populationsize, SDS.float), betaPars.alpha(communityID + 1), betaPars.beta(communityID + 1)), SDS.float);
    CRF = CRF.*factors(communityID + 1);
end

%% empiricalCommunity
function communityID = spTools_empiricalCommunity(populationsize, communities)
% populationsize: number of people that need a community ID
% communities: number of communities. Default is 2.

communityID = floor(communities*rand(1, populationsize));
end


%% empiricalExposure
function BCCexposure = spTools_empiricalExposure(populationsize, llimit, ulimit, peak, communityID)
% populationsize: number of people that need a community ID
% triangular distribution of exposure between llimit and ulimit with peak
% llimit, ulimit and peak may differ across communities

llimit = llimit(communityID + 1);
ulimit = ulimit(communityID + 1);
peak = peak(communityID + 1);
F_peak = (peak - llimit)./(ulimit - llimit);
U = rand(1, populationsize);
BCCexposure = ulimit - sqrt((1 - U).*(ulimit - llimit).*(ulimit - peak));
idx = U < F_peak;
BCCexposure(idx) = llimit(idx) + ...
    sqrt(U(idx).*(ulimit(idx) - llimit(idx)).*(peak(idx) - llimit(idx)));
end


%% exportCSV
function [ok, msg] = spTools_exportCSV(SDS)

ok = false; %#ok<NASGU>
msg = ''; %#ok<NASGU>


maleFields = fieldnames(SDS.males)';
maleSC = [maleFields; cell(size(maleFields))];
maleS = struct(maleSC{:});

femaleFields = fieldnames(SDS.females)';
femaleSC = [femaleFields; cell(size(femaleFields))];
femaleS = struct(femaleSC{:});

allS = mergeStruct(maleS, femaleS);
allFields = fieldnames(allS)';

maleIdx = isfinite(SDS.males.born);
maleCount = find(maleIdx, 1, 'last');
malesNaN = nan(maleCount, 1, SDS.float);
malesM = [
    (1 : maleCount)',   zeros(maleCount, 1)
    ];
for this = allFields
    if ~isfield(SDS.males, this{1})
        malesM = [malesM, malesNaN];
        continue
    end
    dims = size(SDS.males.(this{1})(maleIdx));
    if dims(1)<dims(2)
        malesM = [malesM, cast(SDS.males.(this{1})(maleIdx)', SDS.float)];
    else
        malesM = [malesM, cast(SDS.males.(this{1})(maleIdx), SDS.float)];
    end
end

femaleIdx = isfinite(SDS.females.born);
femaleCount = find(femaleIdx, 1, 'last');
femalesNaN = nan(femaleCount, 1, SDS.float);
femalesM = [
    (1 : femaleCount)', ones(femaleCount, 1)
    ];
for this = allFields
    if ~isfield(SDS.females, this{1})
        femalesM = [femalesM, femalesNaN];
        continue
    end
    dims = size(SDS.females.(this{1})(femaleIdx));
    if dims(1)<dims(2)
        femalesM = [femalesM, cast(SDS.females.(this{1})(femaleIdx)', SDS.float)];
    else
        femalesM = [femalesM, cast(SDS.females.(this{1})(femaleIdx), SDS.float)];
    end
end

allC = [
    [{'ID', 'gender'}, field2str(allFields)]
    num2cell(malesM)
    num2cell(femalesM)
    ];


% ******* Relations *******
relIdx = SDS.relations.ID(:, 1) > 0;
relIDs = SDS.relations.ID(relIdx, :);
relTimes = SDS.relations.time(relIdx, :);

maleRels = relIDs(:, SDS.index.male);
[males, ~, maleIdx] = unique(maleRels);
maleRelCount = zeros(size(males));
for ii = 1 : numel(males)
    maleRelCount(ii) = sum(maleRels == males(ii));
end

femaleRels = relIDs(:, SDS.index.female);
[females, ~, femaleIdx] = unique(femaleRels);
femaleRelCount = zeros(size(females));
for ii = 1 : numel(females)
    femaleRelCount(ii) = sum(femaleRels == females(ii));
end

maxRels = max([maleRelCount; femaleRelCount]);

% [females, femaleRelCount]

relHeader = {};
for ii = 1 : maxRels
    relHeader = [relHeader, {
        sprintf('partner %d', ii), sprintf('start %d', ii), sprintf('stop %d', ii)
        }];
end

maleRelM = nan(maleCount, 3*maxRels, SDS.float);
for ii = 1 : numel(maleRelCount)
    idx = maleRels == males(ii);
    M = [cast(femaleRels(idx), SDS.float),  relTimes(idx, 1:2)]';
    maleRelM(males(ii), 1:3*maleRelCount(ii)) = M(:)';
end

femaleRelM = nan(femaleCount, 3*maxRels, SDS.float);
for ii = 1 : numel(femaleRelCount)
    idx = femaleRels == females(ii);
    M = [cast(maleRels(idx), SDS.float),  relTimes(idx, 1:2)]';
    femaleRelM(females(ii), 1:3*femaleRelCount(ii)) = M(:)';
end

allC = [allC, [
    relHeader
    num2cell(maleRelM)
    num2cell(femaleRelM)
    ]
    ];


% ******* Christiaan's data format request *******
for ii = 1 : maxRels
    startmaleIdx(:,ii) = ~isnan(maleRelM(:,(3*ii)-1));
    malestarttimes(:,ii) = maleRelM(:,(3*ii)-1);
    stopmaleIdx(:,ii) = ~isnan(maleRelM(:,3*ii));
    malestoptimes(:,ii) = maleRelM(:,3*ii);

    startfemaleIdx(:,ii) = ~isnan(femaleRelM(:,(3*ii)-1));
    femalestarttimes(:,ii) = femaleRelM(:,(3*ii)-1);
    stopfemaleIdx(:,ii) = ~isnan(femaleRelM(:,3*ii));
    femalestoptimes(:,ii) = femaleRelM(:,3*ii);

end

maleStatusM = nan(maleCount, 2*2*maxRels, SDS.float);
femaleStatusM = nan(femaleCount, 2*2*maxRels, SDS.float);


[dim1,dim2] = size(malestarttimes);
for ii = 1 : dim1
    malestarttimesii = malestarttimes(ii,:);
    malestoptimesii = malestoptimes(ii,:);
    
    [statusTimeM, statusIdxM] = sort([
    malestarttimesii(startmaleIdx(ii,:)),malestoptimesii(stopmaleIdx(ii,:))
    ],2);
    
    relationCount = [
    ones(sum(startmaleIdx(ii,:), 2), 1)
    -ones(sum(stopmaleIdx(ii,:), 2), 1)
    ];

    relationCumSum = cumsum(relationCount(statusIdxM));
    
    maleStatusM(ii,1:length(statusTimeM)) = statusTimeM;
    maleStatusM(ii,2*maxRels+1:2*maxRels+length(statusTimeM)) = relationCumSum;
    
end

[dim1,dim2] = size(femalestarttimes);
for ii = 1 : dim1
    femalestarttimesii = femalestarttimes(ii,:);
    femalestoptimesii = femalestoptimes(ii,:);
    
    [statusTimeF, statusIdxF] = sort([
    femalestarttimesii(startfemaleIdx(ii,:)),femalestoptimesii(stopfemaleIdx(ii,:))
    ],2);
    
    relationCount = [
    ones(sum(startfemaleIdx(ii,:), 2), 1)
    -ones(sum(stopfemaleIdx(ii,:), 2), 1)
    ];

    relationCumSum = cumsum(relationCount(statusIdxF));
    
    femaleStatusM(ii,1:length(statusTimeF)) = statusTimeF;
    femaleStatusM(ii,2*maxRels+1:2*maxRels+length(statusTimeF)) = relationCumSum;
    
end

statusHeader = {};
for ii = 1 : 2*maxRels    % each relationship gives 2 relationship status updates
    statusHeader = [statusHeader, {
        sprintf('relationstatustime %d', ii)
        }];
end

for ii = 1 : 2*maxRels    % each relationship gives 2 relationship status updates
    statusHeader = [statusHeader, {
        sprintf('relationstatus %d', ii)
        }];
end


allC = [allC, [
    statusHeader
    num2cell(maleStatusM)
    num2cell(femaleStatusM)
    ]
    ];

% ******* Seperate file for relations *******
t = datenum(SDS.end_date)-datenum(SDS.start_date);
t = t/365;
relations = [single(SDS.relations.ID), SDS.relations.time(:,1:2)];
relations = relations(relations(:,1)~=0,:);
relations = [relations, zeros(length(relations(:,1)), 5)];
% male age, female age, serostatus, convertion
for i = 1:length(relations(:,1))
    if relations(i,4)>=t;
        relations(i,4) = Inf;
    end
    male = SDS.relations.ID(i,1);female = SDS.relations.ID(i,2);
    relations(i, 5) = SDS.males.born(male);
    relations(i, 6) = SDS.females.born(female);
    malePos = SDS.males.HIV_positive(male)<relations(i,3);
    femalePos = SDS.females.HIV_positive(female)<relations(i,3);
    relations(i, 7) = ~(malePos&femalePos)|(~malePos&~femalePos);
    
    if SDS.males.HIV_source(male)==female&&SDS.males.HIV_positive(male)>relations(i,3)&&SDS.males.HIV_positive(male)<=relations(i,4)
    relations(i,8) = true;
    end
    if SDS.females.HIV_source(female)==male&&SDS.females.HIV_positive(female)>relations(i,3)&&SDS.females.HIV_positive(female)<=relations(i,4)
    relations(i,9) = true;
    end 
end

relations(:,2) = relations(:,2)+SDS.number_of_males;
population = SDS.number_of_males+SDS.number_of_females;
ID = [unique(SDS.relations.ID(:,1))
    unique(SDS.relations.ID(:,2))+SDS.number_of_males];
ID = setdiff(1:population,ID);
isolate = nan(length(ID),9);


for i = 1:length(ID)
    if ID(i)<=SDS.number_of_males&&SDS.males.born(ID(i))<=t-15
        isolate(i,5) = SDS.males.born(ID(i));
        isolate(i,1)=single(ID(i));
    else
        if ID(i)>SDS.number_of_males&&SDS.females.born(ID(i)-SDS.number_of_males)<=t-15
        isolate(i,6) = SDS.females.born(ID(i)-SDS.number_of_males);
        isolate(i,2)=single(ID(i));
        end
    end
end
relations(:,4) = relations(:,4)-relations(:,3);

header = {'maleID' 'femaleID' 'start_time' 'duration' 'male_birth' 'female_birth' 'serodicordant_start' 'male_convertion' 'female_convertion'};
relations = [header,
num2cell(relations)   
num2cell(isolate)
];

%********Seperate file for transmission network*********
maleID = 1:SDS.number_of_males;
femaleID = (SDS.number_of_males+1):population;
transNet = SDS.males.HIV_source(~isnan(SDS.males.HIV_positive))';
transNet(transNet~=0) = transNet(transNet~=0) + SDS.number_of_males;
 transNet =[transNet   maleID(~isnan(SDS.males.HIV_positive))'   SDS.males.HIV_positive(~isnan(SDS.males.HIV_positive))'];
transNet = [transNet
    SDS.females.HIV_source(~isnan(SDS.females.HIV_positive))'  femaleID(~isnan(SDS.females.HIV_positive))'  SDS.females.HIV_positive(~isnan(SDS.females.HIV_positive))'];
transNet = transNet(transNet(:,1)~=0,:);
header = {'source_ID' 'infected_ID' 'infection_time'};
transNet = [header
    num2cell(transNet)];


% ******* Store *******
% folder = jproject('folder');
folder = '/Users/wimdelva/Documents/Simpact/wim/csvfiles';

[~, file] = fileparts(SDS.data_file);
[ok, msg] = spTools_exportCSV_print(fullfile(folder, [file, 'people.csv']), allC);
[ok, msg] = spTools_exportCSV_print(fullfile(folder,[file,'relations.csv']),relations);
[ok, msg] = spTools_exportCSV_print(fullfile(folder, [file, 'trans.csv']), transNet);
%% exportCSV_print
    function [ok, msg] = spTools_exportCSV_print(csvFile, dataC)
        
        ok = false;
        msg = ''; %#ok<NASGU>
        
        try
            fid = fopen(csvFile, 'w', 'n', 'UTF-8');
            fprintf(fid, '%s', dataC{1, 1});
            fprintf(fid, ', %s', dataC{1, 2:end});
            fprintf(fid, '\n');
            for ii = 2 : size(dataC, 1)
                fprintf(fid, '%g', dataC{ii, 1});
                fprintf(fid, ', %g', dataC{ii, 2:end});
                fprintf(fid, '\n');
            end
            status = fclose(fid);
        catch ME
            msg = ME.message;
            return
        end
        
        ok = status == 0;
        msg = ['CSV file stored as ', csvFile];
    end
end


%% exportNetCDF
function [ok, msg] = spTools_exportNetCDF(SDS)

ok = false;
msg = '';

ok = true;
end



%%
function spTools_

end
