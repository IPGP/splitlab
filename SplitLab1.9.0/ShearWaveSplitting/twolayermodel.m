function [phi0, dt0]=twolayermodel(polaz, phi1,dt1, phi2, dt2, period)
%calculate the apparent splitting parameter ditribution for a 2 Layer model
% output is in backazimuth interval [-90 90)
%
%following [Savage & Silver, 1994]
% index 1 nominates the lower layer,
% index 2 represents the upper layer

%based on a code by Kris Walker


freq = 1/period;%dominant frequency of wavelet?
% ....Assign constants
zero = 1.0e-5;
rad  = pi/180.;



polaz=sort(mod(polaz,180));
if dt1==0
    phi0 = phi2*ones(size(polaz))';
    dt0  = dt2*ones(size(polaz))';
elseif dt2==0
    phi0 = phi1*ones(size(polaz))';
    dt0  = dt1*ones(size(polaz))';
else
    if (phi1 == phi2 | abs(phi1-phi2) == 90 | abs(phi1-phi2) == 180 | abs(phi1-phi2) ==270 | abs(phi1-phi2) == 360)
        phi2=phi2+1E-5;   %% THIS ENSURES APP IS NON-ZERO WITH PHI1=PHI2
        if (dt1==dt2)
            dt2=dt2+1E-2;
        end
    end
    
    % ....Main Loop
    
    th1 = pi*dt1*freq;
    th2 = pi*dt2*freq;
    alph1 = 2.0*(phi1-polaz)*rad;  %% Slight difference
    alph2 = 2.0*(phi2-polaz)*rad;  %% Slight difference
    
    cc = cos(th1).*sin(th2).*cos(alph2) + cos(th2).*sin(th1).*cos(alph1);
    cs = cos(th1).*sin(th2).*sin(alph2) + cos(th2).*sin(th1).*sin(alph1);
    ap = cos(th1).*cos(th2)             - sin(th1).*sin(th2).*cos(alph2-alph1);
    app=                 - sin(th1).*sin(th2).*sin(alph2-alph1);
    
    num = app.^2 + cs.^2;
    denom = app.*ap + cs.*cc;
    
    denom(denom == 0) = 1E-15;
    
    alphap=atan(num./denom);
    
    num2 = app;
    denom2 = cs.*cos(alphap) - cc.*sin(alphap);
    
    
    denom2(denom2 == 0)=1E-5;
    
    
    t0   = atan(num2./denom2);
    dt0  = t0./(pi*freq);
    phi0 = 0.5*alphap./rad+polaz;
    
    
    
    k = dt0 < 0;
    phi0(k) = phi0(k) + 90;
    dt0(k) = abs(dt0(k));
    
    phi0(~k) = 0.5*alphap(~k)./rad+polaz(~k);
    dt0(~k)  = t0(~k)/(pi*freq);
    
    phi0 = mod(phi0,180);
    %
    
    
    phi0 = [phi0(:) phi0(:)-90];
    phi0(phi0>90)=phi0(phi0>90)-180;
    dt0 = dt0(:);
end
%
% d1=abs(diff(mod(phi0,180)));
% d2=diff(dt0);
%
% phi0(d1>90) = nan;
% dt0(d1>90)  = nan;


%%

% figure(99)
% subplot(1,2,1)
% plot(polaz,phi0,'.')
% axis([0 360 -90 90])
%
%
% subplot(1,2,2)
% plot(polaz,dt0,'.')
% axis([0 360 0 4])
