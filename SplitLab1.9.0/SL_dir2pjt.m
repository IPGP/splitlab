function [success, config, eq] = SL_dir2pjt(config)
% dir2pjt(searchstr, indir, outfile) creates a SplitLab project from files in directory
% dir2pjt(searchstr, indir) opens a dialog box to ask for the output file
% dir2pjt(searchstr) uses the current directory as input drectory and asks
%    for an output filename
% dir2pjt uses "*.E.sac" as a search string
%
% dir2pjt(searchstr, indir, outfile,Nextension,Zextension) uses
% Nextension and Zextension as replacement for the components


%
% Example:
%
% indir = 'C:\SAC'
% cd(indir)
% d=dir('Station*');
% for k=1:length(d)
%     cd (d(k).name)
%     dir2pjt('*.E.sac', pwd, [indir filesep d(k).name '.pjt'])
%     cd ..
% end

success=0;
switch config.FileNameConvention
    case 'RDSEED'
        % RDSEED format '1993.159.23.15.09.7760.IU.KEV..BHE.D.SAC'
        Eextension = 'E.D.SAC';
        Nextension = 'N.D.SAC';
        Zextension = 'Z.D.SAC';
        
    case 'miniSEED'
        % miniSEED format 'IU.AGIN.00.BHN.D.1993,159,23:15:00.SAC' 38car,
        Eextension = 'BHE';
        Nextension = 'BHN';
        Zextension = 'BHZ'; 

%  format for RHUM-RUM raw data arriving from RESIF
    case 'RHUM-RUM'
        % miniSEED format 'YV.RR39.00.BH1.M.2012.318.221725.SAC' 36 car
        Eextension = 'BH2';
        Nextension = 'BH1';
        Zextension = 'BHZ'; 

    case 'SEISAN'
        % SEISAN format '2003-05-26-0947-20S.HOR___003_HORN__BHE__SAC'
        Eextension = 'E__SAC';
        Nextension = 'N__SAC';
        Zextension = 'Z__SAC';
        
    case 'YYYY.MM.DD.hh.mm.ss.stn.E.sac'
        Eextension = '.E.SAC';
        Nextension = '.N.SAC';
        Zextension = '.Z.SAC';
        
    case {'YYYY.JJJ.hh.mm.ss.stn.sac.e';
            'YYYY.MM.DD-hh.mm.ss.stn.sac.e';
            'YYYY_MM_DD_hhmm_stnn.sac.e';
            'stn.YYMMDD.hhmmss.e';
            '*.e; *.n; *.z'  }
        Eextension = '.e';
        Nextension = '.n';
        Zextension = '.z';
        
    otherwise
        error('Unknown Filename Format')
end

dname     = config.datadir;
searchstr = config.searchstr;



%%
workbar(0, 'Gathering filenames...')

d = dir([dname filesep searchstr]);
if isempty(d)
    workbar(1, 'Gathering filenames...')
    errordlg( {dname ,'does not contain any files matching the given search criteria.',searchstr})
    return
end

eq = struct('date',{},...
    'dstr',{},...
    'lat',{},...
    'long',{},...
    'depth',{},...
    'azi',{},...
    'bazi',{},...
    'dis',{},...
    'Mw',{},...
    'M0',{},...
    'meca',{},...
    'region',{},...
    'seisfiles',{},...
    'offset',{},...
    'index',{},...
    'phase',{},...
    'energy',{},...
    'results',{},...
    'polarisation',{})   ;


defPhases = [];struct('ttimes',{nan}, 'Names',{{''}}, 'takeoff',{nan}, 'inclination',{nan});
mindate = now;
maxdate = 0;

if length(d)/3>20
    workbar(0, 'starting conversion...')%serves mainly to reset the timer
end

