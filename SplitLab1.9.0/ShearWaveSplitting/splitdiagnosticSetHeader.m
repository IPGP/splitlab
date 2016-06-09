function splitdiagnosticSetHeader(axH, ...
                                  phiRC, dtRC,...
                                  phiSC, dtSC,...
                                  phiEV, dtEV,...
                                  strikes, ...
                                  pol, inc, ...
                                  splitoption, bestfilter,gamma)

global thiseq config


axes(axH);

str11 = sprintf('%4.0f\\circ   (%4.0f\\circ) \\pm%2.0f', strikes(1), phiRC);
str12 = sprintf('%4.0f\\circ   (%4.0f\\circ) \\pm%2.0f', strikes(2), phiSC);
str13 = sprintf('%4.0f\\circ   (%4.0f\\circ) \\pm%2.0f', strikes(3), phiEV);
if config.maxSplitTime>=.1
    str21 = sprintf('%5.2f \\pm%5.2fs', dtRC);
    str22 = sprintf('%5.2f \\pm%5.2fs', dtSC);
    str23 = sprintf('%5.2f \\pm%5.2fs', dtEV);
else
    str21 = sprintf('%5.2g \\pm%5.2gms', dtRC*1000);
    str22 = sprintf('%5.2g \\pm%5.2gms', dtSC*1000);
    str23 = sprintf('%5.2g \\pm%5.2gms', dtEV*1000);
end

SNRstr = ['\rm SNR:\bf' sprintf('%4.1f' ,thiseq.tmpresult.SNR(2) )];


%%
if strcmp(config.studytype,'Reservoir')
    unit = 'm';
    depthunit='m ';
else
    unit='\circ';
    depthunit='km';
end

thiseq.Qstr = '        ' ;

str ={['\rm  Event: \bf' ...
    sprintf('%s (%03.0f) %02.0f:%02.0f  %6.2fN %6.2fE  %.0f%c%c  \\rmMw=\\bf%3.1f',thiseq.dstr, thiseq.date([7 4 5]) ,thiseq.lat, thiseq.long, thiseq.depth,depthunit, thiseq.Mw) ];
    [' \rmStation: \bf' strrep(config.stnname, '_','\_') '   \rmBackazimuth: \bf' sprintf('%5.1f',thiseq.bazi) '\circ   \rmDistance: \bf' sprintf('%.2f',thiseq.geodis3D) depthunit] ;
    ['\rminit.Pol.:  \bf' sprintf('%5.1f',pol)   '\circ    \rmInclination: \bf' sprintf('%5.1f', inc)  '\circ   \rmFilter: \bf' sprintf('%.3fHz - %.2fHz',bestfilter) ];
    [' \rm     \Psi =  ' sprintf('%5.1f' ,gamma) '\circ    strike   (fast)          delay   '];
    ['\rmRotation Correlation:  ' str11 '   ' str21];
    ['\rm      Minimum Energy:  ' str12 '   ' str22];
    ['\rm          Eigenvalue:  ' str13 '   ' str23];
    ['             \rmQuality: \bf'  sprintf('%05.3f',thiseq.Q)  '   ' thiseq.Qstr '\rm    Phase: \bf' thiseq.SplitPhase '        ' SNRstr;] };

if config.calcphase
    if strcmp(config.studytype,'Reservoir')
        aniso =  100 * config.Vs*1000 * dtEV(1) / thiseq.geodis3D;
        str{7} = [str{7} sprintf('    A =\\bf %4.2f%%',aniso)];
    elseif strcmp(config.studytype,'Regional')
        aniso =  100 * config.Vs * dtEV(1) / thiseq.geodis3D;
        str{7} = [str{7} sprintf('    A =\\bf %4.2f%%',aniso)];
    end
end

text(.1, .5,str,...
    'HorizontalAlignment','left',...
    'Tag','FigureHeader',...
    'FontName','fixedwidth','FontSize',10);

