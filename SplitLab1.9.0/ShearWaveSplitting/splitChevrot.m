function splitIntens = splitChevrot(trN, trE, baz, dt, time, T0, T1, f)

Q = trN*cosd(baz)+trE*sind(baz);  % radial component
T = -trN*sind(baz)+trE*cosd(baz); % transverse component
                                  
% filtering of the traces:
ny = 1/(2*dt);
f1 = f(1);
f2 = f(2);
n  = f(3);
               
if f1==0 && f2==inf % i.e. no filter
    Qfil = Q';
    Tfil = T';
else
    if f1 > 0  &&  f2 < inf % bandpass
        [b,a]  = butter(n, [f1 f2]/ny);
    elseif f1==0 &&  f2 < inf % lowpass
        [b,a]  = butter(n, f2/ny,'low');
    elseif f1>0 &&  f2 == inf % highpass
        [b,a]  = butter(n, f1/ny, 'high');
    end
    Qfil = filtfilt(b,a,Q)'; % Radial     (Q) component
    Tfil = filtfilt(b,a,T)'; % Transverse (T) component
end
               
% extend the time window
T0 = T0-5;
T1 = T1+5;
               
% Deconvolution of the trace
i0  = find(time>T0, 1, 'first');
i1  = find(time>T1, 1, 'first');
reg = 0.5;
[RadialDeconv, TransverseDeconv] = Deconvolue(Qfil,...
                                              Tfil,...
                                              i0,...
                                              i1,...
                                              reg);

% Wiener filter (see Monteiller & Chevrot (2011))
regw = 0.0001;
tau  = 30;
[RadialWiener, TransverseWiener] = WienerFilter(RadialDeconv,...
                                                TransverseDeconv,...
                                                dt,...
                                                tau,...
                                                regw,...
                                                i0,...
                                                i1);

% computation of the splitting intensity 
splitIntens = zeros(1,2);
[splitIntens(1,1), splitIntens(1,2)] = splitting_intensity(RadialWiener,...
                                                           TransverseWiener,...
                                                           dt);
