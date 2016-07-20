function SL_databaseViewer(eq_index)
% navigate within the SplitLab database

global eq config

if isempty(eq)
    errordlg('No Earthquakes in database!')
    return
end


% If there is 1 input argument, use function for variable passed.
% Like this, one can call 'getThisLineData' from 'seisKeypress.m' and
% 'seisFigButtons.m' in order to make databaseViewer show line
% corresponding to EQ in SeismoViewer ...
if nargin==1
    handle_h_list = findobj('tag','TableList');
    if ~isempty(handle_h_list);
        set(handle_h_list,'value',eq_index);    
        getThisLineData(handle_h_list);
    end
    return
end

%the next lines indicate the order in which columns are sorted when
%specific button was pressed.
sortorder = [ 3  2  1  5 %date:  day month year
              4  1  2  3 %julian day
              5  6  7  1 %time
              8  9 10  3 %lat
              9  8 10  3 %long
             10 12 13  3 %depth
             11 10 12  3 %Mw
             12 11 10  3 %baz
             13 12 11  3 %Distance
             14 14 14  14]; %ID, sort ID only after ID


%% Database box
strlen   = [ 0 12  5 11  9 9 9 6  10 10 4];
fontsize = 12; %pixel
names    = {'Date','JDay','Time','lat','long','depth','Mw','back-azi','distance','ID'};

figpos = get(0,'ScreenSize');
width  = 365*1.5;
xpos   = figpos(3)- figpos(1) - width*2.22;
ypos   = 70;
figpos = [xpos ypos width 270];

h.dlg = findobj('Type','Figure', 'Name','Database Viewer');
if isempty(h.dlg)
    h.dlg = figure('Name','Database Viewer','color',get(0,'DefaultUIcontrolBackgroundColor'),...
                   'CloseRequestFcn',@my_closereq,...
                   'Position',figpos,'Units','pixel','NumberTitle','off','MenuBar','none' );
else
    clf(h.dlg)
    set(h.dlg,'ResizeFcn','','Position',figpos,'Units','pixel')
    figure(h.dlg)
end

%create empty text to get width of text in pixel
tmp    = uicontrol(h.dlg, 'style','text', 'fontname','fixedWidth', 'fontunits','pixel',...
                   'FontWeight','bold', 'fontsize',fontsize, 'String',repmat('*',1,sum(strlen)), 'visible','off');
ext    = get(tmp,'extent');
pos    = get(h.dlg,'Position');
pos(3) = ext(3)+95;
set(h.dlg,'Position',pos);

val=config.db_index;
if val > length(eq)
    val=[];
end
h.cmenu = uicontextmenu;
h.list = uicontrol(h.dlg, 'style','listbox','Position',[40 150 ext(3)+17 figpos(4)-180],...
                   'tag','TableList','string',[],'fontname','fixedWidth','fontunits','pixel','fontsize',fontsize,...
                   'Backgroundcolor','w','max',999,'Callback', @getThisLineData,'BusyAction','cancel',...
                   'Tooltipstring','Double-click to open',...
                   'UIContextMenu',h.cmenu,'value',val);

% right-click in database box
uimenu(h.cmenu, 'Label', 'Delete','UserData',h.list,...
       'Callback', ['tmpobj = get(gcbo,''UserData'');'...
       'tmp1 = get(tmpobj,''val'');'...
       'tmp2 = setdiff(1:length(eq),tmp1); '...;
       'eq  = eq(tmp2);'...
       'tmp3 =get(tmpobj,''String''); '...
       'set(tmpobj,''value'',[],''string'',tmp3(tmp2,:)); clear tmp*']);


%% Header Buttons
x=0; %offset of first button
for i=2:length(strlen)
    set(tmp,'string',repmat('_',1,strlen(i)))
    xy = get(tmp,'extent');
    h.head(i)=uicontrol(h.dlg, 'style','pushbutton', 'FontWeight','bold',...
        'tag','TableButton', 'string',names(i-1), 'position',[40+x figpos(4)-30 xy(3:4)],...
        'callback',{@sorttable,sortorder(i-1,:),h.list, i-1});
%set(h.head(i),'callback','');
    x = xy(3)+ x - 4;
end

delete(tmp)
set(h.dlg, 'ResizeFcn',@localResizeFcn)


%% Default List display:
col = config.tablesortcolumn;
sorttable([],[],sortorder(col,:), h.list, col);


