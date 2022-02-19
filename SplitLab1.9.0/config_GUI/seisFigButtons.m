function seisFigButtons(fig,seismo)
%create buttons for seismogram plot SL_SeismoViewer and assings callbacks

global thiseq

if nargin<1
    fig = gcf;
end
ht = uitoolbar(fig);

load('icon.mat');


%% BUTTONS
uipushtool(ht,'CData',icon.sac,...
    'TooltipString','Export current seismograms to SAC format',...
    'ClickedCallback', {@exportsac,seismo});

uipushtool(ht,'CData',icon.open,...
    'TooltipString','Show earthquake database [d]' ,...
    'ClickedCallback', 'db_handle = findobj(''Name'',''Database Viewer''); if ~isempty(db_handle); figure(db_handle); else; SL_databaseViewer; end; clear db_handle');

uipushtool(ht,'CData',icon.print,...
    'TooltipString','Print [P]',...
    'ClickedCallback','printdlg(gcbf)' );

uitoggletool(ht,'CData',icon.grid,...
    'TooltipString','Toggle Grid',...
    'onCallback','grid on',...
    'offCallback','grid off');

uipushtool(ht,'CData',icon.map,...
    'TooltipString','Show travel times [t]',...
    'BusyAction','Cancel',...
    'ClickedCallback','viewphases');

uitoggletool(ht,'CData',icon.xzoomIN,...
    'TooltipString','x-ZOOM in [uparrow]',...
    'onCallback',{@xzoomON,seismo},...
    'offCallback',{@xzoomOFF,seismo});

uipushtool(ht,'CData',icon.xzoomOUT,...
    'TooltipString','x-ZOOM out [downarrow]',...
    'ClickedCallback',{@xzoomOutON, seismo});

uipushtool(ht, 'CData', icon.back,...
    'separator', 'on',...
    'TooltipString', 'previous earthquake [PageUp or fn+uparrow (Mac)])',...
    'ClickedCallback', 'idx = thiseq.index-1; if idx < 1; idx = length(eq); end; SL_databaseViewer(idx); SL_SeismoViewer(idx); clear idx',...
    'BusyAction','Cancel' );

uipushtool(ht,'CData',icon.reload,...
    'TooltipString','reload this earthquake [r]',...
    'ClickedCallback','idx = thiseq.index; SL_databaseViewer(idx); SL_SeismoViewer(idx); clear idx',...
    'BusyAction','Cancel' );

uipushtool(ht,'CData',icon.next,...
    'TooltipString','next earthquake [PageDown or fn+downarrow (Mac)])',...
    'ClickedCallback','idx = thiseq.index+1; if idx > length(eq); idx =1 ;end; SL_databaseViewer(idx); SL_SeismoViewer(idx); clear idx',...
    'BusyAction','Cancel');

uipushtool(ht,'CData',icon.run,...
    'separator','on',...
    'TooltipString','Run Splitting analyis [ENTER]',...
    'ClickedCallback','preSplit(0)',...
    'BusyAction','Cancel');

uipushtool(ht,'CData',icon.runBatch,...
    'TooltipString','Run Stacked Splitting Analysis (experimental) [SHIFT-ENTER]',...
    'ClickedCallback','preSplit(1)',...
    'BusyAction','Cancel');


PFig = findobj('Type','Figure','Name','Particle motion');
if isempty(PFig)
    state='off';  
else
    ax = get(PFig,'Children'); 
    for k = 1:length(ax)
    delete(get(ax(k),'Children'))
    end
    state='on';
end

uitoggletool(ht,'CData',icon.particle,...
    'separator','on',...
    'TooltipString','Show particle motion of selection Window',...
    'State',state,...
    'Tag','ParticleButton',...
    'onCallback',{@SL_localparticlemotion,seismo},...
    'offCallback','close(findobj(''Type'',''Figure'', ''Name'',''Particle motion'')); ');

uipushtool(ht,'CData',icon.home,...
    'TooltipString','Zoom to selected phase [Home or fn+leftarrow (Mac)]',...
    'ClickedCallback',@goHome);
if strcmp(thiseq.system,'ENV')
    s  = 'off';
    im = icon.geo;
else
    s  = 'on';
    im = icon.ray;
end

uitoggletool(ht,'CData',icon.ray,...
    'UserData',      icon, 'State', s,...
    'TooltipString','show E-N-Z or L-T-Q seismograms [SPACE]',...
    'onCallback',   {@changesystem,seismo,'ray'},...
    'offCallback',  {@changesystem,seismo,'geo'},...
    'Cdata',im,...
    'Tag','SystemButton');

