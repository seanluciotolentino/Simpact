addpath( [fileparts(which(mfilename)) '\lib'] );
%STARTUP

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com) and
% Lucio

fprintf(1, ' ******* %s %s *******\n', datestr(now), mfilename)


% ******* Settings *******
format compact
format short g
warning('off', 'MATLAB:dispatcher:InexactCaseMatch')
warning('off', 'MATLAB:dispatcher:InexactMatch')
warning('off', 'MATLAB:dispatcher:pathWarning')
warning('off', 'MATLAB:classChanged')
warning('off', 'Simulink:SL_MATLABFcnIncompleteSimState')

system_dependent('DirChangeHandleWarn', 'Never');


% ******* Launch Project Menu *******
if exist('jproject.m', 'file') == 2
    jproject
end

%have to add it twice because somewhere startup removes the path
addpath( [fileparts(which(mfilename)) '\lib'] );
SIMPACTGUI

