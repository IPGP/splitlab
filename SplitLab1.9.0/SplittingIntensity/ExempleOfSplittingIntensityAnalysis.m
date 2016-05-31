%% splitting parameters ---
dt=0.78;
Phi=23.4;

%% max frequency (in seconds) for high pass butterwoth filterring 
fmax=8;

%% SYNTHETICS DATA--------------------
% Backazimuth of data ----
Backazimuth=[10 21 22 25 30 31 34 80 170 175 190 200  300 304 307 310];

% Time basis of synthetics data ----
DT=0.05; % Sampling  
Time=0:DT:100;

% parameter of wavelet -----
sigma=3;

% Radial and Transverse components ----
alpha=Backazimuth-Phi;
[Radial,Transverse]=DefSynth(dt,alpha,sigma,Time);



%% add noise
noise      = rand(size(Transverse));
noise      = filtbuth(5,2,DT,noise);
Transverse = Transverse+noise*.5;


noise      = rand(size(Radial));
noise      = filtbuth(5,2,DT,noise);
Radial     = Radial+noise*.3;

figure;
DisplayData(Time,Radial,Transverse,'unfiltered Radial','unfiltered Tranverse');
%%  Data Pre-processing 

% Step 1: high pass filter 

RadialHighPass=filtbuth(1/fmax,2,DT,Radial);
TransverseHighPass=filtbuth(1/fmax,2,DT,Transverse);

figure;DisplayData(Time,RadialHighPass,TransverseHighPass,'Radial','Tranverse');


% Step 2 : Deconvolution

%  For real data, the user should choose a deconvolution window in each
%  data. The deconvolution window should contain the SK(K)S phase. 
% For the synthetic example, the window is  [T0,T1]
T0=30; % beginning of the deconvolution window
T1=90; % end of the deconvolution window
reg=0.5; % regularization parameter for deconvolution;
i0=find(Time>=T0,1,'first');
i1=find(Time>=T1,1,'first');
[RadialDeconv,TransverseDeconv]=Deconvolue(RadialHighPass,TransverseHighPass,i0,i1,reg);

figure;
DisplayData(Time,RadialDeconv,TransverseDeconv,'Deconvolued Radial','Deconvolued Tranverse');


% Step 3 : Wiener filter
% Window containing the phase :
TW0=30; 
TW1=80;
iw0=find(Time>=TW0,1,'first');
iw1=find(Time>=TW1,1,'first');
regw=0.0001;  % regularization parameter
tau=30; % dominant period = tau/2
%
[RadialWiener,TransverseWiener]=WienerFilter(RadialDeconv,TransverseDeconv,DT,tau,regw,iw0,iw1);
figure;DisplayData(0:DT:DT*(size(RadialWiener,2)-1),RadialWiener,TransverseWiener,'Wiener filtered Radial','Wiener Filtered Tranverse');



%% splitting intensity analysis
% pp : splitting intensity 
% err : error on splitting intensity 
[pp,err]=splitting_intensity(RadialWiener,TransverseWiener,DT);

% dt : delay time
% ddt error on dt
% phi: fast axe
% dphi : error on phi

[ap,dt,phi,ddt,dphi,cov,rms]=fit_sin_new(pp,Backazimuth,err);

%% -- display results--

% plot splitting intensity vs backazimuth
figure;errorbar(Backazimuth,pp,2*err,'o','Markersize',8,'MarkerFaceColor','r')
hold on;

% plot best fit sinusoid
[x,y,mes,fit] =ecrit_res(phi,dt,Backazimuth,pp,err);
plot(fit(:,1),fit(:,2),'LineWidth',2)

% splitting parameters 
title(['\Phi=',num2str(phi),'+/-',num2str(dphi),',  \deltat=',num2str(dt),'+/-',num2str(ddt)],'fontsize',20)

% labels 
xlabel('Backazimuth','fontsize',20)
ylabel('Splitting Intensity','fontsize',20)
set(gca,'fontsize',15);

