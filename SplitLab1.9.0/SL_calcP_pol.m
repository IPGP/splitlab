function phase = SL_calcP_pol(optionstr, polar_method,phase)
%calculate the inclination of the wave from the p-wave polarisation
global thiseq config eq

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% determine polarisation from Particle motion:
% SEE: Jurkevics, A. "Polarisation analysis of Three component array
% data" 1988, BSSA,78(5) 1725-1743
o  = thiseq.Amp.time(1);
ia = floor((thiseq.Ppick(1)-o)/thiseq.dt); %index of first sample picked
ib = ceil((thiseq.Ppick(2)-o)/thiseq.dt); %index of last sample picked

%now extend pick window by 50% at beginning and end:
len = (ib-ia);
iaEXT = ia-ceil(len * .5);
ibEXT = ib+ceil(len * .5);
if iaEXT < 1;    iaEXT = 1; end
if ibEXT > length(thiseq.Amp.time);    ibEXT = length(thiseq.Amp.time);        end


sbar = findobj('Tag','Statusbar');

c=1;

%% now loop over various windows
%%
ext       = ibEXT - iaEXT;               % length of extended window
minlength = ceil(len * .5);        % smallest window is 75% of original picked window
overlap   = ceil(minlength * (.750));  % overlap of windows 25%

