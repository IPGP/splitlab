function config=SL_defaultconfig

% set the main variables for spliting toolbox
% used by 'SL_checkversion' to update unset 'config' fields.

if ispc
    config.host= getenv('COMPUTERNAME');
    user = getenv('USERNAME');
    home = getenv('USERPROFILE');
else
    config.host = getenv('HOSTNAME');
    user= getenv('USER');
    home= getenv('HOME');
 end

[p,f] = fileparts(mfilename('fullpath'));  % directory of Splitlab

%% default locations: change to your needs
config.project     = 'default_project.pjt';
config.datadir     = '/Users/john/Dropbox/JOHNS_WORK/';  %home;
config.projectdir  = '/Users/john/Dropbox/JOHNS_WORK/';  %home;
config.savedir     = '/Users/john/Dropbox/JOHNS_WORK/';  %home;
config.autosave    = true;
config.isWeiredMAC = false;

config.studytype='Teleseismic';
if strcmp(config.studytype,'Teleseismic');
%GLOBAL
config.filterset=[
    0         0            Inf    3.0000 1
    1.0000    0.0100    0.1000    3.0000 0
    2.0000    0.0200    0.2000    3.0000 1
    3.0000    0.0200    0.3000    3.0000 0
    4.0000    0.0100    0.3000    3.0000 1
    5.0000    0.0100    0.4000    3.0000 0
    6.0000    0.0200    1.0000    3.0000 1
    7.0000    0.0100    0.1500    3.0000 0
    8.0000    0.0200    0.2500    3.0000 1
    9.0000    0.0100    1.0000    3.0000 0];  
else
% MICROSEISMIC
config.filterset=[
     0     0   Inf     3     1
     1     0   150     3     0
     2     0   200     3     1
     3     0   250     3     0
     4    20   150     3     1
     5    20   300     3     0
     6    50   300     3     1
     7    50   200     3     0
     8   -70   -50     3     1
     9    20   100     3     0];
end
config.filter.taperlength = 10; %percent of window
config.calcphase   = true;
config.showstats   = true;
% config.calcEnergy  = true;


%% Change to your needs.... 
config.stnname  = '???';     % Name of seimic station
config.netw     = '??';     % Seimmic network code of the station
config.slat     = 0;     % Latitude of station
config.slong    = 0;     % Longitude of station
config.selev    = 0;
% config.isLocationUnitMeters = 0;
% config.geometryOption=1; %Use MatTaup or straight line ; for Ppolset this to "2"
 config.rotation = 0;% station is rotated? in degrees clockwise from north
 config.SwitchEN = false; %East and North components have been exchanged?
 config.signE    = 1; % 1: East componenent points East (the standard);     -1 == East componenent points West 
 config.signN    = 1; % 1: North componenent points North(the standard);    -1 == North componenent points South 
 config.signZ    = 1; % 1: Vertical componenent points Up(the standard);    -1 == points Downward 
%config.rotMatrix = eye(3);
%config.rotAngles = [0 0 0];

config.eqwin    = [90 130];   % search window in degrees around station
config.z_win    = [0 1000];   % search window depth in km
d               = datevec(now);
config.twin     = [03 01 1976 ,d(3) d(2) d(1)]; % timewindow 
config.Mw       = [5  9.75];        % [minimum maximum] magnitude (Mw) of earthquake

config.catalogue= fullfile(p,'harvardCMT.mat');
config.catformat='CMT';
config.FileNameConvention = 'RHUM-RUM';
config.searchstr= '*.SAC'; % ['*.' config.stnname '*.sac'];
config.searchdt = 420; %== 7 minutes search interval for filetime/hypotime match
config.offset   = 0;%
config.Vp       = 3.9;
config.Vs       = 2.2;

% Gridsearch step widths
config.StepsDT  = 2;
config.StepsPhi = 2;

% request defaults
config.request.label     = 'label'; 
config.request.format    = 'NetDC';
%config.request.reqfile   = 'splitlab.req';
config.request.reqtime   = [-60 40*60]; %buffer time (sec) of request before hypotime; eg: [-60 40*60] is 60s before hypo and 40 minute duration
config.request.comp      ='BH?';
config.request.timestamp ='???';

config.request.user     = 'scholzjr';    %user; % 'defaultuser';
config.request.password = 'uufoh4ooK';   % user authentication for restricted data
config.request.institut = 'IPGP';
config.request.phone    = '';
config.request.adress   = 'Champ de Mars, 5 Avenue Anatole France, Paris'; %breqfast request required
config.request.usermail = 'scholz@ipgp.fr'; %[config.request.user '@'];

% add or delete datacenters as cell entries: they will be displayed in selection menu
config.request.DataCenters ={'netdc@fdsn.org';'netdc@ipgp.jussieu.fr';'netdc@knmi.nl';'netdc@iris.washington.edu';'breq_fast@gfz-potsdam.de';'breq_fast@iris.washington.edu';'breq_fast@knmi.nl';'autodrm@iris.washington.edu'};
config.request.mailto      = char(config.request.DataCenters(1));
config.phases     = {'P','PP','PPP','Pdiff','PKS','PcP','PcS','SP','S','SS', 'Sdiff','SKS','SKKS','SKiKS','ScS','sSKS','pSKS','SKP','pPKS','PS','SKJKS','ScP','PKJKP','PKiKP', 'PKKP','PKKS','SKKP'};
config.earthmodel ='ak135';%'prem' 'iasp91'

config.PaperType    = 'A4';
config.exportformat = '.eps'; % default figure export format 
                              % valid strings :
                              %'.ai','.eps', '.fig', '.jpg',  '.pdf',
                              %'.ps','.png', '.tiff'
config.exportresolution         = 300;
config.Colors.PselectionColor   = [.91 .93  1];
config.Colors.SselectionColor   = [1    1  .85];
config.Colors.OldselectionColor = [.9  .9  .9];
config.Colors.TTMarkerColor     = [1    0   1];
config.Colors.SACMarkerColor    = [1    1   1] * .6;
                              
config.comment='';
%config.RayParameterMethod = 1; % 1 == 'RayPath (TeleSeismics: use matTaup)' 2 == 'Source Vector (MicroSeismics/Local studies)'};
config.UseHeaderTimes     = 0;% extract file beginning from file name (0) or from header (1) 
config.tablesortcolumn    = 1;% column by which to sort data per default in Database viewer
config.splitoption        = 'Eigenvalue: min(lambda1 * lambda2)';
config.inipoloption       = 'fixed'; %for EV method: initial geometrical (from backazimuth) or estimated from wave form  
config.resamplingfreq     = 'raw'; %resample seismogram frequncy; give as string
config.interpolmethod     = 'pchip';
config.maxSplitTime       = 4; %maximum time to search for delay in inversion
config.db_index           = []; 

config.batch.useFilterInBatch  =   1;
config.batch.useWindowsInBatch =   0;
config.batch.WindowMode        =   2;  % 1==absolute time; 2== percent relative to selected window length
config.batch.StartWin          = -10;  % seconds before Spick1
config.batch.StopWin           =  15;  % seconds after  Spick1
config.batch.nStartWin         =   3;  % number of start windows
config.batch.nStopWin          =   5;  % number of stop windows
config.batch.windowEXP         =   1;  % linear windowing; 2==window size decays quadratic
config.batch.bestMesurementMethod =2;

config.saveErrorSurface   = 1;         %keep error surface for stacking


%% This program is part of SplitLab
%  2006 Andreas Wuestefeld, Universite de Montpellier, France
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
% Foundation; either version 2 of the License, or (at your option) any later 
% version.
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
% more details.
