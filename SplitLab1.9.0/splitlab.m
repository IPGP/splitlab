function splitlab(var_SeismoViewer)
% Main window of the SplitLab toolbox, configure the parameters and projects
% creating the configuration figure of Splitlab

clearvars -global config eq thiseq
global config

config.version='SplitLab1.9.0';


%% Load last opened project if it exists and check version
%  if button 'New Project' is pressed (see configpanelGENERAL.m), the entry 
%  "new_project.pjt" is PREPENDED to pref 'Splitlab','History'. This allows to 
%  create an if-statement which will run splitlab with the default settings
%  which serve as template for the new project.
pjtlist = getpref('Splitlab','History');
if strcmp( pjtlist{1},'new_project.pjt' )                   
    setpref( 'Splitlab','History', {pjtlist{2:end}} );      %rm first entry of 'Splitlab','History'
    pjtlist = getpref('Splitlab','History');                %reset pjtlist
else
    try                                     
        % try to load last project                  
        load('-mat',pjtlist{1});
    catch
        % if fail to load last project, open splitlab with
        % default settings instead
        warning( 'No project loaded. Please choose manually or use default settings to create new one !\n' );
    end
end
SL_checkversion

ok = checkmattaupclass;
if ok==0; warning('Troubles loading matTaup'); end


[p,f] = fileparts(mfilename('fullpath'));  % directory of Splitlab
set(0, 'DefaultFigurecolor', [224   223   227]/255 ,...
       'DefaultFigureWindowStyle', 'normal',...
       'DefaultUIControlBackgroundColor', [224   223   227]/255); 
close(findobj('Type','Figure', 'Name','Database Viewer'));
close(findobj('Type','Figure', 'Tag','EarthView'));  
close(findobj('Type','Figure', 'Tag','SeismoFigure'));  
close(findobj('Type','Figure', 'Tag','ResultViewer Options'));  
cfig =findobj('Type','Figure', 'Tag','ConfigViewer', 'name',['Configure ' config.version]);


%% try several fonts for best display of text and uicontrols
%  set(0,'screenPixelsPerInch', 96); %This is the default Windows DPI. we need to fix this for portability reasons! 

list = listfonts;
preffont={'M Sans Serif', 'Tahoma', 'Arial','Helvetica','Lucida Sans Unicode'};

for k=1:length(preffont);
    font = preffont(k);
    if sum(strcmpi(font,list))==1
        set(0, 'DefaultUIcontrolFontUnits', 'pixel')
        set(0, 'DefaultUIcontrolFontName', char(font),...          'DefaultAxesFontName',         char(font), ...
               'DefaultUIcontrolFontSize', 10 );         %,...     'DefaultAxesFontSize',         8 ,...
        break
    end
    if k==length(preffont)
        if strcmpi(preffont(end),font)
            disp('Best appearance of SplitLab Interface is with the fonts')
            disp('  "MS Sans Serif"');
            disp('  "Tahoma"')
            disp('These are currently not installed on your system...')
            disp('Press any key to continue')
            pause
        end
    end
end


%% create MAIN FIGURE if empty
if isempty(cfig)
    cfig = figure('name',['Configure ' config.version],...
                  'Tag', 'ConfigViewer',...
                  'KeyPressFcn', @splitlabKeyPress,...
                  'Menubar','none',...
                  'NumberTitle','off','units','pixel');
end


%% Side panel: radio buttons
h.menu = uibuttongroup('visible','on','units','pixel','Position',[5 5 120 410],...
    'BackgroundColor','w','HighlightColor',[1 1 1]*.3,...
    'Tag','radiobuttons',...
    'BorderWidth',1,'BorderType','beveledin',...
    'SelectionChangedFcn', @selcbk);


%% Main Panels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load icon.mat ;

p = get(0,'DefaultFigurePosition');
p(3:4)=[560 420];
set(gcf,'Position',p,'Resize','off');
pos = [130 5 425 410];

configpanelGENERAL;
configpanelSTATION;
configpanelPHASES;
configpanelSEARCHWIN;
configpanelREQUEST;
configpanelFINDFILE;
configpanelSPLITOPTION;


%% Side Panel: radio buttons
h.menu(2) = uicontrol(...
    'Style','Radio','String','General',...
    'BackgroundColor','w',...
    'pos',[10 350 100 30],'parent',h.menu,'HandleVisibility','off',...
    'Userdata',h.panel([6 8]));
h.menu(3) = uicontrol(...
    'Style','Radio','String','Station',...
    'BackgroundColor','w',...
    'pos',[10 325 100 30],'parent',h.menu(1),'HandleVisibility','off',...
    'Userdata',h.panel(1));
h.menu(4) = uicontrol(...
    'Style','Radio','String','Event Window',...
    'BackgroundColor','w',...
    'pos',[10 300 100 30],'parent',h.menu(1),'HandleVisibility','off',...
    'Userdata',h.panel(3));
