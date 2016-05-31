function SL_importSAC
% SACHEADER must have the following entries:
%   KSTNM              - Name of the station
%   STLA, STLO, STEL   - Station coordinates
%   EVLA, EVLO, EVDP   - Event coordinates
%                        Note that event is depth and station elevation
%   GCARC              - Source-Receiver Distance as great circle arc
%                        If GCARC is not set, the entry from DIST is taken
%   AZ, BAZ,           - Azimuth, Backazimut
%   MAG                - Event magnitude
%   NZYEAR,NZJDAY,     - Hypocentre time
%   NZHOUR,NZMIN,NZSEC
%   NZMSEC
%
% Optional:
%   KEVNM              - Name or description for event
%   O                  - The offset maker for each file
%                        If not set, defaulting to zero

global config eq

fnames = uipickfiles('NumFiles',3,'Prompt','Please select 3 SAC files' , 'FilterSpec','*.sac');
if ~iscell(fnames) && fnames==0
    return
end

[dname,fname1,ext1]=fileparts(fnames{1});
[dname,fname2,ext2]=fileparts(fnames{2});
[dname,fname3,ext3]=fileparts(fnames{3});

fname = {[fname1 ext1]; [fname2 ext2]; [fname3 ext3]};
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


defPhases = defConfig.phases;
mindate = now;
maxdate = 0;

config = defConfig;



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

for i=1:3
    try
        S = rsac   (fullfile(dname, fname{i}));
    catch
        fclose all;
        S = rsacsun(fullfile(dname, fname{i}));
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
    if depth(i) == -12345;     disp(['Error: Event Depth or Elevation not given in   ' fname{i}]);    end
    if lat(i)   == -12345;     disp(['Error: Event Latitude not given in             ' fname{i}]);    end
    if long(i)  == -12345;     disp(['Error: Event Longitude not given in            ' fname{i}]);    end
%     if azi(i)   == -12345;     disp(['Error: Event Azimuth not given in              ' fname{i}]);    end
%     if bazi(i)  == -12345;     disp(['Error: Event Backazimuth not given in          ' fname{i}]);    end
    if Mw(i)    == -12345;     disp(['Warning: Event Magnitude not given in          ' fname{i}]);          end
    
    if any([ y(i),jd(i), h(i),m(i),s(i),ms(i)] == -12345)
        disp(['WARNING: Reference time not given in           ' fname{i}])
        dat{i} = [0 0 0 0 0 0 0];
        dstr{i} = datestr(dat{i}, 'dd-mmm-yyyy');
    else
        frac = h(i)/24+ m(i)/1440 +  s(i)/86400 + ms(i)/8640000;
        ref          = datenum(y(i), 0, 0) + jd(i) + frac;
        dat{i} = [datevec(ref) jd];
        dstr{i} = datestr(ref, 'dd-mmm-yyyy');
    end
    dnum(i)= datenum(dat{i}(1:6));
    
    
    
    
    if err
        return
    end
    
end

% if ~all(strcmp(StationName{1}, StationName));  disp(['Error: Station Names are not identical           ' StationName]);err=1;end

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
    lastStart=max(dnum); 
    Offset = (dnum - lastStart) * 24 * 3600;
    disp('Warning: Event times are not identical        '); 
    disp(dstr);
end



if err==1
    return
end

config.stnname    = StationName{1};
config.project    = [StationName{1} '_' dstr{1} '.pjt'];
defConfig.project = [StationName{1} '.pjt'];
defConfig.stnname = StationName{1};
config.slat       = slat(1);
config.slong      = slong(1);
config.selev      = selev(1);

config.phases     = defPhases;

eq(1).date        = dat{1};
eq(1).dstr        = dstr{1};
eq(1).depth       = depth(1);
if gcarc(1) ==-12345
    eq(1).dis     = dis(1);
else
    eq(1).dis     = gcarc(1);
end

if lat(1)==-12345,  eq(1).lat=nan;  else eq(1).lat         = lat(1); end
if long(1)==-12345, eq(1).long=nan; else eq(1).long        = long(1);end
eq(1).azi         = azi(1);
eq(1).bazi        = bazi(1);
eq(1).Mw          = Mw(1);
eq(1).depth       = depth(1);
eq(1).seisfiles   = fname';
eq(1).index       = 1;

eq(1).offset      = Offset;
eq(1).energy      = nan;






if all(strcmp(region{1}, region)) & region{1}~=-12345
    eq(1).region    = region{1};
else
    eq(1).region    = '';
end




mindate = dat{1}(1:6);
maxdate = dat{1}(1:6);
config.twin = [mindate(3:-1:1) maxdate(3:-1:1)];
config.pjtname =  [StationName{i} '.pjt'];




disp(' Run <a href="matlab: global eq thiseq config; splitlab;">SplitLab</a>')



