function SL_SeismoViewer(idx)
% plot seismograms and provide user interaction

if nargin<1 || isempty(idx)
    idx=1;
end

global config eq thiseq

if isempty(eq)
    beep
    errordlg('Sorry no SplitLab-Project is loaded!', 'No project')
    return
end

config.db_index = idx;
if isfield(thiseq,'SplitPhase')
    oldphase = thiseq.SplitPhase;
else
    oldphase = 'SKS';
end

thiseq = [];
try
    thiseq = eq(idx); %AW; 07.01.06
    thiseq.index=idx;
catch
    thiseq = eq(1); %AW; 07.01.06
    thiseq.index=1;
    config.db_index=1;
end

if isempty([thiseq.seisfiles])
    errordlg('No SAC files associated to database!', 'Files not associated')
    return
end

efile = fullfile(config.datadir, thiseq.seisfiles{1});
nfile = fullfile(config.datadir, thiseq.seisfiles{2});
zfile = fullfile(config.datadir, thiseq.seisfiles{3});

if ~exist(efile, 'file') || ~exist(nfile, 'file') || ~exist(zfile, 'file')
    errordlg({'Seismograms not found!', 'Please check data directory', efile, nfile, zfile}, 'File I/O Error')
    return
end


%% Show WorldMap, if on screen
earthfig= findobj('Type', 'Figure',...
                  'Tag','EarthView');
if ~isempty(earthfig)
    SL_Earthview(thiseq.lat, thiseq.long, thiseq.Mw, thiseq.depth, thiseq.date)
    % set(0,'CurrentFigure',seisfig)
    %  set(seisfig,'Position',figpos);
end


%% Plot defaults
scol = [0 0 1; 1 0 0;0 .6 0];           % color ordering of seimogramms
tcol = config.Colors.TTMarkerColor ;    % color of travel time markers
Pcol = config.Colors.PselectionColor;   % color of P_window selection area
Scol = config.Colors.SselectionColor;   % color of S_window selection area
ocol = config.Colors.OldselectionColor; % color of old selection area(s)
afcol= config.Colors.SACMarkerColor ;   % color of SAC header A & F markers

fontsize          = get(0, 'FactoryAxesFontsize')-2;
thiseq.system     = 'ENV'; % or: 'LTQ'; % DEFAULT SYSTEM
thiseq.SplitPhase = 'SKS'; %default selection

thiseq.resultnumber = length(thiseq.results) + 1;
n = thiseq.resultnumber;


%% Get last used filter
if isfield(thiseq.results, 'filter')
    if ~isempty(thiseq.results(end).filter)
        thiseq.filter = thiseq.results(end).filter;
        if length(thiseq.filter) < 3; thiseq.filter(3)=3; end %add number of poles; version compatibility
    else
        thiseq.filter =[0 inf 3];  % Hz; cut freqency;  here unfiltered; last entry is number of poles;
    end
else
    thiseq.filter =[0 inf 3];  % Hz; cut freqency;  here unfiltered; last entry is number of poles;
end


%% Figure initalisation
seisfig = findobj('Tag', 'SeismoFigure');
figname = sprintf('SeismoViewer(%.0f/%.0f): start= %.3fHz  stop= %0.2f Hz  Order: %d', config.db_index, length(eq), thiseq.filter);

if isempty(seisfig)
    pos     = get(0, 'ScreenSize');
    width   = pos(3)-40;
    height  = pos(4)/1.75;
    xpos    = pos(1) +20;
    ypos    = pos(4)/3 ;
    figpos  = [xpos ypos width height];
    seisfig = figure('NumberTitle', 'Off',...
                     'Name', figname,...
                     'Renderer', 'Painters',...
                     'ToolBar', 'None',...
                     'Menubar', 'None',...
                     'Tag', 'SeismoFigure',...
                     'Color', 'w',...
                     'Position', figpos,...
                     'Pointer', 'CrossHair', ...
                     'PaperType', config.PaperType,...
                     'PaperOrientation', 'Landscape',...
                     'PaperUnits', 'Centimeters');
