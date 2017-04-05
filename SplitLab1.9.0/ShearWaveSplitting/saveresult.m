function saveresult(next)
% saves splitting results to database, logfile and saves figures

global eq thiseq config

%% checking
if strcmp(thiseq.Qstr, '        ')
        str='Please select a manual QUALITY of this result';

    errordlg(strvcat(str,' ' ,'or select "Discard" in the Result menu...'),'Error');
    return
end

n   = thiseq.resultnumber;
num = thiseq.index;

%% copy result to permanent "eq" variable
eq(num).results(n).SplitPhase   = strtrim(thiseq.SplitPhase);
eq(num).results(n).incline      = thiseq.selectedinc;
eq(num).results(n).inipol       = thiseq.tmpresult.inipol; 
eq(num).results(n).filter       = thiseq.filter;
eq(num).results(n).strikes      = thiseq.tmpresult.strikes;
eq(num).results(n).dips         = thiseq.tmpresult.dips;
eq(num).results(n).phiRC        = thiseq.tmpresult.phiRC;
eq(num).results(n).dtRC         = thiseq.tmpresult.dtRC;
eq(num).results(n).phiSC        = thiseq.tmpresult.phiSC;
eq(num).results(n).dtSC         = thiseq.tmpresult.dtSC;
eq(num).results(n).phiEV        = thiseq.tmpresult.phiEV;
eq(num).results(n).dtEV         = thiseq.tmpresult.dtEV;
eq(num).results(n).SI           = thiseq.tmpresult.splitIntens;
eq(num).results(n).Q            = thiseq.Q;
eq(num).results(n).Qstr         = thiseq.Qstr;
eq(num).results(n).Spick        = thiseq.tmpresult.Spick;
eq(num).results(n).SNR          = thiseq.tmpresult.SNR;
eq(num).results(n).remark       = thiseq.tmpresult.remark;
eq(num).results(n).method       = config.splitoption;
eq(num).results(n).timestamp    = datestr(now);
eq(num).results(n).ErrorSurface = thiseq.tmpresult.ErrorSurface;
eq(num).results(n).ndfSC        = thiseq.tmpresult.ndfSC;
eq(num).results(n).ndfEV        = thiseq.tmpresult.ndfEV;
if isfield(thiseq,'Ppick')
    eq(num).Ppick =thiseq.Ppick;
end
eq(num).results(n).gamma        = thiseq.tmpresult.gamma;


%% SAVE FIGURES
%change here, if you dont like the figure output (resolution etc)
switch config.exportformat
    case '.ai'
        option={ '-dill', '-noui'};
    case '.eps'
        option={ '-depsc2', '-cmyk',   '-r300', '-noui','-tiff', '-loose','-painters'};
    case '.fig'
        option={};
    case '.jpg'
        option={ '-djpeg', '-r300', '-noui', '-painters'};
    case '.pdf'
        option={ '-dpdf',  '-noui', '-cmyk', '-painters'};
    case '.png'
        option={ '-dpng', '-r300', '-noui',  '-painters'};
    case '.ps'
        option={ '-dps2',   '-adobecset','-r300', '-noui','-loose', '-painters'};
    case '.tiff'
        option={ '-dtiff', '-r150', '-noui'};
end


%% save results plots
fname = sprintf('%4.0f.%03.0f.%02.0f_result_%s%s',...
    thiseq.date([1 7 4]), thiseq.SplitPhase, config.exportformat);


%check if file alredy exists (phase already splitted)
No=2;
while exist(fullfile(config.savedir, fname),'file') == 2
    fname = sprintf('%4.0f.%03.0f.%02.0f_result_%s[%.0f]%s',...
            thiseq.date([1 7 4]), thiseq.SplitPhase,No, config.exportformat);
    No = No+1;
end
    
print( option{:}, fullfile(config.savedir,fname));
eq(num).results(n).resultplot = fname;


%% save seimogramm plots
% %make sure, that LTQ plot is saved
% if thiseq.system=='ENV';
%     thiseq.system='LTQ';
%     button=findobj('Tag','SystemButton');
%     set(button, 'State','On')
%     SL_updatefiltered(flipud(findobj('Tag','seismo')))
% end
% fig = findobj('Tag','SeismoFigure');
% fname = sprintf('%4.0f.%03.0f.%02.0f_LTQseismo_%s%s',...
%     thiseq.date([1 7 4]), thiseq.SplitPhase,config.exportformat);
% print( ['-f' num2str(fig)], option{:}, fullfile(config.savedir, fname))
%eq(num).results(n).seisplot = '';%fname;


%% SAVE DATABASE 
filename    = fullfile(config.projectdir,config.project);

config.db_index = thiseq.index;
save(filename,'eq','config');

clear num filename
thiseq.resultnumber = thiseq.resultnumber+1;
close(gcbf)

SL_writeLogFile('DATA', config, thiseq)


%% Re-plot Seismogram- and DatabaseViewer, with recently splitted window 
%  and new measurement shown in database
SL_databaseViewer(thiseq.index);
SL_SeismoViewer(thiseq.index);


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