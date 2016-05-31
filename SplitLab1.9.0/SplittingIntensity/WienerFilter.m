function [R1,T1]=WienerFilter(R,T,DT,tau,reg,iw0,iw1)

R1=[];
T1=[];
for i=1:1:size(R,1) 
    n=length(R(i,[iw0:1:iw1]));
    [r,t,gauss,error,filtre]=FiltreWienerG2(R(i,[iw0:1:iw1]),T(i,[iw0:1:iw1]),tau,n,DT,reg);
    R1=[R1;r];
    T1=[T1;t];
end