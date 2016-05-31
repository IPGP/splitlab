function [R1,T1]=Deconvolue(R,T,i0,i1,reg)

R1=[];
T1=[];

for i=1:1:size(R,1)
    
    % --
    SignalCut=R(i,i0:1:i1); % deconvolution window
    A1=mt_spiking(SignalCut,reg); % compute filter
    
    
    % Radial --
    C1=conv(R(i,:),A1);  % data filter
    comp=C1(1:1:length(R(i,:))); % resize data
    MAX=max(abs(comp)); % Normalization coeff
    R1=[R1;comp/MAX];  % store deconvolued trace
    
    
    %-- transverse
    C1=conv(T(i,:),A1);  % data filter
    comp=C1(1:1:length(R(i,:))); % resize data
    T1=[T1;comp/MAX];
end