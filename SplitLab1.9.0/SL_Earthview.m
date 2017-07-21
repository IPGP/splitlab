function SL_Earthview(lat, long, mag, depth, datum)
% display worldmap with eathquake location of the current splitlab project
% SL_Earthview(lat, long, mag, depth, month)
% the inputs lat and long mark selected eathquake(s). mag and depth are
% displayed as the window title. The numeric input value month (1-12) corresponds
% to seasonal MODIS worldmap provided by the NASA "Blue Marble Project" is
% displayed. This is an integral view of the visible spectrum of satelite
% images. choose month=0 for a seasonal-free representation

global config eq
fig=gcf;


isMapToolbox = license('checkout', 'MAP_Toolbox');
month  = datum(:,2);
inputs = {lat, long, mag, depth, datum};
earth  = findobj('type','figure', 'tag','EarthView','NumberTitle','off');
ImageFnames={sprintf('world.topo.bathy.2004%02.0f.jpg',month(1));
    'world.natural.jpg';
    'world.Topography.jpg';
    'world.gebco_bathy.jpg';
    'world.lights.jpg';
    'world.Mars.Surface.jpg';
    'world.Moon.Albedo.jpg'};


%% EARTH FIGURE
if isempty(earth)
    
    if ispref('Splitlab','EV_figpos')
        figpos = getpref('Splitlab','EV_figpos');
    else
        figpos = get(0,'ScreenSize');
        width  = 360*1.5; height=180*1.5;
        xpos   = figpos(1) + figpos(3) - width*1.05;
        ypos   = 70 ;
        EV_figpos = [xpos ypos width height];
    end
    
    if length(depth)>1
        depthstr='*';
        magstr ='*';
    else
        depthstr=sprintf('%4.1fkm',depth);
        magstr = sprintf('%3.1f',mag);
    end
    earth = figure( 'Tag','EarthView',...
                    'NumberTitle','off',...
                    'CloseRequestFcn',@my_closereq,...
                    'name',sprintf('Earth Viewer:  Mw: %s   Depth: %s', magstr, depthstr),...
                    'MenuBar','None',...
                    'Position', figpos);
    
    
    if strcmpi(config.studytype,'Teleseismic')
        m1 = uimenu(earth,'Label', 'Style');
        q(1) = uimenu(m1,'Label',  'Monthly Modis', 'Callback',@q_callback, 'Checked','On' );   %standard
        q(2) = uimenu(m1,'Label',  'Natural Earth', 'Callback',@q_callback, 'Checked','Off');
        q(3) = uimenu(m1,'Label',  'Topography',    'Callback',@q_callback, 'Checked','Off');
        q(4) = uimenu(m1,'Label',  'Bathymetry',    'Callback',@q_callback, 'Checked','Off');
        q(5) = uimenu(m1,'Label',  'City Night',    'Callback',@q_callback, 'Checked','Off');
        q(6) = uimenu(m1,'Label',  'Mars Surface',  'Callback',@q_callback, 'Checked','Off');
        q(7) = uimenu(m1,'Label',  'Moon Albedo',   'Callback',@q_callback, 'Checked','Off');
        set(q(config.mapstyle),'Checked','on');         % set mapstyle according to default
        set(q(q~=q(config.mapstyle)),'Checked','off');
        set(q,'Userdata',{q; inputs})

        m2 = uimenu(earth,'Label',  'Night');
        qq(1) = uimenu(m2,'Label',  'City Nights', 'Checked','Off','Callback',@q_callback);
        qq(2) = uimenu(m2,'Label',  'shaded', 'Checked','On','Callback',@q_callback);
        qq(3) = uimenu(m2,'Label',  'none', 'Checked','Off','Callback', @q_callback);
        set(qq(config.nightstyle),'Checked','on');      % set nightstyle according to default
        set(qq(qq~=qq(config.nightstyle)),'Checked','off');        
        set(qq,'Userdata',{qq; inputs})

        m3 = uimenu(earth, 'Label', 'Options');
        qqq(1) = uimenu(m3,'Label', 'Show CMB pierce points of SKS',  'Checked','Off','Callback',@cmbCallback);
        qqq(2) = uimenu(m3,'Label', 'Show CMB pierce points of SKKS', 'Checked','Off','Callback',@cmbCallback);
        qqq(3) = uimenu(m3,'Label', 'Show Great Circle Path',         'Checked','Off','Callback',@gcarcCallback);
        
        if config.showPiercePoints(1)                   % set options according to default
            set(qqq(1),'Checked','On')
        else
            set(qqq(1),'Checked','Off')
        end
        if config.showPiercePoints(2)
            set(qqq(2),'Checked','On')
        else
            set(qqq(2),'Checked','Off')
        end
        if config.showGCarc
            set(qqq(3),'Checked','On')
        else
            set(qqq(3),'Checked','Off')
        end
        set(qqq,'Userdata',{qqq; inputs})     
    end

    if ~strcmp(config.studytype,'Teleseismic')
        ax=axes;
        plot3([eq(:).long], [eq(:).lat],[eq(:).depth],'Marker','.','LineStyle','None','Color',[1 .5 0]);%[1 1 1]*0.5
        hold on
        if strcmp(config.studytype,'Reservoir')
            xs =  config.slong;
            ys =  config.slat;
            zs = -config.selev;
        else
            xs =  config.slong ;
            ys =  config.slat  ;
            zs = -config.selev / 1000;
        end
        
        plot3(xs, ys,   zs,  'kv','Markersize',8,'MarkerFaceColor','r');
        text(xs,  ys-2, zs,  config.stnname,'VerticalAlignment', 'bottom',...
            'HorizontalAlignment','center' ,'Color', 'k', 'FontName','FixedWidth','Fontweight','demi','Interpreter','none')
        set(gca,'zDir','reverse')
    else
        ax=axes('Units', 'normalized','Position',[.0 .0 1 1],'Ydir','reverse');
        LATS   = linspace( -90,  90, 1200 );
        LONS   = linspace(-180, 180, 2400 );
        image(LONS,LATS, ones(1200,2400,3),'Tag','ModisMap')
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % NOW ADD COAST LINE AND EARTHQUAKE LOCATIONS
        hold on
        if   ~any(strcmp(get(q(6:7),'Checked'),'on'))
            if isMapToolbox
                try
                    coast = load('coast.mat');
                    plot(coast.long, -coast.lat,'-','Color',[1 1 1]*.1,'Tag','Terrestrial')
                end
            end
            %plate boundaries
            PB    = load('plates.mat');
            plot(PB.PBlong,  -PB.PBlat ,'-','Color',[0.6 .12 .12],'Tag','Terrestrial')
        end
        
        plot(config.slong, -config.slat,'kv','Markersize',8,'MarkerFaceColor','r');
        text(config.slong, -config.slat-2, config.stnname,'VerticalAlignment', 'bottom',...
            'HorizontalAlignment','center' ,'Color', 'y', 'FontName','FixedWidth','Fontweight','demi','Interpreter','none')
    end
    
    