else
    figure(seisfig); %bring window to front
    figpos = get(gcf,'Position');
    clf(seisfig)
    set(seisfig,...
        'name', figname,...
        'Tag', 'SeismoFigure',...
        'Pointer', 'crosshair',...
        'WindowButtonDownFcn', '',...
        'KeyPressFcn', '',...
        'PaperOrientation','landscape');
end

orient landscape

uicontrol('style', 'Text',...
          'BackGroundColor', 'w',...
          'Units', 'Pixel',...
          'Position', [100 2 figpos(3)-85 14],...
          'Parent', seisfig,...
          'String', '  Status:   Reading seismograms ...',...
          'HorizontalAlignment', 'Left',...
          'Tag', 'Statusbar');
drawnow;


%% Calculate phases
localCalculateGeometry

if config.calcphase && strcmp(config.studytype,'Teleseismic')
    s = findobj('Tag', 'Statusbar');
    set(s, 'String', 'Status:  calculating phase arrivals ...');
    drawnow;
    eq(idx).phase = calcphase;
    thiseq.phase  = eq(idx).phase;
    
    %% Status bar and phase selector menu
    if isempty(thiseq.phase)
        val=1;
        thiseq.phase.Names       = {'none'};
        thiseq.phase.inclination = 0;
        thiseq.phase.ttimes      = [];
        thiseq.phase.takeoff     = [];
    else
        val = strmatch(oldphase, thiseq.phase.Names);
        if isempty(val);
            val = 1;
        else
            val = val(1);
        end
        %thiseq.SplitPhase     = thiseq.phase.Names{val(1)};
        if isempty(thiseq.phase.inclination)
            thiseq.phase.inclination=0;
        end
    end
    
else
    val =2;
    thiseq.phase.Names       = {'None', 'straight line'};
    thiseq.phase.inclination = [0 thiseq.geoinc];
    thiseq.phase.bazi        = [0 thiseq.geobazi];
    thiseq.phase.ttimes      = [nan nan];
    thiseq.phase.takeoff     = [nan nan];

    if config.calcphase && strcmpi(config.earthmodel, 'homogeneous')
        model = calcphase;
        %thiseq.phase = eq(idx).phase;
        thiseq.phase.ttimes      = [thiseq.phase.ttimes       model.ttimes] ;
        thiseq.phase.Names       = {thiseq.phase.Names{:}     model.Names{:}};
        thiseq.phase.inclination = [thiseq.phase.inclination  model.inclination ];
        thiseq.phase.bazi        = [ thiseq.phase.bazi        model.bazi ];
        val =4;
    end
    eq(idx).phase=thiseq.phase;
end

phaseMenu = uicontrol('style', 'PopupMenu',...
                      'Units', 'Pixel',...
                      'Position', [2 1 95 17],...
                      'String', thiseq.phase.Names ,...
                      'Parent', seisfig,...
                      'Value', val,...
                      'HorizontalAlignment','Right',...%%Callback is defined further down...
                      'Tag','PhaseSelector');
drawnow;

%% If available plot mechanism
if isfield(thiseq, 'meca') && ~isempty(thiseq.meca)
    axes('Visible', 'Off',...
         'Units', 'Pixel',...
         'Position', [12 21 50 50],...)
         'DataAspectRatio', [1 1 1]);
    beachball(thiseq.meca, 0, 0, 100, 0, 'r');
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read seismograms and rotate                                         %
thiseq = readseis3D(config,thiseq);                                    %
if isfloat(thiseq)
    if thiseq>0
        SL_SeismoViewer(thiseq);
    end
        return
end                                                                    %
get(findobj('Tag', 'PhaseSelector'), 'Value');                         %

