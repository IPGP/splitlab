function preSplit(isBatchMode)
%% pre-processing of Shear-wave splitting
% input is a logical determine wither batch processing or not batch
% OUTPUT:
%

global thiseq config eq


%%
if nargin==0
    isBatchMode=false;
end

if ~isfield(thiseq, 'Spick') || (isempty(thiseq.Spick(1)) && isempty(thiseq.Spick(2)))
    errordlg('no time window picked for S-phase ... Sorry, can''t split','Error')
    return
end

if  strcmp('Minimum Energy', config.splitoption) &&  strcmp('estimated', config.inipoloption)
    answ =questdlg('Minimum energy method assumes an initial polarisation parallel to the backazimuth. Your settings still estimate the polaristion. Are you sure you want to continue?',...
        'Minimum Energy?','Ooops, I better check my settings', 'I know what I am doing', 'Ooops, I better check my settings');
    if strcmp(answ, 'Ooops, I better check my settings')
        return
    end
end

if diff(thiseq.Spick) < 1.2*config.maxSplitTime
    answ =questdlg(['Your picked S-window is rather short (' num2str(diff(thiseq.Spick)) 'sec) compared to maximum delay time (' num2str(config.maxSplitTime)  'sec). Are you sure you want to continue?'],...
        'Too short...','Ooops, I better check my settings', 'I know what I am doing', 'Ooops, I better check my settings');
    if strcmp(answ, 'Ooops, I better check my settings')
        return
    end
end
if  strcmp('Minimum Energy', config.splitoption) && isempty(strfind(thiseq.SplitPhase,'KS'))
    answ =questdlg({'Eigenvalue methods for non-core-refracted waves (*KS) do only work if the S-polarisation is estimated from the S-Waveform. Are you sure you want to continue?',...
        ' ' ,['You currently have the "' thiseq.SplitPhase '" phase selected.']},...
        'Minimum Energy?','Ooops, I better check my settings', 'I know what I am doing', 'Ooops, I better check my settings');
    if strcmp(answ, 'Ooops, I better check my settings')
        return
    end
end


fprintf(' %s -- Estimating event  %s:%4.0f.%03.0f (%.0f/%.0f) --',...
    datestr(now,13) , config.stnname, thiseq.date(1), thiseq.date(7),config.db_index, length(eq));


%% stacking
n         = 0;
Qmax      = -inf;
Qsum      = 0;
if isBatchMode
    teststring = sprintf('%1d %1d',config.batch.useFilterInBatch,  config.batch.useWindowsInBatch);
    switch teststring % switch does not take arrays, so use this workaround ;-)
        case '1 1'
            nmax = sum(config.filterset(:,5)) *  config.batch.nStartWin * config.batch.nStopWin;
        case '1 0'
            nmax = sum(config.filterset(:,5)) ;
        case '0 1'
            nmax = config.batch.nStartWin * config.batch.nStopWin;
        case '0 0'
            nmax = 1;
            isBatchMode = 0;
    end
else
    nmax = 1;
end
Qvector(1:nmax)=nan;
splitIntens(1:nmax,1:2)=nan;

if isBatchMode && config.batch.useFilterInBatch
    idx    = find(config.filterset(:,5)==1);
    f1     = config.filterset(idx,2);
    f2     = config.filterset(idx,3);
    npoles = config.filterset(idx,4);
else %use current filter
    f1     = thiseq.filter(1);
    f2     = thiseq.filter(2);
    npoles = thiseq.filter(3);
end


%% Start the loops for Filter, Start- and End-Window
%  these as all set to one for non-bath mode...

ttime = now;
sbar=findobj('Tag','Statusbar');

