function splitChevrot % This function automatically measured anisotropic parameters from yet measured data.


%% pre-processing of Shear-wave splitting
% necessary inputs:
% e, n, z, t   = amplitude and time vectors
%                raw data in geographic system
%                these will be rotated, filtered and detrended
% bazi, incli  = backazimuth and inclinationn of wave
% a, f         = begin and end of selection window (in sec)
%

global eq config

%d=dir('*.pjt');       % list the directory and search the pjt file

%for s=1:length(d)
    %load(d(s).name,'-mat')
    %load('BKS_SKS.pjt','-mat')


    for i = 1:length(eq)% Loop over each event with result
        if isempty(eq(i).results);
        
        else
            thiseq=eq(i);
            efile = fullfile(config.datadir, thiseq.seisfiles{1});
            nfile = fullfile(config.datadir, thiseq.seisfiles{2});
            zfile = fullfile(config.datadir, thiseq.seisfiles{3});
            if ~exist(efile,'file')||~exist(nfile,'file')||~exist(zfile,'file')
                errordlg({'Seismograms not found!','Please check data directory',efile,nfile,zfile},'File I/O Error')
                return
            end
        
    %% READ SEISMOGRAMS AND ROTATE
            thiseq  = readseis3D(config,thiseq);
            if isempty(thiseq.dt), return,end

                for num=1:length(eq(i).results)%Loop over number of results per event
                    inc = thiseq.results(num).incline;
                    baz = thiseq.bazi;
                    M   = rot3D(inc, baz); %the rotation matrix

                    ZEN = [thiseq.Amp.Vert, thiseq.Amp.East, thiseq.Amp.North]';
                    LQT = M * ZEN; %rotating

                    thiseq.Amp.Ray    = LQT(1,:);
                    thiseq.Amp.Radial = LQT(2,:);
                    thiseq.Amp.Transv = LQT(3,:);

                    thiseq.Amp.Rad    =  thiseq.Amp.North*cosd(baz)+thiseq.Amp.East*sind(baz);        
                    thiseq.Amp.Trans  = -thiseq.Amp.North*sind(baz)+thiseq.Amp.East*cosd(baz);

                    thiseq.filter = thiseq.results(num).filter;
                    if isfield(thiseq.results(num),'Spick')
                        thiseq.a = thiseq.results(num).Spick(1);
                        thiseq.f = thiseq.results(num).Spick(2);
                    else
                        thiseq.a = thiseq.results(num).a;
                        thiseq.f = thiseq.results(num).f;
                    end
                    T0 = thiseq.a;
                    T1 = thiseq.f;
                    DT = thiseq.dt;
    %%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    %%  BEGIN SPLITTING   
    %%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

                    fprintf(' Event: %s:%4.0f.%03.0f %s %2.0f (%3.0f/%3.0f)',...
                     config.stnname, thiseq.date(1), thiseq.date(7), thiseq.results(num).Qstr, thiseq.results(num).SNR(1),i , length(eq));

                    %% extend selection window
                    extime    = 20 ;%extend by 20sec
                    o         = thiseq.Amp.time(1);%common offset of all files after hypotime
                    extbegin  = floor( (thiseq.a-extime-o) / thiseq.dt);
                    extfinish = floor( (thiseq.f+extime-o) / thiseq.dt);
                    extIndex  = extbegin:extfinish;

                    % indices of selection window relative to extended window
                    ex = floor(extime/thiseq.dt);
                    w  = (ex+1):(length(extIndex)-ex);

                    %%
                    %E =  thiseq.Amp.East;
                    %N =  thiseq.Amp.North;
                    %Z =  thiseq.Amp.Vert;
                    
                    %Q = thiseq.Amp.Radial';
                    %T = thiseq.Amp.Transv';
                    %L = thiseq.Amp.Ray';

                    Q = thiseq.Amp.Rad;
                    T = thiseq.Amp.Trans;
                    L = thiseq.Amp.Ray';

                    %% Filtering
                    % the seismogram components are not yet filtered
                    % define your filter here.
                    % the selected corner frequencies are stored in the variable "thiseq.filter"
                    %
                    ny    = 1/(2*thiseq.dt);%nyquist freqency of seismogramm
                    n     = 3; %filter order
                    f1 = thiseq.filter(1);
                    f2 = thiseq.filter(2);
                    if f1==0 && f2==inf %ok no filter
                        % do nothing
                        % we leave the seismograms untouched
                    else
                        if f1 > 0  &&  f2 < inf
                            % bandpass
                            [b,a]  = butter(n, [f1 f2]/ny);
                        elseif f1==0 &&  f2 < inf
                            %lowpass
                            [b,a]  = butter(n, [f2]/ny,'low');%#ok

                        elseif f1>0 &&  f2 == inf
                            %highpass
                            [b,a]  = butter(n, [f1]/ny, 'high');%#ok
                        end
                        Qfil = filtfilt(b,a,Q)'; % Radial     (Q) component in extended time window
                        Tfil = filtfilt(b,a,T)'; % Transverse (T) component in extended time window
                        %Lfil = filtfilt(b,a,L)'; % Vertical   (L) component in extended time window

                    end

        
            %**************************************************************
            %% CHEVROT'S SPLITTING INTENSITY:

                    % Step 1: high pass filter 
                    fmax=8;
                    Q_HP=filtbuth(1/fmax,2,thiseq.dt,Q');
                    T_HP=filtbuth(1/fmax,2,thiseq.dt,T');
        
                    Time=thiseq.Amp.time;
                    %[x,maxAmp]=max(abs(Qfil));%#ok
                    %Tmax = Time(maxAmp);
                    T0= T0-5;
                    T1= T1+5;

                    %  For real data, the user should choose a deconvolution window in each
                    %  data. The deconvolution window should contain the SK(K)S phase.
                    i0=find(Time>=T0,1,'first');
                    i1=find(Time>=T1,1,'first');
                    reg = 0.5; % regularization parameter for deconvolution;
                    [RadialDeconv,TransverseDeconv]...
                        = Deconvolue(Qfil,Tfil,i0,i1,reg);
                        %= Deconvolue(Q_HP,T_HP,i0,i1,reg);
    
                    %  Wiener filter:               
                    m   = 2^max((nextpow2(length(RadialDeconv)) - 1), 12);
                    Y   = fft(RadialDeconv, m);
                    Pyy = Y.* conj(Y) / m;
                    [tmp, ind] = max(Pyy(1:m/2));
                    %domfreq = 1/thiseq.dt*(ind)/m;
                
                    regw = 0.0001;  % regularization parameter
                    %tau  = 2/domfreq; % dominant period = tau/2
                    tau=30;
                    [RadialWiener,TransverseWiener] ...
                        = WienerFilter(RadialDeconv, TransverseDeconv, DT, tau, regw, i0, i1);
        
                    splitIntens=zeros(1,2);
                    [splitIntens(1,1), splitIntens(1,2)] = splitting_intensity(RadialWiener, TransverseWiener, DT);

     

                    %% Assign results field to global variable
                    % first temporary, since we don't know if results will be used
                    % Later, within the diagnostic plot, the result may be assigned to the
                    % permanent eq.results-structure
                    %
                    thiseq.tmpresult.SI   = splitIntens;


            %% finishing  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                    fprintf([ ' -- SI value:', num2str(splitIntens(1,1),2), ' ± ', num2str(splitIntens(1,2),2), '\n']);


            %% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            %%    END SPLITTING
            %% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++



                    %% copy result to permanent "eq" variable
        
                    eq(i).results(num).SI           = thiseq.tmpresult.SI;        
                    eq(i).results(num).ErrorSurface = [];

                end %Result Loop
        end %empty check
        fclose all;
    end% eq loop

    filename    = fullfile(config.projectdir,config.project);
    config.db_index = thiseq.index;
    save(filename,'eq','config');
    fclose all;
%end% project loop

