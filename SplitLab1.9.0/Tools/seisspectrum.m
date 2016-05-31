function  seisspectrum(src,evt,seis)
% Show spectrogram of radial component within time window

% modified G. Barruol, sept 2014, to search tremors and to determine their
% time picks manually

global thiseq config

%% ------------------------------- directory and name definition ----------
% define the place to save the file containing the tremor detections

stnm='PORMA'   ;                % station name
direc='/Users/guilhem/Documents/Antarctica/sismo_data/noise/Tremor_detections/PORMA_tremor_detections'; % define the  directory
%radic='tremor_detections3.txt';     % define de radical of the output files
radic='test.txt';     % define de radical of the output files

%----------------creates output files and writes the headers -------------
cd(direc);                      % directory with station
tremor_detect = fopen([stnm,'_',radic],'a+');                               % File with the detections within the working directory

%% -------------------------------

if ~isfield(thiseq, 'Ppick') || all(thiseq.Ppick==0)
    errordlg('Please select a P-window first...')
    return
end
o  = thiseq.Amp.time(1);
ia = floor((thiseq.Ppick(1)-o)/thiseq.dt);
ib = ceil((thiseq.Ppick(2)-o)/thiseq.dt);


% seisax=findobj('Tag','seisaxes','Type','Axes');
% seis = get(seisax,'children');
% seis = cell2mat(seis(1:3));


if strcmp(thiseq.system,'ENV')
    x = get(seis(1),'Ydata');  x = x(ia:ib);
    y = get(seis(2),'Ydata');  y = y(ia:ib);
    z = get(seis(3),'Ydata');  z = z(ia:ib);

    alabel=(get( get( get(seis(1),'Parent'),'Ylabel'), 'String'));
    blabel=(get( get( get(seis(2),'Parent'),'Ylabel'), 'String'));
    clabel=(get( get( get(seis(3),'Parent'),'Ylabel'), 'String'));
else
    x = get(seis(1),'Ydata');  x = x(ia:ib);
    y = get(seis(2),'Ydata');  y = y(ia:ib);
    z = get(seis(3),'Ydata');  z = z(ia:ib);

    alabel=(get( get( get(seis(1),'Parent'),'Ylabel'), 'String'));
    blabel=(get( get( get(seis(2),'Parent'),'Ylabel'), 'String'));
    clabel=(get( get( get(seis(3),'Parent'),'Ylabel'), 'String'));
end

%% creation figure
fig = findobj('name', 'Spectrum Viewer','type','figure');
if isempty(fig)
    fig=figure('name', 'Spectrum Viewer',...
        'NumberTitle',     'off',...
        'Units','normalized',...
        'Position',[.15 .15 .66 .7]);
else
    figure(fig)
    clf
end

%%
frequenz  = round(1 /thiseq.dt);

nfft   = 2^(nextpow2(frequenz)+0);
window   = hann(nfft); % 

noverlap = round(length(window)/4);
%noverlap = round(length(window)/2); % mod GB, march 2014
%noverlap = round(length(window)/8); % mod GB, march 2014
Fs=(logspace(0, 1, nfft)-1)/9 * frequenz/2;

try
    ax(1)= subplot (3,1,1);
    pos=get(ax(1),'Position');
    set(ax(1),'Position',pos.*[.7 1 .8 1])

    [S,F,T,P] = spectrogram(x, window, noverlap, Fs, frequenz);
    p=pcolor(T,F, 10*log10(abs(P)));set(p ,'edgecolor','none','Zdata',zeros(size(P)))
    clim = caxis;shading flat

    ax(2) = subplot (3,1,2);
    pos=get(ax(2),'Position');
    set(ax(2),'Position',pos.*[.7 1 .8 1])

    [S,F,T,P] = spectrogram(y,  window, noverlap, Fs, frequenz);
    p=pcolor(T,F, 10*log10(abs(P)));set(p ,'edgecolor','none','Zdata',zeros(size(P)))
    clim(3:4) = caxis;shading flat

    ax(3) = subplot (3,1,3);
    pos=get(ax(3),'Position');
    set(ax(3),'Position',pos.*[.7 1 .8 1])

    [S,F,T,P] = spectrogram(z,  window, noverlap, Fs, frequenz);
    p=pcolor(T,F, 10*log10(abs(P)));set(p ,'edgecolor','none','Zdata',zeros(size(P)))
    clim(5:6) = caxis;shading flat


