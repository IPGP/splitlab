function SL_ttcurves(earthmodel, phases, depth, dis, win)
% Plot Travel time curves and travel paths
   
if isempty(earthmodel)|isempty(phases)
    return
end







if nargin==0
    earthmodel = 'prem';
    phases     = 'P,S,PcP,ScS,SKS,SKKS';
    depth      = 0;
    dis        = 40;
    win        = [90 130];
end
pos = get(0,'DefaultFigurePosition');







% convert cell to comma-separated string as used by matTaup toolbox:
xx  = phases{1};
for i=2:length(phases);
    xx=strcat(xx, ',', phases{i});
end;
phases=xx;





ttfig=findobj('name','Travel Time Curves','Type','Figure');
close(ttfig)
figure
taupCurve(earthmodel, depth, phases);
ttfig=gcf;
set(ttfig,'NumberTitle','off', 'name','Travel Time Curves', 'Position', pos - [pos(3)/2 0 0 0])

plot([dis dis],ylim,'k:');


yy = [ylim fliplr(ylim)];
xx = [ win(1) win(1) win(2) win(2)];
f  = fill(xx, yy, [0.8 1 0.8], 'EdgeColor','none');


c = get(gca,'children');
set(gca,'children',[c(2:end);c(1)],'Layer','Top','XMinorTick','on');


text(mean(win),yy(1),...
  {'selected','earthquake','window'},...
  'Color',[.3 .5 .3],...
  'VerticalAlignment','Bottom',...
  'HorizontalAlignment','Center')

title(['Travel times for ' upper(earthmodel) '-model; depth = ' num2str(depth) 'km'] )


%% %% plot phases
tpfig=findobj('name','Travel paths','Type','Figure');
close(tpfig)
figure
try
taupPath(earthmodel, depth, phases,'deg',dis);
catch
    clf;hold on
    [cx,cy]=circle(6371);
    plot(cx,cy,'k');
    [cx,cy]=circle(3480);
    plot(cx,cy,'color',[0.5 0.5 0.5],'linewidth',2);
    [cx,cy]=circle(1220);
    plot(cx,cy,'color',[0.5 0.5 0.5],'linewidth',2);
    plot(0,6371-depth,'k*')
    plot(sin(dis/180*pi)*6371, cos(dis/180*pi)*6371, 'kv','MarkerFacecolor','k')
    axis off;
    axis equal;
end
tpfig=gcf;
set(tpfig,'NumberTitle','off', 'name','Travel paths', 'Position', pos+[pos(3)/2 0 0 0] )

title(['Travel paths for ' upper(earthmodel) '-model; depth = ' num2str(depth) 'km'] )

%%
function [cx,cy]=circle(r)
    ang=0:0.002:pi*2;
    cx=sin(ang)*r;
    cy=cos(ang)*r;
return;