else
    figure(earth)
    set(earth,'name',['Earth Viewer:  Magnitude: ' num2str(mag,'%.1f') '    Depth: ' num2str(depth) 'km'])
    delete(findobj('Tag','EQMarkerEarth'))
    delete(findobj('Tag','SplittedMarker'))
    delete(findobj('Tag','Sun'))
    
    if strcmp(config.studytype,'Teleseismic')
        zoom(earth,'out')

        men=findobj('parent',earth,'type','uimenu');
        q   = get(men(3),'children');   %maps
        qq  = get(men(2),'children');   %nights
        qqq = get(men(1),'children');   %options
        
        if config.showPiercePoints(1)   %set to make correct checks
            set(qqq(3),'Checked','On')
        else
            set(qqq(3),'Checked','Off')
        end
        if config.showPiercePoints(2)
            set(qqq(2),'Checked','On')
        else
            set(qqq(2),'Checked','Off')
        end
        if config.showGCarc
            set(qqq(1),'Checked','On')
        else
            set(qqq(1),'Checked','Off')
        end     
        set(q , 'Userdata',{q ; inputs});
        set(qq, 'Userdata',{qq; inputs});
        set(qqq,'Userdata',{qqq; inputs});
    end
end


%% set config.mapstyle & config.nightsyle according to latest button clicked
menu = findobj(earth,'type','uimenu');
menu_night = menu(7:9);

for k = 1:length( menu_night )
    if strcmpi( menu_night(k).Checked, 'On' )
        config.nightstyle = length( menu_night )-k+1;
    end
end

menu_map = menu(10:end);
for k = 1:length( menu_map )
    if strcmpi( menu_map(k).Checked, 'On' )
        config.mapstyle = length( menu_map )-k+1;
    end
end


