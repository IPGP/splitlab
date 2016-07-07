function [strike, dip] = abc2enz(backazimuth,theta,phi)

% disp('unsupported and untested feature!!')
azimuth = backazimuth + 180;

fx =   cosd(phi)   .*  sind(azimuth) +  sind(phi) .* cosd(theta) .* cosd(azimuth);
fy =  -sind(phi)   .*  sind(azimuth) +  cosd(phi) .* cosd(theta) .* cosd(azimuth);
% fz = -sind(theta) .* cosd(azimuth);


dip = acos(sqrt(fx.^2 + fy.^2)) * 180 / pi;

strike = atan2(fx , fy) * 180 / pi;
strike = mod(strike, 180);
strike(strike>90) = strike(strike>90)-180;
