function [gclat, gclon]= gcpts(latitude1,longitude1,azimuth,distance,npts)
%earthradius=6371.2
b=distance/180*pi;%/earthradius
lat1=latitude1*pi/180;
lon1=longitude1*pi/180;
azimuth1=azimuth*pi/180;


lat2 = asin( sin(lat1).*cos(b)  +  cos(lat1) .* sin(b) .* cos(azimuth1));
lon2 = lon1 + atan2(...
    sin(azimuth1) .* sin(b)    .* cos(lat1),...
    cos(b)         - sin(lat1) .* sin(lat2));


gclon = 180*lon2(:)/pi;
gclat = 180*lat2(:)/pi;
gclon = mod(gclon, 360);
gclon(gclon>=180) = gclon(gclon>=180)-360;