%% Update plot with Mapstyle, Nightsytle, Station symbol/name and Sun Zenit Position
ax = findobj('Parent',earth, 'Type','Axes');
if strcmp(config.studytype,'Teleseismic')
    mapstyle(1) = findobj('type',' uimenu','Label', 'Monthly Modis');
    mapstyle(2) = findobj('type',' uimenu','Label', 'Natural Earth');
    mapstyle(3) = findobj('type',' uimenu','Label', 'Topography');
    mapstyle(4) = findobj('type',' uimenu','Label', 'Bathymetry');
    mapstyle(5) = findobj('type',' uimenu','Label', 'City Night');
    mapstyle(6) = findobj('type',' uimenu','Label', 'Mars Surface');
    mapstyle(7) = findobj('type',' uimenu','Label', 'Moon Albedo');
    
    
    if strcmp(get(mapstyle(1),'Checked'),'on');
        imName = ImageFnames{1};
    elseif strcmp(get(mapstyle(2),'Checked'),'on');
        imName = ImageFnames{2};
    elseif strcmp(get(mapstyle(3),'Checked'),'on');
        imName = ImageFnames{3};
    elseif strcmp(get(mapstyle(4),'Checked'),'on');
        imName = ImageFnames{4};
    elseif strcmp(get(mapstyle(5),'Checked'),'on');
        imName = ImageFnames{5};
    elseif strcmp(get(mapstyle(6),'Checked'),'on');
        imName = ImageFnames{6};
        mission = {...
            'Mars 3'; '(1971)'
            'Viking 1'; ' (1975) '
            'Viking 2'; ' (1975) '
            'Pathfinder'; '  (1996)  '
            'Spirit'; '(2003)'
            'Opportunity';'  (2003)   ' };
        locs = [-45. -158.
            22.46 -47.95
            47.93 133.75
            19.26 -33.25
            -14.57 175.47
            -1.95 -5.53];
        hold on
        plot(locs(:,2), -locs(:,1) ,'w^','tag','landings')
        text(locs(:,2), -locs(:,1)+2, {mission{1:2:end}}, 'VerticalAlignment','Top', 'HorizontalAlignment','Center','color','w','Fontsize',7,'tag','landings')
        hold off
    elseif strcmp(get(mapstyle(7),'Checked'),'on');
        imName = ImageFnames{7};
        mission = {'Apollo 11'; 'Apollo 12'; 'Apollo 14'; 'Apollo 15'; 'Apollo 16'; 'Apollo 17' };
        locs = [0.67 23.47
            -3.01 -23.42
            -3.65 -17.47
            26.13 3.63
            -8.97 15.50
            20.19 30.77];
        hold on
        plot(locs(:,2), -locs(:,1) ,'k^','tag','landings')
        text(locs(:,2), -locs(:,1)+2, mission, 'VerticalAlignment','Top', 'HorizontalAlignment','Center','color','k','Fontsize',7,'tag','landings')
        hold off
        
    end
    ThisIm = imread(imName);
    
    LATS   = linspace( -90,  90, size(ThisIm,1) );
    LONS   = linspace(-180, 180, size(ThisIm,2) );
    
    shownight(1) = findobj('type',' uimenu','Label',  'City Nights');
    shownight(2) = findobj('type',' uimenu','Label',  'shaded');
    shownight(3) = findobj('type',' uimenu','Label',  'none');
    
    if ~strcmp(get(shownight(3),'Checked'),'on') ...
            && ~any(strcmp(get(mapstyle(5:7),'Checked'),'on'))...
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get sun Position and calculate day-night line
        dn = datenum(datum(1,1:6));
        dv = datevec(dn);
        dv(1,2:end) = 0;
        doy = dn - datenum(dv);%DayOfYear
        diy = datenum(dv+[1 0 0 0 0 0]) - datenum(dv);%daysInYear
        
        %zenith of the sun
        sunlat = 23.45*cosd(360/diy*(doy+10)); % http://en.wikipedia.org/wiki/Declination
        sunlon = (0.5-rem(dn,1))*360;           % simply hourwise going along the longitude
        
        % calculate Day-Night-line for current event
        [latc,lonc]  = gcpts(sunlat,sunlon, 0:3:360, 90);
        ff= find(abs(diff(lonc))>180);
        if ~isempty(ff)
            s=sign(lonc(ff));
            lonc = [lonc(1:ff); 180*s;    -180*s;    lonc(ff+1:end)];
            latc = [latc(1:ff); latc(ff); latc(ff);  latc(ff+1:end)];
        end
        %now get index of pixel in image corresponding to the line
        [lonc,i]=unique(lonc);
        latc=interp1(lonc,latc(i),LONS);
        
        %         YY = floor((latc+90)/180*size(ThisIm,1)-1)+1;
        XX = 1:size(ThisIm,2);
        
        
        logi = logical(zeros(size(ThisIm)));
        for k = 1:length(XX);
            m = LATS>latc(k);
            logi(m,k,:) = 1;
        end 
        
        %check whether sun is above or below line
        i=floor((sunlon+180)/360*size(ThisIm,2)-1)+1;
        i=max(i,1);
        if sunlat>latc(i)
            logi = ~logi;
        end
        
        if strcmp(get(shownight(2),'Checked'),'on');
            ThisIm(logi) = ThisIm(logi)*.6;
            hold on
            plot(sunlon, sunlat,'yh','MarkerSize',6,'MarkerFaceColor','y', 'Tag','Sun');
            plot(sunlon, sunlat,'yo','MarkerSize',8, 'Tag','Sun');
            %             plot(moonlon, moonlat,'wo','MarkerSize',10,'MarkerFaceColor','w', 'Tag','Sun');
            hold off
        elseif strcmp(get(shownight(1),'Checked'),'on');
            Night  = imread(ImageFnames{5});
            ThisIm(logi) = (Night(logi));
            hold on
            plot(sunlon, sunlat,'yh','MarkerSize',6,'MarkerFaceColor','y', 'Tag','Sun');
            plot(sunlon, sunlat,'yo','MarkerSize',8, 'Tag','Sun');
            %             plot(moonlon, moonlat,'wo','MarkerSize',10,'MarkerFaceColor','w', 'Tag','Sun');
            hold off
        end
        
    else
        set(shownight(3),        'Checked' ,'on')
        set(shownight(1:2),        'Checked' ,'off')
    end
    
    obj = findobj('type','uimenu','Label',   'Night');
    if any(strcmp(get(mapstyle(6:7),'Checked'),'on'))
        set(obj,'Visible','off')
    else
        set(obj,'Visible','on')
    end
    
    %plot the new image
    set(findobj('parent',ax,'Type','Image','Tag','ModisMap'), 'Cdata',ThisIm)
    
    %PlateBoundary and coast line
    obj = findobj('type','line','Tag','Terrestrial');
    if any(strcmp(get(mapstyle(6:7),'Checked'),'on'))
        set(obj,'Visible','off')
    else
        set(obj,'Visible','on')
    end
    
