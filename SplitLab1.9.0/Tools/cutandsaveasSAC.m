function cutandsaveasSAC
%Cut multiple SAC files at common start and end times

global eq config thiseq
if strcmp(config.netw,'??')
    errordlg('"??" is not a valid network name!')
    return
end

C = cellfun('isempty', [eq.seisfiles]);
if all(C(:))
errordlg('Please associate first the SAC files to the database!','Files not associated')
    return
end

dname=uigetdir(config.savedir,...
    strcat('Where do you want to write the new files?',...
    ' The new filenames will match the RDSEED convention.')');
if ~ischar(dname)
    return
end

    logfile = [dname, filesep, 'database_' config.project(1:end-4),'.dat'];
    fid_log  = fopen(char(logfile),'w+');
    if fid_log==-1
        errordlg ({'Problems while opening logfile:',logfile,' ', 'Please check output directory'})
    else
       fprintf(fid_log,'\n  date                 lat    long   baz    East-Component                         North-Component                       Vertical-Component' );
    end

for k=1:length(eq)
    workbar(k/length(eq),['Processing files for earthquake ' eq(k).dstr] )   
    thiseq = eq(k);
    comps  = readsacs(thiseq.date); %get the earthquakes to be cut ; 
    [distkm,~] = distance(config.slat,config.slong,thiseq.lat,thiseq.long,referenceEllipsoid('wgs84','km'));
    cname ='ENZ'; %order of components in stucture (see assignFilesAuto)
    
    for m=1:3
        fname = sprintf('%04.0f.%03.0f.%02.0f.%02.0f.%07.4f.%s.%s.BH%c..SAC',...
            comps.newdate(1), comps.newdate(7), comps.newdate(4), comps.newdate(5), comps.newdate(6),...
            config.netw, config.stnname, cname(m));
        outname = fullfile(dname,fname);
        %access structure using dynamic filed names 
        tmp  = comps.(cname(m));
        tmp = ch(tmp,...
            'DELTA',  mean(diff(comps.time)),...
            'O',      comps.origin,...
            'B',      comps.time(1),...
            'E',      comps.time(end),...
            'GCARC',  thiseq.dis,...
            'DIST',   distkm,...
            'NPTS',   length(comps.time),...
            'KSTNM',  config.stnname,...
            'KNETWK', config.netw,...
            'KCMPNM', comps.Kname.(cname(m)),...
            'STLA',   config.slat,...
            'STLO',   config.slong,...
            'EVLA',   thiseq.lat,...
            'EVLO',   thiseq.long,...
            'EVDP',   thiseq.depth,...
            'AZ',     thiseq.azi,...
            'BAZ',    thiseq.bazi,...
            'GCARC',  thiseq.dis,...
            'MAG',    thiseq.Mw,...
            'IZTYPE', 11,...      %'IO'; reference time is hypo time
            'NZYEAR', comps.newdate(1),...
            'NZJDAY', comps.newdate(7),...
            'NZHOUR', comps.newdate(4),...
            'NZMIN',  comps.newdate(5),...
            'NZSEC',  floor(comps.newdate(6)),...
            'NZMSEC', round((comps.newdate(6) - floor(comps.newdate(6)))*1000));
%            'T0',     thiseq.phase.ttimes(1)+comps.origin,...
%            'T1',     thiseq.phase.ttimes(2)+comps.origin,...
%            'T2',     thiseq.phase.ttimes(3)+comps.origin,...
%            'T3',     thiseq.phase.ttimes(4)+comps.origin,...
%            'T4',     thiseq.phase.ttimes(5)+comps.origin,...
%            'T5',     thiseq.phase.ttimes(6)+comps.origin,...
%            'T6',     thiseq.phase.ttimes(7)+comps.origin,...
%            'T7',     thiseq.phase.ttimes(8)+comps.origin,...
%            'T8',     thiseq.phase.ttimes(9)+comps.origin,...
%            'T9',     thiseq.phase.ttimes(10)+comps.origin,..
%             'NZYEAR', thiseq.date(1),...
%             'NZJDAY', thiseq.date(7),...
%             'NZHOUR', thiseq.date(4),...
%             'NZMIN',  thiseq.date(5),...
%             'NZSEC',  floor(thiseq.date(6)),...
%             'NZMSEC', round((thiseq.date(6) - floor(thiseq.date(6)))*1000));     
        wsac(outname, tmp)
        file{m}=fname;
    end
    fprintf(fid_log,'\n%20s  %6.2f %6.2f %6.2f  %s %s %s',...
    datestr(thiseq.date(1:6)), thiseq.lat, thiseq.long, thiseq.bazi,...
    file{1},file{2},file{3});
        
    
