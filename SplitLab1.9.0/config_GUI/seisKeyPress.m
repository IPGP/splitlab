function seisKeyPress(~,evnt,seis)
% handle keypress within Splitlab seismogram plot

global thiseq eq config
src = gcbf;

% local filter is temporary filter structure, filt structure in calling
% function will be assigned to the new value
f1 = thiseq.filter(1);
f2 = thiseq.filter(2);
norder = thiseq.filter(3);

if strcmp(evnt.Key,'shift')
    return
end
set(src,'Pointer','watch')

if strcmp(evnt.Key,'return')
    if length(evnt.Modifier) == 1 && strcmp(evnt.Modifier{:},'shift')
        preSplit(1)%Batch Mode
    else
        preSplit(0)
    end
    %return
    
elseif (length(evnt.Key)>1) && (strcmp(evnt.Key(1),'f'))
    switch evnt.Key(2)
        case '1'
            twin = [-20 10];
        case '2'
            twin = [-20 20];
        case '3'
            twin = [-20 40];
        case '4'
            twin = [-10 60];
        case '5'
            twin = [-20 60];
        otherwise
            return
    end
    twin =twin/2000;
    val          = get(findobj('Tag','PhaseSelector'),'Value');
    tbase        = thiseq.phase.ttimes(val);
    thiseq.Spick = tbase + twin;
    hfill        = findobj('Tag','SplitWindow');
    set(hfill,'Xdata',[thiseq.Spick(1); thiseq.Spick(1); thiseq.Spick(2);  thiseq.Spick(2)])

% MAC 'home': fn + control + leftarrow    
elseif strcmp(evnt.Key,'home')
    %jump close to selected phase
    val  = get(findobj('Tag','PhaseSelector'),'Value');
    %try
    t_home = floor(thiseq.phase.ttimes(val)/10)*10 - 500*thiseq.dt; %~500 samples before phase; at full 10 seconds
    xlim([t_home t_home+5000*thiseq.dt]) % timewindow of 3000 samples sec
    %end

elseif strcmp(evnt.Key,'rightarrow')
    xx = xlim;
    xlim(xx+diff(xx)/13)

elseif strcmp(evnt.Key,'leftarrow')
    xx=xlim;
    xlim(xx-diff(xx)/13)

elseif strcmp(evnt.Key,'uparrow') %zoom in by 20%
    xx = xlim;
    point = getCurrentPoint(seis(4));

    if isempty(point)
        limit = (xx + [diff(xx) - diff(xx)] / 5);
    else
        xp = point(1);
        limit = xx + [xp-xx(1) (xp-xx(2))] / 5;
    end
    
    lim = diff(limit)/thiseq.dt;
    if 100 <= lim;
        sa=findobj('Tag','seismo');
        set(sa,'LineStyle','-','Marker','none')
    elseif 10 <= lim && lim < 100
        sa=findobj('Tag','seismo');
        set(sa,'LineStyle','-','Marker','.')
    elseif lim < 10
        sa=findobj('Tag','Statusbar');
        set(sa,'String','Sorry, reached maximum Zoom level...')
        set(gcbf,'Pointer','crosshair')
        return
    end
    xlim(limit) %zoom in by 20%

elseif strcmp(evnt.Key,'downarrow') %zoom out by 20%
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


% MAC 'pageup': fn + uparrow
elseif strcmp(evnt.Key,'pageup') || (strcmp(evnt.Key,'tab') && ~isempty(evnt.Modifier))  %previous event
    if strcmp(evnt.Key,'pageup') || (strcmp(evnt.Key,'tab') && strcmp(evnt.Modifier,'shift'))
        idx = thiseq.index-1;
        if idx < 1;
            idx = length(eq);
        end;
        SL_databaseViewer(idx)
        SL_SeismoViewer(idx);
        clear idx
    end