% Initialise ray frame seismograms. are assigned later in "beautify section"
thiseq.Amp.L  = zeros(size(thiseq.Amp.Vert));                          %
thiseq.Amp.SG = zeros(size(thiseq.Amp.Vert));                          %
thiseq.Amp.SH = zeros(size(thiseq.Amp.Vert));                          %
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(config.studytype, 'Reservoir')
    titlestr = {sprintf('Event: %s, (%03.0f); M_w = %3.1f;  Station: %s ', thiseq.dstr, thiseq.date(7), thiseq.Mw, strrep(config.stnname,'_', '\_'));
        sprintf(['Backazimuth: %6.2f\\circ  Inclination: %6.2f\\circ  3D-Distance: %.2f m' '   Depth: %.1f m'], thiseq.bazi, thiseq.geoinc, thiseq.geodis3D, thiseq.depth)};
elseif strcmp(config.studytype, 'Regional')
    titlestr = {sprintf('Event: %s, (%03.0f); M_w = %3.1f;  Station: %s ',thiseq.dstr, thiseq.date(7), thiseq.Mw, strrep(config.stnname,'_', '\_'));
        sprintf('Backazimuth: %6.2f\\circ  GeoInc: %6.2f\\circ  Epi-Distance: %6.2fkm   3D-Distance: %.2f km Depth: %.2fkm',thiseq.bazi, thiseq.geoinc, thiseq.dis, thiseq.geodis3D, thiseq.depth)};
else
    titlestr={sprintf('Event: %s, (%03.0f); M_w = %3.1f;  Station: %s ',thiseq.dstr, thiseq.date(7), thiseq.Mw, strrep(config.stnname,'_', '\_'));
        sprintf('Backazimuth: %6.2f\\circ  Distance: %6.2f\\circ   Depth: %.1fkm', thiseq.bazi, thiseq.dis, thiseq.depth)};
end


%% Axes:
s = findobj('Tag', 'Statusbar');
set(s, 'String', 'Status:  Drawing axes ...');
drawnow;

pos    = [.066 .63 .89 .25; .066 .36 .89 .25; .066 .09 .89 .25]; %position of axis
bigpos = [pos(3,1:3) pos(1,4)+pos(1,2)-pos(3,2)]; %exactly the size of the 3 seismograms

% TRAVEL TIMES
% are plotted in an invisible axes, so we only have to plot them once...
subax(4) = axes('position', bigpos,...
                'Parent', seisfig,...
                'Xlim', [thiseq.Amp.time(1) thiseq.Amp.time(end)],...
                'Tag','TTimeAxes',...
                'XMinorTick','On');

% ORIGINAL SAC MARKERS
x = [thiseq.SACpicks; thiseq.SACpicks;  nan(size(thiseq.SACpicks)) ];
y = repmat([0 1 nan], size(thiseq.SACpicks));
line(x(:), y, 'Color', afcol, 'LineStyle', '-', 'Parent', subax(4));
text(thiseq.SACpicks, ones(size(thiseq.SACpicks))*.995,...
     thiseq.SACpickNames,...
     'Color', afcol,...
     'FontSize', fontsize+1,...
     'VerticalAlignment', 'Top', ...
     'HorizontalAlignment', 'Left', ...
     'Parent', subax(4));

% plot traveltimes
for i=1:length(thiseq.phase.ttimes)
    if any([strcmp(thiseq.phase.Names{i}, 'P-pol(bazi)') strcmp(thiseq.phase.Names{i}, 'P-pol')])
        %do nothing
    else
        tt = thiseq.phase.ttimes(i) ; %add origin time
        line([tt tt], [0 1],...
             'Color', tcol,...
             'LineStyle', ':',...
             'Tag', 'TTime',...
             'Parent', subax(4));
        text(tt, 0, [' ' thiseq.phase.Names{i}],...
             'Color', tcol,...
             'FontSize', fontsize+1,...
             'Rotation', 90,...
             'Tag', 'TTime',...
             'VerticalAlignment', 'Top',...
             'HorizontalAlignment', 'Left',...
             'Parent', subax(4));
    end
end

% SEISMOGRAM AXES
for i=1:3
    subax(i) = axes('Units', 'Normalized',...
                    'Position', pos(i,:),...
                    'Box', 'On',...
                    'FontSize', fontsize,...
                    'XMinorTick', 'On',...
                    'Parent', seisfig);
    seis(i)  = plot(thiseq.Amp.time, thiseq.Amp.time,...
                    'Color', scol(i,:),...
                    'Tag', 'seismo',...
                    'Parent', subax(i)); %dummy seismogram, initimlies size
