function out=SL_eqwindow
% Find earthquakes within given window
% Syntax: eq=SL_eqwindow
% Search paramters are retrived from global "config" structure
% and consist of
%  - time window
%  - depth window
%  - distance window
%  - magnitude (Mw) window
% earthquake database file is given by "config.catalogue"
%
% output is structure with fields:
%     out.date     = [year month day hour minute sec julian_day];
%     out.dstr     = date as string
%     out.lat      = latitude
%     out.long     = longitude
%     out.depth    = depth in km
%     out.azi      = azimuth
%     out.bazi     = backazimuth
%     out.dis      = distance from station in degree
%
%     out.meca     = [strike dip rake]; faulting mechanism
%     out.Mw       = moment magnitude
%     out.M0       = seismic momemt
%     out.region   = region as given in Harvard CMT table
%
%  Additional fields for further use are initialized (still empty):
%     out.seisfiles = [{''};{''};{''}];  %path to seismograms
%     out.offset    = [0; 0; 0];         %offset: difference between hypotime and beginn of seimogramm
%     out.index             =[];%
%     out.phase.Names       = {''};
%     out.phase.rayparam    = {};
%     out.phase.ttimes      = {};
%     out.phase.inclination = {};
%     out.phase.takeoff     = {};
%     out.energy      = nan;
%
%     out.results  = [];
%
% You can access an earthquake using the format out(index)
% for example
%        out(1).dstr
% will result in the datestring of the first earthquake in database
% use the format
%        [out(1:3).year]
% to retrieve multiple datas in a vector
%
% See also cmtread, SL_assignFilesAuto SL_showeqstats

%  by A. Wuestefeld,
%  Univ. Montpellier, France
%  10.03.2005

%Changed 17.02.09: replace mapping toolbox functions by native ones...



global config
persistent cmt

TIMEwin = config.twin;
SKSwin  = config.eqwin;

if ~exist(config.catalogue,'file')
    CMT=which('harvardCMT.mat');
    NEIC=which('neic.mat');
    txt = {'Earththquake catalogue file does not exist!',...
        ' ', config.catalogue,' ',...
        'You may want to use:',...
        CMT,NEIC,' ',...
        'Please select a valid Splitlab Catalogue file or',...
        'press the "Update" button to create one'}
    answ = questdlg(txt,'File not found...','CMT','NEIC','Cancel','CMT');
    if ~strcmp(answ,'Cancel')
        eval(['config.catalogue= ' answ ';'])
    else
    return
    end
end



if strcmp(config.catformat,'TXT')
    if isempty(cmt)
        cmt=SL_neic2mat(config.catalogue);
    end
else
    load(config.catalogue);
end







%setting up time identifier:
eventid = datenum([cmt(:).year],[cmt(:).month],[cmt(:).day],[cmt(:).hour],[cmt(:).minute],[cmt(:).sec]); %make 6 digit number, unique for year_month combination
t_win   = [datenum(TIMEwin([3 2 1]))   datenum(TIMEwin([6 5 4]))+.9999];%from 00:00 to 23:59

%% Error handling
err=[];
if diff(t_win)<=0
    err=strvcat(err,'Selected time window wrong! Check value order!');
end
if diff(config.Mw)<=0
    err=strvcat(err,'Selected magnitude window wrong! Check value order!');
end
if diff(SKSwin)<=0
    err=strvcat(err,'Selected distance window wrong! Check value order!');
end
if diff(config.z_win)<=0
    err=strvcat(err,'Selected depth window wrong! Check value order!');
end
if ~isempty(err)
    try;close(h);end
    out=[];
    errordlg(err)
    return
end



warn = [];
if t_win(1) < floor(min(eventid))
    mineq = sprintf('%02.0f.%02.0f.%04.0f',cmt.day(1),cmt.month(1),cmt.year(1));
    warn=(strvcat(' ','WARNING: Entered time window starts before catalogue:',...
        ['        "' config.catalogue '"' ],...
        ['         Consider updating catalogue or change window.'],...
        ['         First earthquake in catalogue:   ' mineq]));
    twin(1)=eventid(1);
	tt=datevec(eventid(1));
    config.twin(1:3)=tt([3 2 1]);