%% Result list
header    = ' Phase   \Psi_{RC}    \Psi_{EV}   \deltat_{RC}  \deltat_{EV}   Q\_manu  Q\_auto  Filter       Remark';
h.info(1) = uipanel('parent',h.dlg, 'units','pixel', 'Position',[40 40 ext(3)+17 100],'tag','ResultsPanel');
h.info(4) = axes('parent',h.info(1), 'units','pixel', 'Position',[2 78 ext(3)+11 18]);
axis off
h.info(2) = text(0,0,header,'HorizontalAlignment','left','VerticalAlignment','bottom ', ...
                 'Tag','ResultHeader','Interpreter','Tex', ...
                 'fontname','fixedWidth','fontunits','pixel','fontsize',fontsize,'FontWeight','bold');

h.info(3) = uicontrol('parent',h.info(1),'style','listbox','max',0, 'value',1,'Position',[1 1 ext(3)+12 80],...
                      'tag','ResultsBox','string',[],'Backgroundcolor','w','fontname','fixedWidth',...
                      'fontunits','pixel','fontsize',fontsize,'HorizontalAlignment','left',...
                      'Callback','database_editResults(''Select'')','BusyAction','Cancel');

load icon;

h.button1  = uicontrol(h.dlg,'style','pushbutton','Position',[40 8 50 25],...
                      'string','View','Callback','SL_SeismoViewer(get(findobj(''Tag'',''TableList''),''Value''))');
h.button2 = uicontrol(h.dlg,'style','pushbutton','Position',[100 8 50 25],...
                      'Tooltipstring','Remove earthquakes with no result from database',...
                      'string','CleanUp','Callback','database_editResults(''Cleanup'')');
h.button3 = uicontrol('style','pushbutton','Position',[160 8 60 25],...
                      'string','       Export','Tag','ExportButton','Cdata',icon.excel,...
                      'Tooltipstring','Export tabel to Excel worksheet',...
                      'Callback','pjt2xls');
h.button4 = uicontrol('style','pushbutton','Position',[230 8 50 25],...
                      'string','Statistic',...
                      'Tooltipstring', 'Show statistics plot',...
                      'Callback','SL_showeqstats');
h.button5 = uicontrol('Style','checkbox','String','EarthViewer',...
                      'pos',[285 8 80 25],'value', config.showearth,...
                      'Callback','config.showearth = get(gcbo,''Value''); filename = fullfile(config.projectdir,config.project); save(filename,''eq'',''config''); SL_databaseViewer;');          

% for single result
h.button6 = uicontrol(h.dlg,'style','pushbutton','Position',[ext(3)-60 8 60 25],...
                      'string','Remove','Enable','off','Tag','ResultsButton',...
                      'Tooltipstring','Remove result from database',...
                      'Callback','database_editResults(''Del'')');
h.button7 = uicontrol(h.dlg, 'style','pushbutton', 'Position',[ext(3)+7 8 50 25],...
                      'string','Edit','Enable','off','Tag','ResultsButton', ...
                      'Tooltipstring', 'Edit values ...',...
                      'Callback','database_editResults(''Edit'')');
h.button8 = uicontrol(h.dlg, 'style','pushbutton', 'Position',[ext(3)-117 8 50 25],...
                      'string','','Enable','of','Tag','ResultsButton', ...
                      'Cdata', icon.presentation,'Tooltipstring', 'View resultfiles',...
                      'Callback','database_editResults(''View'')');
 
getThisLineData(h.list);  % show results of EQ directly, no need to click first                 
if ~config.showearth      % close EarthView window if not wanted and still open
     close(findobj('Type', 'Figure', 'Tag',  'EarthView'));  
end
%END OF PROGRAMM


%% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function getThisLineData(h_list,evt)
global eq config

h_dlg = gcf;
val   = get(h_list,'Value');

if strcmp(get(h_dlg,'SelectionType'),'open')
    %double click
    SL_SeismoViewer(val);