end

xlabel(sprintf('seconds after %02.0f:%02.0f:%06.3f', thiseq.date(4:6)));
set(subax(1:2), 'XTickLabel', [])
set(subax, 'Tag', 'seisaxes')

% Link all 4 X-axis
set(subax,...
    'Color', 'None',...
    'YLimMode', 'Auto',...
    'XMinorTick', 'On',...
    'TickLength', [0.007 0.025],...
    'Xlim', [thiseq.Amp.time(1) thiseq.Amp.time(end)],...
    'Parent', seisfig)

set(seisfig, 'currentAxes', subax(4))


%% Linking of axes
link_obj = linkprop(subax, {'Xlim','Xgrid','Ygrid'});
setappdata(subax(4), 'dummy', link_obj);

%% Initialise time selector area
% based on "gline.m" of statistics toolbox
% is at first invisible (area == 0)
hold(subax(4), 'on')
split.x = [];
split.index=idx;

%old windows
for n = 1: thiseq.resultnumber-1
    x = [thiseq.results(n).Spick(1)   thiseq.results(n).Spick(1)    thiseq.results(n).Spick(2)    thiseq.results(n).Spick(2)];
    fill(x, [0 1 1 0], ocol,...
        'Parent', subax(4), ...
        'EdgeColor', 'None', ...
        'Visible', 'On',...
        'Tag', 'OldWindow');
        %c = get(subax(4),'children'); set(subax(4),'Children',[c(2:end) ;c(1)]);
end

%new (active) window
x = [0 0 0 0];
split.hfill = fill(x, [0 1 1 0], Scol,...
                   'Parent',subax(4),...
                   'EdgeColor','none',...
                   'Visible','on',...
                   'Tag','SplitWindow');
split.Stext = text(0, 1, ' S-pick',...
                   'Color','red',...
                   'Visible','Off',...
                   'Parent', subax(4),...
                   'FontSize', 8,...
                   'FontWeight', 'Demi',...
                   'Rotation', 90,...
                   'HorizontalAlignment', 'Right',...
                   'VerticalAlignment', 'Top');

thiseq.Ppick = [ 0 0 0 0];
if isfield(thiseq, 'Ppick') && ~isempty(thiseq.Ppick)
    if length(thiseq.Ppick)==1
        Ppos = [thiseq.Ppick; thiseq.Ppick; thiseq.Ppick; thiseq.Ppick];
    else
        Ppos = [thiseq.Ppick(1); thiseq.Ppick(1); thiseq.Ppick(2); thiseq.Ppick(2)];
    end
else
    Ppos = [0 0 0 0];
    thiseq.Ppick = Ppos(1:2);
end

split.hPfill = fill(Ppos, [0 1 1 0], Pcol,...
                    'Parent', subax(4),...
                    'EdgeColor', 'None',...
                    'Visible', 'On',...
                    'Tag', 'PWindow');
split.Ptext = text(Ppos(1), 1, ' P-pick',...
                   'Color', 'blue',...
                   'Visible', 'Off',...
                   'Parent', subax(4),...
                   'FontSize', 8,...
                   'FontWeight', 'Demi',...
                   'Rotation', 90,...
                   'HorizontalAlignment', 'Right',...
                   'VerticalAlignment', 'Top');

c = get(subax(4), 'Children');
r = thiseq.resultnumber+4;
order = [c(r:end) ;c(1:r-1)];
set(subax(4), 'Children', order)


%% FINAL beautify
set(subax(4), 'Visible', 'Off')
title(subax(4), titlestr,...
      'Visible', 'On',...
      'FontName', 'FixedWidth',...
      'Tag', 'BackgroundSeisAxesTitle',...
      'HandleVisibility', 'On',...
      'FontSize', fontsize+2)
