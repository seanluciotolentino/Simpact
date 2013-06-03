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
    date = datestr((sim_time*daysPerYear)+datenum(start_date)) ;
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

integral = exp(alpha) .* (exp(beta .* t2) - exp(beta .* t1)) ./ beta;

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


malesID = 1:SDS.number_of_males;
femalesID=1:SDS.number_of_females;
femalesID=femalesID+SDS.number_of_males;
ID=[malesID,femalesID]';
gender = [zeros(1, SDS.number_of_males) ones(1,SDS.number_of_females)]';
born=[SDS.males.born, SDS.females.born]';
deceased=[SDS.males.deceased, SDS.females.deceased]';
father=[SDS.males.father, SDS.females.father]';
mother=[SDS.males.mother,SDS.females.mother]'+SDS.number_of_females;
mother(mother==SDS.number_of_males)=0;
HIV_positive=[SDS.males.HIV_positive,SDS.females.HIV_positive]';

male_source = SDS.males.HIV_source + SDS.number_of_males;
male_source(male_source==SDS.number_of_males)=0;
HIV_source = [male_source, SDS.females.HIV_source]';
sex_worker = [false(1, SDS.number_of_males), SDS.females.sex_worker]';
AIDS_death = [SDS.males.AIDS_death,SDS.females.AIDS_death]';
CD4_infection = [SDS.males.CD4Infection, SDS.females.CD4Infection]';
CD4_death = [SDS.males.CD4Death, SDS.females.CD4Death]';
ARV_eligible=[SDS.males.ARV_eligible, SDS.females.ARV_eligible]';


ID=single(ID);
father=single(father);
mother=single(mother);
HIV_source = single(HIV_source);

allC=[ID,gender, born, deceased, father, mother, HIV_positive, HIV_source, ...
    sex_worker, AIDS_death, CD4_infection,CD4_death, ARV_eligible];
allC=allC(~isnan(born),:);
head={'id','gender','born','deceased','father','mother','hiv.positive','hiv.source',...
    'sex.worker', 'aids.death','cd4.infection','cd4.death','arv.eligible'};
allC=[head
    num2cell(allC)];


% ******* Seperate file for relations *******
relations = [single([SDS.relations.ID]), SDS.relations.time(:,1:2),single(SDS.relations.proximity)];
relations(:,2)=relations(:,2)+SDS.number_of_males;
relations=relations(relations(:,1)~=0,:);
header = {'male.id' 'female.id' 'start.time' 'end.time','proximity'};
relations = [header
num2cell(relations)   
];

%********Seperate file for test*********
test = [single(SDS.tests.ID),SDS.tests.time];
test = test(test(:,1)~=0,:);
header = {'id','time'};
test = [header
    num2cell(test)];

%********Seperate file for ARV*********
ARV = [single(SDS.ARV.ID),SDS.ARV.time, single(SDS.ARV.CD4), SDS.ARV.life_year_saved];
ARV = ARV(ARV(:,1)~=0,:);
header = {'id','arv.start','arv.stop','cd4','life.year.saved'};
ARV = [header
    num2cell(ARV)];

% ******* Store *******
folder ='result/csv'; 
if ~isdir(folder)
mkdir(folder);
end
file=SDS.data_file(14:17);
save(fullfile(folder, ['sds_', file, '.mat']), 'SDS');
[ok, msg] = exportCSV_print(fullfile(folder, ['allC_', file, '.csv']), allC);
[ok, msg] = exportCSV_print(fullfile(folder,['relation_', file,'.csv']),relations);
[ok, msg] = exportCSV_print(fullfile(folder, ['test_', file, '.csv']), test);
[ok, msg] = exportCSV_print(fullfile(folder, ['arv_', file, '.csv']), ARV);
    
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
