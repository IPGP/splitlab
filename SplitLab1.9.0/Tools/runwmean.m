function [xx,dd,dd_err,nn]=runwmean(x,y,z,dx)
%
% to compute a weighted running mean of a matrix z(x,y,z)
% 
% x=abscisse
% y=value to average
% z=weighting factor (errorbar)
%
% dx=stepwidths
%
% xx     = new coordinates
% dd     = blockmean
% dd_err = mean of the error
% nn     = number in block
%
%--------------------------------------------------
xmin=min(x); xmax=max(x); 
nx=ceil((max(x)-min(x))/dx); 
dd=zeros(nx-1,1); nn=dd;
dd_err=zeros(nx-1,1);
xx=xmin+dx/2+(0:nx-1)*dx; 

for i=1:nx
  x1=xmin+(i-1)*(xmax-xmin)/nx; x2=x1+dx;
  %xx(i)=(x1+x2)/2;
    I=(x<=x2 & x>=x1) ; %very slight overlap
    nn(i)=sum(I);
    if(sum(I)~=0), dd(i)=wmean(y(I),1-z(I));
                   dd_err(i)=sum(z(I))/nn(i);  
    end %average
%    if(sum(I)~=0), dd(i)=sum(y(I))/nn(i); end %average
end             


