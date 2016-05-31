function [filtR,filtT,gauss,error,filtre] = FiltreWienerG2(compR,compT,tau,n_filt,delta,epsilon)

% Constantes ----------
lengthR=length(compR);
time=[0:delta:delta*(lengthR-1)];
[max_compR,Point_peak]=max(compR);
time_peak=(Point_peak-1)*delta;

% Definition de la gaussienne derivee 2 fois----------------------------------------------
K=4*pi^2/tau^2;
t=time-time_peak;
g=exp(-K*t.^2);
g=-2*K*(2*K*t.^2-1).*g;
gauss=g/max(g);
MAX=max(abs(compR));

compR=compR/MAX;
compT=compT/MAX;

%Initialisation calcul -------------------------------------------------------------------
Rjs=zeros(2*n_filt-1);
Gj2=zeros(2*n_filt-1);
npt = 2^(fix(log(2*n_filt-1)/log(2))+1);

% Fourier transform of signals
fr = fft(compR,npt);
ft = fft(compT,npt);

%Signal Autocorrelation
%[Rjs,lags] = xcorr_old(compR,compR,n_filt,2);
[Rjs,lags] =xcorr(compR,compR,n_filt,'biased');
TRjs = fft(Rjs,npt);

%Signal wavelet Crosscorrelation
%[Gj,lags] = xcorr_old(compR,gauss,n_filt,2);
[Gj,lags]=xcorr(gauss,compR,n_filt,'biased');
TGj = fft(Gj,npt);

% Computes W
W = TGj./(TRjs+epsilon);

% Filter data
filtre=W;
filtR = real(ifft(W.*fr,npt));
filtT = real(ifft(W.*ft,npt));
%filtR=filtR(1:1:lengthR);
%filtT=filtT(1:1:lengthR);
%
error = sum((gauss(1:lengthR)-filtR(1:lengthR)).^2)/sum(gauss(1:lengthR).^2);
%error=0;