% MAC 'pagedown': fn + downarrow
elseif strcmp(evnt.Key,'pagedown') || strcmp(evnt.Key,'tab') && isempty(evnt.Modifier) %next event
    idx = thiseq.index+1;
    if idx > length(eq);
        idx = 1;
    end;
        SL_databaseViewer(idx)
        SL_SeismoViewer(idx);
        clear idx
    
elseif strcmp(evnt.Key,'backspace')
    sa=findobj('Tag','seismo');
    set(sa,'LineStyle','-','Marker','none')
    xlim('auto')
    
elseif strcmp(evnt.Key,'delete')
    trashfunction = @localTrash;
    trashfunction(gcbf,evnt);
        
else
    switch evnt.Character
        case 'a'
            configSPLITADVANCED
            
        case 'd'
            db_handle = findobj('Name','Database Viewer'); 
            if ~isempty(db_handle); 
                uistack(db_handle,'top'); 
            else 
                SL_databaseViewer; 
            end
            clear db_handle;
        
        case 'f'
            ny = 0.5/thiseq.dt;
            doloop = 1 ;
            while doloop
                [f1, f2, norder,key] = filterdialog(thiseq.filter);
                f  = sort([f1 f2]);
                f1 = f(1);      
                f2 = f(2);
                if ( (any( [f1 f2] >= ny ) && f2~=inf ) || f1<0 && f2>0)
                    beep
                    e=errordlg({'Filter frequencies must be in interval',[' 0 <= f1 < f2 < ' num2str(0.5/thiseq.dt) ' = f_nyquist'],'Both values negative give a stop-band filter'},'Warning');
                    waitfor(e)
                else
                    doloop = false;
                end
                if key>1
                    config.filterset(key-1, 2:4) = [f1 f2 norder];
                end
            end
            
        case 'h'
            tmp = thiseq;
            tmp = rmfield(tmp, 'seisfiles');
            files = cell2mat(thiseq.seisfiles(:));
            txt = ['   |- seisfiles : ' files(1,:);
                   '   |              ' files(2,:);
                   '   |              ' files(3,:)];
            str = strucdisp(tmp,2,1,7);
            str = char(' thiseq', str(1,:) ,txt, str);
            h=figure('WindowStyle', 'Modal',... 
                     'Name','thiseq variable viewer',...
                     'KeyPressFcn',@lscallback);
            uicontrol('Units','Normalized',...
                      'Position',[.05 .05 .9 .9],...
                      'Style','edit',...
                      'Parent',h,...
                      'Value',1,...
                      'max',100,...
                      'min',0,...
                      'BackGroundColor','w',...
                      'FontName','FixedWidth',...
                      'String',str)

        case 'j'
            if  sum(thiseq.Ppick ~=0)
                dummy = SL_calcP_pol('single','Jurkewicz','P');
                eq(thiseq.index).Ppick = thiseq.Ppick;
                eq(thiseq.index).phase = thiseq.phase;
            else
                helpdlg('Please pick a P-Wave window first ','Oups, No P-window...')
            end
            
        case 'J'
            if sum(thiseq.Ppick ~=0)
                dummy = SL_calcP_pol('multi','Jurkewicz','S');
                eq(thiseq.index).Ppick = thiseq.Ppick;
                eq(thiseq.index).phase = thiseq.phase;
            else
                helpdlg('Please pick a P-Wave window first ','Oups, No P-window...')
            end
            
        case {'l', 'z'}
            % lock yaxis...
            button = findobj('Tag','LockButton');
            if strcmpl('off', state);
                set(button, 'State','On') %this also invokes the "buttonDownFunction"
            else
                set(button, 'State','Off')
            end
            
        case 'o'
            splitlab( 'change_radio_button' );
        
        case 'p' % polarisation analysis
            if  sum(thiseq.Ppick ~=0)
                dummy = SL_calcP_pol('single','Teanby','P');
                eq(thiseq.index).Ppick = thiseq.Ppick;
                eq(thiseq.index).phase = thiseq.phase;
            else
                helpdlg('Please pick a P-Wave window first ','Oups, No P-window...')
            end
            
        case 'P' % polarisation analysis
            printdlg(gcbf);
            
        case 'r'
            idx = thiseq.index; 
            SL_databaseViewer(idx); 
            SL_SeismoViewer(idx); 
            clear idx
        
        case {'s','S'}  % spectro
            if sum(thiseq.Ppick ~= 0)
              if(evnt.Character == 's')
                plotfreqz('loglog','semilogx');
              else
                plotfreqz('plot','plot');
              end
            else
                helpdlg('Please pick a P-Wave window first ','Oups, No P-window...');
            end
        
        case 't'
            viewphases;
        
        case 'T' % polarisation analysis
            if  sum(thiseq.Ppick ~=0)
                dummy = SL_calcP_pol('single','Teanby','P');
                eq(thiseq.index).Ppick = thiseq.Ppick;
                eq(thiseq.index).phase = thiseq.phase;
            else
                helpdlg('Please pick a P-Wave window first ','Oups, No P-window...')
            end
            
        case {'0' '1' '2' '3' '4' '5' '6' '7' '8' '9'}
            i = find(config.filterset(:,1) == str2num(evnt.Character));
            f1 = config.filterset(i,2);
            f2 = config.filterset(i,3);
            norder = config.filterset(i,4);

        case '+'
            if f1*1.03<f2
                f1=f1*1.03;
            end
            
        case '-'
            f1=f1*.97;
            
        case '*'
            ny = round(1 / thiseq.dt / 2); %nyquist frequency
            if f2*1.03<ny
                f2=f2*1.03;
            end
            
        case '/'
            if f2*.97>f1
                f2=f2*.97;
            end
            
        case '<'
            f1=f1*.97;
            f2=f2*.97;
                    
        case '>'
            ny = round(1 / thiseq.dt / 2); %nyquist frequency
            if f2*1.03<ny
                f1=f1*1.03;
                f2=f2*1.03;
            end

        case ' ' %space
            % rotate system
            button=findobj('Tag','SystemButton');
            if thiseq.system == 'ENV';
                thiseq.system='LTQ';
                set(button, 'State','On')%this also invokes the "buttonDownFunction"
            elseif thiseq.system == 'LTQ';
                thiseq.system='ENV';
                set(button, 'State','Off')
            end
    end %switch
