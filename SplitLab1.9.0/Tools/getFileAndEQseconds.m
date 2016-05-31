function [FIsec, FIyyyy, EQsec, Omarker] = getFileAndEQseconds(F,eqin,offset)
%	Calculate start times of the files in seconds after midnight, January 1st
% this works for SAC files created with rdseed4.5.1
% eg: F = '1993.159.23.15.09.7760.IU.KEV..BHN.D.SAC'
% if your filnames contains no julian day, please use command
% dayofyear (in Splitlab/Tools)
% 


% Windows user can try a renamer , for example 1-4aren (one-for all renamer)
% http://www.1-4a.com/rename/ perhaps this adress is still valid

global config

if config.UseHeaderTimes || strcmp(config.FileNameConvention, '*.e; *.n; *.z')
    
    FIyyyy  = zeros(1,size(F,1));
    FIddd   = zeros(1,size(F,1));
    FIHH    = zeros(1,size(F,1));
    FIMM    = zeros(1,size(F,1));
    FISS    = zeros(1,size(F,1));
    FIMSEC  = zeros(1,size(F,1));
    Omarker = zeros(1,size(F,1));

    for k=1:size(F,1)
        workbar(k/size(F,1),'Reading header')
        try
            sac = rsac([config.datadir filesep F(k,:)]);
        catch
            fclose all;
            sac = rsacsun([config.datadir filesep F(k,:)]);
        end
        [FIyyyy(k), FIddd(k), FIHH(k), FIMM(k), FISS(k), FIMSEC(k)] =...
            lh(sac, 'NZYEAR','NZJDAY','NZHOUR','NZMIN', 'NZSEC', 'NZMSEC'); 
        Omarker(k) = lh(sac, 'O');
    end
    if any(FIMSEC==-12345) || any(FISS==-12345) || any(FIMM==-12345) || any(FIHH==-12345) || any(FIddd==-12345) || any(FIyyyy==-12345) 
        disp('WARNING: Some header times are not set propperly. Assigning files with no warranty')
    end
     FISS  ( FISS    == -12345) = 0;    
     FIMSEC( FIMSEC  == -12345) = 0;
     Omarker(Omarker == -12345) = 0;  %verify, if O-marker is set   
     FIsec  =  FIMSEC/1000 + FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400 + Omarker;

    fclose all;