catch
    e= errordlg({'Cannot run "spectrogram" function of Signal Processing Toolbox',lasterr});
    waitfor(e)
    close(gcf)
    return
end



tit  = {alabel,blabel,clabel};
xl   = xlim;
tcol = config.Colors.TTMarkerColor ;
afcol= config.Colors.SACMarkerColor ;   % color of SAC header A & F markers

for k=1:3
    axes(ax(k));
    shading interp

    %  plot traveltimes
    set(gca,'Layer','top','color','none')
    tick=get(gca,'xtick');
    if k<3
        set(gca,'xticklabel',[]);
    else
        set(gca,'xticklabel',num2cell(tick+thiseq.Ppick(1)));
    end
    
    title(gca,{[config.stnname,'  ',thiseq.dstr,'   (',num2str(thiseq.date(7)),...
        ')   ',num2str(thiseq.date(4)),'h   ',tit{k} ,...
        ' component Power Spectral Density [dB/Hz]']});  %, Titre au dessus de chaque spectro 
    
    xlabel('')
    grid on
    mmax=round(max(clim)/10)*5;
    mmin=round(min(clim)/10)*5;
    caxis([mmin mmax])
    set(gcf,'Colormap',flipud(jet))


    % ORIGINAL SAC MARKERS
    xx = [thiseq.SACpicks; thiseq.SACpicks;  nan(size(thiseq.SACpicks)) ]-thiseq.Ppick(1);
    yy = repmat([0 max(ylim) nan], size(thiseq.SACpicks));
    line(xx(:), yy, 'Color',afcol, 'LineStyle','-', 'Parent',ax(k));
    if k==1
        text((thiseq.SACpicks-thiseq.Ppick(1))/diff(xlim), zeros(size(thiseq.SACpicks))*.995*max(ylim),...
            deblank(thiseq.SACpickNames),...
            'units','normalized',...
            'Color',               'w',...
            'FontSize',            8,...
            'VerticalAlignment',   'top', ...
            'HorizontalAlignment', 'Center', ...
            'Parent',              ax(k));
    end


    % plot traveltimes
    for i=1:length(thiseq.phase.ttimes)
        if any( [  strcmp(thiseq.phase.Names{i}, 'P-pol(bazi)')   strcmp(thiseq.phase.Names{i}, 'P-pol')] )
            %do nothing
        else
            tt = thiseq.phase.ttimes(i)-thiseq.Ppick(1);  %add origin time
            if xl(1)<tt && tt<xl(2)
                line([tt tt], [0 max(ylim)], 'Color',tcol, 'LineStyle','-', 'Tag','TTime', 'Parent',ax(k));
                if k==1
                    text(tt/diff(xlim), 0,[thiseq.phase.Names{i} ' '],...
                        'units','normalized',...
                        'Color',tcol, 'FontSize',8, 'rotation',90, 'Tag','TTime',...
                        'VerticalAlignment','top', 'HorizontalAlignment','right', 'Parent',ax(k));
                end
            end
        end
    end
end


pos= get(ax(3),'position');

cb=colorbar('SouthOutside');
set(cb,'units','normalized','position',[.1 .05 .5 .02])
set(ax(3),'Position',pos.*[1 1.2 1 1])


%% uicontrols
h= uipanel('units','normalized','Title','Configuration','FontSize',10,...
    'Position',[pos(1)+pos(3)+.05   .2 .2 .7] );
%units
uh = uicontrol(fig,'Style','popupmenu','Parent',h,...
    'Value',1,...
    'BackGroundColor','w',...
    'units','normalized',...
    'Position',[.1 .01 .8 .05],...
    'string',{'Frequency','Period'},...
    'Callback',{@changeUnits,ax});

%% colormap limits (2 uppermost sliders)
ah(1) = uicontrol(fig,'Style','slider','Parent',h,...
    'Max',mmax,'Min',mmin,'Value',mmin,...
    'units','normalized',...
    'SliderStep',[0.05 0.1],...
    'Position',[.1 .9 .8 .05],...
    'string','colormap max',...
    'Callback',@changeCmap);

ah(2) = uicontrol(fig,'Style','slider','Parent',h,...
    'Max',mmax,'Min',mmin,'Value',mmax,...
    'units','normalized',...
    'SliderStep',[0.05 0.1],...
    'Position',[.1 .83 .8 .05],...
    'string','colormap max',...
    'Callback',@changeCmap);
