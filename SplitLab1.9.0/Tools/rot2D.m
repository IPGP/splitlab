function [x, y] = rot2D(x, y, angle)
% rotate data given in cartesian corrdiantes about a certain angle
% rotation should be anti-clockwise   

[THETA,R] = cart2pol(x,y);          % convert to polar coordinates
a_rad = ((angle*pi)./180);          % convert angle to radiant
THETA=THETA+a_rad;                  % add a_rad to theta
[x, y] = pol2cart(THETA,R);         % convert back to Cartesian coordinates