win=[1:(ib-ia)]+ceil(len*.5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loop over all filter presets defined in  seisKeyPress.m
tmp_filter = thiseq.filter; %save current filter settings
if strcmp(optionstr, 'single')
    keysToPress = -1; %only use current filter
elseif strcmp(optionstr, 'multi')
    used= find(config.filterset(:,5)==1)-1;
    keysToPress = [-1; used(:) ]; %loop through all filters
else
    error(['unkown option: ' optionstr])
end

for FFF = keysToPress
    if FFF > -1
        fakePress.Key       = 'dummy';
        fakePress.Character = num2str(FFF);
        %seisKeyPress([], fakePress, [])% now, thiseq.filter contains the fake-keyPress values
        id = find(FFF==config.filterset(:,1));
        thiseq.filter = config.filterset(id,2:4);
    end
    str = sprintf(' Status: Calculating wave polarisation @ filter : [%.3f - %0.2f]Hz  N=%dPoles', thiseq.filter);
    set(sbar , 'String',str);
    drawnow
    
    
    [E, N, Z] = getFilteredSeismograms(thiseq, iaEXT, ibEXT);
    %     ff=gcf;
    % figure(89)
    %
    % plot(Z(win))
    % figure(ff);
    if isempty(E)
        disp(['  Skipping filter set   [' num2str(thiseq.filter) ']'])
        continue;
    end
    
    [bazimuthP, incP]=testRandomise(E(win), N(win), Z(win) , polar_method,phase);
    
end
thiseq.filter = tmp_filter; %reset to original values


fig = findobj('Tag','PolAnalWindow');
if isempty(fig)
    S=get(0,'DefaultFigurePosition');
    fig=figure( 'Position', S.*[0.9 0.8  1 1.2],...
        'NumberTitle',     'off',...
        'ToolBar','none',...
        'Tag','PolAnalWindow',... 
        'WindowButtonUpFcn','close(gcbf)',...
        'KeyPressFcn','close(gcbf)');
else
    figure(fig)
    clf
end
set(fig, 'Name',['Polarisation analysis: ' polar_method ' (press any key or click to close)'] )

ax(1) = axes('Position', [0.13    0.45    0.3347    0.45]);
ax(2) = axes('Position', [0.57    0.45    0.3347    0.45]);
ax(3) = axes('Position', [0.13    0.05    0.3347    0.25]);
ax(4) = axes('Position', [0.57    0.05    0.3347    0.25]);


%calculate errors using circular statistics
bazierr   = circ_std(bazimuthP / 180*pi) * 180/pi;
incerr    = circ_std(incP      / 180*pi) * 180/pi;


axes(ax(1))
bazimuthP = mod(bazimuthP, 360);
if bazierr>3;            col='r';        else;           col='g';        end
[a1,b1]   = rose(bazimuthP*pi/180, 60);
bins=polargeo(a1,b1);
patch(get(bins,'xdata'), get(bins,'ydata'), col);


view(0,90)

axes(ax(2))
if incerr>3;            col='r';        else;           col='g';        end
[a2,b2] = rose(incP*pi/180, 60);
bins = polargeo(a2,b2, 'half');
patch(get(bins,'xdata'), get(bins,'ydata'), col);
view(00, -90)


figure(gcf)

np   = b1(2:4:end);
[dummy, i] = max(np)     ;
lims = [a1(i*4-2)  a1(i*4-1)] *180/pi ;
vals = bazimuthP(lims(1) <= bazimuthP & bazimuthP <lims(2));
bazimuthP = mean(vals);
azimuthP  = bazimuthP-180;

np   = b2(2:4:end);
[dummy, i] = max(np)     ;
lims = [a2(i*4-2)  a2(i*4-1)] *180/pi ;
vals = incP(lims(1) <= incP & incP <lims(2));
incP = mean(vals);


%%
axes(ax(1))
hold on
switch config.studytype
    case 'Teleseismic'
        inbazi = thiseq.bazi;
    case 'Regional'
        inbazi = thiseq.geobazi;
    case 'Reservoir'
        inbazi = thiseq.geobazi;
end

plot([0 sind(bazimuthP)*max([xlim ylim])],   [0 cosd(bazimuthP)*max([xlim ylim])],   'b-', 'linewidth',2 )
plot([0 sind(inbazi)*max([xlim ylim])],      [0 cosd(inbazi)*max([xlim ylim])],      'k--','linewidth',2 )

hold off
if bazierr>10;            col='red';        else;           col='black';        end %#ok<NOSEM>
title('Backazimuth distribution')
xlabel({['Centred Mean: \bf' num2str(bazimuthP,'%.2f') '\circ'], ['Standard deviation: \color{' col '} ' num2str(bazierr,'%.2f')]})

axes(ax(2))
hold on
plot([0 sind(incP)*max([xlim ylim])],               [0 cosd(incP)*max([xlim ylim])], 'b-','linewidth',2 )


if strcmp(thiseq.phase.Names(2), 'straight line')
    FF=2;
else
    FF = find(thiseq.Ppick(1)<=thiseq.phase.ttimes & thiseq.phase.ttimes <=  thiseq.Ppick(2));
end
for k=FF
    angl=mod(thiseq.phase.inclination(k),180);
    plot([0 sind(angl)*max([xlim ylim])], [0 cosd(angl)*max([xlim ylim])], 'k--','linewidth',2 )
    text(sind(angl)*max([xlim ylim]), ...
        cosd(angl)*max([xlim ylim]) , ...
        thiseq.phase.Names(k),...
        'FontWeight','demi',...
        'Rotation',-90+angl);
end
hold off


if incerr>10;            col='red';        else;           col='black';        end
title('Inclination Distribution')
xlabel({['Centred Mean: \bf' num2str(incP,'%.2f') '\circ'], ['Standard deviation: \color{' col '} ' num2str(incerr,'%.2f')]})


%append or update P-Pol values
if strcmp(thiseq.phase.Names(end), 'P-pol(bazi)' )
    idx = length(thiseq.phase.Names) -1;
else
    if length(thiseq.phase.Names)==1  & thiseq.phase.Names{1} ==' ';
        idx = 1;
    else
        idx = length(thiseq.phase.Names) + 1;
    end
    thiseq.phase.Names{idx} = 'P-pol';
    thiseq.phase.Names{idx+1} = 'P-pol(bazi)';
end


%%
%     Z       L
% M * E  =    SG
%     N       SH
angle=(90-bazimuthP)/180*pi;
M = [cos(angle) sin(angle); -sin(angle) cos(angle)];
OUT = M * [E(win), N(win)]';

m=max(abs([OUT(1,:)';  Z(win); E(win); N(win)]));

%horizontals
axes(ax(3))
plot(E(win)/m,  N(win)/m)
axis([-1 1 -1 1])
axis square


%verticals
axes(ax(4))
plot(OUT(1,:)/m,  Z(win)/m)
axis([-1 1 -1 1])
axis square
set(ax(3:4), 'XtickLabel',[], 'YtickLabel',[], 'Xtick',[0], 'Ytick',[0],'Xgrid','On','Ygrid','On') 


%%

thiseq.phase.ttimes(idx:idx+1)      = [thiseq.Ppick(1)      thiseq.Ppick(1)];
thiseq.phase.inclination(idx:idx+1) = [incP                 incP] ;
thiseq.phase.bazi(idx:idx+1)        = [bazimuthP            thiseq.bazi]  ;

selector = findobj( 'Tag','PhaseSelector');
set(selector, 'string', thiseq.phase.Names)
set(selector, 'Value',idx,'Enable','on');
RotatePhaseSelect(selector);
phase=[];
% else
%     sbar = findobj('Tag','Statusbar');
%     str= sprintf(' Polarisation analysis:  Back-azimuth = %.2f%c +/- %.2f; Inclination = %.2f%c +/- %.2f;',...
%         bazimuthP,186,bazierr , incP,186,incerr);
%     set(sbar , 'String',str);
%     drawnow
%     phase=[];
% end

thiseq.Ppol=[bazimuthP,bazierr,incP,incerr];
i = thiseq.index;
eq(i).Ppol=[bazimuthP,bazierr,incP,incerr];


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