end


%% plot GCarc of EQ, SKS and SKKS piercingpoints (if wished and phase exists)
%  earthquakes already splitted, plot in green 
ind=[];
for i=1:length(eq)
    if ~isempty(eq(i).results)
        ind=[ind i];
    end
end

hold on
if ~strcmp(config.studytype,'Teleseismic')
    if strcmp(config.studytype,'Reservoir')
        xs =  config.slong;
        ys =  config.slat;
        zs = -config.selev;
    else
        xs =  config.slong ;
        ys =  config.slat  ;
        zs = -config.selev / 1000;
    end
    x = [ xs * ones(size(long));    long  ];
    y = [ ys * ones(size(long));    lat   ];
    z = [ zs * ones(size(long));    depth ];

    plot3(x, y, z,                                    'LineStyle' ,'-','Color','m','Tag','SplittedMarker','Parent',ax,'LineWidth',1)
    plot3([eq(ind).long], [eq(ind).lat], [eq(ind).depth],'Marker' ,'.','Color','g','LineStyle','None','Tag','SplittedMarker','Parent',ax);
    plot3(long, lat, depth, 'rp','MarkerFaceColor','y','Tag','EQMarkerEarth','Markersize',14,'Parent',ax);    %  Hypocenter
else
    %plot([eq(:).long], -[eq(:).lat],'Marker','.','LineStyle','None','Color',[1 .5 0]);%[1 1 1]*0.5
    %plot([eq(ind).long], -[eq(ind).lat],'Marker','.','Color','g','LineStyle','None','Tag','SplittedMarker','Parent',ax);
    plot(long, -lat, 'rp','MarkerFaceColor','y','Tag','EQMarkerEarth','Markersize',14,'Parent',ax);    %  Hypocenter

    for k =1:length(lat)
        
        % color for Symbols and GRarc, green if there is measurements, else
        % red
        results_EQ = eq(config.db_index).results;
        if isempty(results_EQ)
            color = 'r';        %red
        else
            color = 'g';        %green
        end
        
        if any(config.showPiercePoints==1)   
            if all(config.showPiercePoints==[1 1])
                phasestr='SKS,SKKS';
            elseif all(config.showPiercePoints==[1 0])
                phasestr='SKS';
            elseif all(config.showPiercePoints==[0 1])
                phasestr='SKKS';
            end
            %pierce Points at Core-Mantle Boundary
            cmbdepth=2891;
            tt_pierce = taupPierce(...
                config.earthmodel,...
                depth(k),phasestr,...
                'sta',[config.slat config.slong],...
                'evt', [lat(k)  long(k)],...
                'pierce',cmbdepth,...
                'nodiscon');
            skksCount=0;
            for kk=1:length(tt_pierce)
                ff= find(tt_pierce(kk).pierce.depth==cmbdepth);
                cmblat=tt_pierce(kk).pierce.latitude(ff);
                cmblon=tt_pierce(kk).pierce.longitude(ff);
                switch tt_pierce(kk).phaseName
                    case 'SKS'
                        mf_color = 'w';
                        mark='o';
                    case 'SKKS'
                        mf_color = 'w';
                        mark='d';
                        skksCount=skksCount+1;
                        if skksCount>1
                            continue%only use one SKKS phase
                        end
                    otherwise
                        mf_color = 'c';
                end
                plot(cmblon,-cmblat, [mark color],  'MarkerFaceColor',mf_color, 'Tag','SplittedMarker')
            end
            
        end
        
        if config.showGCarc
            %GreatCricle Arc
            [gclat,gclon] = gcarc(config.slat,config.slong, lat(k),long(k), 25);
            ff= find(abs(diff(gclon))>180);
            if ~isempty(ff)
                s=sign(gclon(ff));
                gclon = [gclon(1:ff); 180*s;       nan; -180*s;      gclon(ff+1:end)];
                gclat = [gclat(1:ff); gclat(ff); nan; gclat(ff); gclat(ff+1:end)];
            end
            plot(gclon,  -gclat ,'-','Color',color,'Tag','SplittedMarker','Parent',ax,'LineWidth',2)
        end
        
    end
