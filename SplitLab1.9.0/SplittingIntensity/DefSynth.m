% Synthetics data after splitting of initial derivative of gauss wavelet. 
%
%  alpha : angle beteween backazimuth and fast axis in degrees
%  Time  : time 
%  dt    : delay time between the two quasi shear waves 
%  sigma : parameter for derivative of gauss wavelet

function [Radial,Transverse]=DefSynth(dt,alpha,sigma,Time)
% backazimuth
alpha=deg2rad(alpha);
% wavelets 
Time=Time-Time(length(Time))/2;
w0=-2*(Time+dt/2).*exp(-((Time+dt/2)/sigma).^2)/(sigma*sigma);
w1=-2*(Time-dt/2).*exp(-((Time-dt/2)/sigma).^2)/(sigma*sigma);

% radial and transverse components
for k=1:1:length(alpha)
    Radial(k,:)=w0*cos(alpha(k))^2+w1*sin(alpha(k))^2;
    Transverse(k,:)=0.5*(w1-w0)*sin(2*alpha(k));
end
% normalization
for k=1:1:length(alpha)
    MAX=max(abs(Radial(k,:)));
    Radial(k,:)=Radial(k,:)/MAX;
    Transverse(k,:)=Transverse(k,:)/MAX;
end