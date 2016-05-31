function M = rot3D(inc, bazi)
% return the seismogram rotation matrix M
%    
%     Z       L
% M * E  =    SG
%     N       SH
%
%
% After Plesinger, Hellweg, Seidl; 1986 
% "Interactive high-resolution polarisation analysis of broad band seismograms"; 
% Journal of Geophysics (59) 129-139


inc  = inc/180*pi;
bazi = bazi/180*pi; 

M = [cos(inc)     -sin(inc)*sin(bazi)    -sin(inc)*cos(bazi);
     sin(inc)      cos(inc)*sin(bazi)     cos(inc)*cos(bazi);
        0              -cos(bazi)             sin(bazi)];


