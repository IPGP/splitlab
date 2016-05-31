% Macro to calculate weigthed means for splitting measurements from ©SplitLab projects
% the output files with '_gmt.txt'are ready to be plotted with GMT
%
% Mickaël Bonnin(03/2010)
% modified Guilhem Barruol 11/2011, astrolabe
% modified Guilhem Barruol 03/2014, for the Arlita SKS measurements (low
% weight for dt>3.0s, close to nulls)
%
%% Cleaning of Workspace and Command Window:

clear all
close all
clc

%% Initialization and options:

%cd('/Users/mickaelbonnin/Documents/Anatolia/Piercing_point/Anatolia/'); %directory with projects
%cd('/Users/guilhem/Documents/Alpes/projects_backup/')               %directory with projects
%cd ('/Users/guilhem/Documents/Reunion/Arlita_SKS/projects_backup/mean_SKS/') %directory with projects
%cd ('/Users/guilhem/Documents/Antarctica/Papier_SKS_RF_ARLITA_2014/SKS_projects_mean/') %directory with projects
cd ('/Users/guilhem/Documents/Reunion/Iles_Eparses/sismo_data/SKS_iles_eparses/Eparses_SKS_projects/') %directory with projects

exp='Eparses'; % experiment name (for the subsequent file naming)


%good=1; if good==1; disp('You are using good measurements only'); end
good=0; if good==0; disp('You are using all measurements (Good,Fair,Poor) except Nulls'); end

%SC=1; if SC==1; disp('Minimum Energy results'); end
SC=0; if SC==0; disp('Eigen Values results'); end

fmean=1; if fmean==1; disp('And you perform weigthed mean'); end
%fmean=0; if fmean==0; disp('And you perform weigthed median'); end

istd=2; if istd==2; disp('You are using weighted mean of the error values'); end
%istd=1; if istd==1; disp('You are using standart deviation as error bar'); end
%istd=0; if istd==0; disp('You are using error of the mean as error bars'); end

phisd_min = 2;      % Minimal value of the error bars
phisd_max = 20;     % Maximal value of the error bars to fix excessive values problems (eg, +/- Inf values)
dtsd_max  = 0.4;    % maximal value for dt error


%% création des fichiers output et en-tête

d=dir('*.pjt'); % list the directory and search the pjt file


if good==1
    meanG       = fopen([exp,'_wmean_good.txt'],'w');     % Weighted mean values for good measurements only
    meanG_gmt   = fopen([exp,'_wmean_good_gmt.txt'],'w'); % Weighted mean values for good measurements ready to be plotted with gmt
    loggood     = fopen([exp,'_wmean_good.log'],'w');     % Log file

    fprintf(loggood,'======================================================================================\n');
    fprintf(loggood,'Donnees et options utilisees :  \n');
    fprintf(loggood,'Good=1: good only, Good=0: all ........................................... Good = %i\n',good);    
    fprintf(loggood,'SC=1: Minimum energy, SC=0:eigenvalues ...................................... SC= %i\n',SC);
    fprintf(loggood,'fmean=1: weighed mean, fmean=0: weighted median ......................... fmean = %i\n',SC);
    fprintf(loggood,'istd=0 error of mean, =1: standard dev, =2:weighted mean of errors ...... istd  = %i\n',istd);
    fprintf(loggood,'error phi min: phisd_min  = %2.0f  deg. \n',phisd_min);
    fprintf(loggood,'error phi max: phisd_max  =  %2.0f deg. \n',phisd_max);
    fprintf(loggood,'error dt max:  dtsd_max   =  %3.1f  sec \n',phisd_min);
    fprintf(loggood,'======================================================================================\n');
    fprintf(meanG,'Sta  Lat Long Averaged_phi  phi_sd  Averaged_dt  dt_sd nb_events\n');
