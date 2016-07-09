function getIRISstationInfo(varargin)
% This function reads NEIC station database and allows the user to select a
% station (double click) to be imported into SplitLab
% The database was imported to Matlab from the NEIC web page as follows
% (You may want to update...)
%
% Go to http://www.iris.edu/SeismiQuery/station.htm
% select by region [90 -90 -180 180]
% turn on 
%   "Network"
%   "Station" 
%   "Elevation" 
%   "Start Time" 
%   "End Time" 
%   "Site Like"
%   "Network affiliation like"
% Set the "Start Time" to sometime around 1960
% Now click "View Results" and Download the HTML table.
% open it with Excel or similar and save it as a TAB seperated text file.
% You may need tochange the format of the start- and end-time columns to
% represent a date to something matlab recognises (e.g., 'yyyy-mm-dd')
% The text file may contain some HTML rubish and a footer line, whihc needs
% to be deleted befor converting it with the code below to a .mat file.
%
% %% START CODE
% format='%s %s %s %s %f %f %f %s %s'; 
% fid = fopen('IRIS_stationMay2009.txt');
% C = textscan(fid, format, 'HeaderLines',1,'Delimiter','\t');
% fclose(fid);
% save IRISstations02May2009.mat C
% %% END CODE



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



fig=figure('NumberTitle','off',...
    'Units','Character','MenuBar','None','Name','IRIS station database as of May 2009');
pos=get(fig,'Position');
pos(3:4)= [128 30];
pos(1)= 15;
set(fig,'Position',pos);

hinfostr = uicontrol( 'Style','text',    'FontName','FixedWidth',...
    'Units','characters','Position',[4 1 120 6],...
    'Parent',gcf,...
    'String','loading database...');
drawnow
load IRISstations02May2009.mat
set(hinfostr,'String','Click on a station to see more information')
outstr=sortData(0,0,2,C,fig);%default sorting by station (column 2)
listBox = uicontrol('Style','listbox',...
    'FontName','FixedWidth',...
    'Units','characters',...
    'Position',[4 8 120 20],...
    'BackgroundColor','white',...
    'Max',89,'Min',1,...
    'Parent',gcf,...
    'String',outstr,...
    'callback',{@listCallback,hinfostr});

header={'NET','STAT','STARTTIME','ENDTIME','LAT','LON','ELEVATION','SITE'};
width=[0 7 9 18 18 12 12];
x=3;
for k=1:6
    x=x+width(k)+1;
    uicontrol('Style','PushButton','Units','Character','FontName','FixedWidth',...
        'Position',[x, 28 width(k+1) 1.5],'String',header{k},...
        'UserData',listBox,...
        'CallBack',{@sortData,k})
end






%%
pos=get(0,'ScreenSize');
width= 360*1.5; height=180*1.5;
xpos = pos(1) + pos(3) - width*1.05;
ypos = 70 ;
pos=[xpos ypos width height];
earth = figure('NumberTitle','off',...
    'name','Earth Viewer',...
    'MenuBar','None','Position', pos);
ax=axes('Units', 'normalized','Position',[.0 .0 1 1],'Ydir','reverse','Parent',earth);
LATS   = linspace( -90,  90, 1200 );
LONS   = linspace(-180, 180, 2400 );
ThisIm = imread('world.topo.bathy.200406.jpg');
image(LONS,LATS, ThisIm,'Tag','ModisMapAX','Parent',ax)


set(fig, 'CloseRequestFcn',{@my_closefcn,earth})


function my_closefcn(src,evnt,earth)
if ishandle(earth)
    delete(earth)
end
delete(gcbf)


%%
function outstr=sortData(src,evnt,col,varargin);
if nargin==5
    C=varargin{1};
    fig=varargin{2};
else
    C=get(gcbf,'UserData');
    fig=gcbf;
end
[dummy,i] = sort(C{col});
s=repmat(' | ',size(i));
start = char(C{3}(i));
start = start(:,1:11);
outstr=[char(C{1}(i))  s char(C{2}(i)) s start s char(C{4}(i)) s num2str(C{5}(i),'%10.3f') s num2str(C{6}(i),'%10.3f')];

if nargin<4
    set(get(src,'UserData'), 'String',outstr)
end
D={C{1}(i) C{2}(i) C{3}(i) C{4}(i) C{5}(i) C{6}(i) C{7}(i) C{8}(i) C{9}(i)};
set(fig,'UserData',D);

%%
function listCallback(src,evnt,hinfostr);

C=get(gcbf,'UserData');
id = get(src,'Value');


select = get(gcbf,'SelectionType');
switch lower(select)
    case 'open'
        [y1, m1, d1] = datevec(C{3}(id),'yyyy-mm-dd');
        
        if datenum(datevec(C{4}(id),'yyyy-mm-dd'))>now;         
            [y2, m2, d2] = datevec(now);
        else
            [y2, m2, d2] = datevec(C{4}(id),'yyyy-mm-dd');
        end
        twin= num2str([d1 m1 y1 d2 m2 y2]);        
        evalin('base',...
            ['config.twin=['   num2str(twin) ']; '...
            'config.slat='   num2str(C{5}(id)) '; '...
            'config.slong='   num2str(C{6}(id)) '; '...
            'config.selev='    num2str(C{7}(id)) '; '...
            'config.stnname='''  char(C{2}(id)) '''; '...
            'config.comment=''' char(C{8}(id)) '''; '...
            'config.netw='''    char(C{1}(id)) '''; '])
        splitlab;
    case 'normal'
        s=repmat(' ; ',size(id'));
        set(hinfostr,'String',[char(C{8}(id)) s char(C{9}(id))])
        ax =get(findobj('Tag','ModisMapAX'),'Parent');
        
        if ~isempty(ax)
            hold(ax,'on');
            delete(findobj('Tag','StationMarker','Parent',ax));
            
            
            lat     = -C{5}(id);
            lon     =  C{6}(id);
            stnname =  C{2}(id);
            plot(lon, lat,'k^','Markersize',8,'MarkerFaceColor','r','Tag','StationMarker','Parent',ax);
            text(lon, lat-2, stnname,'VerticalAlignment', 'bottom','Tag','StationMarker','Parent',ax,...
                'HorizontalAlignment','center' ,'Color', 'y', 'FontName','FixedWidth','Fontweight','demi','Interpreter','none')
        end
end