else
    %%single click
    h_ax            = findobj('Tag','EQmap');
    mark            = findobj('Tag','thisEQMarker');
    r_box           = findobj('Tag','ResultsBox');
    config.db_index = val;   % if EQ clicked in table, assign config.de_index
                             % as this is used to show next time this last
    
    if ~isempty(mark),  delete(mark); end
    % set figure UserData to selection index!
    set(h_dlg,'Userdata',val); %for use with split button

    % Result display
    outstr = [];
    for j = 1:length(val)
        R = eq(val(j)).results;
        outstr = char(['-------------------------------- ' eq(val(j)).dstr ' -------------------------------------']);
        %outstr = '';
        if ~isempty(R)
            if strcmp(config.studytype,'Reservoir')
                unit = 'm';
            else
                unit =char(186);
            end
            for k = 1:length(R)
                P = R(k).SplitPhase;
                Q = R(k).Q;     %automatic Quality
                M = R(k).Qstr;  %Manual Quality
                %phis = [R(k).phiSC(1) R(k).phiRC(1)];
                strikes = [R(k).strikes(1) R(k).strikes(3)];
                dts  = [R(k).dtRC(1)  R(k).dtEV(1)];
                o = sprintf(['%6s %5.1f' unit ' %5.1f' unit '  %3.1fs  %3.1fs %9s %5.2f   [%4.3f %4.2f] %s'],...
                            P, strikes,dts, M, Q, R(k).filter(1:2),  R(k).remark);
                outstr = char(outstr,o);
            end
        end
        L(j) = length(R); %numbers of results per earthquake
    end
    L = cumsum([1 L+1]); %separation lines
    set(r_box, 'String',outstr, 'value',1, 'UserData',L)


    %% EarthMap of EQ
    Mw=round([eq(val).Mw]*10)/10;
    if config.showearth
        SL_Earthview([eq(val).lat],[eq(val).long],Mw,[eq(val).depth],reshape([eq(val).date],7,[])');
    end
end
filename = fullfile(config.projectdir,config.project);   
save(filename,'eq','config');  %save pjt when clicking through lines (because of config_db.index)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sorttable(src,evt,order,h_list, button)
global eq config

%
dvec=reshape([eq(:).date], 7, [])';
indices   = (1:size(dvec,1))';

listdata  = [dvec(:,[ 3 2 1 7 4 5 6])...  day month year Julian_day hour minute second
            [eq(:).lat]'   [eq(:).long]'...
            [eq(:).depth]' [eq(:).Mw]'   [eq(:).bazi]'...
            [eq(:).dis]'   indices];%
listdata(listdata == -12345) = 0;

%code for table sort, also when clicking twice !
try
   counter = getpref('tmp_vars', 'counter_table');
catch
   setpref('tmp_vars', 'counter_table', 0);
   counter = 0;
end

% depending on number of clicks on button, create correct sorting 'ascend'
% or 'descend'
if config.tablesortcolumn == button && button ~= 10 %'ID'
    counter   = counter + 1;
    new_order = (-1)^counter * order;
elseif button ~= 10
    counter   = 0;
    new_order = order;
else  % button == 10 ('ID')
    counter   = counter + 1;
    new_order = order;
end
config.tablesortcolumn = button;
setpref('tmp_vars', 'counter_table', counter);
[sdat,idx]  = sortrows(listdata, new_order);

% sets correct indices depending on if table is sorted ascending
if sdat(end,order(1)) < sdat(1,order(1))
    indices = flipud( indices );
end
sdat = [sdat(:,1:13)  indices];

% taking care on 'ID' button
if button == 10;
    i=0;
    while i < counter
        i = i+1; 
        sdat = flipud(sdat);
    end
end

% make sure correct unit is shown
if strcmp(config.studytype,'Reservoir')
    unit = 'm';
    unit2= 'm ';
else
    unit = char(186);
    unit2= 'km';
end

%format strings
datum = '%02.0f.%02.0f.%04.0f %03.0f';
hms   = ' %02.0f:%02.0f:%02.0f';
param = [' %6.1f' unit ' %6.1f' unit ' %4.0f' unit2 '  %3.1f'];
geom  = ['   %5.1f' char(186) '  %5.1f' unit ];

qual=' %4d ';
sdat = sdat(:,1:14);
% end

format = [datum hms param geom qual];

%format string produces line of match characters....
tmpstr = cell(size(sdat,1),1);
for k=1:size(sdat,1)
    tmpstr{k} = sprintf(format,sdat(k,:) );
end
outstr=deblank(char(tmpstr));
clear tmpstr

set(h_list,...
    'String',outstr,...
    'UserData',idx) %update display, Userdata are sort order incices
eq=eq(idx);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localResizeFcn(fig,evt)

set(fig,'Units','pixels');
figpos = get(fig,'Position');
if figpos(4) < 200
    figpos(4) =200;
    set(fig,'Position',figpos)
end

l = findobj('tag','TableList');
u = findobj('tag','TableButton');
r = findobj('tag','ResultsPanel');

for i =u';
    uold   = get(i,'Position');
    set(i,'Position',[uold(1) figpos(4)-30 uold(3) uold(4)]);
end
lold   = get(l,'Position');
set(l,'Position',[lold(1:3) figpos(4)-179]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function my_closereq(src,evt)
    earth    = findobj('type','figure', 'Name','Database Viewer');
    database = findobj('type','figure', 'tag','EarthView');
    delete(earth);
    delete(database);
%%%if both lines uncommented, when EarthViewer is closed global option is
%%%changed and dabaseViewer executed to display checkbox correctly
    %config.showearth = false;  
    %SL_databaseViewer;


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