set(ah, 'UserData',{ah,ax})

%% colormap
ch(1) = uicontrol(fig,'Style','popupmenu','Parent',h,...
    'Value',1,...  % changed to 1 (jet) by default, GB sept 2014
    'BackGroundColor','w',...
    'units','normalized',...
    'Position',[.1 .76 .8 .05],...
    'string',{'jet','hsv','colorcube','hot','cool','copper','gray','bone','pink','spring','summer','autumn','winter'},...
    'Callback',@changeColormap);

ch(2) = uicontrol(fig,'Style','checkbox','Parent',h,...
    'Value',1,... % changed from 1, GB sept 2014
    'units','normalized',...
    'Position',[.1 .69 .8 .05],...
    'string','Invert Colormap',...
    'Callback',@changeColormap);

set(ch,   'UserData',{ch,ax})


%% ylimits (freq upper limit and lower limit) 
sh(1) = uicontrol(fig,'Style','slider','Parent',h,...
    'Max',1,'Min',0,'Value',0,...
    'units','normalized',...
    'SliderStep',[0.05 0.1],...
    'Position',[.1 .55 .8 .05],...
    'string','colormap max',...
    'Callback',@changeSpecPara);

sh(2) = uicontrol(fig,'Style','slider','Parent',h,...    'Max',frequenz/2,'Min',0,'Value',frequenz/2,...
    'Max',1,'Min',0,'Value',1.,...
   'units','normalized',...
    'SliderStep',[0.05 0.1],...
    'Position',[.1 .48 .8 .05],...
    'string','colormap max',...
    'Callback',@changeSpecPara);

%% nfft & overlap                   (y,  window, noverlap, nfft, frequenz);
fh(1) = uicontrol(fig,'Style','slider','Parent',h,...
    'Max',7,'Min',-7,'Value',nextpow2(nfft)-nextpow2(frequenz),...
    'units','normalized',...
    'Position',[.1 .34 .8 .05],...
    'string','colormap max',...
    'Callback',@changeSpecPara);

fh(2) = uicontrol(fig,'Style','slider','Parent',h,...
    'Max',.9,'Min',.0,'Value',noverlap/length(window),...
    'units','normalized',...
    'SliderStep',[0.05 0.1],...
    'Position',[.1 .27 .8 .05],...
    'string','colormap max',...
    'Callback',@changeSpecPara);

str={'hann','hamming','bartlett','tukeywin','bohmanwin','flattopwin'};
fh(3) = uicontrol(fig,'Style','popupmenu','Parent',h,...
    'Value',1,...
    'BackGroundColor','w',...
    'units','normalized',...
    'Position',[.1 .20 .8 .05],...
    'string',str,...
    'Callback',@changeSpecPara);

set([sh,fh],   'UserData',{fh,sh,uh,ax,frequenz})
set(gcf,  'UserData',{x,y,z});

%% ------------ section for time pick, added GB, sept 2014----------
% ------------------------------------------------------------------
disp 'pause: check spectro parameters and then type a key to start the pick'
pause; % allow to change the spectro parameters before picking the arrival

button = questdlg('pick time o this spectro?', ...
        ' Dialog','Yes','No','No');

    switch button
            case 'No',
            disp (['---------------------- tremor detection event ',thiseq.dstr,'  --------------------------------']);
            disp ('No detection ');
            stop;
            case 'Yes',
            disp('Pick arrival on spectro');

% pick manuel du début du tremor
[x, y] = ginputc(1, 'Color', 'b', 'LineWidth', 0.5);        % pick manuel (entrer enter pour le valider)

Time_tremor=x+thiseq.Ppick(1);                  % temps depuis le début du fichier
Min_tremor=floor(Time_tremor/60.);              % minutes depuis le début du fichier
Sec_tremor=Time_tremor-(Min_tremor*60) ;        % secondes 

disp (['---------------------- tremor detection event ',thiseq.dstr,'  --------------------------------']);
disp (['x(s)= ',num2str(x), '  Ppick(s) = ',num2str(thiseq.Ppick(1)),'  Time_tremor(s) = '...
    ,num2str(Time_tremor),'  Minutes tremor = ', num2str(Min_tremor),'  Sec tremor= ',num2str(Sec_tremor)]);