h.menu(5) = uicontrol(...
    'Style','Radio','String','Request',...
    'BackgroundColor','w',...
    'pos',[10 275 100 30],'parent',h.menu(1),'HandleVisibility','off',...
    'Userdata',h.panel(4:5));
h.menu(6) = uicontrol(...
    'Style','Radio','String','Phases',...
    'BackgroundColor','w',...
    'pos',[10 250 100 30],'parent',h.menu(1),'HandleVisibility','off',...
    'Userdata',h.panel([2 10]));
h.menu(7) = uicontrol(...
    'Style','Radio','String','Find Files ',...
    'BackgroundColor','w',...
    'pos',[10 225 100 30],'parent',h.menu(1),'HandleVisibility','off',...
    'Userdata',h.panel([7 9]));
h.menu(8) = uicontrol(...
    'Style','Radio','String','Split Options',...
    'BackgroundColor','w',...
    'pos',[10 200 100 30],'parent',h.menu(1),'HandleVisibility','off',...
    'Tag','SplitOptions',...
    'Userdata',h.panel(11));


%% Side panel: push buttons
uicontrol('parent',h.menu(1),...
    'Units','pixel',...
    'Style','Pushbutton',...
    'Position',[10 160 100 25],...    'Cdata', icon.help,...
    'String','Help',...
    'Tooltip',' See help documents',...
    'Callback','open SplitLabPro_TheUserGuide.pdf' );

files   = {};
for k =1:length(pjtlist);
    [pp,name,ext] = fileparts(pjtlist{k});
    files{k}=[name ext];
end
loadstr={'    Load Project','    Browse...', files{:}};

h.menu(9) = uicontrol(...
    'Style','popupmenu',...
    'String',loadstr,...
    'UserData',pjtlist,...
    'BackgroundColor','w',...
    'pos',[6 128 110 25],'parent',h.menu(1),'HandleVisibility','off',...
    'Callback',@loadcallback);

h.menu(10) = uicontrol(...
    'Style','pushbutton',...
    'String','Save Project As',...
    'pos',[10 100 100 25],'parent',h.menu(1),'HandleVisibility','off',...
    'Callback',@savecallback,...
    'USERDATA', h.menu(8));

h.menu(11) = uicontrol(...
    'Style','pushbutton',...
    'String','View Seismograms',...
    'ToolTipString','Start / Continue splitting',...
    'pos',[10 70 100 25],'parent',h.menu(1),'HandleVisibility','off',...
    'Callback','SL_SeismoViewer(config.db_index)'); %open last splitting event

h.menu(12) = uicontrol(...
    'Style','pushbutton',...
    'String',' View Database',...
    'pos',[10 40 100 25],'parent',h.menu(1),'HandleVisibility','off',...
    'Callback','SL_databaseViewer');

h.menu(13) = uicontrol(...
    'Style','pushbutton',...
    'String','Results',...
    'pos',[10 10 100 25],'parent',h.menu(1),'HandleVisibility','off',...
    'Callback','SL_Results');

h.menu(14) = uicontrol(...
    'Style','pushbutton',...
    'String',' Save Preferences',...
    'ToolTipString','Save current configuration to MatLab preference file',...
    'pos',[7 380 106 22],'parent',h.menu(1),'HandleVisibility','off',...
    'Callback','SL_preferences(config);  helpdlg(''Preferences saved to MatLab Preferences!'',''Preferences'')');


%% CHANGE READIOBUTTON & SHOWN CONTENT PER CODE (and not click).
%  doesn't work. When arguement is passed, I want that the main splitlab
%  window shows the splitoptions, meaning it should be coded that the last
%  radiobutton is activated and that the correspondent content is shown.
%  GENERALLY: there seem to be little issues displaing ONLY the content of
%  the activated radio button, e.g. sometimes one can see the content of
%  former radio buttons in the panel gaps .. I've no idea what this is
%  about...
if nargin==1 %      There is 1 input argument, use function handle
    if ~isempty( cfg )
%         figure( cfg );
%         set(h.menu(1), 'SelectedObject',h.menu(8));
% 
%         a=get(h.menu(2),'Userdata');
%         b=get(h.menu(3),'Userdata');
%         c=get(h.menu(4),'Userdata');
%         d=get(h.menu(5),'Userdata');
%         e=get(h.menu(6),'Userdata');
%         f=get(h.menu(7),'Userdata');
%         h=get(h.menu(8),'Userdata');
% 
%         set(a,'visible','off');
%         set(b,'visible','off');
%         set(c,'visible','off');
%         set(d,'visible','off');
%         set(e,'visible','off');
%         set(f,'visible','off');
%         set(h,'visible','on');   
    else 
        mess = sprintf( '\nMain Splitlab Figure closed. Cannot show splitting options.');
        warning( mess ); 
    end
    return
