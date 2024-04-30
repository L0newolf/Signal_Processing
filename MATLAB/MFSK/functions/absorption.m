function a = absorption(freq,distance,depth,rho,S,T)

%ABSORPTION Computes sound absorption in the ocean
%
%  a = absorption(freq,distance,depth,rho,S,T)
%    freq is frequency in Hz
%    distance is in meters, default: 1000
%    depth is distance in meters, default: 10
%    rho is density in kg/m3, default: 1023
%    S is salinity in parts per thousand, default: 35
%    T is temperature in deg C, default: 27
%    a is absorption in linear space
%
% Reference: Brekhovskikh & Lysanov, Fundamentals of Ocean Acoustics, p9-10.
%   Based on work by Marsh & Schulkin, JASA 34, p864-865, 1962.
%   Based on work by Thorp & Browning, J. Sound Vib. 26, p576-578, 1973.
%
% Author: Mandar Chitre
% Last modified: Dec 16, 2003
% $Revision: 1.3 $

% optional parameters
if nargin < 2, distance = []; end
if nargin < 3, depth = []; end
if nargin < 4, rho = []; end
if nargin < 5, S = []; end
if nargin < 6, T = []; end

% constants and defaults
atm = 1e5/9.8;                    % atmospheric pressure, kg/m3
if isempty(distance)
  distance = 1000;                % default distance, m
end
if isempty(depth)
  depth = 10;                     % nominal depth, m
end
if isempty(rho)
  rho = 1023;                     % density of sea water, kg/m3
end
if isempty(S)
  S = 35;                         % salinity of sea water, parts per thousand
end
if isempty(T)
  T = 27;                         % water temperature, deg C
end

% derived quantities
f = freq/1000;                    % frequency, kHz
P = (rho*depth+atm)*1e-4;         % hydrostatic pressure, kg/cm3
fT = 21.9*10^(6-1520/(T+273));    % relaxation frequency, kHz

if f > 3
  % Marsh & Schulkin
  A = 2.34e-6;
  B = 3.38e-6;
  a = 8.68*(S*A*fT*f*f/(fT*fT+f*f)+B*f*f/fT)*(1-6.54e-4*P);
else
  % Thorp
  a = (0.11*f*f/(1+f*f)+44*f*f/(4100+f*f))*1e-3;
end

% scale by distance and convert to linear scale
a = 10^(-a*distance/20);
 