function [DELTA,RANGE,SRAZ,RSAZ] = sphere_dist(SLAT,SLON,RLAT,RLON)
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
COSDEL = max(-1.0,  min(1.0,cos(THA).*cos(THB)+sin(THA).*sin(THB).*COSDPH));

DELTA = acos(COSDEL)/DEGRAD;
RANGE = DELTA * 111.1195;
SINCOSZ = sin(THA).*cos(THB)-sin(THB).*cos(THA).*COSDPH;
SINSINZ = -sin(THB).*SINDPH;
SRAZ = atan2(SINSINZ,SINCOSZ)/DEGRAD;

SINCOSZ = sin(THB).*cos(THA)-sin(THA).*cos(THB).*COSDPH;
SINSINZ = sin(THA).*SINDPH;
RSAZ = atan2(SINSINZ,SINCOSZ)/DEGRAD;