ylabel(subax(4), sprintf('f_1 = %4.3f Hz   f_2 = %4.3f Hz',thiseq.filter(1:2)),...
       'Tag', 'TTimeAxesLabel',...
       'HandleVisibility', 'On',...
       'Units', 'Normalized',...
       'Position', [1.03 .5 1],...
       'Visible', 'On',...
       'FontSize', fontsize)
set(seisfig, ...
    'WindowButtonDownFcn', {@buttonDown, split, subax(4), seis}, ...
    'KeyPressFcn',         {@seisKeyPress, seis});

v=version;
if sscanf(v(1:3),'%f')>=7.4
    set(seisfig, 'WindowScrollWheelFcn', {@figScroll, [seis subax(4)]});
end

hold off;

seisfigbuttons(seisfig,seis);

set(phaseMenu,...
    'Callback', 'RotatePhaseSelect(gcbo)',...
    'KeyPressFcn', {@seisKeyPress, [seis subax(4)]},...
    'UserData',seis)

RotatePhaseSelect(phaseMenu)
% if ~config.calcphase
%     set(phaseMenu,'Enable','off ')
% end

set(subax, 'Xlim', [thiseq.Amp.time(1) thiseq.Amp.time(end)])
s = findobj('Tag', 'Statusbar');
if strcmp('raw', config.resamplingfreq)
    set(s,'String', ['Status:  sampling frequency = ' num2str(1/thiseq.dt) 'Hz']);
else
    set(s,'String', ['Status:  sampling frequency = ' num2str(1/thiseq.dt) 'Hz (resampled)']);
end
drawnow;

%%***************************************
 button = findobj('Tag', 'SystemButton');
 thiseq.system = 'LTQ';
 set(button, 'State','On')
 %button = findobj('Tag','LockButton');
 %set(button, 'State','On')
%%***************************************

figure(seisfig);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                         S U B F U N C T I O N S                      %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buttonDown(src, evnt, split, ax, seis )
global thiseq

Pt1 = get(ax, 'CurrentPoint');
xxx = xlim;
if Pt1(1) < xxx(1) || Pt1(1) > xxx(2)
    return
else
    switch get(src, 'SelectionType')
        case 'alt' %right click
            split.x = [Pt1(:,1); Pt1(:,1)];
            set(src,...
                'pointer','left',...
                'WindowButtonMotionFcn', {@buttonMotion, split, ax, seis});
            set(src,...
                'WindowButtonUpFcn', {@buttonUp, split, ax, seis})
            
            if isfield(thiseq, 'Ppick') && ~isempty(thiseq.Ppick) && ~all(thiseq.Ppick==0)
                vp2vs = Pt1(1,1) / thiseq.Ppick(1);
                status = findobj('Tag','Statusbar');
                set(status,...
                    'String', sprintf(' S-Window: %11.3fsec -- %.3fsec;  vp/vs = %4.3f',split.x(1),split.x(3), vp2vs ));
                drawnow;
            end

        case 'extend' %Shift
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
            set(src,...
                'WindowButtonUpFcn', '',...
                'WindowButtonMotionFcn', '',...
                'Pointer', 'Custom',...
                'PointerShapeCData', pointer,...
                'PointerShapeHotSpot',[7 7])
            localZoomSeismo(seis);
        case 'normal' %left-click
            split.x = [Pt1(:,1); Pt1(:,1)];
            set(src,...
                'pointer', 'left',...
                'WindowButtonMotionFcn',{@buttonMotion, split, ax, seis});
            set(src, 'WindowButtonupFcn', {@buttonUp, split, ax, seis})
        case 'open' %double click
            %inputdlg
            return
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buttonMotion(src, evnt, split, ax, seis)

Pt2 = get(gca,'CurrentPoint');
Pt2 = Pt2(:,1);
split.x(3:4) = Pt2;
split.x      = sort(split.x);

if strcmp(get(src,'SelectionType'),'normal')
    set(split.Ptext,...
        'Position',[split.x(1),1,0],...
        'Visible','On')
    %set(split.hPfill,'Xdata',split.x,'Visible','on','eraseMode','normal');
    set(split.hPfill,...
        'Xdata',split.x,...
        'Visible','On');
    %    set(split.hPfill,'Xdata',split.x,'EraseMode','xor');
