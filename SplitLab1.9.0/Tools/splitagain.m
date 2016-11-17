function splitagain 

% Get through a SplitLab project and recompute the measurements 
% already performed plots are not redone

global thiseq config eq


for i = 1:length(eq)% Loop over each event with result
    if isempty(eq(i).results);
        % do nothing
    else
		n    = 0;
		Qmax = -inf;
		Qsum = 0;
		nmax = 1;
		Qvector(1:nmax)=nan;

        thiseq=eq(i);

        % READ SEISMOGRAMS AND ROTATE
        thiseq  = readseis3D(config,thiseq); % Get the seismograms (thiseq.Amp)
        if isequal(thiseq,0);
            close(gcf);
            fprintf('No data for project (skip station): %s\n\n', config.project);
            return;
        end

    	for num=1:length(eq(i).results) % Loop over number of results per event
            
        	inc = thiseq.results(num).incline;
        	M   = rot3D(inc, thiseq.bazi); % The rotation matrix

        	ZEN = [thiseq.Amp.Vert, thiseq.Amp.East, thiseq.Amp.North]';
        	LQT = M * ZEN; % Rotating from geographical to ray

        	SG  = LQT(2,:)'; % Radial trace
        	SH  = LQT(3,:)'; % Transverse trace

        	thiseq.filter  = thiseq.results(num).filter; % Filter parameters (freq. min., freq. max. and poles)
        	thiseq.Spick   = thiseq.results(num).Spick;  % Analysis windoq previously defined by the user

			%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			%      BEGIN SPLITTING
			%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        	fprintf(' %s -- Estimating event %s: %4.0f.%03.0f (%.0f/%.0f) --',...
            	datestr(now,13) , config.stnname, thiseq.date(1), thiseq.date(7),i , length(eq));

			extime    = config.maxSplitTime * 2; % Extend to both sides
			o         = thiseq.Amp.time(1);      % Common offset of all files after hypotime

			winStartVec = thiseq.Spick(1);  % Begin of the time window
			winStopVec  = thiseq.Spick(2);  % End of the time window
			extbegin  = round( (thiseq.Spick(1)-extime-o) / thiseq.dt) + 1; % Begin of the window after extension
			extfinish = round( (thiseq.Spick(2)+extime-o) / thiseq.dt) + 1; % End of the window after extension
			extIndex  = extbegin:extfinish; % List of the index of the analysis window

       		% FILTERING
        	% the seismogram components are not yet filtered
        	% define your filter here.
        	% the selected corner frequncies are stored in the varialbe "thiseq.filter"
        	%
        	ny     = 1/(2*thiseq.dt); % Nyquist frequency of seismogramm
            npoles = thiseq.filter(3); % Poles
        	f1     = thiseq.filter(1); % Freq. min.
        	f2     = thiseq.filter(2); % Freq. max.
            if f1==0 && f2==inf % No filter
            	% Do nothing
            	% We leave the seismograms untouched
        	else
            	if f1 > 0 && f2 < inf
                	% Bandpass
                	[b,a]  = butter(npoles, [f1 f2]/ny);
            	elseif f1==0 && f2 < inf
                	% Lowpass
                	[b,a]  = butter(npoles, f2/ny,'low');
            	elseif f1>0 && f2 == inf
                	% Highpass
                	[b,a]  = butter(npoles, f1/ny, 'high');
            	end
            	SG = filtfilt(b,a,SG); % Filtered radial     (Q)
            	SH = filtfilt(b,a,SH); % Filtered transverse (T)
            end

        	% CUT TO EXTENDED WINDOW

         	SG = SG(extIndex); % Filtered radial component in extended time window
        	SH = SH(extIndex); % Filtered transverse component in extended time window

    		count=0;
            for kk = 1:length(winStartVec)    % Loop over the window
                for jj = 1:length(winStopVec)
            		count=count+1;
            		n=n+1;

            		t1 = winStartVec(end) - winStartVec(kk) ;
            		t2 = winStopVec(jj)   - winStartVec(kk) ;
 
            		i1 = round((extime-t1) / thiseq.dt);
            		i2 = i1 + round(t2 / thiseq.dt);
            
           		 	w = i1:i2;

        			%**************************************************************
        			%      SPLITTING METHODS
        			%**************************************************************
        
        			[tmp_phiSC, tmp_dtSC, tmp_phiEV, tmp_dtEV,  Ematrix, tmp_FSsc, tmp_SG_SH_corSC, tmp_Eresult, tmp_gamma] = ...
            	    		splitSilverChan(SG,...
                    	            		SH,...
                        	        		w,...
                            	    		thiseq.dt,....
                  	              			config.maxSplitTime, ...
                   	             			config.splitoption,...
                  	              			0,...
                                			config.StepsPhi,...
                                			config.StepsDT);  % Silver and Chan analysis method

		            if strcmp(config.inipoloption, 'fixed')
        	   	    	tmp_gamma=0;
            		end
        
        			[tmp_phiRC, tmp_dtRC, Cmap, tmp_FSrc, tmp_SG_SH_corRC, tmp_Cresult] = ...
                			splitRotCorr(SG,...
                             	 		 SH,...
                             	 		 w,...
                             	 		 config.maxSplitTime,...
                             	 		 thiseq.dt,...
                             	 		 0, ...
                             	 		 config.StepsPhi,...
                             	 		 0);  % Rotation correlation method
        
            		% PUT VALUES IN TEMPORARY VARIABLES...
            		switch config.splitoption
                		case 'Minimum Energy'
                    		Q = NullCriterion(tmp_phiSC(1), tmp_phiRC(1), tmp_dtSC(1), tmp_dtRC(1));  % Quality parameter
                		otherwise
                    		Q = NullCriterion(tmp_phiEV(1), tmp_phiRC(1), tmp_dtEV(1), tmp_dtRC(1));
            		end

            		Qvector(n)=Q;
            		Qsum  = Qsum + Q;
            		if Q > Qmax; end
                    allFasts(n,1:3)  = [ tmp_phiRC   tmp_phiSC   tmp_phiEV];
                    allDelays(n,1:3) = [ tmp_dtRC    tmp_dtSC    tmp_dtEV];
            
                	phiRC_val   = tmp_phiRC;
                	dtRC_val    = tmp_dtRC  ;
                	FSrc        = tmp_FSrc;
                	SG_SH_corRC = tmp_SG_SH_corRC;
                
                	phiEV_val   = tmp_phiEV;
                	dtEV_val    = tmp_dtEV  ;
                	phiSC_val   = tmp_phiSC;
                	dtSC_val    = tmp_dtSC    ;
                	FSsc        = tmp_FSsc;
                	SG_SH_corSC = tmp_SG_SH_corSC;
                                
                	gamma       = tmp_gamma;
                
                	Cresult   = tmp_Cresult;
                	Eresult   = tmp_Eresult;
                	CmapStack =  Cmap;
                
                	wbest = w;
                	Qmax  = Q;
                	SpickBest = [winStartVec(kk) winStopVec(jj)];

                end
            end

			thiseq.Q = Qmax;
			w = wbest;
			thiseq.Spick = SpickBest;

        	% POST-PROCESSING
        	M = [ cosd(gamma)  sind(gamma);
        		 -sind(gamma)  cosd(gamma)   ];

        	QTini   = M * [SG, SH]';    %rotating input wave forms
        	QTcorRC = M * SG_SH_corRC'; %rotating corrected wave forms
        	QTcorSC = M * SG_SH_corSC';

        	QTcorRC = detrend(QTcorRC','linear'); QTcorRC = detrend(QTcorRC,'constant');
        	QTcorSC = detrend(QTcorSC','linear'); QTcorSC = detrend(QTcorSC,'constant');
        	FSrc = detrend(FSrc,'linear');        FSrc    = detrend(FSrc,'constant');
        	FSsc = detrend(FSsc,'linear');        FSsc    = detrend(FSsc,'constant');
        
        	% SIGNAL-TO-NOISE RATIO
        	SNR  = [...
        			max(abs(QTcorRC(:,1))) / (2*std(QTcorRC(:,2)));   %SNR_QT on same window after correction (like Restivo & Helffrich,1998)
        			max(abs(QTcorSC(:,1))) / (2*std(QTcorSC(:,2)))... %SNR_QT on same window after correction (like Restivo & Helffrich,1998)
        		   ];

	        % DOMINANT FREQUENCY:
    	    m   = 2^max((nextpow2(1/thiseq.dt) - 1), 12);
 	        Y   = fft(QTcorSC(:,1), m);
 	        Pyy = Y.* conj(Y) / m;
 	        [~, ind]     = max(Pyy(1:m/2,:));
  	        thiseq.domfreq = 1/thiseq.dt*(ind)/m;


        	% ERROR BARS
        	[errbar_phiRC, errbar_tRC, LevelRC]        = geterrorbarsRC(QTini(2,w)', Cmap,              Cresult);
        	[errbar_phiSC, errbar_tSC, LevelSC, ndfSC] = geterrorbars(  QTini(2,w)', Ematrix(:,:,1), Eresult(1));
        	[errbar_phiEV, errbar_tEV, LevelEV, ndfEV] = geterrorbars(  QTini(2,w)', Ematrix(:,:,2), Eresult(2));

        	phiRC   = [phiRC_val   errbar_phiRC(1)];
        	dtRC    = [dtRC_val    errbar_tRC(1)  ];
        	phiSC   = [phiSC_val   errbar_phiSC(1)];
        	dtSC    = [dtSC_val    errbar_tSC(1)  ];
        	phiEV   = [phiEV_val   errbar_phiEV(1)];
        	dtEV    = [dtEV_val    errbar_tEV(1)  ];

			[thiseq.tmpresult.strikes, thiseq.tmpresult.dips] = abc2enz(...
    			thiseq.bazi, ...
    			inc, ...
    			[phiRC(1) phiSC(1) phiEV(1)]);

			thiseq.inipol = abc2enz(...
    			thiseq.bazi, ...
    			inc, ...
    			gamma);

            if strcmpi(config.studytype,'Teleseismic') 
     			% Rotate into geographical coordinates
    			theta = gamma + thiseq.bazi;
    			XX0 =  cosd(theta)*SG_SH_corSC(:,2) + sind(theta)*SG_SH_corSC(:,1);
    			YY0 = -sind(theta)*SG_SH_corSC(:,2) + cosd(theta)*SG_SH_corSC(:,1);
    			XX1 =  cosd(theta)*SG_SH_corRC(:,2) + sind(theta)*SG_SH_corRC(:,1);
    			YY1 = -sind(theta)*SG_SH_corRC(:,2) + cosd(theta)*SG_SH_corRC(:,1);
    
    			SG_SH_corSC(:,1) =  YY0; % Now North component of corrected seismogram
    			SG_SH_corSC(:,2) =  XX0; % Now East  component of corrected seismogram
    			SG_SH_corRC(:,1) =  YY1; % Now North component of corrected seismogram
    			SG_SH_corRC(:,2) =  XX1; % Now East  component of corrected seismogram
                
    			if strcmp(config.inipoloption, 'fixed')
        			rota     = thiseq.bazi;
        			%gamma    = gamma + thiseq.bazi;
        			allFasts = mod(allFasts + thiseq.bazi,180);
    			else
        			rota     = thiseq.inipol;
       				%gamma    = gamma + thiseq.inipol;
        			allFasts = mod(allFasts + thiseq.inipol,180);
    			end
                
    			allFasts(allFasts>90) = allFasts(allFasts>90)-180;
     
    			steps             = floor(mod(rota, 180)/config.StepsPhi) ;
    			CmapStack         = circshift(CmapStack, steps);
    			Ematrix(:,:,2)    = circshift(Ematrix(:,:,2), steps);
    
    			steps             = floor(mod(thiseq.bazi, 180)/config.StepsPhi) ;
    			Ematrix(:,:,1)    = circshift(Ematrix(:,:,1), steps);

%     			phiRC(1) = mod(phiRC(1)+rota,180);    %if uncommented, phi is like srike
%     			phiSC(1) = mod(phiSC(1)+rota,180);    %if uncommented, must adabt results plot
%     			phiEV(1) = mod(phiEV(1)+rota,180);
    
    			if phiRC(1)>90, phiRC(1)=phiRC(1)-180;end
    			if phiSC(1)>90, phiSC(1)=phiSC(1)-180;end
    			if phiEV(1)>90, phiEV(1)=phiEV(1)-180;end
            end

 			fprintf(' Phi = %5.1f; %5.1f; %5.1f    dt = %.1f; %.1f; %.1f\n', ...
    				phiRC(1),phiSC(1),phiEV(1), dtRC(1),dtSC(1), dtEV(1));
 
        	% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        	%    END SPLITTING
        	% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++


        	% COPY RESULTS TO PERMANENT "eq" VARIABLE
	    	eq(i).results(num).strikes      = thiseq.tmpresult.strikes;
            eq(i).results(num).dips         = thiseq.tmpresult.dips;
            eq(i).results(num).Q            = thiseq.Q;
            eq(i).results(num).phiRC        = phiRC;
	    	eq(i).results(num).dtRC         = dtRC;
	  		eq(i).results(num).phiSC        = phiSC;
	    	eq(i).results(num).dtSC         = dtSC;
	    	eq(i).results(num).phiEV        = phiEV;
	    	eq(i).results(num).dtEV         = dtEV;
            eq(i).results(num).LevelRC      = LevelRC;
            eq(i).results(num).LevelSC      = LevelSC;
            eq(i).results(num).LevelEV      = LevelEV;
            eq(i).results(num).ErrorSurface = Ematrix;
            eq(i).results(num).ndfSC        = ndfSC;
            eq(i).results(num).ndfEV        = ndfEV;
            eq(i).results(num).SNR          = SNR;
    		eq(i).results(num).timestamp    = datestr(now);
            eq(i).results(num).gamma        = gamma;

            % SAVE PROJECT
            filename        = fullfile(config.projectdir,config.project);
            config.db_index = thiseq.index;
            save(filename,'eq','config');

    	end %Result Loop
    end %empty check 
end % eq loop

fprintf('Done.\n\n');
