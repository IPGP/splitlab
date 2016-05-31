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

if any(2 ~= [exist(efile,'file') exist(nfile,'file') exist(zfile,'file')  ])
    errordlg({'Files do not exist:',efile, nfile, zfile })
    out=0;
    return
end
s = findobj('Tag','Statusbar');
try
    e = rsac(efile);set(s,'String', '  Status:   Reading seismograms ... East');drawnow
    n = rsac(nfile);set(s,'String', '  Status:   Reading seismograms ... East North');drawnow
    v = rsac(zfile);set(s,'String', '  Status:   Reading seismograms ... East North Vertical');drawnow
catch
    e = rsacsun(efile);set(s,'String', '  Status:   Reading seismograms ... East');drawnow
    n = rsacsun(nfile);set(s,'String', '  Status:   Reading seismograms ... East North');drawnow
    v = rsacsun(zfile);set(s,'String', '  Status:   Reading seismograms ... East North Vertical');drawnow
end

%% get SAC header markers:

[A(1), F(1), O(1) , T0(1), T1(1), T2(1), T3(1), T4(1), T5(1), T6(1), T7(1), T8(1), T9(1)] = ...
    lh(e, 'A', 'F', 'O' ,'T0' , 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9');
[A(2), F(2), O(2) , T0(1), T1(1), T2(1), T3(1), T4(1), T5(1), T6(1), T7(1), T8(1), T9(1)] = ...
    lh(n, 'A', 'F', 'O' ,'T0' , 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9');
[A(3), F(3), O(3) , T0(1), T1(1), T2(1), T3(1), T4(1), T5(1), T6(1), T7(1), T8(1), T9(1)] = ...
    lh(v, 'A', 'F', 'O' ,'T0' , 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9');

A = A(A~=-12345);
F = F(F~=-12345);
O = O(O~=-12345);
T0 = T0(T0~=-12345);
T1 = T1(T1~=-12345);
T2 = T2(T2~=-12345);
T3 = T3(T3~=-12345);
T4 = T4(T4~=-12345);
T5 = T5(T5~=-12345);
T6 = T6(T6~=-12345);
T7 = T7(T7~=-12345);
T8 = T8(T8~=-12345);
T9 = T9(T9~=-12345);
if isempty(A); A = nan;  F = nan;   end
if isempty(F); A = nan;  F = nan;   end
A = mean(A(:) + thiseq.offset(:));
F = mean(F(:) + thiseq.offset(:));




names = {' A', ' F', ' O' ,' T0' , ' T1', ' T2', ' T3', ' T4', ' T5', ' T6', ' T7', ' T8', ' T9'};
if isempty(O);     O  = nan; else    O  = mean(O(:)  + thiseq.offset(:)); end
if isempty(T0);    T0 = nan; else    T0 = mean(T0(:) + thiseq.offset(:));  tmp = lh(e,'KT0'); if ~strcmp(deblank(tmp), '-12345'); names{4}=[' ' deblank(tmp)];end;  end
if isempty(T1);    T1 = nan; else    T1 = mean(T1(:) + thiseq.offset(:));  tmp = lh(e,'KT1'); if ~strcmp(deblank(tmp), '-12345'); names{5}=[' ' deblank(tmp)];end;  end
if isempty(T2);    T2 = nan; else    T2 = mean(T2(:) + thiseq.offset(:));  tmp = lh(e,'KT2'); if ~strcmp(deblank(tmp), '-12345'); names{6}=[' ' deblank(tmp)];end;  end
if isempty(T3);    T3 = nan; else    T3 = mean(T3(:) + thiseq.offset(:));  tmp = lh(e,'KT3'); if ~strcmp(deblank(tmp), '-12345'); names{7}=[' ' deblank(tmp)];end;  end
if isempty(T4);    T4 = nan; else    T4 = mean(T4(:) + thiseq.offset(:));  tmp = lh(e,'KT4'); if ~strcmp(deblank(tmp), '-12345'); names{8}=[' ' deblank(tmp)];end;  end
if isempty(T5);    T5 = nan; else    T5 = mean(T5(:) + thiseq.offset(:));  tmp = lh(e,'KT5'); if ~strcmp(deblank(tmp), '-12345'); names{9}=[' ' deblank(tmp)];end;  end
if isempty(T6);    T6 = nan; else    T6 = mean(T6(:) + thiseq.offset(:));  tmp = lh(e,'KT6'); if ~strcmp(deblank(tmp), '-12345'); names{10}=[' ' deblank(tmp)];end; end
if isempty(T7);    T7 = nan; else    T7 = mean(T7(:) + thiseq.offset(:));  tmp = lh(e,'KT7'); if ~strcmp(deblank(tmp), '-12345'); names{11}=[' ' deblank(tmp)];end; end
if isempty(T8);    T8 = nan; else    T8 = mean(T8(:) + thiseq.offset(:));  tmp = lh(e,'KT8'); if ~strcmp(deblank(tmp), '-12345'); names{12}=[' ' deblank(tmp)];end; end
if isempty(T9);    T9 = nan; else    T9 = mean(T9(:) + thiseq.offset(:));  tmp = lh(e,'KT9'); if ~strcmp(deblank(tmp), '-12345'); names{13}=[' ' deblank(tmp)];end; end







%% shift time vector
%offset is negativ, if file begins before origin time
offset = floor(thiseq.offset*10^8)/10^8;
e(:,1) = e(:,1) + offset(1);
n(:,1) = n(:,1) + offset(2);
v(:,1) = v(:,1) + offset(3);

%% check sampling rate
dt = [single(lh(e,'DELTA')) single(lh(n,'DELTA')) single(lh(v,'DELTA')) ];
dt = 1./double(1./dt);

if length(unique(dt)) > 1 %check if sampling rate is equal
    disp('resampling of seismogram neccesary')
    beep
    [r,d] = rat(max(dt)./dt);
    if any(d~=1),
        disp('ERROR: impossible to handle SAC time vector')
        disp(['   Mean sampling rates (E, N, Z):    [' num2str(1./dt) ']Hz'])
        disp( '   Please check "B" and "E" header entries')
        error('   Cannot treat sampling rate of seismograms')
    end
    e = e(2, 1:r(1):end);
    n = n(2, 1:r(2):end);
    v = v(2, 1:r(3):end);
end
dt=max(dt);

%% times relative to origin time
thestart = max([e(1,1)   n(1,1)   v(1,1)  ]);% adding half a sample
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
% EastAmp  = detrend(e,'constant');
% EastAmp  = detrend(EastAmp,'linear');
% NorthAmp = detrend(n,'constant');
% NorthAmp = detrend(NorthAmp,'linear');
% VertAmp  = detrend(v,'constant');
% VertAmp  = detrend(VertAmp,'linear');

 EastAmp  = e;
 NorthAmp = n;
 VertAmp  = v;


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