end
drawnow;


%% POSTCART or ACKNOWLEDGEMENTS
% intrestingly, at startup the first value of the random gegenator is often 0.9501
% so, generate first dum dummy random numbers, and than in a new round take 
% two random to state if show postcard or acknowldgement dialogs
users = {'mibonnin', 'scholzjr'};
if ~strcmp(config.request.user, users) 
    rand(100,100);
    R = rand(1,2);   
    if R(1)>.92
        postcardware;
    end 
    if R(2)>.92
        acknowledgement;
    end
end


%% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function selcbk(source,eventdata)
%set selected menu panel visible, others are made invisible

old = get(eventdata.OldValue,'Userdata');
new = get(eventdata.NewValue,'Userdata');

set (old, 'visible', 'off');
set (new, 'visible', 'on');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function loadcallback(source,eventdata)
evalin('base','global eq thiseq config');
global config
val =get(gcbo,'Value');

if  val ==1;
    %"Load" string... do nothing!
    return
elseif  val == 2 %Browse...
    str ={'*.pjt', '*.pjt - SplitLab project files';
        '*.mat', '*.mat - MatLab files';
        '*.*',     '* - All files'};
    pjtlist = getpref('Splitlab','History');
    
   [tmp1,pathstr] = uigetfile( str ,'Project file', [config.projectdir, filesep]) ; 
    if isstr(pathstr) %user did not cancel
        load('-mat',fullfile(pathstr,tmp1))
        newfile = fullfile(pathstr,tmp1);
        match = find(strcmp(newfile, pjtlist));

        if isempty(match)% selection not in history
            if length(pjtlist)>10
                pjtlist = {newfile, pjtlist{1:10}};
            else
                pjtlist = {newfile, pjtlist{:}};
            end
        else
            %re-order list
            L       = 1:length(pjtlist);
            new     = [match setdiff(L,match)];
            pjtlist = pjtlist(new);
        end
    else %user did cancel
        return
    end

else
    pjtlist = getpref('Splitlab','History');
    %moving recently loaded to top of list
    n       = val-2; %data does not contain the "Load" and "browse" entries
    L       = 1:length(pjtlist);
    new     = [n setdiff(L,n)];
    pjtlist = pjtlist(new);
    
    files = get(gcbo,'Userdata'); %need full path name, which is stored in userdata
    if exist(files{n}, 'file')
        load('-mat',files{n})
    else
        errordlg(['The file ' files{n} ' doesn''t exist anymore.'],'No such File');
        return
    end
    [pathstr,name] = fileparts(files{n});
end

config.projectdir = pathstr;
setpref('Splitlab','History', pjtlist);

if ~isfield(config,'version') || isempty(config.version) || (1.2)> sscanf(config.version(9:11),'%f')
    warning('This project is created with an older version of SplitLab. Result format will be converted...')
    SL_convert2ver1_2
end
splitlab;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function savecallback(src,e)
global config eq

str ={'*.pjt', '*.pjt - SplitLab project files';
    '*.mat', '*.mat - MatLab files';
    '*.*',     '* - All files'};
[tmp1,tmp2]=uiputfile( str ,'Project file', ...
    [config.projectdir, filesep, config.project]);

if ischar(tmp2)
    oldpjt = config.project ;
    config.projectdir = tmp2;
    config.project    = tmp1;
    newfile = fullfile(tmp2,tmp1);
    pjtlist = getpref('Splitlab','History');
    match   = find(strcmp(newfile, pjtlist));

    if isempty(match)% selection not in history
        if length(pjtlist)>10
            pjtlist = {newfile, pjtlist{1:10}};
        else
            pjtlist = {newfile, pjtlist{:}};
        end
    else
        %re-order list
        L       = 1:length(pjtlist);
        new     = [match setdiff(L,match)];
        pjtlist = pjtlist(new);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpref('Splitlab','History', pjtlist)
    save(fullfile(tmp2,tmp1),    'config','eq')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    files   = {};
    for k =1:length(pjtlist);
        [pp,name,ext] = fileparts(pjtlist{k});
        files{k}=[name ext];
    end
    loadstr={'    Load Project','    Browse...', files{:}};
    loadUIcontrol = get(gcbo,'Userdata');
    set(loadUIcontrol,'UserData', pjtlist, 'String', loadstr)
    
    pjtfield = findobj('String',oldpjt,'type','uicontrol');
    set(pjtfield,'String',config.project)
    
end
clear tmp*;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function splitlabKeyPress(source, event)

seisView = findobj('type','figure','Tag','SeismoFigure');
%number = get(seisView, 'Number');

isempty(seisView)
if strcmp( event.Key, 'o') && ~isempty(seisView)
    uistack(seisView, 'top');
end


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
