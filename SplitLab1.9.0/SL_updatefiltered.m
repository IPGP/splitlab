function SL_updatefiltered(seis)
% update the 3 component display after filtering

global thiseq  config eq


ny = round(1 / thiseq.dt / 2); %nyquist frequency
f1 = thiseq.filter(1);
f2 = thiseq.filter(2);

if length(thiseq.filter)<3 %version compatibility
    norder = 3;
else
    norder = thiseq.filter(3);
end

subax = get(seis,'Parent');
ya= findobj('Tag','TTimeAxesLable');

if f1==0 & f2==inf
    %no filter
    txt = sprintf('SeismoViewer (%.0f/%.0f): unfiltered', config.db_index, length(eq));
    if thiseq.system=='ENV'
        set(seis(1), 'Ydata',thiseq.Amp.East)
        set(seis(2), 'Ydata',thiseq.Amp.North)
        set(seis(3), 'Ydata',thiseq.Amp.Vert)
    elseif thiseq.system=='LTQ'
        set(seis(1), 'Ydata',thiseq.Amp.SG)
        set(seis(2), 'Ydata',thiseq.Amp.SH)
        set(seis(3), 'Ydata',thiseq.Amp.L)
    end
    set(ya, 'String', 'unfiltered')

else
    if f1 > 0  &  f2 < inf
        % bandpass
        txt = sprintf('SeismoViewer(%.0f/%.0f): start= %.3fHz  stop= %0.2f Hz  Order:%d', config.db_index, length(eq),f1,f2,norder );
        [b,a]  = butter(norder, [f1 f2]/ny);
        set(ya, 'String', sprintf('f_1 = %4.2f s   f_2 = %4.2f s',1./thiseq.filter(1:2)))

    elseif f1==0 &  f2 < inf
        %lowpass
        txt = sprintf('SeismoViewer(%.0f/%.0f): lowpass stop= %.2fHz  Order:%d', config.db_index, length(eq),f2,norder );
        [b,a]  = butter(norder, [f2]/ny,'low');
        set(ya, 'String', sprintf('f = %4.2fs (lowpass)',1./f2))

    elseif f1>0 &  f2 == inf
        %highpass
        txt = sprintf('SeismoViewer(%.0f/%.0f): highpass  start= %0.3f Hz  Order:%d', config.db_index, length(eq),f1,norder );
        [b,a]  = butter(norder, [f1]/ny, 'high');
        set(ya, 'String', sprintf('f = %4.2fs (highpass)',1./f1))
    elseif f1<0 &  f2 <0
        %bandstop
        txt = sprintf('SeismoViewer(%.0f/%.0f): bandstop start= %.3fHz  stop= %0.2f Hz  Order:%d', config.db_index, length(eq),-f2,-f1,norder );
        [b,a]  = butter(norder, [-f2 -f1]/ny,'stop');
        set(ya, 'String', sprintf('bandstop f_1 = %4.2f s   f_2 = %4.2f s',1./thiseq.filter(2:-1:1)))
    else
        errordlg(sprintf('There seems to be a problem with the filter: f1=%f Hz   f2=%f Hz   P=%d',thiseq.filter))
        return
    end

    %%
    E =  thiseq.Amp.East;
    N =  thiseq.Amp.North;
    Z =  thiseq.Amp.Vert;

    SG = thiseq.Amp.SG';
    SH = thiseq.Amp.SH';
    L = thiseq.Amp.L';

    %% DeTrend & DeMean

    E = detrend(E,'linear');E = detrend(E,'constant');
    N = detrend(N,'linear');N = detrend(N,'constant');
    Z = detrend(Z,'linear');Z = detrend(Z,'constant');

    SG = detrend(SG,'linear');SG = detrend(SG,'constant');
    SH = detrend(SH,'linear');SH = detrend(SH,'constant');
    L  = detrend(L,'linear') ;L  = detrend(L, 'constant');

    %% Cosine Taper
    len   = round(length(E)); %taper length is 2% of total seismogram length
    taper = tukeywin(len, config.filter.taperlength/100);      
    E  = E  .* taper;     
    N  = N  .* taper;     
    Z  = Z  .* taper;     
    SG = SG .* taper;    
    SH = SH .* taper;   
    L  = L  .* taper;    

%     g=gcf;
%     figure(3)
%     plot(taper)
%     figure(g)


    %do filtering
    if thiseq.system=='ENV'
        Amp = (filtfilt(b, a, E));
        set(seis(1), 'Ydata',Amp)
        Amp = (filtfilt(b, a, N));
        set(seis(2), 'Ydata',Amp)
        Amp = (filtfilt(b, a, Z));
        set(seis(3), 'Ydata',Amp)
    elseif thiseq.system=='LTQ'
        Amp = (filtfilt(b, a, SG));
        set(seis(1), 'Ydata',Amp)
        Amp = (filtfilt(b, a, SH));
        set(seis(2), 'Ydata',Amp)
        Amp = (filtfilt(b, a, L));
        set(seis(3), 'Ydata',Amp)
    end


end




switch thiseq.system
    case 'ENV'
        ylabel(subax{1}, 'East');
        ylabel(subax{2}, 'North')
        ylabel(subax{3}, 'Vertical')
    case 'LTQ'
        if strcmp(config.inipoloption, 'estimated');
            ylabel(subax{1}, 'SG');
            ylabel(subax{2}, 'SH')
            ylabel(subax{3}, 'Ray')
        else
            ylabel(subax{1}, 'Q');
            ylabel(subax{2}, 'T')
            ylabel(subax{3}, 'L')
        end
    otherwise
        warning('unknown system given...')
end

set(get(subax{1},'Parent'), 'name', txt);
%% This program is part of SplitLab
% ? 2006 Andreas W?stefeld, Universit? de Montpellier, France
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