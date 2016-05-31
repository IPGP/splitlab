function out = readseis3D(config,thiseq)
% read three seismograms (eq(i).seisfiles{1:3}) and rotate in 3D
% add to thiseq-structure the fields Amp (E, N, Z, Q, T, L components)
% times vector and dt(sampling rate)
%
% The sesimogramms are shifted by offset time (difference between hypo time
% and beginn of seimogram) and are cut to common times
%
% AW Feb. 2006

%% CHANGES
% 17.02.06 - offset negative for times before hypotime
%          - possible to use startr times other than zero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%read in
efile = fullfile(config.datadir, thiseq.seisfiles{1});
nfile = fullfile(config.datadir, thiseq.seisfiles{2});
zfile = fullfile(config.datadir, thiseq.seisfiles{3});

if any(0 == [exist(efile,'file') exist(nfile,'file') exist(zfile,'file')  ])
    errordlg('Files do not exist')
    return
end
s = findobj('Tag','Statusbar');
sac(1) = readsac(efile);set(s,'String', '  Status:   Reading seismograms ... East');drawnow
sac(2) = readsac(nfile);set(s,'String', '  Status:   Reading seismograms ... East North');drawnow
sac(3) = readsac(zfile);set(s,'String', '  Status:   Reading seismograms ... East North Vertical');drawnow



% try
%     e = rsac(efile);set(s,'String', '  Status:   Reading seismograms ... East');drawnow
%     n = rsac(nfile);set(s,'String', '  Status:   Reading seismograms ... East North');drawnow
%     v = rsac(zfile);set(s,'String', '  Status:   Reading seismograms ... East North Vertical');drawnow
% catch
%     e = rsacsun(efile);set(s,'String', '  Status:   Reading seismograms ... East');drawnow
%     n = rsacsun(nfile);set(s,'String', '  Status:   Reading seismograms ... East North');drawnow
%     v = rsacsun(zfile);set(s,'String', '  Status:   Reading seismograms ... East North Vertical');drawnow
% end

%% get SAC header markers:



A = mean([sac(:).A] + thiseq.offset(:));
F = mean([sac(:).F] + thiseq.offset(:));

names = {' A', ' F', ' O' ,' T0' , ' T1', ' T2', ' T3', ' T4', ' T5', ' T6', ' T7', ' T8', ' T9'};





%% shift time vector
%offset is negativ, if file begins before origin time
offset = floor(thiseq.offset*10^8)/10^8;
sac(:).B = e(:,1) + offset(1);
n(:,1) = n(:,1) + offset(2);
v(:,1) = v(:,1) + offset(3);

%% check sampling rate
dt = [sac(:).DELTA ];

%% times relative to origin time
thestart = max([sac(:).B] + offset );% adding half a sample
theend   = min([e(end,1) n(end,1) v(end,1)]);% for excluding accidential overlap

if thestart>theend
    Err =errordlg({['Files do not cover the same time window at earthquake #' num2str(config.db_index)],...
        ' ',thiseq.seisfiles{:},...
        ' ', 'Skipping to next event...'},'Error opening files');
    waitfor(Err)
    out = config.db_index+1;

    return
end


%% synchonize seismograms: cut at times common to all 3 seismograms
indE = find(e(:,1)>thestart & e(:,1)<theend);%FIRST SAC coloumn REPRESENTS TIME VECTOR
indN = find(n(:,1)>thestart & n(:,1)<theend);
indV = find(v(:,1)>thestart & v(:,1)<theend);


% Vectors should be same size, but to be sure, take shortest length
L = min([length(indE) length(indN) length(indV) ]);
e = e( indE(1:L), 2 ); %SECOND SAC coloumn REPRESENTS AMPLITUDE
n = n( indN(1:L), 2 );
v = v( indV(1:L), 2 );
tvec = linspace(thestart, theend, size(e,1));


% s        = sign(log10(1/thestart)).*round(abs(log10(1/thestart))) ;
% thestart = round(10.^(sign(s).*s) .* thestart) .* 10.^-(sign(s).*s);
% tvec = thestart:dt:(thestart+(L-1)*dt);

%% interpolate if neccesary

if ~strcmp('raw', config.resamplingfreq)
    newdt = 1/str2num(config.resamplingfreq);
    if (dt/newdt*L)>100000
        ans =questdlg('This resampling frequency will result in more than 10^6 data points. This may slow down Splitlab!',...
            'Lots of data',...
            'Oops, I will better re-think that','Thanks, but I know what I am doing','Thanks, but I know what I am doing');
        if strcmp(ans, 'Oops, I will better re-think that')
           set(s,'String', sprintf('Status:  Using raw data sampling frequency... '));drawnow 
           newdt =dt;
           evalin('base','config.resamplingfreq=''raw'';');
        end
    end
    if dt ~= newdt
        s = findobj('Tag','Statusbar');
        set(s,'String', sprintf('Status:  %s-Interpolation to new sampling frequency %sHz... ', config.interpolmethod ,config.resamplingfreq));drawnow

        tvec_old=tvec;
        tvec=thestart:newdt:theend;
        Y  = [e n v];
        Yi = interp1(tvec_old', Y, tvec',config.interpolmethod );
        e  = Yi(:,1);
        n  = Yi(:,2);
        v  = Yi(:,3);
        dt=newdt;
        set(s,'String', sprintf('Status:  %s-Interpolation to new sampling frequency %sHz... Done', config.interpolmethod ,config.resamplingfreq));drawnow
    end
end

%%    % remove mean & trend
EastAmp  = detrend(e,'constant');
EastAmp  = detrend(EastAmp,'linear');
NorthAmp = detrend(n,'constant');
NorthAmp = detrend(NorthAmp,'linear');
VertAmp  = detrend(v,'constant');
VertAmp  = detrend(VertAmp,'linear');

%% Perform station correction:
a = config.rotation/180*pi;
M = [ cos(a) sin(a);
    -sin(a) cos(a)];

New      = M * [EastAmp NorthAmp]';
if config.SwitchEN
    EastAmp  = New(2,:)' * config.signE;
    NorthAmp = New(1,:)' * config.signN;
else
    EastAmp  = New(1,:)' * config.signE;
    NorthAmp = New(2,:)' * config.signN;
end
VertAmp = VertAmp * config.signZ;


% NewAmp  = [EastAmp, NorthAmp, VertAmp] * config.rotMatrix;


%% ========================================================================
out = thiseq;
out.Amp.East   = EastAmp;
out.Amp.North  = NorthAmp;
out.Amp.Vert   = VertAmp;
out.Amp.time   = tvec;
out.dt         = dt;

picks = [A F O T0 T1 T2 T3 T4 T5 T6 T7 T8 T9 ];
% names = {' A', ' F', ' O' ,' T0' , ' T1', ' T2', ' T3', ' T4', ' T5', ' T6', ' T7', ' T8', ' T9'};
n     = isnan(picks);

out.SACpicks     = picks(~n);
out.SACpickNames = names(~n);


