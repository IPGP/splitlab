function [gclat,gclon,DELTA,RANGE,SRAZ,RSAZ]=gcarc(SLAT,SLON,RLAT,RLON, npts)
% C     GCDSE -- Compute great circle distance in a spherical earth
% C
% C     Assumes:
% C        SLAT, SLON, RLAT, RLON - Receiver lat & lon (degrees)
% C
% C     Returns:
% C        DELTA - distance (degrees)
% C        RANGE - distance (km)
% C        SRAZ - source->receiver azimuth
% C        RSAZ - receiver->source azimuth

DEGRAD = atan(1.0)/45.0;
THA = DEGRAD*(90.0-SLAT);
THB = DEGRAD*(90.0-RLAT);
COSDPH = cos(DEGRAD*(SLON-RLON));
SINDPH = sin(DEGRAD*(SLON-RLON));
COSDEL = max(-1.0,  min(1.0,cos(THA)*cos(THB)+sin(THA)*sin(THB)*COSDPH));

DELTA = acos(COSDEL)/DEGRAD;
RANGE = DELTA * 111.1195;
SINCOSZ = sin(THA)*cos(THB)-sin(THB)*cos(THA)*COSDPH;
SINSINZ = -sin(THB)*SINDPH;
SRAZ = atan2(SINSINZ,SINCOSZ)/DEGRAD;

SINCOSZ = sin(THB)*cos(THA)-sin(THA)*cos(THB)*COSDPH;
SINSINZ = sin(THA)*SINDPH;
RSAZ = atan2(SINSINZ,SINCOSZ)/DEGRAD;

if (SRAZ < 0.0), SRAZ = SRAZ + 360.0; end
if (RSAZ < 0.0), RSAZ = RSAZ + 360.0; end


[gclat,gclon] = greatcrcle(SLAT*DEGRAD,SLON*DEGRAD,SRAZ*DEGRAD,RANGE, npts);
gclat = [SLAT;gclat];
gclon = mod([SLON;gclon], 360);
gclon(gclon>=180) = gclon(gclon>=180)-360;



%%
function [phi,lambda] = greatcrcle(phi0, lambda0, az, rng, npts)
% On a sphere of radius A, compute points on a great circle at specified
% azimuths and ranges.  PHI, LAMBDA, PHI0, LAMBDA0, and AZ are angles in
% radians, and RNG is a distance having the same units as R.


% Reference
% ---------
% J. P. Snyder, "Map Projections - A Working Manual,"  US Geological Survey
% Professional Paper 1395, US Government Printing Office, Washington, DC,
% 1987, pp. 29-32.

% Convert the range to an angle on the sphere (in radians).
earthradius=6371.2;
rng = rng / earthradius;

% Ensure correct azimuths at either pole.
epsilon = 10*eps;    % Set tolerance
az(phi0 >= pi/2-epsilon) = pi;    % starting at north pole
az(phi0 <= epsilon-pi/2) = 0;     % starting at south pole


% expand to vector of length npts
az      = az(ones(npts,1));
rng     = linspace(0,rng,npts)';
phi0    = phi0(ones(npts,1));
lambda0 = lambda0(ones(npts,1));


% Calculate coordinates of great circle end point using spherical trig.
phi = asin( sin(phi0).*cos(rng) + cos(phi0).*sin(rng).*cos(az) );

lambda = lambda0 + atan2( sin(rng).*sin(az),...
    cos(phi0).*cos(rng) - sin(phi0).*sin(rng).*cos(az) );

lambda = lambda * 180 / pi;
phi    = phi    * 180 / pi;