for ii=1:length(f1)
    
    %% Get Seismograms....
    [tmp_SG, tmp_SH,extime,winStartVec,winStopVec]= localGetFilteredSeismograms(isBatchMode, f1(ii), f2(ii), npoles(ii));
    %%
    thiseq.filter = [f1(ii),f2(ii),npoles(ii)];
    SL_updatefiltered(flipud(findobj('Tag','seismo')));
    
    if isBatchMode && config.batch.useFilterInBatch
        set(sbar,'String',sprintf('Status: Batch mode using filter  %.3f -- %.3f Hz',f1(ii),f2(ii) ));drawnow;
    end
    
    count=0;
    countmax=length(winStartVec)*length(winStopVec);
    for kk = 1:length(winStartVec)
        for jj = 1:length(winStopVec)
            count=count+1;
            n=n+1;
            t1 = winStartVec(end) - winStartVec(kk) ;
            t2 = winStopVec(jj)   - winStartVec(kk) ;
 
            i1 = round((extime-t1) / thiseq.dt);
            i2 = i1 + round(t2 / thiseq.dt);
            
            w = i1:i2;
            hsplit = findobj('Tag','SplitWindow');
            
            xx = [winStartVec(kk) winStopVec(jj); winStartVec(kk) winStopVec(jj)] ;
            
            %**************************************************************
            % SPLITTING METHODS
            if isBatchMode
                set(hsplit, 'Xdata', xx(:), 'FaceColor', config.Colors.SselectionColor.*[1 1 .6])
            end

            if ~isBatchMode
                set(sbar,'String',['Status: Calculating ' config.splitoption ' Method']);
                drawnow;
            end

            [tmp_phiSC, tmp_dtSC, tmp_phiEV, tmp_dtEV,  Ematrix, tmp_FSsc, tmp_SG_SH_corSC, tmp_Eresult, tmp_gamma] = ...
                splitSilverChan(tmp_SG,...
                                tmp_SH,...
                                w,...
                                thiseq.dt,....
                                config.maxSplitTime, ...
                                config.splitoption,...
                                isBatchMode,...
                                config.StepsPhi,...
                                config.StepsDT);
            if strcmp(config.inipoloption, 'fixed')
                tmp_gamma=0;
            end

            if ~isBatchMode
                set(sbar,'String','Status: Calculating with Rotation-Correlation method');
                drawnow;
            end

            [tmp_phiRC, tmp_dtRC, Cmap, tmp_FSrc, tmp_SG_SH_corRC, tmp_Cresult] = ...
                splitRotCorr(tmp_SG,...
                             tmp_SH,...
                             w,...
                             config.maxSplitTime,...
                             thiseq.dt,...
                             isBatchMode, ...
                             config.StepsPhi,...
                             config.isWeiredMAC);
            
            if strcmp(config.studytype,'Teleseismic')
                %%% CHEVROT's Splitting Intensity:
                reg = 0.5; % regularization parameter for deconvolution;
                [RadialDeconv,TransverseDeconv]...
                    = Deconvolue(tmp_SG', tmp_SH', w(1),w(end),reg);
                
                %  Wiener filter:
                m   = 2^max((nextpow2(length(RadialDeconv)) - 1), 12);
                Y   = fft(RadialDeconv, m);
                Pyy = Y.* conj(Y) / m;
                [~, ind]     = max(Pyy(1:m/2));
                domfreq = 1/thiseq.dt*(ind)/m;
                
                regw = 0.0001;  % regularization parameter
                tau  = 2/domfreq; % dominant period = tau/2
                [RadialWiener,TransverseWiener] ...
                    = WienerFilter(RadialDeconv, TransverseDeconv, thiseq.dt, tau, regw, w(1), w(end));
                
                % splitting intensity analysis
                splitIntens(n,1:2) = splitting_intensity(RadialWiener, TransverseWiener, thiseq.dt);
            end

            % put values in temporary variables ...
            switch config.splitoption
                case 'Minimum Energy'
                    Q = NullCriterion(tmp_phiSC(1), tmp_phiRC(1), tmp_dtSC(1), tmp_dtRC(1));
                otherwise
                    Q = NullCriterion(tmp_phiEV(1), tmp_phiRC(1), tmp_dtEV(1), tmp_dtRC(1));
            end
            
            Qvector(n)=Q;
            Qsum  = Qsum + Q;
            Qmean = Qsum/n;
            if Q > Qmax;
            end
            allFasts(n,1:3)  = [ tmp_phiRC   tmp_phiSC   tmp_phiEV];
            allDelays(n,1:3) = [ tmp_dtRC    tmp_dtSC    tmp_dtEV];
            
            
            if ~isBatchMode
                useThis=1;
            else
                switch config.batch.bestMesurementMethod
                    case 1 %'Maximum Q-value'
                        if Q > Qmax;                             useThis=1;   else  useThis=0;   end
                    case 2 %'Maximum absolute Q-value'
                        if isinf(Qmax) || abs(Q) > abs(Qmax) ;   useThis=1;   else  useThis=0;   end
                    case 3 %'Weighted max Q-value',
                        if Q > Qmax ;                            useThis=1;   else  useThis=0;   end
                    case 4 %'Weighted max abs Q-value',
                        if isinf(Qmax) || abs(Q) > abs(Qmax) ;   useThis=1;   else  useThis=0;   end
                    case 5 %stacking
                        useThis=0;
                        if n==1
                            CmapStack        =  Cmap           / tmp_Cresult ;%
                            EmapStack(:,:,1) =  Ematrix(:,:,1) / tmp_Eresult(1);
                            EmapStack(:,:,2) =  Ematrix(:,:,2) / tmp_Eresult(2) * sign(tmp_Eresult(2));
                        else
                            CmapStack        = CmapStack        + Cmap           / tmp_Cresult;
                            EmapStack(:,:,1) = EmapStack(:,:,1) + Ematrix(:,:,1) / tmp_Eresult(1);
                            EmapStack(:,:,2) = EmapStack(:,:,2) + Ematrix(:,:,2) / tmp_Eresult(2) * sign(tmp_Eresult(2));
                        end
                        param(n,:)= [i1 i2 f1(ii), f2(ii), npoles(ii)];
                    case 6 %cluster analysis                        
                        useThis=0;
                        param(n,:)= [i1 i2 f1(ii), f2(ii), npoles(ii)];
                        thispick(n,:) = [winStartVec(kk) winStopVec(jj)];

