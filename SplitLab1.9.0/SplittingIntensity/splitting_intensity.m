function [pp,err] = splitting_intensity(compR,compT,delta)

% Compute the derivative of the radial component
[derR] = derive(compR,delta);

rmsR = diag(sqrt(derR*derR'));

a = size(compR);
nsta = a(1);
npoint = a(2);
deg2rad = pi/180;
t = 0:delta:(npoint-1)*delta;

% Projection of the data on the derivative of
% the radial component
nr = zeros(nsta,1);
pp = zeros(nsta,1);
nr(:) = 2./(rmsR(:).*rmsR(:));
pp(:) = -nr(:).*diag(compT*transpose(derR));

% Calculates the errors of pp
[err] = err_split(pp,compT,rmsR);
%pp = pp';
% Ntraces=size(derR,1);
% sigma=0.15;
% for i=1:1:Ntraces
%     err(i)=2*sigma/norm(derR(i,:));
% end