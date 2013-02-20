function SIMPACT
%SIMPACT Graphical User Interface.
%   Stochastic model of the HIV epidemic.
%   Use spRun for running SIMPACT in batch-mode.
%   Support for MATLAB release 7.9 (R2009b) and higher.
%
%   See also spRun, modelHIV, spTools.
%

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)
debugMsg

Prefs.debug = isme;
Prefs.appName = 'SIMPACT';
Prefs.appIcon = 'si_icon.jpg';
Prefs.hidden = {'index', 't0', 'tFinal', 'output'};
Prefs.final = '(males|females|relations)';  % substructures that can't be edited
%Prefs.finalFields = {'user_name', 'file_date', 'object_type', 'now'};  % fields that can't be edited
Prefs.finalFields = {'user_name', 'file_date', 'object_type'};  % fields that can't be edited
Prefs.dataFolder = jproject('folder');
Prefs.dataName = 'SDS';
Prefs.dataFcn = @modelHIV;  % handle to data function which initialises the data structure
Prefs.runFcn = @spRun;      % handle to run function which stops/pauses/starts simulation
Prefs.menu = {
    modelHIVrestart('handle', 'menu')
    spTools('handle', 'menu')
    spGraphs('handle', 'menu')
    };      % handles to menu functions
Prefs.help = 'SIMPACT.html';
Prefs.about = {
    'Stochastic model of the HIV epidemic.'
    'International Centre for Reproductive Health - ICRH'
    'University of Ghent, Belgium'
    };


% ******* SIMPACT Graphical Interface *******
structGui(Prefs)

if isdeployed
    % prevent GUI from closing immediately
    pause
end
end