end
fclose(fid_log);



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [comps]= readsacs(hypotime)
    global config thiseq
    offset = floor(thiseq.offset*100)/100;

%read in
try
    e = rsac(fullfile(config.datadir, thiseq.seisfiles{1}));
    n = rsac(fullfile(config.datadir, thiseq.seisfiles{2}));
    v = rsac(fullfile(config.datadir, thiseq.seisfiles{3}));
catch
    e = rsacsun(fullfile(config.datadir, thiseq.seisfiles{1}));
    n = rsacsun(fullfile(config.datadir, thiseq.seisfiles{2}));
    v = rsacsun(fullfile(config.datadir, thiseq.seisfiles{3}));
end
comps.Kname.E=lh(e,'KCMPNM');
comps.Kname.N=lh(n,'KCMPNM');
comps.Kname.Z=lh(v,'KCMPNM');

% offE = lh(e,'O');
% offN = lh(n,'O');
% offV = lh(v,'O');
% if offE==-12345, offE=-thiseq.offset(1); end
% if offN==-12345, offN=-thiseq.offset(2); end
% if offV==-12345, offV=-thiseq.offset(3); end


% shift time vector
%offset is negativ, if file begins before hypotime 
e(:,1) = e(:,1)  + thiseq.offset(1);
n(:,1) = n(:,1)  + thiseq.offset(2);
v(:,1) = v(:,1)  + thiseq.offset(3);

%%
dt = [mean(diff(e(:,1)))   mean(diff(n(:,1)))   mean(diff(v(:,1)))];
dt = round(dt*1000)/1000;
dt = max(dt);

% times relative to origin time
thestart = max([e(1,1)   n(1,1)   v(1,1)  ])+dt/2;% adding half a sample
theend   = min([e(end,1) n(end,1) v(end,1)])+dt/2;% for excluding accidential overlap

for pick ={'A' 'F' 'T0' 'T1' 'T2' 'T3' 'T4' 'T5' 'T6'  'T7' 'T8' 'T9'}
    t=lh(e, char(pick));
    if t~=-12345
        e=ch(e, char(pick), t - 0);%offE);
    end

    t = lh(n, char(pick)) ;
    if t~=-12345
        n=ch(n, char(pick), t - 0);%offN);
    end

    t = lh(v, char(pick)) ;
    if t~=-12345
        v=ch(v, char(pick), t - 0);%offV );
    end
end

%calculate new timevector for SAC header
filestart = hypotime(1:6)+[0 0 0 0 0 thestart]; % Shift by minimum offset
filestart = datenum(filestart);   % convert to serial number...
new       = datevec(filestart);   % and back to vector
new(7)    = dayofyear(new(1), new(2), new(3));

%synchonize seismograms: cut at times commom to all 3 seismograms
Eamp = e(e(:,1)>thestart & e(:,1)<theend, 2); %SECOND FILES REPRESENTS AMPLITUDE
Namp = n(n(:,1)>thestart & n(:,1)<theend, 2);
Zamp = v(v(:,1)>thestart & v(:,1)<theend, 2);

%usually, they should have the same length; but in some cases, where one
%sample macthes excactly the start or end time, that componet has one
%element more, but we need be sure to have the same number of elements     
len = min([length(Eamp) length(Namp) length(Zamp)]);
                                               % 
comps.time = (0:dt:(len-1)*dt)'; 
comps.E    = [comps.time    Eamp(1:len)    e(1:len,3)];
comps.N    = [comps.time    Namp(1:len)    n(1:len,3)];
comps.Z    = [comps.time    Zamp(1:len)    v(1:len,3)];
comps.origin = -thestart; %
comps.newdate= new;


