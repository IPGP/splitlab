function SL_distance_window_select

global config


set(0,'Units','pixels')
scnsize = get(0,'ScreenSize');

%Define the size and location of the figures:
pos  = [scnsize(3)/6,...
    1/6*scnsize(4) ,...
    scnsize(3)/3*2,...
    scnsize(4)/3*2];


figure(19)
clf
set(gcf,'UserData',config.eqwin,'position',pos)
ax=axes;
load plates.mat;

[latlow,lonlow]= gcpts(config.slat,config.slong, 0:5:360, config.eqwin(1));
[latup,lonup]  = gcpts(config.slat,config.slong, 0:5:360, config.eqwin(2));
ff= find(abs(diff(lonlow))>180);
for k = 1:length(ff)
    idx = ff(k)+((k-1)*3);
    s=sign(lonlow(idx));
    lonlow = [lonlow(1:idx); 180*s;        nan;    -180*s;       lonlow(idx+1:end)];
    latlow = [latlow(1:idx); latlow(idx);  nan;    latlow(idx);  latlow(idx+1:end)];
end
ff= find(abs(diff(lonup))>180);
for k = 1:length(ff)
    idx = ff(k)+((k-1)*3);
    s=sign(lonup(idx));
    lonup = [lonup(1:idx); 180*s;       nan;    -180*s;      lonup(idx+1:end)];
    latup = [latup(1:idx); latup(idx);  nan;    latup(idx);  latup(idx+1:end)];
end

I = imread('world.topo.bathy.200407.jpg');
I= flipdim(I,1)*1.1;
LONS=linspace(-180, 180, size(I,2) );
LATS=linspace(-90,  90,  size(I,1) );

image(LONS,LATS, I,'Parent',ax ,'Tag','ModisMap');
set(ax, 'YDir','normal','xtick',-180:45:180, 'ytick',-90:30:90)
hold on
daspect([1 .9 1])
plot(PBlong, PBlat, 'LineStyle','-','Linewidth',1,'Tag','Platebounds','Color',[0.6 .12 .12])

%Grid lines at 15Deg intervals
for dis = 20:20:165;
    [latd,lond]= gcpts(config.slat,config.slong, 0:5:360, dis);
    ff= find(abs(diff(lond))>180);
    for k = 1:length(ff)
        idx = ff(k)+((k-1)*3);
        s=sign(lond(idx));
        lond = [lond(1:idx); 180*s;      nan;    -180*s;     lond(idx+1:end)];
        latd = [latd(1:idx); latd(idx);  nan;    latd(idx);  latd(idx+1:end)];
    end
    plot(lond,latd,  ':', 'Color','m', 'linewidth',1);%SKSwindow
end




plot(lonlow,latlow, '-', 'Color','b', 'linewidth',2,'TAG','LOWER','ButtonDownFcn', @localChangeSKSWin );%SKSwindow
plot(lonup, latup , '-', 'Color','r', 'linewidth',2,'TAG','UPPER','ButtonDownFcn', @localChangeSKSWin);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

text(...
    config.slong, config.slat-3, config.stnname,...
    'color', 'y',...
    'horizontalalignment','center',...
    'verticalalignment','top',...
    'FontWeight','demi','TAG','STATIONMARKERtxt');
plot(config.slong, config.slat, 'kv','MarkerFaceColor','r','MarkerSize',8,'TAG','STATIONMARKER','ButtonDownFcn', @localStation);

uicontrol('Style','PushButton','String','View events','Position',[10 5 80 20],...
    'Callback',@showEvents)

Plist={'P','S','Pdiff','Sdiff','PP','SS','PPP','PcP','PcS','ScS','ScP','PS','SP',...
    'SKP','PKS','SKS','SKiKS','SKJKS','PKiKP','PKJKP', ...
    'PKKP', 'PKKS','SKKS', 'SKKP'};
phaseval=find(strcmp(Plist, config.phases(1)));

uicontrol('Style','PopUpMenu','String',Plist,'Position',[100 10 70 15],'BackGroundColor','w',...
    'Callback',@usePhases,'Value',phaseval)
uicontrol('Style','PushButton','String','travel times','Position',[190 5 80 20],...
    'Callback','SL_ttcurves(config.earthmodel,config.phases, config.z_win(1), mean(config.eqwin), config.eqwin)')
hold off

set(get(gca,'Title'),  'String', sprintf( 'Distance =  %.0f\\circ -  %.0f\\circ',config.eqwin))







end

%% ////////////////////////
function usePhases(src,evnt)
global config
val=get(src,'Value');
pnames=get(src,'String');
config.phases = pnames(val);
tt=taupCurve(config.earthmodel, 0, char(config.phases));
if ~isempty(tt.distance)
    dis=[tt(:).distance];
    config.eqwin=round([min(dis) max(dis)]);
   
    SL_distance_window_select
else
    warndlg('Phase not found')
end
end
















%% ////////////////////////////////////////////////////
function localStation(src,evt)
ax=get(src,'Parent');
set(gcbf,'WindowButtonMotionFcn',{@buttonStationMotion,src},...
    'WindowButtonUpFcn','set(gcbf,''WindowButtonMotionFcn'',[],''Pointer'',   ''arrow'');SL_distance_window_select;')
set(gcbf,'Pointer','Hand')
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buttonStationMotion(src,evnt, linehndl)
global config
Pt = get(gca,'CurrentPoint');
set(linehndl,'Xdata',Pt(1,1),'Ydata',Pt(2,2))
set(get(gca,'Title'),  'String', sprintf( 'Station =  %.1f\\circN -  %.1f\\circE',Pt(1,1:2)))
config.slat=Pt(2,2);
config.slong=Pt(1,1);
end


%% /////////////////////////////////////////////////////////////

function showEvents(src,evnt)
global config


dat = SL_eqwindow;

obj = findobj('Tag','12345EVENTS');
delete(obj)
hold on
plot([dat.long],[dat.lat],'y.','TAG','12345EVENTS')
hold off

end
%% ///////////////////////////////////////////////////////////////////////
function localChangeSKSWin(src,evnt)
ax=get(src,'Parent');
set(gcbf,'WindowButtonMotionFcn',{@buttonMotion,src},...
    'WindowButtonUpFcn','set(gcbf,''WindowButtonMotionFcn'',[],''Pointer'',   ''arrow'');   config.eqwin=round(sort(get(gcbf,''UserData'')));');
set(gcbf,'Pointer','Hand')
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buttonMotion(src,evnt, linehndl)
global config
Pt2 = get(gca,'CurrentPoint');



dis = sphere_dist(Pt2(1,2),Pt2(1,1), config.slat,config.slong );
ud=get(gcbf,'UserData');


if strcmp(get(linehndl,'TAG'),'LOWER')
    ud(1)=dis;
else
    ud(2)=dis;
end
set(gcbf,'UserData',ud)






[latlow,lonlow]  = gcpts(config.slat,config.slong, 0:5:360, dis);
ff= find(abs(diff(lonlow))>180);
for k = 1:length(ff)
    idx = ff(k)+((k-1)*3);
    s=sign(lonlow(idx));
    lonlow = [lonlow(1:idx); 180*s;        nan;    -180*s;       lonlow(idx+1:end)];
    latlow = [latlow(1:idx); latlow(idx);  nan;    latlow(idx);  latlow(idx+1:end)];
end

set(linehndl,'Xdata',lonlow,'Ydata',latlow)
set(get(gca,'Title'),  'String', sprintf( 'Distance =  %.0f\\circ -  %.0f\\circ',sort(ud)))





end