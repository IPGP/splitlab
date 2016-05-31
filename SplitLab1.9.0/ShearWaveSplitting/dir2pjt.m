function dir2pjt(searchstr, indir, outfile)
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


if nargin == 0
    %     dname = uigetdir(pwd);
    dname = pwd;
    if ~dname
        return
    end
    dlgtitel = 'Give some info:';
    prompt   = {'Directory','search string','Extension format','Include Subdir (1=Yes; 0=No)'};
    defaults = {dname, '*', '-H1','1'};
    defaults = {dname, '*', '.E.sac','0'};
    defaults = {dname, '*', '.E','0'};
    
    answer   = inputdlg( prompt, dlgtitel, 1,defaults);
    
    if isempty(answer)
        return
    end
    dname    = [answer{1} filesep];
    searchstr= [answer{2} answer{3}];
    recursive= answer{4}=='1';
    
    switch answer{3}
        case '.E.sac'
            Nextension = '.N.sac';
            Zextension = '.Z.sac';
        case '.e'
            Nextension = '.n';
            Zextension = '.z';
        case '.E'
            Nextension = '.N';
            Zextension = '.Z';
        case '-H1'
            Nextension = '-H2';
            Zextension = '-V';
    end
    
    
else
    if nargin==1
        dname=pwd;
    end
    if nargin >1
        dname = indir;
    end
    if nargin >2
        [dnameout, fnameout, ext] = fileparts(outfile);
        fnameout=[fnameout ext];
    end
    if strcmp('.E.sac',searchstr(end-5:end))
        Nextension = '.N.sac';
        Zextension = '.Z.sac';
    elseif strcmp('.e',searchstr(end-1:end))
        Nextension = '.n';
        Zextension = '.z';
        %     case '.E'
        %             Nextension = '.N';
        %             Zextension = '.Z';
    else
        error('unknown extension. please adjust the function dir2pjt')
    end
end

if dname(end)==filesep
    dname=dname(1:end-1);
end







%workbar(0, 'Gathering filenames...')
d = dir([dname filesep searchstr]);
if isempty(d)
    if recursive
        d = dir(dname);
    else
        workbar(1, 'Gathering filenames...')
        errordlg( {dname ,'does not contain any files matching the given search criteria.',searchstr})
        return
    end
end

try
    defConfig = getpref('Splitlab','Configuration');
catch
    defConfig = SL_defaultconfig;
end
defConfig.datadir    = dname;
defConfig.projectdir = dname;
defConfig.savedir    = dname;
defConfig.catalogue  = '';
% defConfig.version ='SplitLab1.3.2';
c = SL_defaultconfig;
defConfig.filterset=c.filterset;

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

config = defConfig;
config.db_index=1;

nain = nargin;
%workbar(0, 'starting conversion...')%serves mainly to reset the timer




if recursive
    d2=dir(dname);
    is = [0 0 d2(3:end).isdir]==1;
    sub=d2(is);
else
    sub.name='.';
end

for kk=1:length(sub);
    if recursive
        pname = fullfile(dname,sub(kk).name,searchstr);
            workbar(kk/length(sub), sub(kk).name);
            drawnow
            pause(.5)
    else    
        pname = fullfile(dname,searchstr);
    end
    d=dir(pname);
    for k = 1:length(d)
        Ename = d(k).name;
        
        if ~recursive
        if length(d)>20
            workbar(k/length(d), Ename);
        end
        end
        L = length(Nextension);
        
        Nname = [Ename(1:end-L) Nextension];
        Zname = [Ename(1:end-L) Zextension];
        
        fname={[sub(kk).name  filesep  Ename],
            [sub(kk).name  filesep  Nname], 
            [sub(kk).name  filesep  Zname]};
        
        
        if ~exist(fullfile(dname, fname{2}) , 'file')  || ~exist(fullfile(dname, fname{3}),  'file')
            continue
        end
        xxx =findstr(dname,filesep);
        
        
        
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
            %         if azi(i)   == -12345;     disp(['Error: Event Azimuth not given in              ' fname{i}]);err=1;    end
            %         if bazi(i)  == -12345;     disp(['Error: Event Backazimuth not given in          ' fname{i}]);err=1;    end
            %if Mw(i)    == -12345;     disp(['Warning: Event Magnitude not given in          ' fname{i}]);          end
            
            if any([ y(i),jd(i), h(i),m(i),s(i),ms(i)] == -12345)
                disp(['WARNING: Reference time not given in           ' fname{i}])
                dat{i} = [0 0 0 0 0 0 0];
                dstr{i} = datestr(dat{i}, 'dd-mmm-yyyy');
            else
                frac = h(i)/24+ m(i)/1440 +  s(i)/86400 + ms(i)/8640000;
                ref          = datenum(y(i), 0, 0) + jd(i) + frac;
                dat{i} = [datevec(ref) jd(i)];
                dstr{i} = datestr(ref, 'dd-mmm-yyyy');
            end
            dnum(i)= datenum(dat{i}(1:6));
            
            
            
            
            if err
                break
            end
            
        end
        if err
            continue %goto next East file name
        end
        %check consistency of each component
       % if ~all(strcmp(StationName{1}, StationName));  disp(['Error: Station Names are not identical           ' [StationName{:}]]);err=1;end
        
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
                continue %go to next East-component
            end
        end
        
        % continue by adding at the end of project...
        idx = length(eq) + 1;
        eq(idx).date        = dat{1};
        eq(idx).dstr        = dstr{1};
        eq(idx).depth       = depth(1);
        if gcarc(1) ==-12345
            %         eq(idx).dis     = dis(1);
            eq(idx).dis =sqrt( (config.slat-lat(1)).^2  +  (config.slong-long(1)).^2  +  (config.selev+depth(1)).^2   );
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
end
if length(eq)==0
    disp('No files found')
    disp(searchstr)
    disp(d)
    return
end



if nargin < 3
    [fnameout, dnameout] = uiputfile('*.pjt', 'Save Project As...',config.project);
end

if dnameout
    pjtname           = fullfile(dnameout,fnameout);
    config.projectdir = dnameout;
    config.project    = fnameout;
    
    save(pjtname, 'config', 'eq');
    
    disp(' ')
    disp([' Run SplitLab on <a href="matlab: global eq thiseq config;  load (''' pjtname ''', ''-mat'' ); splitlab; ">' pjtname '</a>'])
end