else   
    meanall     = fopen([exp,'_wmean_all.txt'],'w');      % Weighted mean values for all measurements (g;f;p)
    meanall_gmt = fopen([exp,'_wmean_all_gmt.txt'],'w');  % Weighted mean values for all measurements ready to be plotted with gmt
    logall      = fopen([exp,'_wmean_all.log'],'w');      % Log file
    fprintf(logall,'======================================================================================\n');
    fprintf(logall,'Donnees et options utilisees :  \n');
    fprintf(logall,'Good=1: good only, Good=0: all ........................................... Good = %i\n',good);    
    fprintf(logall,'SC=1: Minimum energy, SC=0:eigenvalues ...................................... SC= %i\n',SC);
    fprintf(logall,'fmean=1: weighed mean, fmean=0: weighted median ......................... fmean = %i\n',SC);
    fprintf(logall,'istd=0 error of mean, =1: standard dev, =2:weighted mean of errors ...... istd  = %i\n',istd);
    fprintf(logall,'error phi min: phisd_min  = %2.0f  deg. \n',phisd_min);
    fprintf(logall,'error phi max: phisd_max  =  %2.0f deg. \n',phisd_max);
    fprintf(logall,'error dt max:  dtsd_max   =  %3.1f  sec \n',phisd_min);
    fprintf(logall,'======================================================================================\n');
    fprintf(meanall,'Sta  Lat Long Averaged_phi  phi_sd  Averaged_dt  dt_sd nb_events\n');
end



%% Loop over all the projects


for s=1:length(d) % Loop over all the projects
    load(d(s).name,'-mat')
    disp('----------------------------------------')
    disp(config.project)    % Display the project name
    
    leq=length(eq); % Preallocations of the variables
    phi1=zeros(leq,2);
    dt1=zeros(leq,2);
    Slat=config.slat;
    Slon=config.slong;
    tgood=zeros(1,leq);
    phis=zeros(leq,2);

% écriture pour chaque station    
    
    if good==0
    fprintf(logall,'  \n');
    fprintf(logall,'--------------------------------------------------------------------------\n');
    fprintf(logall,'Station %s\n',config.stnname);
    fprintf(logall,'--------------------------------------------------------------------------\n');
    fprintf(logall,'  Events used:\n');        
    else
    fprintf(loggood,'  \n');
    fprintf(loggood,'--------------------------------------------------------------------------\n');
    fprintf(loggood,'Station %s\n',config.stnname);
    fprintf(loggood,'--------------------------------------------------------------------------\n');
    fprintf(loggood,'  Events used:\n');        
    end

    
%% Loop over all the events within a project
    
    for k = 1:leq    % Loop over each event with result
        for val=1:length(eq(k).results)     % Loop over number of results per event
            thisphase = eq(k).results(val).SplitPhase;
