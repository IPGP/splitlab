function [E ,N,Z] = getFilteredSeismograms(thiseq, ia, ib)
% perform filtering of data, stored in "thiseq" structure and return E, N Z
% seismograms
% ia, ib (if given) are start and end index of filtered trace

global config

if nargin == 1
    ia = 1;
    ib = length(thiseq.Amp.time);
end


E = thiseq.Amp.East;
N = thiseq.Amp.North;
Z = thiseq.Amp.Vert;
% DeTrend & DeMean
E = detrend(E,'linear');E = detrend(E,'constant');
N = detrend(N,'linear');N = detrend(N,'constant');
Z = detrend(Z,'linear');Z = detrend(Z,'constant');

    %% Cosine Taper
    len   = round(length(E)); %taper length is 2% of total seismogram length
    taper = tukeywin(len, config.filter.taperlength/100);      
    E  = E  .* taper;     
    N  = N  .* taper;     
    Z  = Z  .* taper;    

% Filtering
% the seismogram components are not yet filtered
% define your filter here.
% the selected corner frequencies are stored in the varialbe "thiseq.filter"
%
ny    = 1/(2*thiseq.dt);%nyquist freqency of seismogramm

f1 = thiseq.filter(1);
f2 = thiseq.filter(2);
n  = thiseq.filter(3); %filter order
if f1==0 && f2==inf %no filter
    % do nothing
    % we leave the seismograms untouched
else
    if f1 > 0  &&  f2 < inf
        % bandpass
        [b,a]  = butter(n, [f1 f2]/ny);
    elseif f1==0 &&  f2 < inf
        %lowpass
        [b,a]  = butter(n, f2/ny,'low');
    elseif f1>0 &&  f2 == inf
        %highpass
        [b,a]  = butter(n, f1/ny, 'high');
    elseif f1<0 &  f2 <0
        %bandstop
        [b,a]  = butter(n, [-f2 -f1]/ny, 'stop');
    end
    if all(b==0)
        E=[]; N=[]; Z=[];
        return
    end
    
    E = filtfilt(b,a,E);
    N = filtfilt(b,a,N);
    Z = filtfilt(b,a,Z);
end

% Cut to window
E = E(ia:ib);
N = N(ia:ib);
Z = Z(ia:ib);