%%
L = length(Nextension);
problematic=0;
for k = 1:length(d)
    tmp_fname = d(k).name;
    
    switch config.FileNameConvention
        case 'miniSEED'
            fdE = strfind(Eextension,tmp_fname);
            if ~isempty(fdE)
                Ename=tmp_fname;
            else
                continue
            end
        
            if length(d)/3>20
                workbar(k/length(d), Ename);
            end
            
            Nname = [Ename(1:fdE+1) 'N' Ename(fdE+3:end)];
            Zname = [Ename(1:fdE+1) 'Z' Ename(fdE+3:end)];
            
        case 'RHUM-RUM'
            fdE = strfind(Eextension,tmp_fname);
            if ~isempty(fdE)
                Ename=tmp_fname;
            else
                continue
            end
        
            if length(d)/3>20
                workbar(k/length(d), Ename);
            end
            
            Nname = [Ename(1:fdE+1) '1' Ename(fdE+3:end)];
            Zname = [Ename(1:fdE+1) 'Z' Ename(fdE+3:end)];
            
        otherwise
    
            if strcmpi(tmp_fname(end-L+1:end), Eextension)
                Ename=tmp_fname;
            else
                continue
            end
    
            if length(d)/3>20
                workbar(k/length(d), Ename);
            end
    
            Nname = [Ename(1:end-L) Nextension];
            Zname = [Ename(1:end-L) Zextension];
    
    end
        
        fname={Ename, Nname, Zname};
    
        if ~exist(fullfile(dname, Nname) , 'file')  || ~exist(fullfile(dname, Zname),  'file')
            disp(['No corresponding N- or E- component for ' Ename])
            problematic=problematic+1;
            continue
        end
        xxx = strfind(dname,filesep);%#ok
        
    
    
    for i=1:3
        try
            S = rsac ( [dname filesep fname{i}]);
        catch
            fclose all;
            S = rsacsun ([dname filesep fname{i}]);
        end
        
        Offset(i) = lh(S, 'O');
        if Offset(i)==-12345; Offset(i)=0;end
        
        err=0;
        region{i}                                                             = lh(S, 'KEVNM');
        StationName{i}                                                        = deblank(lh (S, 'KSTNM'));
        [slat(i), slong(i),selev(i)]                                          = lh(S,'STLA', 'STLO','STEL');
        [lat(i), long(i), depth(i), dis(i), gcarc(i), azi(i), bazi(i), Mw(i)] = lh(S, 'EVLA','EVLO','EVDP', 'DIST', 'GCARC', 'AZ', 'BAZ', 'MAG');
        [y(i),jd(i), h(i),m(i),s(i),ms(i)]                                    = lh(S,'NZYEAR', 'NZJDAY' ,  'NZHOUR','NZMIN','NZSEC','NZMSEC' );
        
        if selev(i) == -12345;     selev(i) = -(lh(S, 'STDP'));        end
        if depth(i) == -12345;     depth(i) = -(lh(S, 'EVEL'));        end
        if slat(i)  == -12345;     disp(['Error: Station Latitude not given in           ' fname{i}]);err=1;    end
        if slong(i) == -12345;     disp(['Error: Station Longitude not given in          ' fname{i}]);err=1;    end
        if selev(i) == -12345;     disp(['Error: Station Depth or Elevation not given in ' fname{i}]);err=1;    end
        if depth(i) == -12345;     disp(['Error: Event Depth or Elevation not given in   ' fname{i}]);err=1;    end
        if lat(i)   == -12345;     disp(['Error: Event Latitude not given in             ' fname{i}]);err=1;    end
        if long(i)  == -12345;     disp(['Error: Event Longitude not given in            ' fname{i}]);err=1;    end
        if azi(i)   == -12345;     disp(['Error: Event Azimuth not given in              ' fname{i}]);err=1;    end
        if bazi(i)  == -12345;     disp(['Error: Event Backazimuth not given in          ' fname{i}]);err=1;    end
        %if Mw(i)    == -12345;     disp(['Warning: Event Magnitude not given in          ' fname{i}]);          end
        
        if any([ y(i),jd(i), h(i),m(i),s(i)] == -12345)
            disp(['WARNING: Reference time not given in           ' fname{i}])
            dat{i} = [0 0 0 0 0 0 0];
            dstr{i} = datestr(dat{i}, 'dd-mmm-yyyy');
        else
            if ms(i) ==-12345;                ms(i)=0;                  end
            frac = h(i)/24+ m(i)/1440 +  s(i)/86400 + ms(i)/8640000;
            ref          = datenum(y(i), 0, 0) + jd(i) + frac;
            dat{i} = [datevec(ref) jd(i)];
            dstr{i} = datestr(ref, 'dd-mmm-yyyy');
        end
        dnum(i)= datenum(dat{i}(1:6));
         
        
        if err
            problematic=problematic+1;
            break
        end
        
    end
    if err
        problematic=problematic+1;
        continue %goto next East file name
    end
    %check consistency of each component
    if ~all(strcmp(StationName{1}, StationName));  disp(['Error: Station Names are not identical           ' StationName]);err=1;end
    
    if ~all(slat(1)==slat);     disp(['Error: Station Latitudes are not identical:   ' num2str(slat)]);err=1;    end
    if ~all(slong(1)==slong);   disp(['Error: Station Longitudes are not identical:  ' num2str(slong)]);err=1;   end
    if ~all(selev(1)==selev);   disp(['Error: Station Elevations are not identical:  ' num2str(selev)]);err=1;   end
    if ~all(depth(1)==depth);   disp(['Error: Event Depth are not identical:         ' num2str(depth)]);err=1;   end
    if ~all(lat(1)==lat);       disp(['Error: Event Latitudes are not identical:     ' num2str(lat)]);err=1;     end
    if ~all(long(1)==long);     disp(['Error: Event Longitudes are not identical:    ' num2str(long)]);err=1;    end
    if ~all(azi(1)==azi);       disp(['Error: Event Azimuths are not identical:      ' num2str(azi)]);err=1;     end
    if ~all(bazi(1)==bazi);     disp(['Error: Event Backazimuths are not identical:  ' num2str(bazi)]);err=1;    end
    if ~all(Mw(1)==Mw);         disp(['Warning: Event Magnitudes are not identical:  ' num2str(Mw)]);            end
    if ~all(datenum(dat{1}(1:6)) == dnum)
        disp(['Warning: Event times are not identical        ' dstr]);          end
    
    
    
    
    % Now check consistency with previous files
    if k==1 %first file: creat new config structre
        config.stnname    = StationName{1};
        % config.project    = [StationName{1} '_' dstr{1} '.pjt'];
        config.project = [StationName{1} '.pjt'];
        
        config.slat       = slat(1);
        config.slong      = slong(1);
        config.selev      = selev(1);
        
        config.phases     = defPhases;
        
        mindate = datenum(dat{1}(1:6));
        maxdate = datenum(dat{1}(1:6));
        
    else
        if ~strcmpi(config.stnname, StationName{1})
            disp('Station name differs from first event in list. Please consider adjusting the search string!')
            disp(['Skipping ' Ename])
            problematic=problematic+1;
            continue %go to next East-component
        end
    end
    
    % continue by adding at the end of project...
    idx = length(eq) + 1;
    eq(idx).date        = dat{1};
    eq(idx).dstr        = dstr{1};
    eq(idx).depth       = depth(1);
    if all(dis==-12345)
        dis=nan;
    end
    if gcarc(1) ==-12345
        eq(idx).dis     = dis(1);
    else
        eq(idx).dis     = gcarc(1);
    end
    
    eq(idx).lat         = lat(1);
    eq(idx).long        = long(1);
    eq(idx).azi         = azi(1);
    eq(idx).bazi        = bazi(1);
    eq(idx).Mw          = Mw(1);
    eq(idx).depth       = depth(1);
    eq(idx).seisfiles   = fname';
    eq(idx).index       = 1;
    
    eq(idx).offset      = -Offset;
    eq(idx).energy      = nan;
    if all(strcmp(region{1}, region)) & region{1}~=-12345
        eq(1).region    = region{1};
    else
        eq(1).region    = '';
    end
    
    thisdnum= datenum(dat{1}(1:6));
    if thisdnum<mindate
        config.twin(1:3) = dat{1}(3:-1:1);
    elseif thisdnum>maxdate;
        config.twin(4:6) = dat{1}(3:-1:1);
    end
end

workbar(1)
if length(eq)>0;
    h=helpdlg(sprintf('Succesfully imported %d events. %d files were skipped. Please save the database!',length(eq), problematic),'Import');
    waitfor(h)
    success=1;
end