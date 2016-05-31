function [bazimuthP, incP]=testRandomise(E,N,Z,method,phase)

global thiseq

bazi = thiseq.bazi;

c = 0;
XYZ = [E-mean(E), N-mean(N), Z-mean(Z)];
XY  = [E-mean(E), N-mean(N)];
for k= linspace(.6, .9, 10)
    n = round(length(E)*k);
    for kk=1:20
        c         = c + 1;
        s         = randomsample(length(E),n);
        [mat,lam] = eig(cov(XYZ(s,:)));
        switch upper(phase)
            case 'S'
        vec       = mat(:,1);
            case 'P'
        vec       = mat(:,3);
            otherwise
                error('!!!')
        end
                
        
        % incP(c)    = 90- atan( abs(vec(3))/ sqrt(vec(2)^2 + vec(1)^2) ) * 180 / pi;
        switch method
            case 'Jurkewicz'
                % Polarization analysis of three-component array data
                % A Jurkevics, 1988 - Bulletin of the Seismological Society of America
                % v. 78; no. 5; p. 1725-1743
                incP(c)      = acos(vec(3)) * 180 / pi;
                azimuthP(c)  = mod(atan2( vec(1)*sign(vec(3)) , vec(2)*sign(vec(3)))  * 180 / pi, 360);
                bazimuthP(c) = mod(180 +azimuthP(c), 360);
                
            case 'Teanby' %unpublished
                %   Right-handed system: E-N-Z
                %   Find best azimuth by correcting E-N plane
                %   Backazimuth from largest eigenvector vector in E-N plane
                %   Vec(1) = X == E
                %   Vec(2) = Y == N
                [mat,lam]    = eig(cov(XY(s,:)));        
                vec          = mat(:,2);

                
                %   Backazimuth is from north, thus substract 90
                angle         = pi/2 - atan2( vec(2), vec(1));
                bazimuthP(c)  = mod(180 +  (angle  * 180 / pi), 360);
                angle         = (90-bazimuthP(c) )/180*pi;
                
                % Now rotate counter-clockwise North into azimuth direction:
                M    = [cos(angle) sin(angle); -sin(angle) cos(angle)];
                SHSh = M * XY';
                
                
                % Finally, rotate the radial direction into ray frame
                SvZ=[SHSh(1,:)', Z-mean(Z)];
                [mat,lam]    = eig(cov(SvZ(s,:)));
                vec          = mat(:,2);
                angle        = atan2( vec(2) , vec(1));
                
                % Vertical is supposed to be positive upward, inclination defined from vertical down!
                incP(c)      = 90- mod( angle * 180 / pi, 360);
                
        end
    end
end


% correction by comparing with geometric backazimuth:
% if difference between 90 and 270 degrees, flip hemispheres
% bazimuthP = [bazimuthP bazimuthPJ];
% incP      = [incP incPJ];
dd = cosd(bazi - bazimuthP) < 0;
bazimuthP(dd) = mod (180 + bazimuthP(dd), 360);
incP(dd)      = 180 - incP(dd);

bazimuthP = mod(bazimuthP,360);
incP      = mod(incP,180);




%%
if nargout==0
    figure(99)
    
    x  = 1:c;
    y1 = [bazimuthP; x; x*0];
    y2 = [incP;      x; x*0];
    
    subplot(1,2,1)
    [v,L, i] = ransacfitline(y1, 1.5, 0);
    m = mean(bazimuthP(i));
    p=plot(x,bazimuthP,'b.',  x(i),bazimuthP(i),'ro',[x(1) x(end)], [m m],'k');
    set(p(3),'LineWidth',2)
    ylim([0,360])
    
    
    subplot(1,2,2)
    [v,L, i] = ransacfitline(y2, 1.5, 0);
    m = mean(incP(i));
    p=plot(x,incP,'b.',  x(i),incP(i),'ro',[x(1) x(end)], [m m],'k');
    set(p(3),'LineWidth',2)
    ylim([0,180])
end


