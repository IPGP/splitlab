function plotfreqz(mode1, mode2)

global thiseq
o  = thiseq.Amp.time(1);
ia = floor((thiseq.Ppick(1)-o)/thiseq.dt); %index of first sample picked
ib =  ceil((thiseq.Ppick(2)-o)/thiseq.dt); %index of last sample picked
%now extend pick window by 20% at beginning and end(for tapering):
len = (ib-ia);
ia = ia - round(len * .1);
ib = ib + round(len * .1);
if ia < 1;    ia = 1; end
if ib > length(thiseq.Amp.time);    ib = length(thiseq.Amp.time);        end

[E, N, Z] = getFilteredSeismograms(thiseq, ia, ib);



%%
figure(15)
clf
L=length(E);
m =2^max((nextpow2(1/thiseq.dt) - 1), 12);
% m =2^(nextpow2(L));
%padding with zeros:
E(L+1:m)=0;
N(L+1:m)=0;
Z(L+1:m)=0;

ny = round(1 / thiseq.dt / 2); %nyquist frequency
f1 = thiseq.filter(1);
f2 = thiseq.filter(2);
norder = thiseq.filter(3);

f   = 1/thiseq.dt*(1:m/2)/m; 
if f1 > 0  &  f2 < inf
       [b,a]  = butter(norder, [f1 f2]/ny);
elseif f1==0 &  f2 < inf
    [b,a]  = butter(norder, [f2]/ny,'low');
elseif f1>0 &  f2 == inf
    [b,a]  = butter(norder, [f1]/ny, 'high');
elseif f1<0 &  f2 <0
        %bandstop
        [b,a]  = butter(norder, [-f2 -f1]/ny, 'stop');
end
if f1==0 & f2==inf
    data.x=f;
    data.y=zeros(size(f)); 
else
   [data.y,data.x]=freqz(b,a, f, 1/thiseq.dt);
   data.y = abs(data.y);
   % convert to dezibel:
   data.y = log10(data.y);
   
end

clf

y   = [E  N Z ];
Y   = fft(y,m);
Pyy = Y.* conj(Y) / m;

warning off
[AX,H1,H2] = plotyy(  f,Pyy(1:m/2,:),  data.x, data.y, mode1, mode2);
warning on

set(get(AX(2),'Ylabel'),'String','Filter Magnitude (dB)')
set(get(AX(1),'Ylabel'),'String','Spectral Power')
set(H2,'LineWidth',2)
% set(H2(1),'color','b')
set(gcf,'children',[AX(1) AX(2)]);
set(AX(2),'color','w')
set(AX(1),'color','none')


set(H1(1),'color','b')
set(H1(2),'color','r')
set(H1(3),'color',[0 .6 0])



linkaxes(AX,'x');
legend(AX(1),{'East','North','Z'}, 'Location', 'NorthWest')
xlim([min(f) max(f)])

xlabel('frequency (Hz)')
title('Frequency content of P-Window')

% c=findobj('type', 'axes', 'parent',gcf);
% set(c,'xScale', 'log')
keyboardnavigate on