% comment GB april2014 to use both SKS and SKKS values iles eparses
%            if ~strcmp('SKS', thisphase)  % Exit if not SKS phase
%                break
%            end
            
            [tgood(k)]=strcmp('Good    ',eq(k).results(val).Qstr); % Search for Good splitting measurements 
            tgood=tgood';
            [m,n,o]=find(tgood); % I use 'o' has an indicator of the number of Good measurements
            
                if good==0
                    if strcmp('GoodNull',eq(k).results(val).Qstr) || strcmp('FairNull',eq(k).results(val).Qstr) ||...
                       strcmp('PoorNull',eq(k).results(val).Qstr); % Discard the Nulls events
                    continue
                    else                 
                        disp(['station ',config.stnname,' event ' ,eq(k).dstr,'-',num2str(eq(k).date(7)),...
                            ' ',eq(k).results(val).Qstr]);
            
    % Extraction of the splitting parameters for good measurements only:                   
    
                        if SC==1
                            phi1(k,1)     = eq(k).results(val).phiSC(1); % Phi
                            phi1(k,2)     = eq(k).results(val).phiSC(2); % Standart deviation of Phi
                            dt1(k,1)      = eq(k).results(val).dtSC(1);  % Delay time
                            dt1(k,2)      = eq(k).results(val).dtSC(2);  % Standard deviation of the delay time
                        else
                            phi1(k,1)     = eq(k).results(val).phiEV(1); % Phi
                            phi1(k,2)     = eq(k).results(val).phiEV(2); % Standart deviation of Phi
                            dt1(k,1)      = eq(k).results(val).dtEV(1);  % Delay time
                            dt1(k,2)      = eq(k).results(val).dtEV(2);  % Standard deviation of the delay time                            
                        end 
                        
                    fprintf(logall,'event %s-%i  %6.2f ± %4.1f  %4.2f ± %4.2f %s\n',eq(k).dstr,eq(k).date(7),phi1(k,1),phi1(k,2),...
                        dt1(k,1),dt1(k,2),eq(k).results(val).Qstr);

                            %if phi1(k,1) < 0 % Fix problem of negative angles
                            %    phi1(k,1) = phi1(k,1)+180;
                            %end
                  % Conditions on the splitting parameters
                  
                            if phi1(k,2) == 0
                                phi1(k,2) = phisd_min; 
                            end
                            
                            if abs(phi1(k,2)) > phisd_max || isnan(phi1(k,2)) % Fix problems of excessive standard deviations of Phi measurements
                                phi1(k,2) = phisd_max ;
                            end
                            
                            if isnan(dt1(k,2))
                                dt1(k,2) = dtsd_max; 
                            end   
                            
                            if dt1(k,2)> dtsd_max
                                dt1(k,2) = dtsd_max;    % Error set to max in case of error Inf
                            end
                                                            
                    
                    end
                else

                    if strcmp('Good    ',eq(k).results(val).Qstr);
                        disp(['station ',config.stnname,' event ' ,eq(k).dstr,'-',num2str(eq(k).date(7)),...
                            ' ',eq(k).results(val).Qstr]);
 
    % Extraction of the splitting paramters for all the measurements:                    
                        
                            if SC==1
                                phi1(k,1)     = eq(k).results(val).phiSC(1); % Phi
                                phi1(k,2)     = eq(k).results(val).phiSC(2); % Standart deviation of Phi
                                dt1(k,1)      = eq(k).results(val).dtSC(1);  % Delay time
                                dt1(k,2)      = eq(k).results(val).dtSC(2);  % Standard deviation of the delay time
                            else
                                phi1(k,1)     = eq(k).results(val).phiEV(1); % Phi
                                phi1(k,2)     = eq(k).results(val).phiEV(2); % Standart deviation of Phi
                                dt1(k,1)      = eq(k).results(val).dtEV(1);  % Delay time
                                dt1(k,2)      = eq(k).results(val).dtEV(2);  % Standard deviation of the delay time                            
                            end 
 
                    fprintf(loggood,'event %s-%i  %6.2f ± %4.1f  %4.2f ± %4.2f %s\n',eq(k).dstr,eq(k).date(7),phi1(k,1),phi1(k,2),...
                        dt1(k,1),dt1(k,2),eq(k).results(val).Qstr);

                            %if phi1(k,1) < 0
                            %    phi1(k,1) = phi1(k,1)+180;
                            %end

                  % Conditions on the splitting parameters
                            
                            if phi1(k,2) == 0
                               phi1(k,2) = phisd_min; 
                            end
                            
                            if abs(phi1(k,2)) > phisd_max || isnan(phi1(k,2))
                                phi1(k,2) = phisd_max;
                            end 
                            
                            if isnan(dt1(k,2))
                                dt1(k,2) = dtsd_max; 
                            end
                                                
                    else   
                    
                        
                    end
                end    
        end  
            
        
     % Separate the events with splitting measurements (?0) from events without splitting measurements (0)
     
            [i,j,phi] = find(phi1(:,1));
            phisd = phi1(i,2);           % matrice contenant les erreur phi de toutes les mesures de cette station
            nb=length(phi);
            phi2=[phi,phisd];

            
            [i2,j2,dt]=find(dt1(:,1));
            dtsd  = dt1(i2,2);           % matrice contenant les erreur dt de toutes les mesures de cette station
            
            if fmean==0
                [phi,z1]=sort(phi2(:,1));
                phisd=phi2(z1,2);
            end
                        
    end
                    
            mi=min(phi);
            ma=max(phi);
            dif=ma-mi; 

        if good==1 && isempty(o) % Avoid crash of the macro when project does not have Good measurements 
           disp('No good events ! Sorry...')
           fprintf(loggood,'  No good events ! Sorry... ');
           fprintf(loggood,'  ');
        continue
        else
            for nbl=1:nb
                if phi(nbl)<0
                   phi(nbl)=phi(nbl)+180; % We add 180° to the fast azimuth to summ
                 end    
            end
      
            
            if dif > 140  % if dif > 155 data are close to ±90° (E/W strike) and thus cannot be summed (90-90=0 => N/S strike)
                if fmean==0
                   phi2(:,1)=phi;
                   [phi,z1]=sort(phi2(:,1));
                   phisd=phi2(z1,2);
                end
            elseif dif > 80 && dif < 140
                disp('Warning: Evidences of scaterring in the data') % if dif > 90 & < 150 splitting parameters cannot be averaged because there is too much scaterring
            end    
            
            if fmean==0 && good==1
                fprintf(loggood,'  Sorted fast azimuths: * is median\n');
                elseif fmean==0 && good==0
                fprintf(logall,'  Sorted fast azimuths: * is median\n');
                elseif fmean==1 && good==1
                fprintf(loggood,'  Values used for the weighted mean:\n');
                elseif fmean==1 && good==0
                fprintf(logall,'  Values used for the weighted mean:\n');
            end    
    