end
if t_win(2) > ceil(max(eventid))
    maxeq = sprintf('%02.0f.%02.0f.%04.0f',cmt.day(end),cmt.month(end),cmt.year(end));
    warn=strvcat(warn,' ','WARNING: Entered time window ends after catalogue:',...
        ['         "' config.catalogue '"' ],...
        ['         Consider updating catalogue or change window.'],...
        ['         Last earthquake in catalogue:    ' maxeq]) ;
    t_win(2)= eventid(end);
	tt=datevec(eventid(end));
    config.twin(4:6)=tt([3 2 1]);
end
if ~isempty(warn)
    e = warndlg(warn);
	splitlab;
end


z_win=config.z_win;
if ~strcmp(config.studytype,'Reservoir')
    [dis, range, azi,bazi] = sphere_dist( cmt.lat, cmt.long, config.slat,config.slong );
    azi      = mod(azi,  360);
    bazi      = mod(bazi, 360);
else
    z = (  cmt.depth + config.selev); % elevation is positiv upwards, eventdepth positive downwards
    % this assumes an backazimuth from station to event, positive clockwise
    % from North and Inclination positive from vertical down (==0deg)
    dy         = cmt.lat  - config.slat;
    dx         = cmt.long - config.slong;
    hdis       = sqrt(dx.^2 + dy.^2);%in horizontal distance

    dis        = sqrt(hdis.^2  + z.^2);%in 3D
    bazi       = mod(atan2(dx,dy)  * 180/pi, 360);
    azi        = mod(bazi+180  , 360);
    SKSwin = [min(dis) max(dis)];
    z_win=config.z_win*1000;
end


%% search routine
%hndl=helpdlg('Searching for earthquakes...');
sks     =...
    find(SKSwin(1)    <  dis       & dis              <  SKSwin(2)    ...
    & t_win(1)        <= eventid   & floor(eventid)   <= t_win(2)     ...
    & config.Mw(1)    <= cmt.Mw    & cmt.Mw           <= config.Mw(2) ...
    & z_win(1)        <= cmt.depth & cmt.depth        <= z_win(2)          );

if isempty(sks)
    errordlg('No earthquake found with given criteria...','Sorry')
    out=[];
    return
end

%% OUTPUT structure:
dstr = datestr(eventid(sks),1);

for i=1:length(sks)
    out(i).date     = [cmt.year(sks(i)) cmt.month(sks(i)) cmt.day(sks(i)) cmt.hour(sks(i)) cmt.minute(sks(i)) cmt.sec(sks(i)) cmt.jjj(sks(i))];
    out(i).dstr     = dstr(i,:);
    
    out(i).lat      = cmt.lat(sks(i));
    out(i).long     = cmt.long(sks(i));
    out(i).depth    = cmt.depth(sks(i));
    out(i).azi      = azi(sks(i));
    out(i).bazi     = bazi(sks(i));
    out(i).dis      = dis(sks(i));
    
    
    
    
    out(i).Mw       = cmt.Mw(sks(i));
    
    if strcmp(config.catformat,'CMT')
        out(i).M0       = cmt.M0(sks(i));
        out(i).meca     = [cmt.strike(sks(i)) cmt.dip(sks(i)) cmt.rake(sks(i))];
        out(i).region   = deblank(cmt.region( sks(i), :) );
    end
    
    out(i).seisfiles = [{''};{''};{''}];  %path to seismograms
    out(i).offset    = [0; 0; 0];         %offset: difference between hypotime and beginn of seimogramm
    out(i).index     = [1 1 1];
    out(i).phase.Names       = {''};
    out(i).phase.rayparam    = [];
    out(i).phase.ttimes      = [];
    out(i).phase.inclination = [];
    out(i).phase.takeoff     = [];
    
    out(i).energy      = nan; %for SKS energy
    
    out(i).results  = []; %initilize as empty variable
end
% close(h)
if exist('e','var')
    waitfor(e)% You have to press the warning OK button
end

%% This program is part of SplitLab
% © 2006 Andreas Wüstefeld, Université de Montpellier, France
%
% DISCLAIMER:
%
% 1) TERMS OF USE
% SplitLab is provided "as is" and without any warranty. The author cannot be
% held responsible for anything that happens to you or your equipment. Use it
% at your own risk.
%
% 2) LICENSE:
% SplitLab is free software; you can redistribute it and/or modifyit under the
% terms of the GNU General Public License as published by the Free Software
% Foundation; either version 2 of the License, or(at your option) any later
% version.
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
% more details.