string = [config.stnname,' ',thiseq.dstr,' ',num2str(thiseq.date(7)),' ',...
     num2str(thiseq.date(1)),' ',num2str(thiseq.date(2)),' ',num2str(thiseq.date(3)),...
     ' ',num2str(thiseq.date(4)),' ',num2str(Min_tremor),' ',num2str(Sec_tremor)];

% string = [num2str(thiseq.date(7),'%03.0f'),' ',...
%     num2str(thiseq.date(3),'%02.0f'),'/',num2str(thiseq.date(2),'%02.0f'),'/',num2str(thiseq.date(1),'%04.0f'),' ',...
%     num2str(thiseq.date(4),'%02.0f'),':',num2str(Min_tremor,'%02.0f'),':',num2str(Sec_tremor,'%05.2f'),' '];
 

fprintf(tremor_detect,'%s\n',string);    % écriture de chaque détection dans le fichier 
 
% saving the spectro as a pdf file
name=[num2str(thiseq.date(1)),'_',num2str(thiseq.date(2)),'_',num2str(thiseq.date(3))...
    ,'_',num2str(thiseq.date(4)),'h_',config.stnname,'.pdf'];
%name=[config.stnname,'_',thiseq.dstr,'_',num2str(thiseq.date(4)),'h','.pdf'];
print ('-f5','-dpdf', name);         % put the number corresponding to the right figure to save

end; 
% ------------------------------------------------------------------
% ------------ end of section for time pick, added GB, sept 2014----------

function changeUnits(src,evt,ax)
yt=get(ax(1),'YTick');
switch get(src,'Value')
    case 1 %Freq
        set(ax,'YTickLabel',yt)
        ylabel(ax(1),'Frequency [Hz]')
        ylabel(ax(2),'Frequency [Hz]')
        ylabel(ax(3),'Frequency [Hz]')
    case 2 %period
        set(ax,'YTickLabel',1./yt)
        ylabel(ax(1),'Period [s]')
        ylabel(ax(2),'Period [s]')
        ylabel(ax(3),'Period [s]')
end


%%
function changeColormap(src,evt)
ud = get(src,'UserData');
ch       = ud{1};
ax       = ud{2};

str = get(ch(1),'String');
S   = get(ch(1),'Value');
I = get(ch(2),'Value');

if I
    eval(['colormap(flipud(' str{S} '))'])
else
    eval(['colormap(' str{S} ')'])
end


function changeSpecPara(src,evt)
comp = get(gcbf,'UserData');
ud = get(src,'UserData');
fh       = ud{1};
sh       = ud{2};
uh       = ud{3};
ax       = ud{4};
frequenz = ud{5};
ny       = frequenz/2;

mm = get(sh,'Value');
fmax = (10^mm{2}-1)/9 * ny;
fmin = (10^mm{1}-1)/9 * ny;
if fmax<fmin
    disp('MAX must be larger than MIN y-limits')
    return
end

val      = round(get(fh(1),'Value'));
nfft   = 2^(nextpow2(frequenz)+val);

fcn = get(fh(3),'String');
fcnval = get(fh(3),'Value');

if fcnval==4
    eval (['win   = ' fcn{fcnval} '(nfft, .4);']);
else
    eval (['win   = ' fcn{fcnval} '(nfft);']);
end
noverlap = round(length(win) * get(fh(2),'Value'));
set(fh(1),'Value',val);

Fs =(logspace(0, 1, nfft)-1)/9;
Fs = (Fs  * (fmax-fmin)) + fmin;


for k=1:3
    [S,F,T,P] = spectrogram(comp{k}, win, noverlap, Fs, frequenz);
    a=findobj('Parent',ax(k),'Type','Surface');
    set(a,...
        'Xdata', T,...
        'Ydata', F,...
        'Zdata', zeros(size(P)),...
        'Cdata', 10*log10(abs(P)));
    %     shading(ax(k),'flat')
    
    set(ax,'Ylim',[fmin fmax])
    changeUnits(uh,[],ax)
end



%%
function changeCmap(src,evt)
ud = get(src,'UserData');
sh = ud{1};
ax = ud{2};

mm = get(sh,'Value');
mmax = mm{2};
mmin = mm{1};
if mmax<mmin
    disp('MAX must be larger than MIN colormap value')
    return
end

set(ax,'Clim',[mmin mmax])


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