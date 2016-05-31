function E = calcEnergy(thiseq)
%calulate energy of SG wave for given mechanism 
% (see Stein, S. & Wysession, M. 
% "An Introduction to Seismology, Earthquakes, and Earth Structure"
% Blackwell Publishing, 1999)


strike = thiseq.meca(1)/180*pi;
dip    = thiseq.meca(2)/180*pi;
slip   = thiseq.meca(3)/180*pi;
azi    = thiseq.azi/180*pi;

sR = sin(slip).*sin(dip).*cos(dip);
qR = sin(slip).*cos(2.*dip).*sin(strike-azi)   + ...
    cos(slip).*cos(dip).*cos(strike-azi);
pR = cos(slip).*sin(dip).*sin(2.*(strike-azi)) - ...
    sin(slip).*sin(dip).*cos(dip).*cos(2.*(strike-azi));

f = find(strcmp(thiseq.phase.Names,'SKS'));
if isempty(f)
    disp(['No SKS phase found for earthquake ' thiseq.dstr '    Setting Energy to zero'])
    disp(strvcat(thiseq.phase.Names{:}))
    disp(' ')
    E=0;
else
    takeoff = thiseq.phase.takeoff(f(1))/180*pi;
    E =  1.5.*sR.*sin(2.*takeoff)   + ...
        qR.*cos(2.*takeoff)         + ...
        0.5.*pR.*sin(2.*takeoff);
end
















%%%%%%%%