else % USE FILENAME
    switch config.FileNameConvention
        case 'RDSEED'
            % RDSEED format '1993.159.23.15.09.7760.IU.KEV..BHN.D.SAC' 
            FIyyyy = str2num(F(:,1:4));%#ok
            FIddd  = str2num(F(:,6:8));%#ok
            FIHH   = str2num(F(:,10:11));%#ok
            FIMM   = str2num(F(:,13:14));%#ok
            FISS   = str2num(F(:,16:17));%#ok
            FIMMMM = str2num(F(:,18:22));%#ok
            FIsec  = FIMMMM + FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400;

        case 'miniSEED'
            % miniSEED format 'IU.AGIN.00.BHN.D.1993.159.231500.SAC'
            FIyyyy = str2num(F(:,18:21));%#ok
            FIddd  = str2num(F(:,23:25));%#ok
            FIHH   = str2num(F(:,27:28));%#ok
            FIMM   = str2num(F(:,29:30));%#ok
            FISS   = str2num(F(:,31:32));%#ok
            FIsec  = FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400;

         case 'RHUM-RUM'
            % miniSEED format 'YV.RR39.00.BH1.M.2012.318.221725.SAC'
            FIyyyy = str2num(F(:,18:21));%#ok
            FIddd  = str2num(F(:,23:25));%#ok
            FIHH   = str2num(F(:,27:28));%#ok
            FIMM   = str2num(F(:,29:30));%#ok
            FISS   = str2num(F(:,31:32));%#ok
            FIsec  = FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400;

        case 'SEISAN'
            % SEISAN format '2003-05-26-0947-20S.HOR___003_HORN__BHZ__SAC'
            FIyyyy = str2num(F(:,1:4));%#ok
            FImonth= str2num(F(:,6:7));%#ok
            FIdd   = str2num(F(:,9:10));%#ok
            FIHH   = str2num(F(:,12:13));%#ok
            FIMM   = str2num(F(:,14:15));%#ok
            FISS   = str2num(F(:,17:18));%#ok

            FIddd = dayofyear(FIyyyy',FImonth',FIdd')';%julian Day
            FIsec =  FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400;


        case 'YYYY.JJJ.hh.mm.ss.stn.sac.e'
            %  Format: 1999.136.15.25.00.ATD.sac.z
            FIyyyy = str2num(F(:,1:4));%#ok
            FIddd  = str2num(F(:,6:8));%#ok
            FIHH   = str2num(F(:,10:11));%#ok
            FIMM   = str2num(F(:,13:14));%#ok
            FISS   = str2num(F(:,16:17));%#ok
            FIsec  = FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400;
            
        case 'YYYY.MM.DD.hh.mm.ss.stn.E.sac';
            % Format: 2003.10.07-05.07.15.DALA.sac.z
            FIyyyy = str2num(F(:,1:4));%#ok
            FImonth= str2num(F(:,6:7));%#ok
            FIdd   = str2num(F(:,9:10));%#ok
            FIHH   = str2num(F(:,12:13));%#ok
            FIMM   = str2num(F(:,15:16));%#ok
            FISS   = str2num(F(:,18:19));%#ok

            FIddd = dayofyear(FIyyyy',FImonth',FIdd')';%julian Day
            FIsec  =  FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400;
            
        case 'YYYY.MM.DD-hh.mm.ss.stn.sac.e';
            % Format: 2003.10.07-05.07.15.DALA.sac.z
            FIyyyy = str2num(F(:,1:4));%#ok
            FImonth= str2num(F(:,6:7));%#ok
            FIdd   = str2num(F(:,9:10));%#ok
            FIHH   = str2num(F(:,12:13));%#ok
            FIMM   = str2num(F(:,15:16));%#ok
            FISS   = str2num(F(:,18:19));%#ok

            FIddd = dayofyear(FIyyyy',FImonth',FIdd')';%julian Day
            FIsec  =  FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400;
            
        case 'YYYY_MM_DD_hhmm_stnn.sac.e';
            % Format: 2005_03_02_1155_pptl.sac (LDG/CEA data)
            FIyyyy = str2num(F(:,1:4));%#ok
            FImonth= str2num(F(:,6:7));%#ok
            FIdd   = str2num(F(:,9:10));%#ok
            FIHH   = str2num(F(:,12:13));%#ok
            FIMM   = str2num(F(:,14:15));%#ok
            
            FIddd = dayofyear(FIyyyy',FImonth',FIdd')';%julian Day
            FIsec = FIMM*60 + FIHH*3600 + (FIddd)*86400;

        case 'stn.YYMMDD.hhmmss.e'
            % Format: fp2.030723.213056.X (BroadBand OBS data)
            FIyyyy = 2000 + str2num(F(:,5:6));%#ok %only two-digit year identifier => add 2000, assuming no OBS data before 2000
            FImonth= str2num(F(:,7:8));%#ok
            FIdd   = str2num(F(:,9:10));%#ok
            FIHH   = str2num(F(:,12:13));%#ok
            FIMM   = str2num(F(:,14:15));%#ok
            FISS   = str2num(F(:,16:17));%#ok

            FIddd = dayofyear(FIyyyy',FImonth',FIdd')';%julian Day
            FIsec = FISS + FIMM*60 + FIHH*3600 + (FIddd)*86400;
    end
    
    Omarker = zeros(size(FIsec));
end

%% get earthquake origin times
EQsec=zeros(1,length(eqin));
for a=1:length(eqin);
    EQsec(a) = eqin(a).date(6) + eqin(a).date(5)*60 + eqin(a).date(4)*3600 + eqin(a).date(7)*86400;
end

EQsec = EQsec + offset;

