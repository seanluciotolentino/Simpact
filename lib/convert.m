function out = convert(fromTo, arg)
%CONVERT

% Copyright 2009-2011 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    convert_test
    return
elseif nargin == 1
    arg = 1;
end

out = NaN;

% ******* Conversion Factors (consistent with Cards) *******
g0 = 9.80665;               % gravitational acceleration [m/s²]
s_min = 60;                 % seconds per minute
min_h = 60;                 % minutes per hour
s_h = s_min*min_h;          % seconds per hour
kg_lb = 0.45359237;         % kilograms per pound
m_in = 0.0254;              % meters per inch
m_ft = m_in*12;             % meters per foot
mm_in = m_in*1e3;           % mm per inch
Pa_psi = g0*kg_lb/m_in^2;   % Pascal per PSI
bar_psi = Pa_psi/1e5;       % bar per PSI
m3_USgallon = 231*m_in^3;   % US liquid gallon per cubic meter
Kat0C = 273.15;             % Kelvin at 0°Celsius
kJkg_BTUlb = 2.326;
kJ_BTU = kJkg_BTUlb*kg_lb;
kJkgK_BTUlbF = 4.1868;      % BTUs per kJ by following definition:
% International [Steam] Table (IT) calorie, which was defined by the Fifth
% International Conference on the Properties of Steam (London, July 1956)
% to be exactly 4.1868 J.


% ******* Main *******
switch fromTo
    case 'in to m'
        out = arg*m_in;
        
    case 'ft to m'
        out = arg*m_ft;
        
    case 'm to ft'
        out = arg/m_ft;
        
    case 'lb/h to kg/s'
        out = arg*kg_lb/s_h;
        
    case 'lb to kg'
        out = arg*kg_lb;
        
    case 'psi to bar'
        out = arg*bar_psi;
        
    case {'°F to °C', 'F to C'}
        out = (arg - 32)*5/9;
        
    case {'°C to °F', 'C to F'}
        out = arg*9/5 + 32;
        
    case {'°F to K', 'F to K'}
        out = convert('°F to °C', arg) + Kat0C;
        
    case 'USgallon to m³'
        out = arg*m3_USgallon;
        
    case 'USgallon/min to m³/h'
        out = convert('USgallon to m³', arg)*min_h;
        
    case 'm³ to USgallon'
        out = arg/m3_USgallon;
        
    case 'm³/h to USgallon/min'
        out = convert('m³ to USgallon', arg)/min_h;
        
    case 'BTU to kJ'
        out = arg*kJ_BTU;
        
    case 'BTU/h to kW'
        out = arg*kJ_BTU/s_h;
        
    case 'BTU/lb to kJ/kg'
        out = arg*kJkg_BTUlb;
        
    case 'BTU/lb°F to kJ/kgK'
        out = arg*kJkgK_BTUlbF;
        
    otherwise
        error('Unknown conversion: %s', fromTo)
end
end


%% test
function convert_test

debugMsg


end


%%
function convert_

end