end %else

%set(gcbf,'KeyPressFcn',{@seisKeyPress,seis})

%% filtering and display...
if ishandle(src)
    switch evnt.Character
        case {'0' '1' '2' '3' '4' '5' '6' '7' '8' '9' '*' '+' '/' '-' '<' '>' 'f'}
            
            ny = round(1 / thiseq.dt / 2); %nyquist frequency
            %if (f1~=0 & (abs(f1) >= ny))  ||  (f2~=inf & (abs(f2) >= ny))
            %    warndlg('Filter frequencies larger than Nyquist frequency. Please check your filter settings.')
            %    f2=inf;
            %elseif f1~=0 & abs(f1) / ny   <   0.001
            %    str = sprintf('Lower filter frequency (%f Hz) appears to be rather small compared to Nyquist frequency (%f Hz). This may result in inacurate or useless seismograms. Please check your filter settings.',f1, ny);
            %    w=warndlg(str,'Filter problem','modal');
            %    f1=0;

            %elseif f2~=0 & abs(f2) / ny   <   0.001
            %    str = sprintf('Upper filter frequency (%f Hz) appears to be rather small compared to Nyquist frequency (%f Hz). This may result in inacurate or useless seismograms. Please check your filter settings.',f2, ny);
            %    w=warndlg(str,'Filter problem','modal');
            %    f2=0;
            %end
            %else
                thiseq.filter = [f1 f2 norder]; %update variable filt in caller function
                SL_updatefiltered(seis(1:3));
            
    end
end

set(gcbf,'Pointer','crosshair')


%% SUBFUNCTIONS
function lscallback(src,evnt)
if strcmp(evnt.Key,'return') || strcmp(evnt.Character,'h')
    close(src);
end