else
    %set(split.Stext,'position',[split.x(1),1,0],'Visible','on')
    %set(split.hfill,'Xdata',split.x,'Visible','on','eraseMode','normal');
    set(split.Stext,...
        'Position',[split.x(1),1,0],...
        'Visible','On')
    set(split.hfill,...
        'Xdata',split.x,...
        'Visible','On');
    
    %set(split.hfill,'Xdata',split.x,'EraseMode','xor');
end

set(src, 'WindowButtonupFcn', {@buttonUp, split, ax, seis})
status = findobj('Tag','Statusbar');
set(status, 'String', sprintf(' P-Window: %11.3fsec -- %.3fsec    (dt=%.3f)', split.x(1), split.x(3), split.x(3)-split.x(1)));
drawnow;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buttonUp(src, evnt, split, ax, seis)
global thiseq  eq

set(src,...
    'WindowButtonMotionFcn', '',...
    'Pointer', 'CrossHair');

if abs(diff(split.x(2:3))) < diff(xlim)*.005 % 0.5precent of total axes length
    status = findobj('Tag', 'Statusbar');
    set(status, 'String', 'Time window less than 0.5% of window length! Aborting');
    drawnow;
    
    if strcmp(get(src, 'SelectionType'), 'normal')
        if isfield(thiseq, 'Ppick')
            set(split.hPfill, 'Xdata', [thiseq.Ppick(1); thiseq.Ppick(1); thiseq.Ppick(2); thiseq.Ppick(2)])
            set(split.Ptext, 'Visible', 'Off')
            %            set(split.Ptext,'Position', [thiseq.Ppick(1) 1 0])
            %             pause(.5)
        end
    else
        if isfield(thiseq, 'Spick')
            set(split.hfill, 'Xdata', [thiseq.Spick(1); thiseq.Spick(1); thiseq.Spick(2); thiseq.Spick(2)])
            set(split.Stext, 'Position', [thiseq.Spick(1) 1 0])
            %             pause(.5)
            set(split.Stext, 'Visible', 'Off')
        end
    end
    
else
    xxx = xlim;

    if split.x(1) < xxx(1) || split.x(4) > xxx(2)
        return
    else
        if ishandle(split.hfill)
            n = thiseq.resultnumber;
            if strcmp(get(src,'SelectionType'), 'normal')
                %set(split.hPfill,'Xdata',split.x,'eraseMode','normal');
                set(split.hPfill, 'Xdata', split.x);
                thiseq.Ppick = [split.x(2) split.x(3)];
                eq(thiseq.index).Ppick = thiseq.Ppick;
                status = findobj('Tag', 'Statusbar');                
                set(status, 'String', sprintf(' P-Window: %11.3fsec -- %.3fsec    (dt=%.3f)', split.x(1), split.x(3), split.x(3)-split.x(1)));
                drawnow;
            else
                %set(split.hfill,'Xdata',split.x,'eraseMode','normal');
                set(split.hfill, 'Xdata', split.x);
                thiseq.Spick(1) = split.x(2); %start of window
                thiseq.Spick(2) = split.x(3); %end of window
                status = findobj('Tag', 'Statusbar');
                set(status, 'String', sprintf(' S-Window: %11.3fsec -- %.3fsec   [Press ENTER to start splitting measurement]', split.x(1), split.x(3)));
                drawnow;
            end
        end
    end
    uistack([split.hfill; split.hPfill], 'bottom');
end

pb = findobj('Tag', 'ParticleButton');
if strcmp(get(pb,'State'), 'On')
    if strcmp(get(src,'SelectionType'), 'normal')
        tit='P-Window';
    else
        tit='S-window';
    end
    SL_showparticlemotion(gcbf, seis, split.x(2:3), tit)
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localZoomSeismo(seis)
global thiseq

point1 = get(gca,'CurrentPoint');    % button down detected
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1);                  % extract x and y
point2 = point2(1);