uitoggletool(ht,'CData',icon.unlocked,...
    'UserData',      icon, 'State', 'off',...
    'TooltipString','Lock or unlock Y-axis linking [l or z]',...
    'Tag', 'LockButton',...
    'onCallback',   @changelockstate,...
    'offCallback',  @changelockstate);

uipushtool(ht,'CData',icon.spect,...
     'TooltipString','Spectogram of selection (use P-window) [s or S]',...
     'Separator','on',...
     'ClickedCallback',{@SL_SpectroViewer,seismo}');

% uipushtool(ht,'CData',icon.edit,...
%     'TooltipString','Splitting options [o]',...
%     'Tag', 'SplitOptionButton',...
%     'ClickedCallback',' splitlab(''change_radio_button'');',...
%     'BusyAction','Cancel');

uipushtool(ht,'CData',icon.config,...
    'TooltipString','Advanced splitting options [a]',...
    'Tag', 'AdvancedSplitOptionButton',...
    'ClickedCallback',' configSPLITADVANCED',...
    'BusyAction','Cancel');

uipushtool(ht,'CData',icon.trash,...
    'TooltipString','delete [enf or fn+backspace (Mac)]',...
    'Separator','on',...
    'ClickedCallback',@localTrash);

uipushtool(ht,'CData',icon.sound,...
     'TooltipString','Play selection',...
     'ClickedCallback',@playseismo);
 
uipushtool(ht,'CData',icon.camera,...
    'TooltipString','save grafic ...',...
    'ClickedCallback',@localSavePicture);

tmp = mfilename('fullpath');
tmp = fileparts(tmp);
tmp = strrep(tmp, 'private', ['Doc' filesep 'Keyboard_shortcuts.html']);

cbstr = ['web (''' tmp  ''')' ];
uipushtool(ht,'CData',icon.help,...
    'TooltipString','Help [h]',...
    'ClickedCallback',@localStructBox);


%% S U B F U N C T I O N S                                            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function goHome(src,evt)
global thiseq  
%jump close to selected phase
    val  = get(findobj('Tag','PhaseSelector'),'Value');
    t_home = floor(thiseq.phase.ttimes(val)/10)*10 - 30; %~30 seconds before phase; at full 10 seconds
    xlim([t_home-40 t_home+210]) % timewindow of 150 sec

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function changelockstate(src,event)
seis = findobj('Tag','seismo');

switch get(src,'State')
    case 'on'%lock to common Y-limits
        for k=1:3
            yyy(k,:) = get(get(seis(k),'Parent'),'YLim');
        end
        yyy =[min(yyy(:,1)) max(yyy(:,2))];
        for k=1:3
            set(get(seis(k),'Parent'), 'YLim',yyy,'YLimMode','manual')
        end
        set(src,'Cdata',getfield(get(src,'UserData'),'locked'))
    case 'off'%unlock Y-limits
        for k=1:3
            set(get(seis(k),'Parent'),'YLimMode','auto')
        end
        set(src,'Cdata',getfield(get(src,'UserData'),'unlocked'))
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function playseismo(a,b)
global thiseq

if ~isfield(thiseq, 'Ppick')
    errordlg('Please select a P-window first...')
    return
end

o  = thiseq.Amp.time(1);
ia = floor((thiseq.Ppick(1)-o)/thiseq.dt);
ib =  ceil((thiseq.Ppick(2)-o)/thiseq.dt);


seis   = findobj('tag','seismo');
y(:,1) = get(seis(1),'Ydata');
y(:,2) = get(seis(2),'Ydata');

y = y(ia:ib,:); %only selection
y = y/max(abs(y(:)));%we normalize the seismogram, to listen 
                     %to the same loudness for each seismogram
s     = sign(y);
music = abs(y(:,1)).^.5 .* s(:,1); %amplify small amplitudes

sound(music, 1000)%shift it in audible frequencies


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function exportsac(src,event,seis)
global thiseq config
persistent exportdir %make it the same for subsequent calls during this matlab session

if isempty(exportdir)
    exportdir = config.savedir;
end
exportdir = uigetdir(exportdir);
if ~exportdir %cancelled
    exportdir=[];
    return
end


%% ----------------------------
Amp(1,:) = get(seis(1), 'Ydata');
Amp(2,:) = get(seis(2), 'Ydata');
Amp(3,:) = get(seis(3), 'Ydata');
time     = get(seis(1), 'Xdata');

%only export current zoom
xx     = xlim;
window = find(xx(1) <=time & time<=xx(2));
Amp    = Amp(:,window); 
time   = time(window);


if strcmp(thiseq.system,'ENV')
    cname = 'ENZ';
    cmpinc = [90  90   0];
    cmpaz  = [0   90  90];
elseif strcmp(thiseq.system,'LTQ')
    cname = 'QTL';
    cmpinc = [-12345.0 -12345.0 -12345.0];
    cmpaz  = [-12345.0 -12345.0 -12345.0];
end


if ~isfield(thiseq,'Ppick')
    T0 = -12345;
    T1 = -12345;
    KT0='-12345';
    KT1='-12345';
else
    T0 = thiseq.Ppick(1);
    T1 = thiseq.Ppick(2);
    KT0='Pstart';
    KT1='Pend';
end
if ~isfield(thiseq,'Spick')
    T2 = -12345;
    T3 = -12345;
    KT2='-12345';
    KT3='-12345';
else
    T2 = thiseq.Spick(1);
    T3 = thiseq.Spick(2);
    KT2='Sstart';
    KT3='Send';
end

%determine date and hour of file begin
starttime = datenum(thiseq.date(1), thiseq.date(2), thiseq.date(3), thiseq.date(4), thiseq.date(5), thiseq.date(6)+time(1));
D         = datevec(starttime);
JJJ       = dayofyear(D(1), D(2), D(3));

files=[];
for m=1:3
    %access structure using dynamic filed names
    tmp  = bsac(time,Amp(m,:));
    tmp = ch(tmp,...
        'DELTA',  mean(diff(time)),...
        'O',      0,...
        'B',      time(1),...
        'E',      time(end),...
        'T0',      T0,...
        'T1',      T1,...
        'T2',      T2,...
        'T3',      T3,...
        'KT0',     KT0,...
        'KT1',     KT1,...
        'KT2',     KT2,...
        'KT3',     KT3,...
        'USER0',      T2-(T3-T2)/2,...These are for use in Teanby's automated splitting code
        'USER1',      T2,...
        'USER2',      T3,...
        'USER3',      T3+(T3-T2),...
        'NPTS',   length(time),...
        'CMPAZ',  cmpaz(m),...    %These are only correct for E,N,Z cooridnates
        'CMPINC', cmpinc(m),...   %These are only correct for E,N,Z cooridnates
        'KSTNM',  config.stnname,...
        'KNETWK', config.netw,...
        'STLA',   config.slat,...
        'STLO',   config.slong,...
        'KCMPNM', cname(m),...
        'EVLA',   thiseq.lat,...
        'EVLO',   thiseq.long,...
        'EVDP',   thiseq.depth,...
        'BAZ',    thiseq.bazi,...
        'GCARC',  thiseq.dis,...
        'IZTYPE', 11,...      %'IO'; reference time is hypo time
        'NZYEAR', thiseq.date(1),...
        'NZJDAY', thiseq.date(7),...
        'NZHOUR', thiseq.date(4),...
        'NZMIN',  thiseq.date(5),...
        'NZSEC',  floor(thiseq.date(6)),...
        'NZMSEC', round((thiseq.date(6) - floor(thiseq.date(6)))*1000));
    
    
    if (T0 == -12345) & (T2==-12345)%no P-and S-pick
        num = min([9   length(thiseq.phase.ttimes)-1]);%SAC allows only 10 picks
        for k=0:num
            tmp = ch(tmp,...
                ['T' num2str(k)] , thiseq.phase.ttimes(k+1),...
                ['KT' num2str(k)], char(thiseq.phase.Names(k+1)));
        end
    end


    fname = sprintf('%04.0f.%03.0f.%02.0f.%02.0f.%07.4f.%s.%s_%0.2f_%0.2f_%dp.%c.SAC',...
        D(1), JJJ, D(4), D(5), D(6),...
        config.netw, config.stnname, thiseq.filter,cname(m));
    outname = fullfile(exportdir,fname);
    files   = strvcat(files,fname);
    wsac(outname, tmp)
end
helpdlg({'SAC files written to directory',exportdir, ' ', files})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function changesystem(src,event,seis,sys)
global thiseq
%change icon of button
switch sys
    case 'geo'
        set(src,'CData', getfield(get(src,'USERData'),'geo'));
        thiseq.system='ENV';
    case 'ray'
        set(src,'CData', getfield(get(src,'USERData'),'ray'));
        thiseq.system='LTQ';
end
%plot new data:
SL_updatefiltered(seis)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SL_localparticlemotion(src,evt,seis)
SL_showparticlemotion(gcbf,seis,[nan nan], 'No pick' )


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localSavePicture(hFig,evt)
global config thiseq
defaultname = sprintf('%s_%4.0f.%03.0f.%02.0f.%s.',config.stnname,thiseq.date([1 7 4]),thiseq.system);
defaultextension = strrep(config.exportformat,'.','');
exportfiguredlg(gcbf, [defaultname defaultextension],config.savedir,config.exportresolution)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xzoomON(src,evt,seismo)
ud.down=get(gcbf,'WindowButtonDownFcn');
ud.up  =get(gcbf,'WindowButtonUpFcn');
ud.motion=get(gcbf,'WindowButtonMotionFcn');
set(src,'USERdata',ud);
s=nan;
pointer=[
    s s s s 1 1 1 1 s s s s s s s s
    s s 1 1 s 2 s 2 1 1 s s s s s s
    s 1 2 s 2 s 2 s 2 s 1 s s s s s
    s 1 s 2 s 1 1 2 s 2 1 s s s s s
    1 s 2 s 2 1 1 s 2 s 2 1 s s s s
    1 2 s 1 1 1 1 1 1 2 s 1 s s s s
    1 s 2 1 1 1 1 1 1 s 2 1 s s s s
    1 2 s 2 s 1 1 2 s 2 s 1 s s s s
    s 1 2 s 2 1 1 s 2 s 1 s s s s s
    s 1 s 2 s 2 s 2 s 2 1 s s s s s
    s s 1 1 2 s 2 s 1 1 1 1 s s s s
    s s s s 1 1 1 1 s s 1 1 1 s s s
    s s s s s s s s s s s 1 1 1 s s
    s 1 s s s s s 1 s s s s 1 1 1 s
    1 1 1 1 1 1 1 1 1 s s s s 1 1 1
    s 1 s s s s s 1 s s s s s s 1 s];
set(gcbf,...
    'WindowButtonDownFcn',{@localZoomSeismo,gcbf,seismo},...
    'WindowButtonUpFcn','',...
    'WindowButtonMotionFcn','',...
    'Pointer','Custom',...
    'PointerShapeCData',pointer,...
    'PointerShapeHotSpot',[7 7])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xzoomOFF(hFig,evt,seismo)
ud=get(gcbo,'USERdata');
set(gcbf,...
    'WindowButtonDownFcn',ud.down,...
    'WindowButtonUpFcn',ud.up,...
    'WindowButtonMotionFcn',ud.motion,...
    'Pointer','crosshair')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xzoomOutON(src,evt,seismo)
t   = get(seismo(2),'xData');
x   = xlim;
xx  = diff(x/2);
xxx = x+[-xx xx];
if xxx(1) < t(1);   xxx(1) = t(1);   end
if xxx(2) > t(end); xxx(2) = t(end); end

subax=findobj('Type','Axes','Parent',gcbf);
set(subax(4),'xlim', xxx)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localZoomSeismo(hFig,evt,fig,seismo)
global thiseq
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1);              % extract x and y
point2 = point2(1);
p1 = min(point1,point2);             % calculate locations
offset = abs(point1-point2);         % and dimensions
x = [p1(1) p1(1)+offset(1) ];

if (x(2)-x(1))/thiseq.dt < 40
    %prevent exessive zooming smaller than 40 samples
    sb= findobj('Tag','Statusbar');
    set (sb, 'String','Maximum zoom level reached! Do you really want to look at less than 40 samples????')
       
    return
end

subax=findobj('Type','Axes','Parent',gcbf);
set(subax(4),'xlim', round(x(1:2)))

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localStructBox(src,evt)
global thiseq
%%
tmp = thiseq;
tmp = rmfield(tmp, 'seisfiles');
files = cell2mat(thiseq.seisfiles(:));
txt = ['   |- seisfiles : ' files(1,:);
       '   |              ' files(2,:);
       '   |              ' files(3,:)];


str = strucdisp(tmp,2,1,7);
str = char(' thiseq', str(1,:) ,txt, str);

h=figure('WindowStyle', 'Modal',... 
         'Name','thiseq variable viewer',...
         'KeyPressFcn',@lscallback);

uicontrol('Units','Normalized',...
          'Position',[.05 .05 .9 .9],...
          'Style','edit',...
          'Parent',h,...
          'Value',1,...
          'max',100,...
          'min',0,...
          'BackGroundColor','w',...
          'FontName','FixedWidth',...
          'String',str)


function lscallback(src,evnt)
if strcmp(evnt.Key,'return') || strcmp(evnt.Character,'h')
    close(src);
end