%                         if n==1
%                             tmpMapArray = zeros (size(Cmap,1), size(Cmap,2), nmax,3);
%                         end
%                         %save the error surface in temparray,later use that
%                         %one closest to the cluster mean
%                         tmpMapArray(:,:,n,1)= Cmap;
%                         tmpMapArray(:,:,n,2)= Ematrix(:,:,2);
%                         tmpMapArray(:,:,n,3)= Ematrix(:,:,2);
                end
            end
            
            if useThis
                phiRC       = tmp_phiRC;
                dtRC        = tmp_dtRC  ;
                FSrc        = tmp_FSrc;
                SG_SH_corRC = tmp_SG_SH_corRC;
                
                phiEV       = tmp_phiEV;
                dtEV        = tmp_dtEV  ;
                phiSC       = tmp_phiSC;
                dtSC        = tmp_dtSC    ;
                FSsc        = tmp_FSsc;
                SG_SH_corSC = tmp_SG_SH_corSC;
                SG          = tmp_SG;
                SH          = tmp_SH;
                
                bestfilter  = [f1(ii) f2(ii) npoles(ii)];
                
                gamma       = tmp_gamma;
                
                Cresult = tmp_Cresult;
                Eresult = tmp_Eresult;
                CmapStack =  Cmap;
                EmapStack =  Ematrix;
                
                wbest = w;
                Qmax  = Q;
                SpickBest = [winStartVec(kk) winStopVec(jj)];
            end
            
           
            if isBatchMode
                progress = [  count/countmax  n/nmax ];
                progresstxt = {...
                    sprintf('This Quality: %.3f  Mean: %.3f',Q,Qmean),...
                    sprintf('Filter  %.3f -- %.3f Hz  Best: %.3f',f1(ii),f2(ii),abs(Qmax)' )};
                if n==1
                    hndl = workbar2(progress, progresstxt,'Multi-Window');
                else
                    if ishandle(hndl)
                        workbar2(progress, progresstxt,'Multi-Window');
                    else %has been closed => abort
                        xx = [thiseq.Spick; thiseq.Spick]  ;
                        set(hsplit, 'Xdata', xx(:), 'FaceColor',config.Colors.SselectionColor)
                        set(gcbf,'Pointer','crosshair')
                        set(sbar,'String','Status: Batch processing aborted by user');drawnow;
                        fprintf(2, 'Aborted... \n')%#ok
                        return
                    end
                end
            end
        end
    end
end %filter stacking


%% now post-processing
if  isBatchMode && config.batch.bestMesurementMethod > 4
    if config.batch.bestMesurementMethod==5
        %Cresult   = -max(CmapStack(:))/n;
        %Eresult   = [1 sign(tmp_Eresult(2))];
        CmapStack = -CmapStack / n;
        EmapStack = EmapStack / n;
        Eresult   = [1 min(min(EmapStack(:,:,2)))];
        
        %     find minimum in respective error surface
        [phiRC, dtRC]  = localGetMinimum(CmapStack);
        [phiSC, dtSC]  = localGetMinimum(EmapStack(:,:,1));
        [phiEV, dtEV]  = localGetMinimum(EmapStack(:,:,2));

    elseif  config.batch.bestMesurementMethod==6
        %Cluster analysis
        i1 = allDelays(:,1)>0 &  allDelays(:,1)<config.maxSplitTime*.999;
        i2 = allDelays(:,2)>0 &  allDelays(:,2)<config.maxSplitTime*.999;
        i3 = allDelays(:,3)>0 &  allDelays(:,3)<config.maxSplitTime*.999;
        [dtRC, phiRC, bestRC] =  clusteranal(allDelays(i1,1), allFasts(i1,1) , thiseq.dt*config.StepsDT, config.StepsPhi);
        [dtSC, phiSC, bestSC] =  clusteranal(allDelays(i2,2), allFasts(i2,2) , thiseq.dt*config.StepsDT, config.StepsPhi);
        [dtEV, phiEV, bestEV] =  clusteranal(allDelays(i3,3), allFasts(i3,3) , thiseq.dt*config.StepsDT, config.StepsPhi);
        
        phiRC = phiRC(bestRC); 
        phiSC = phiSC(bestSC); 
        phiEV = phiEV(bestEV);
        dtRC  = dtRC(bestRC);
        dtSC  = dtSC(bestSC);
        dtEV  = dtEV(bestEV);
    end
    
    %     find window and filter closest to that minimum
    y   = (allFasts  -  repmat([ phiRC  phiSC   phiEV], size(allFasts,1),  1)   );
    x   = (allDelays -  repmat([ dtRC    dtSC    dtEV], size(allDelays,1), 1)   );

    %normalize
    y   = y/180;
    x   = x/config.maxSplitTime;
    dis = sqrt(x.^2 + y.^2);
    [~,closest] = min(dis);
%     SpickBest = [winStartVec(closest(3)) winStopVec(jj)];
    
    
    switch config.splitoption
        case 'Minimum Energy'
            Qmax = NullCriterion(phiSC(1), phiRC(1), dtSC(1), dtRC(1));
            bestpara   = param(closest(2),:);
            SpickBest = [winStartVec(closest(2)) winStopVec(closest(2))];
        otherwise
            bestpara   = param(closest(3),:);
            Qmax = NullCriterion(phiEV(1), phiRC(1), dtEV(1), dtRC(1));
            SpickBest = [winStartVec(closest(3)) winStopVec(closest(3))];
    end
    
    bestparaXC   = param(closest(1),:);
    bestfilterXC = bestparaXC(3:4);
    bestfilter   = bestpara(3:4);
    
    wbestXC      = bestparaXC(1):bestparaXC(2);
    wbest        = bestpara(1):bestpara(2);
    
    % redo splitting with best parameter set
    thiseq.filter = [bestfilter(1), bestfilter(2), bestpara(5)];
    SL_updatefiltered(flipud(findobj('Tag','seismo')));
    
    [SG, SH] = localGetFilteredSeismograms(true, bestfilter(1), bestfilter(2) , bestpara(5));
    
    %**************************************************************
    % SPLITTING METHODS
    [~, ~, ~, ~,  Ematrix, FSsc, SG_SH_corSC, Eresult2, gamma] = ...
        splitSilverChan(SG, SH, wbest, thiseq.dt, config.maxSplitTime, config.splitoption, false, config.StepsPhi, config.StepsDT);
    if  ~config.batch.bestMesurementMethod==5
        Eresult=Eresult2;
    end
    if strcmp(config.inipoloption, 'fixed')
        gamma=0;
    end
    if  config.batch.bestMesurementMethod==6
        [tmp_SG, tmp_SH] = localGetFilteredSeismograms(true, bestfilterXC(1), bestfilterXC(2) , bestparaXC(5));
    end
    [~, ~, CmapStack, FSrc, SG_SH_corRC, Cresult] = ...
        splitRotCorr(tmp_SG, tmp_SH, wbestXC,config.maxSplitTime, thiseq.dt, false, config.StepsPhi,config.isWeiredMAC);

    if  config.batch.bestMesurementMethod==6
        EmapStack = Ematrix;
        switch config.splitoption %determine wihcih errorsurface to use...
            case 'Minimum Energy'
                Qmax = NullCriterion(phiSC, phiRC, dtSC, dtRC);
            otherwise
                Qmax = NullCriterion(phiEV, phiRC, dtEV, dtRC);
        end
    end
    
    
end

thiseq.filter = bestfilter;
SL_updatefiltered(flipud(findobj('Tag','seismo'))); 

%weighting of quality
if config.batch.bestMesurementMethod==3 || config.batch.bestMesurementMethod ==4 || config.batch.bestMesurementMethod ==6
   Qmax  = 2/3*Qmax + 1/3*Qmean;
end

thiseq.Q  = Qmax;
w  = wbest;
thiseq.Spick = SpickBest;
xx = [thiseq.Spick; thiseq.Spick]  ;
set(hsplit, 'Xdata', xx(:), 'FaceColor',config.Colors.SselectionColor)
set(gcbf,'Pointer','crosshair')


%**************************************************************
%% PostProcessing and Graphics preparation

%gamma is mathematically positive from SG towards SH...
M = [ cosd(gamma)  sind(gamma);
    -sind(gamma)  cosd(gamma)   ];

QTini   = M * [SG, SH]';   %rotating input wave forms
QTcorRC = M * SG_SH_corRC'; %rotating corrected wave forms
QTcorSC = M * SG_SH_corSC';

QTcorRC = detrend(QTcorRC','linear'); QTcorRC = detrend(QTcorRC,'constant');
QTcorSC = detrend(QTcorSC','linear'); QTcorSC = detrend(QTcorSC,'constant');
FSrc = detrend(FSrc,'linear');        FSrc    = detrend(FSrc,'constant');
FSsc = detrend(FSsc,'linear');        FSsc    = detrend(FSsc,'constant');


%% **************************************************************
%Signal-To-Noise ratio
SNR  = [...
    max(abs(QTcorRC(:,1))) / (2*std(QTcorRC(:,2)));   %SNR_QT on same window after correction (like Restivo & Helffrich,1998)
    max(abs(QTcorSC(:,1))) / (2*std(QTcorSC(:,2)))... %SNR_QT on same window after correction (like Restivo & Helffrich,1998)
    ];


% dominant frequency:
m   = 2^max((nextpow2(1/thiseq.dt) - 1), 12);
Y   = fft(QTcorSC(:,1), m);
Pyy = Y.* conj(Y) / m;
[~, ind]     = max(Pyy(1:m/2,:));
thiseq.domfreq = 1/thiseq.dt*(ind)/m;


%%
set(sbar,'String','Status: Calculating confidence regions');drawnow

[errbar_phiRC, errbar_tRC, LevelRC] = geterrorbarsRC(QTini(2,w)', CmapStack,           Cresult);
[errbar_phiSC, errbar_tSC, LevelSC, ndfSC] = geterrorbars(  QTini(2,w)', EmapStack(:,:,1), Eresult(1));
[errbar_phiEV, errbar_tEV, LevelEV, ~] = geterrorbars(  QTini(2,w)', EmapStack(:,:,2), Eresult(2));

phiRC   = [phiRC   errbar_phiRC(1)];
dtRC    = [dtRC    errbar_tRC(1)  ];
phiSC   = [phiSC   errbar_phiSC(1)];
dtSC    = [dtSC    errbar_tSC(1)  ];
phiEV   = [phiEV   errbar_phiEV(1)];
dtEV    = [dtEV    errbar_tEV(1)  ];

fprintf(' Phi = %5.1f; %5.1f; %5.1f    dt = %.1f; %.1f; %.1f\n', ...
    phiRC(1), phiSC(1), phiEV(1), dtRC(1), dtSC(1), dtEV(1));

caltime = (now - ttime)*24*3600;


%% 3D correction: project to geographical system
%initial polarisation as the strike...

[thiseq.tmpresult.strikes, thiseq.tmpresult.dips ] = abc2enz(...
    thiseq.selectedpol, ...
    thiseq.selectedinc, ...
    [phiRC(1) phiSC(1) phiEV(1)]);

thiseq.inipol = abc2enz(...
    thiseq.selectedpol, ...
    thiseq.selectedinc, ...
    gamma);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Correction to rotate into semi-geographical coordinates 
% Note, that this does not account for dips!

if strcmpi(config.studytype,'Teleseismic') 
    %rotate into geographical coordinates
    theta = gamma + thiseq.bazi;
    XX0 =  cosd(theta)*SG_SH_corSC(:,2) + sind(theta)*SG_SH_corSC(:,1);
    YY0 = -sind(theta)*SG_SH_corSC(:,2) + cosd(theta)*SG_SH_corSC(:,1);
    XX1 =  cosd(theta)*SG_SH_corRC(:,2) + sind(theta)*SG_SH_corRC(:,1);
    YY1 = -sind(theta)*SG_SH_corRC(:,2) + cosd(theta)*SG_SH_corRC(:,1);
    XX2 =  cosd(theta)*SH               + sind(theta)*SG;
    YY2 = -sind(theta)*SH               + cosd(theta)*SG;
    
    SG_SH_corSC(:,1) =  YY0; %Now North component of corrected seismogram
    SG_SH_corSC(:,2) =  XX0; %Now East  component of corrected seismogram
    SG_SH_corRC(:,1) =  YY1; %Now North component of corrected seismogram
    SG_SH_corRC(:,2) =  XX1; %Now East  component of corrected seismogram
    SG               =  YY2; %Now North component of initial seismogram
    SH               =  XX2; %Now East  component of initial seismogram

    if strcmp(config.inipoloption, 'fixed')
        rota     = thiseq.bazi;
        %gamma    = gamma    + thiseq.bazi;
        thiseq.inipol = thiseq.bazi;
        allFasts = mod(allFasts + thiseq.bazi,180);
    else
        rota     = thiseq.inipol;
        %gamma    = gamma    + thiseq.inipol;
        allFasts = mod(allFasts + thiseq.inipol,180);
    end

    allFasts(allFasts>90) = allFasts(allFasts>90)-180;    
    
    steps             = floor(mod(rota, 180)/config.StepsPhi) ;
    CmapStack         = circshift(CmapStack, steps);
    EmapStack(:,:,2)  = circshift(EmapStack(:,:,2), steps);
    
    steps             = floor(mod(thiseq.bazi, 180)/config.StepsPhi) ;
    EmapStack(:,:,1)  = circshift(EmapStack(:,:,1), steps);

%     phiRC(1) = mod(phiRC(1)+rota,180);    %if uncommented, phi is like srike
%     phiSC(1) = mod(phiSC(1)+rota,180);    %if uncommented, must adabt results plot
%     phiEV(1) = mod(phiEV(1)+rota,180);
    
    if phiRC(1)>90, phiRC(1)=phiRC(1)-180;end
    if phiSC(1)>90, phiSC(1)=phiSC(1)-180;end
    if phiEV(1)>90, phiEV(1)=phiEV(1)-180;end

end   


%% Assign results field to global variable
% first temporary, since we don't know if results will be used
% Later, within the diagnostic plot, the result may be assigned to the
% permanent eq.results-structure
%
% See also: saveresult.m
thiseq.tmpresult.phiRC = phiRC;
thiseq.tmpresult.dtRC  = dtRC;
thiseq.tmpresult.phiSC = phiSC;
thiseq.tmpresult.dtSC  = dtSC;
thiseq.tmpresult.phiEV = phiEV;
thiseq.tmpresult.dtEV  = dtEV;
thiseq.tmpresult.splitIntens = splitIntens;
thiseq.tmpresult.inipol  = thiseq.inipol;
thiseq.tmpresult.SNR     = SNR;
thiseq.tmpresult.domfreq = thiseq.domfreq;
thiseq.tmpresult.Spick   = SpickBest;
thiseq.tmpresult.remark  = '';  %default remark
if config.saveErrorSurface
    thiseq.tmpresult.ErrorSurface = Ematrix;
    thiseq.tmpresult.ndfSC = ndfSC;
end

%% diagnostic plot
ttime = now;
w = w(:);
splitdiagnosticplot(SG, SH, QTini,...
                    w(1)*thiseq.dt,...
                    w,...
                    thiseq.selectedinc,...
                    thiseq.tmpresult.strikes ,...
                    thiseq.dt, ...
                    gamma,...
                    phiRC, dtRC, CmapStack, FSrc, QTcorRC, SG_SH_corRC, ...
                    phiSC, dtSC, EmapStack, FSsc, QTcorSC, SG_SH_corSC,...
                    phiEV, dtEV, ...
                    LevelSC, LevelRC, LevelEV,...
                    config.splitoption, Qvector, bestfilter, ...
                    allFasts,allDelays);

drawtime=(now-ttime)*24*3600;


%% finishing  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
set(sbar,'String',['Status:  calculation time: ' num2str(caltime,4) ' seconds;     drawing time: ' num2str(drawtime,4) 'sec'])
drawnow;


%% Log file; saving all different results
SL_writeLogFile('LOG',config, thiseq)


%% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [SG,SH,extime,winStartVec,winStopVec] = localGetFilteredSeismograms(isBatchMode,f1,f2,npoles)
global config thiseq


%% extend selection window
extime = config.maxSplitTime * 2 ;%extend to both sides
o      = thiseq.Amp.time(1); %common offset of all files after hypotime

if isBatchMode
    if config.batch.windowEXP<=1
        facB = linspace(0,1, config.batch.nStartWin).^config.batch.windowEXP;
        facE = linspace(0,1, config.batch.nStopWin).^config.batch.windowEXP;
    else
        facB = 1-linspace(0,1, config.batch.nStartWin) .^ (1/config.batch.windowEXP);
        facE = 1-linspace(0,1, config.batch.nStopWin)  .^ (1/config.batch.windowEXP);
        facB = fliplr(facB);
        facE = fliplr(facE);
    end
    
    switch config.batch.WindowMode
        case 1 %seconds
            minWin = config.batch.StartWin;
            maxWin = config.batch.StopWin;
        case 2 %percent
            len = thiseq.Spick(2) - thiseq.Spick(1);
            minWin = config.batch.StartWin/100*len;
            maxWin = config.batch.StopWin/100*len;
        case 3 %use P-window
            if thiseq.Ppick(1)< thiseq.Spick(1) && thiseq.Spick(2)< thiseq.Ppick(2)
                minWin = (thiseq.Ppick(1) - thiseq.Spick(1));
                maxWin = (thiseq.Ppick(2) - thiseq.Spick(2));
            else
                errordlg('P-window does not overlap with S-window!')
                set(gcbf,'Pointer','arrow')
                return
            end
    end
    if config.batch.nStartWin==1;    minWin=0; end
    if config.batch.nStopWin ==1;    maxWin=0; end
    if config.batch.useWindowsInBatch==0;  minWin=0;maxWin=0; end
    if config.batch.useWindowsInBatch
        winStartVec = thiseq.Spick(1)*ones(1,config.batch.nStartWin) + facB * minWin;
        winStopVec  = thiseq.Spick(2)*ones(1,config.batch.nStopWin)  + facE * maxWin;
    else
        winStartVec = thiseq.Spick(1);
        winStopVec  = thiseq.Spick(2);
    end
    
    % indices of selection window relative to extended window
    extbegin  = round( (thiseq.Spick(1)  - extime + minWin - o) / thiseq.dt) + 1;
    extfinish = round( (thiseq.Spick(2)  + extime + maxWin - o) / thiseq.dt) + 1;
    extIndex  = extbegin:extfinish;
    
else
    winStartVec = thiseq.Spick(1);
    winStopVec  = thiseq.Spick(2);
    extbegin  = round( (thiseq.Spick(1)-extime-o) / thiseq.dt) + 1;
    extfinish = round( (thiseq.Spick(2)+extime-o) / thiseq.dt) + 1;
    extIndex  = extbegin:extfinish;
end

if extbegin <1
    errordlg('Sorry, but splitting window must be at least the maximum delay time after start of seismogram','Window error')
    return
end


%%
if strcmp(thiseq.SplitPhase, 'none')
    SH= thiseq.Amp.North(:);
    SG = -thiseq.Amp.East(:);
else
    SG = thiseq.Amp.SG(:);
    SH = thiseq.Amp.SH(:);
end


%% DeTrend & DeMean
SG = detrend(SG,'linear');SG = detrend(SG,'constant');
SH = detrend(SH,'linear');SH = detrend(SH,'constant');


%% Cosine Taper
len   = length(SG); %taper length is 2% of total seismogram length
taper = tukeywin(len, config.filter.taperlength/100);        
SG = SG .* taper;    
SH = SH .* taper;  


%% Filtering
% the seismogram components are not yet filtered
% define your filter here.
% the selected corner frequencies are stored in the varialbe "thiseq.filter"
%
ny  = 1/(2*thiseq.dt);%nyquist freqency of seismogramm

if f1==0 && f2==inf %no filter
    % do nothing
    % we leave the seismograms untouched
else
    if f1 > 0  &&  f2 < inf
        % bandpass
        [b,a] = butter(npoles, [f1 f2]/ny);
    elseif f1==0 &&  f2 < inf
        %lowpass
        [b,a] = butter(npoles, f2/ny,'low');
        
    elseif f1>0 &&  f2 == inf
        %highpass
        [b,a] = butter(npoles, f1/ny, 'high');
    elseif f1<0 &&  f2 <0
        %bandstop
        [b,a] = butter(npoles, [-f2 -f1]/ny, 'stop');
    end
    SG = filtfilt(b,a,SG); %Radial     (Q) component in extended time window
    SH = filtfilt(b,a,SH); %Transverse (T) component in extended time window
    
end
%% Cut to extended window
SG = SG(extIndex);
SH = SH(extIndex);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [phi, dt]  = localGetMinimum(mapStack)
global thiseq config


[~, ind]            = min(mapStack(:));
[indexPhi, indexDt] = ind2sub(size(mapStack), ind);

shift  = (indexDt-1)*config.StepsDT;    % samples
dt     = shift * thiseq.dt;         % seconds

phi_test_min = -90+indexPhi*config.StepsPhi; % fast axis in SH-SG system, relative to SG
phi          = mod(phi_test_min,  180);

if phi>90
    phi = phi-180; %put in -90:90
end