p1 = min(point1,point2);             % calculate locations
offset = abs(point1-point2);         % and dimensions
x = [p1(1) p1(1)+offset(1) ];

set(gcbf, 'Pointer', 'CrossHair')

if (x(2)-x(1))/thiseq.dt < 40
    %prevent exessive zooming smaller than 40 samples
    sb = findobj('Tag', 'Statusbar');
    set(sb, 'String', 'Maximum zoom level reached! Do you really want to look at less than 40 samples????')
    return
end

subax=findobj('Type', 'Axes', 'Parent', gcbf);
set(subax(4), 'xlim', (x(1:2)))


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figScroll(src, evnt, seis)
global thiseq

if evnt.VerticalScrollCount < 0
    xx = xlim;
    point = getCurrentPoint(seis(4));
    if isempty(point)
        limit = (xx + [diff(xx) -diff(xx)] /5);
    else
        xp = point(1);
        limit = xx + [xp-xx(1) (xp-xx(2))] /5;
    end
    lim = diff(limit)/thiseq.dt;
    if 100 <= lim;
        sa = findobj('Tag', 'seismo');
        set(sa, 'LineStyle', '-',...
            'Marker','none')
    elseif 10 <= lim && lim < 100
        sa = findobj('Tag', 'seismo');
        set(sa,'LineStyle','-',...
            'Marker','.')
    elseif lim < 10
        sa=findobj('Tag', 'Statusbar');
        set(sa, 'String', 'Sorry, reached maximum Zoom level...')
        set(gcbf, 'Pointer', 'crosshair')
        return
    end
    xlim(limit) %zoom in by 20%
    
elseif evnt.VerticalScrollCount > 0
    xx = xlim;
    point = getCurrentPoint(seis(4));

    if isempty(point)
        limit = (xx - [diff(xx) -diff(xx)] /5);
    else
        xp = point(1);
        limit = xx - [xp-xx(1) (xp-xx(2))] /5;
    end
    lim = diff(limit)/thiseq.dt;

    if 100 <= lim;
        sa=findobj('Tag','seismo');
        set(sa,'LineStyle','-','Marker','none')
    else
        sa=findobj('Tag','seismo');
        set(sa,'LineStyle','-','Marker','.')
    end
    xlim(limit) %zoom out by 20%
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localCalculateGeometry
global config thiseq

% caluclate in straight line geometric parameters
if strcmp(config.studytype,'Reservoir')
    % all in meters
    z = (  thiseq.depth + config.selev); % elevation is positiv upwards, eventdepth positive downwards% this assumes an backazimuth from station to event, positive clockwise
    % from North and Inclination positive from vertical down (==0deg)
    dy       = thiseq.lat  - config.slat;
    dx       = thiseq.long - config.slong;
    hdis     = sqrt(dx.^2 + dy.^2);%in horizontal distance
    geobazi  = atan2(dx,dy)  * 180/pi;
    geoazi   = geobazi+180;
    geodis3D = sqrt(hdis.^2  + z.^2);%in 3D
    geoinc   = atan(hdis./z) * 180/pi;
else
    % elevation in meters, depth in kilometers:
    z =  (  thiseq.depth + config.selev/1000); % elevation is positiv upwards, eventdepth positive downwards
    % calculate spherical distance and angles (teleseismic)
    [dis, range, geoazi, geobazi] = sphere_dist(thiseq.lat, thiseq.long, config.slat, config.slong);
    geodis3D  = sqrt(range.^2 + z.^2); %in 3D
    geoinc    = atan(range./z) * 180/pi;
end

if strcmp(config.studytype,'Reservoir')
    thiseq.dis  = geodis3D;
elseif strcmp(config.studytype,'Regional')
    thiseq.dis  = range;
else
    thiseq.dis  = dis;
end

thiseq.geobazi       = mod(geobazi, 360);
thiseq.geoinc        = mod(geoinc, 180);
thiseq.geodis3D      = geodis3D;

if thiseq.bazi == -12345
    thiseq.bazi = thiseq.geobazi;
end
if thiseq.dis  == -12345
    thiseq.dis  = range;
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
