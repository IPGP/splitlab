function SL_showparticlemotion(fig,seis, window, tit)
% show the particle motion in selected time window

global thiseq config



h = findobj('Type','Figure', 'Name','Particle motion');
if isempty(h)
    h    = figure('Name','Particle motion','Position',[ 10 100 700 200],'NumberTitle','off','MenuBar','none','color','w');
else
    clf(h)
end

figure(h)
m4 = uimenu(h,'Label',   'Figure');
uimenu(m4,'Label',  'Save current figure',  'Callback','exportfiguredlg(gcbf,  [config.stnname ''_EQstats'' config.exportformat], config.savedir,config.savedir,config.exportresolution)');
uimenu(m4,'Label',  'Page setup',           'Callback','pagesetupdlg(gcbf)');
uimenu(m4,'Label',  'Print preview',        'Callback','printpreview(gcbf)');
uimenu(m4,'Label',  'Print current figure', 'Callback','printdlg(gcbf)');


ax(1) = axes('units','Normalized', 'Position',[.05 .11 .3 .75], 'Box', 'On',  'XLim', [-1 1], 'yLim', [-1 1], 'Xtick',[-1 0 1], 'Ytick',[-1 0 1]);
ax(2) = axes('units','Normalized', 'Position',[.35  .11 .3 .75], 'Box', 'On',  'XLim', [-1 1], 'yLim', [-1 1], 'Xtick',[-1 0 1], 'Ytick',[-1 0 1]);
ax(3) = axes('units','Normalized', 'Position',[.65  .11 .3 .75], 'Box', 'On',  'XLim', [-1 1], 'yLim', [-1 1], 'Xtick',[-1 0 1], 'Ytick',[-1 0 1]);



if all(isnan(window));
    if isfield(thiseq,'Spick') && all(thiseq.Spick~=0)
        window = thiseq.Spick;
        tit = 'S-Window';
    elseif isfield(thiseq,'Ppick') && all(thiseq.Ppick~=0)
        window = thiseq.Ppick;
        tit = 'P-Window';
    else

set(ax, 'XLim', [-1 1], 'yLim', [-1 1], 'Xtick',[], 'Ytick',[],'DataAspectRatio',[1 1 1])
        alabel=(get( get( get(seis(1),'Parent'),'Ylabel'), 'String'));
        blabel=(get( get( get(seis(2),'Parent'),'Ylabel'), 'String'));
        clabel=(get( get( get(seis(3),'Parent'),'Ylabel'), 'String'));
        xlabel(ax(1),alabel); ylabel(ax(1),blabel);
        xlabel(ax(2),alabel); ylabel(ax(2),clabel);
        xlabel(ax(3),blabel); ylabel(ax(3),clabel);
        return; %initialistiation
    end
end

if tit(1)=='S'
        colormap(copper);
elseif (tit(1)=='P')
    colormap(cool)
end

o         = thiseq.Amp.time(1);
ia = floor((window(1)-o)/thiseq.dt);
ib =  ceil((window(2)-o)/thiseq.dt);

if strcmp(thiseq.system,'ENV')
    x = get(seis(1),'Ydata');  x = x(ia:ib);
    y = get(seis(2),'Ydata');  y = y(ia:ib);
    z = get(seis(3),'Ydata');  z = z(ia:ib);
    
    alabel=(get( get( get(seis(1),'Parent'),'Ylabel'), 'String'));
    blabel=(get( get( get(seis(2),'Parent'),'Ylabel'), 'String'));
    clabel=(get( get( get(seis(3),'Parent'),'Ylabel'), 'String'));

    X = sin(thiseq.bazi/180*pi);
    Y = cos(thiseq.bazi/180*pi);  
%     Z = sin(atan(thiseq.dis/(-config.selev-thiseq.depth))); 
    Z = sin(atan(thiseq.selectedinc/180*pi)); 
else
    x = get(seis(1),'Ydata');  x = x(ia:ib);
    y = get(seis(2),'Ydata');  y = y(ia:ib);
    z = get(seis(3),'Ydata');  z = z(ia:ib);
    
    alabel=(get( get( get(seis(1),'Parent'),'Ylabel'), 'String'));
    blabel=(get( get( get(seis(2),'Parent'),'Ylabel'), 'String'));
    clabel=(get( get( get(seis(3),'Parent'),'Ylabel'), 'String'));
    X = 0;
    Y = 1;
    Z = 0;
end

%% backazimuth:

plot(ax(1), [-X X], [-Y Y], 'k:' )
hold(ax(1), 'on')
text( -X,-Y,'bazi','Parent',ax(1), 'FontSize', get(gca,'FontSize')-1,'Rotation',90-mod(thiseq.bazi,180),'VerticalAlignment','Bottom','HorizontalAlignment','Left')


m = max(abs([x, y, z]));
xx = x'/m;
yy = y'/m;
zz = z'/m;

patch('Parent',ax(1), 'Faces',1:length(y)+1, 'Vertices',[xx yy;nan nan],'FacevertexCdata' ,(1:length(y)+1)','facecolor','none','edgecolor','interp')
patch('Parent',ax(2), 'Faces',1:length(y)+1, 'Vertices',[xx zz;nan nan],'FacevertexCdata' ,(1:length(y)+1)','facecolor','none','edgecolor','interp')
patch('Parent',ax(3), 'Faces',1:length(y)+1, 'Vertices',[yy zz;nan nan],'FacevertexCdata' ,(1:length(y)+1)','facecolor','none','edgecolor','interp')
xlabel(ax(1),alabel); ylabel(ax(1),blabel); 
xlabel(ax(2),alabel); ylabel(ax(2),clabel); 
xlabel(ax(3),blabel); ylabel(ax(3),clabel); 
hold(ax(1),'off')


% if strcmp(thiseq.system,'ENV')
%     xlabel(get( get( get(seis(1),'Parent'),'Ylabel'), 'String'))
%     ylabel(get( get( get(seis(2),'Parent'),'Ylabel'), 'String'))
% else
%     xlabel(get( get( get(seis(2),'Parent'),'Ylabel'), 'String'))
%     ylabel(get( get( get(seis(1),'Parent'),'Ylabel'), 'String'))
% end
title(ax(2),tit);
set(ax, 'XLim', [-1 1], 'yLim', [-1 1], 'Xtick',[], 'Ytick',[],'DataAspectRatio',[1 1 1])

figure(fig)



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