end
hold off


%% set final zooms and labels
if strcmp(config.studytype,'Reservoir')
    rotate3d(earth, 'on')
    daspect(ax, [1 1 1])
    xlabel('Easting')
    ylabel('Northing')
    zlabel('Depth')
    grid on
    set(ax, 'Zdir','reverse')
elseif strcmp(config.studytype,'Teleseismic')
    axis off
    zoom(earth,'reset')
    zoom(earth,'on')
else
    rotate3d(earth, 'on')
    set(ax, 'Zdir','reverse')
    xlabel('East [\circ]')
    ylabel('North [\circ]')
    zlabel('Depth [km]')
    grid on
    daspect(ax, [1   1  111.1195])
end


%% save & give focus to previous figure (databaseViewer)
filename = fullfile(config.projectdir,config.project); %to save preferences
save(filename,'eq','config');

figure(fig)


%% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function q_callback(src,evt)
ud   = get(src,'Userdata');
tmp1 = ud{1};
in   = ud{2};

set(tmp1(tmp1~=src),'Checked','off');
set(src,'Checked','on')

delete(findobj('Tag','landings'))
SL_Earthview(in{1},in{2},in{3},in{4},in{5})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cmbCallback(src,evt)
global config
ud    = get(src,'Userdata');
lab=get(src,'Label');
tmp1  = ud{1};
set(tmp1(tmp1~=src),'Checked','off');
set(src,'Checked','on')
in =ud{2};
delete(findobj('Tag','landings'))

if strcmp(lab(end-3:end), 'SKKS')
    i=2;
else
    i=1;
end
config.showPiercePoints(i) = mod(config.showPiercePoints(i)+1, 2);
if config.showPiercePoints(i)
    config.showPiercePoints(i) = 1;
    set(src,'Checked','On');
else
    config.showPiercePoints(i) = 0;
    set(src,'Checked','Off');
end
SL_Earthview(in{1},in{2},in{3},in{4},in{5})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gcarcCallback(src,evt)
global config
ud = get(src,'Userdata');
in = ud{2};

config.showGCarc = mod(config.showGCarc+1, 2);
if config.showGCarc
    config.showGCarc = 1;
    set(src,'Checked','On');
else
    config.showGCarc = 0;
    set(src,'Checked','Off');
end
SL_Earthview(in{1},in{2},in{3},in{4},in{5})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function my_closereq(src,evt)
global config
    earth     = findobj('type','figure', 'Tag','EarthView');
    EV_figpos = get(earth,'Position');
    setpref( 'Splitlab','EV_figpos',EV_figpos );
    delete(earth); 
% if both lines uncommented, when EarthViewer is closed global option is
% changed and dabaseViewer executed to display checkbox correctly
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