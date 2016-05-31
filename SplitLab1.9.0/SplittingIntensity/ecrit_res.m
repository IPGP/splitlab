function [x,y,mes,fit] = ecrit_res(phi,dt,az,pp,err)

deg2rad = pi/180;

x=(0:pi/100:2*pi);
y=zeros(1,length(x));
y(:)=dt*sin(2*(x(:)-phi*deg2rad));

mes(:,1) = az(:);
mes(:,2) = pp(:);
mes(:,3) = err(:);

fit(:,1) = x(:)/deg2rad;
fit(:,2) = y(:);


%rms=0;%#ok
rms= norm(pp - dt*sin(2*((az-phi)*deg2rad)))/sqrt(length(pp));