%        if good==1 && isempty(o) % Avoid crash of the macro when project does not have Good measurements 
%           disp('No good events ! Sorry...')
%        continue
%        else
            
           phiw=zeros(nb,1);
           dtw=zeros(nb,1);
           
     %% We assign weight to the measurements using phisd values      
           
           for nbi=1:nb            
                if phisd(nbi,1) < 5
                   phiw(nbi,1) = 1;
                elseif phisd(nbi,1) < 10
                   phiw(nbi,1) = 0.7;
                elseif phisd(nbi,1) < 15
                   phiw(nbi,1) = 0.5;
                elseif phisd(nbi,1) < 20
                   phiw(nbi,1) = 0.3;
                else 
                   phiw(nbi,1) = 0.1;
                end   
           end
           
     % We assign weight to the measurements using dtsd values
           for nbj=1:nb
                if dtsd(nbj,1) < 0.1
                   dtw(nbj,1) = 1; 
                elseif dtsd(nbj,1) < 0.15
                   dtw(nbj,1) = 0.7; 
                elseif dtsd(nbj,1) < 0.20
                   dtw(nbj,1) = 0.5;
                elseif dtsd(nbj,1) < 0.31
                   dtw(nbj,1) = 0.3;
                else
                   dtw(nbj,1) = 0.1;
                end
                
                if dt(nbj,1) > 3.0 % consider that dt>3 are close to null, low weight
                   dtw(nbj) = 0.1;
                   phiw(nbj)=0.1;
                end

           end
      
      % We write the values in the log files     
           
           for nbk=1:nb
                if fmean==0
                    if good==1
                        if mod(nb,2)==1 && nbk==floor((nb/2)+1)     % odd case for the location (* in the log file) of the median value
                            fprintf(loggood,'  %6.2f ± %4.1f weight %3.1f     %4.2f ± %4.2f weight %3.1f\n',...
                                    phi(nbk), phisd(nbk), phiw(nbk),dt(nbk), dtsd(nbk), dtw(nbk));
                        elseif mod(nb,2)==0 && nbk==nb/2            % even case for the location (* in the log file) of the median value 
                            fprintf(loggood,'  %6.2f ± %4.1f weight %3.1f     %4.2f ± %4.2f weight %3.1f\n',...
                                    phi(nbk), phisd(nbk), phiw(nbk),dt(nbk), dtsd(nbk), dtw(nbk));
                        else
                            fprintf(loggood,'  %6.2f ± %4.1f weight %3.1f     %4.2f ± %4.2f weight %3.1f\n',...
                                    phi(nbk), phisd(nbk), phiw(nbk),dt(nbk), dtsd(nbk), dtw(nbk));
                        end    
                    else
                        if mod(nb,2)==1 && nbk==floor((nb/2)+1)
                            fprintf(logall,'  %6.2f ± %4.1f weight %3.1f     %4.2f ± %4.2f weight %3.1f \n',...
                                    phi(nbk), phisd(nbk), phiw(nbk),dt(nbk), dtsd(nbk), dtw(nbk));
                        elseif mod(nb,2)==0 && nbk==nb/2
                            fprintf(logall,'  %6.2f ± %4.1f weight %3.1f     %4.2f ± %4.2f weight %3.1f \n',...
                                    phi(nbk), phisd(nbk), phiw(nbk),dt(nbk), dtsd(nbk), dtw(nbk));
                        else
                            fprintf(logall,'  %6.2f ± %4.1f weight %3.1f     %4.2f ± %4.2f weight %3.1f \n',...
                                    phi(nbk), phisd(nbk), phiw(nbk),dt(nbk), dtsd(nbk), dtw(nbk));
                        end                            
                    end
                else
                    if good==1
                            fprintf(loggood,'  %6.2f ± %4.1f weight %3.1f     %4.2f ± %4.2f weight %3.1f \n',...
                                    phi(nbk), phisd(nbk), phiw(nbk),dt(nbk), dtsd(nbk), dtw(nbk));
                    else
                            fprintf(logall,'  %6.2f ± %4.1f weight %3.1f     %4.2f ± %4.2f weight %3.1f \n',...
                                    phi(nbk), phisd(nbk), phiw(nbk),dt(nbk), dtsd(nbk), dtw(nbk));
                    end    
                end
           end
          
  %%  Calculation of the phi weighted mean, weighted median and of the error bars associated   
           
            if fmean==0                         % phi et erreur si calcul median
                phi_wm  = wmedian(phi,phiw);
                phisd_m = mean(phisd);
            else
                phi_wm  = wmean(phi,phiw);      % phi si calcul weighted mean
                
                if istd==0
                  phisd_m = confmean(phi);      % error phi si weighted mean
                end
                
                if istd==1
                  phisd_m = std(phi);           % error phi si standard deviation
                end
                
                if istd==2
                  phisd_m=wmean(phisd,phiw);    % moyenne pondérée des erreurs
                end
                
            end

  %%  Calculation of the dt weighted mean, weighted median and of the error bars associated   
            
            if fmean==0                             % dt et erreur si calcul median
                dt_wm  = wmedian(dt,dtw);
                dtsd_m = mean(dtsd);
            else

                dt_wm = wmean(dt,dtw);              % moyenne pondérée des dt 
            
                if istd==0                           
                    dtsd_m  = confmean(dt);         % erreur de la moyenne
                end
            
                if istd==1
                    dtsd_m  = std(dt);              % deviation standard des erreurs
                end
            
                if istd==2
                    dtsd_m = wmean(dtsd,dtw);       % moyenne pondérée des erreurs 
                end
            
            end
            
 %%           
            if phisd_m==9999 || dtsd_m==9999
               phisd_m = std(phi);
               dtsd_m= std(dt);
            end
            
            if phi_wm<0                             % keep only positive phi
                phi_wm=phi_wm+180;
            end

            if nb==1                                % if only 1 measurement, report the measurement error bar
               phisd_m = phisd;
               dtsd_m= dtsd;
            end

 %%        % We write the results in the results files   
            
            if good==1
                fprintf(loggood,'--------------------------------------------------------------------------\n');
                fprintf(meanG,'%s %8.3f %8.3f %6.2f %4.2f %4.2f %4.2f %3i\n',config.stnname, Slat, Slon, phi_wm, phisd_m, dt_wm, dtsd_m, nb);
                fprintf(meanG_gmt,'%8.3f %8.3f %6.2f %4.2f %s\n', Slat, Slon, phi_wm, dt_wm, config.stnname);
                fprintf(loggood,'%s nb_of_measurements: %i || phiwm: %6.2f ± %5.2f || dtwm: %4.2f ± %4.2f\n',config.stnname, nb, phi_wm, phisd_m, dt_wm, dtsd_m);
                fprintf(loggood,'--------------------------------------------------------------------------\n');
            else    
                fprintf(logall,'--------------------------------------------------------------------------\n');
                fprintf(meanall,'%s %8.3f %8.3f %6.2f %4.2f %4.2f %4.2f %3i\n',config.stnname,  Slat, Slon, phi_wm, phisd_m, dt_wm, dtsd_m, nb);
                fprintf(meanall_gmt,'%8.3f %8.3f %6.2f %4.2f %s\n', Slat, Slon, phi_wm, dt_wm, config.stnname);
                fprintf(logall,'%s nb_of_measurements: %i || phiwm: %6.2f ± %5.2f || dtwm: %4.2f ± %4.2f\n',config.stnname,nb, phi_wm, phisd_m, dt_wm, dtsd_m);
                fprintf(logall,'--------------------------------------------------------------------------\n');

            end
        end

end



fclose all;