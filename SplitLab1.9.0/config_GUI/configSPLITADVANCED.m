function configSPLITADVANCED(varargin)
global config

fig_handle = findobj('tag','Advanced');

if ~isempty( fig_handle )
    figure(fig_handle);    
else
    %% Figure window
	fig=figure('tag','Advanced',...
               'NumberTitle','off',...
               'WindowStyle','normal',...
               'name','Advanced Splitting Options',...
               'Color', [224   223   227]/255,...
               'MenuBar','None',...
               'Position',[100 100 500 320],...
               'KeyPressFcn', @advancedKeyPress);
    
    if any(strfind(computer, 'MAC'))
        set(fig,...
            'DefaultUIcontrolFontName',   'Monaco', ...
            'DefaultUIcontrolFontSize',   7, ...
            'DefaultUIcontrolFontAngle',  'normal', ...
            'DefaultUIcontrolFontWeight', 'normal')
    end

    
    %% Filter Key-Press Associations
    panel = uipanel('Units','pixel',...
                    'Title','Filter Key-Press Associations',...
                    'Position',[10 10  250 305],...
                    'BackgroundColor', [224  223  227]/255);

    uicontrol('Style','pushbutton', 'String', 'Learn more about filters',...
        'pos',[270 25 150 20],...
        'parent',fig,...
        'Callback','open(''FilteringInMatlab-AnIntroduction.pdf'');');

    uicontrol('Style','pushbutton', 'String', 'OK',...
        'pos',[430 20 60 30],...
        'parent',fig,...
        'Callback','close(gcbf);');

    
    pos=get(panel,'Position');
    x=[5 40 100 155 200 ];
    for k=10:-1:1;
        key=mod(k-1,10);
        y=pos(4)-(23*(k+1))-20;
        uicontrol('Style','text','Position',[x(1) y 30 16], 'String',num2str(key), 'Parent',panel);
        uicontrol('Style','edit','Position',[x(2) y 50 18], 'String',num2str(config.filterset(k,2)), 'Parent',panel,'BackGroundColor','w','Callback',['config.filterset(' num2str(k) ',2)=str2num(get(gcbo,''String''));' ]);
        uicontrol('Style','edit','Position',[x(3) y 50 18], 'String',num2str(config.filterset(k,3)), 'Parent',panel,'BackGroundColor','w','Callback',['config.filterset(' num2str(k) ',3)=str2num(get(gcbo,''String''));' ]);
        uicontrol('Style','edit','Position',[x(4) y 40 18], 'String',num2str(config.filterset(k,4)), 'Parent',panel,'BackGroundColor','w','Callback',['config.filterset(' num2str(k) ',4)=str2num(get(gcbo,''String''));' ]);
        hndfil(k)=uicontrol('Style','checkbox','Tag','check','Position',[x(5)+15 y 20 16], 'value',config.filterset(k,5), 'Parent',panel,'Callback',['config.filterset(' num2str(k) ',5)=get(gcbo,''Value'');' ]);
    end
    
    y=pos(4)-(23*(1))-25;
    uicontrol('Style','text','Position',[x(1) y 30 16], 'String','Key', 'Parent',panel);
    uicontrol('Style','text','Position',[x(2) y 50 32], 'String','Lower Freq. [Hz]', 'Parent',panel);
    uicontrol('Style','text','Position',[x(3) y 50 32], 'String','Upper Freq. [Hz]', 'Parent',panel);
    uicontrol('Style','text','Position',[x(4) y 40 16], 'String','nPoles', 'Parent',panel);
    hndfil(end+1)=uicontrol('Style','text','Position',[x(5) y 40 32], 'String','Use in batch', 'Parent',panel);

    uicontrol('Style','text','Position',[x(1) 5 30 16],  'String','Taper', 'Parent',panel);
    uicontrol('Style','text','Position',[x(3) 5 100 16], 'String','% of window length', 'Parent',panel);
    uicontrol('Style','edit','Position',[x(2) 5 50 18],  'String',num2str(config.filter.taperlength),'Parent',panel,'BackGroundColor','w','Callback', 'config.filter.taperlength=str2num(get(gcbo,''String''));' );


    %% BATCH Selection
    bpanel = uipanel('Units','pixel',...
                     'Title','Batch Processing',...
                     'Position',[270 60  220 255],...
                     'BackgroundColor', [224   223   227]/255);

    hnd(1)  = uicontrol('Style','text','Position',[10 165 120 15], 'String','Units', 'Parent',bpanel, 'tag','WindoBatchOff');
    hnd(2)  = uicontrol('Style','text','Position',[10 140 120 15], 'String','Begin extension ', 'Parent',bpanel);
    hnd(3)  = uicontrol('Style','text','Position',[10 120 120 15], 'String','End extension ', 'Parent',bpanel);
    hnd(4)  = uicontrol('Style','text','Position',[10  95 120 15], 'String','No. of Begin Windows', 'Parent',bpanel,'tag','WindoBatchOff');
    hnd(5)  = uicontrol('Style','text','Position',[10  75 120 15], 'String','No. of End Windows', 'Parent',bpanel,'tag','WindoBatchOff');
    hnd(6)  = uicontrol('Style','text','Position',[10  55 120 15], 'String','Windowing weight', 'Parent',bpanel,'tag','WindoBatchOff');
    hnd(7)  = uicontrol('Style','PopUpMenu','Position',[130 165 85 20],'String', {'Seconds' 'Percent' ,'P-window'},'Parent',bpanel,'Value',config.batch.WindowMode,'BackGroundColor','w','Callback',{@activate,'config.batch.WindowMode=get(gcbo,''Value'');'},'tag','WindoBatchOff');
    hnd(8)  = uicontrol('Style','edit','Position',[130 140 50 18], 'String',num2str(config.batch.StartWin),  'Parent',bpanel,'BackGroundColor','w','Callback','config.batch.StartWin  = str2num(get(gcbo,''String''));' );
    hnd(9)  = uicontrol('Style','edit','Position',[130 120 50 18], 'String',num2str(config.batch.StopWin),   'Parent',bpanel,'BackGroundColor','w','Callback','config.batch.StopWin   = str2num(get(gcbo,''String''));' );
    hnd(10) = uicontrol('Style','edit','Position',[130  95 50 18], 'String',num2str(config.batch.nStartWin), 'Parent',bpanel,'BackGroundColor','w','Callback','config.batch.nStartWin = round(str2num(get(gcbo,''String'')));' );
    hnd(11) = uicontrol('Style','edit','Position',[130  75 50 18], 'String',num2str(config.batch.nStopWin),  'Parent',bpanel,'BackGroundColor','w','Callback','config.batch.nStopWin  = round(str2num(get(gcbo,''String'')));' );
    hnd(12) = uicontrol('Style','edit','Position',[130  55 50 18], 'String',num2str(config.batch.windowEXP), 'Parent',bpanel,'BackGroundColor','w','Callback','config.batch.windowEXP = str2num(get(gcbo,''String''));' );

    set(hnd(7),'UserData',hnd)
    %%

    uicontrol('Style','text',...
              'Position',[10  25 200 15],...
              'String','Determine best measurement from',...
              'Parent',bpanel);

    uicontrol('Style','PopUpMenu',...
        'Position' ,[15 5 188 20],...
        'BackGroundColor','w',...
        'String'   , {'Maximum Q-value','Maximum absolute Q-value','Weighted max. Q-value','Weighted max absolute Q-value','Stacked Error Surfaces','Cluster analysis'},...
        'Parent'   ,bpanel,...
        'Value'    ,config.batch.bestMesurementMethod,...
        'Tooltip'  ,'Switching this off will use the Error Surface with maximum Quality',...
        'Callback' ,'config.batch.bestMesurementMethod=get(gcbo,''Value'');');

    hfilter = uicontrol('Style','checkbox',...
                        'Position' ,[20 215 178 15],...
                        'String'   , 'Use multiple Filters',...
                        'Tag'      , 'hfilter',...
                        'Parent'   ,bpanel,...
                        'Value'    ,config.batch.useFilterInBatch,...    'Tooltip'  ,'Switching this of will use the Error Surface with maximum Quality',...
                        'UserData' ,hndfil,...
                        'Callback' , {@activate,'config.batch.useFilterInBatch=get(gcbo,''Value'');'});
    
    hwindow= uicontrol('Style','checkbox',...
                       'Position' ,[20 195 178 15],...
                       'String'   , 'Use multiple Windows',...
                       'Tag'      , 'hwindow',...
                       'Parent'   ,bpanel,...
                       'Value'    ,config.batch.useWindowsInBatch,...    'Tooltip'  ,'Switching this of will use the Error Surface with maximum Quality',...
                       'UserData' ,hnd,...
                       'Callback' ,{@activate,'config.batch.useWindowsInBatch=get(gcbo,''Value'');'});

    activate(hfilter,[]);
    activate(hwindow,[]);
end


%% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function activate(src,evt,varargin)
if nargin==3
    evalin('base',varargin{1})%change the config variable...
end

hndl=get(src,'UserData');
if src~=hndl(7)
    if get(src,'Value')==1;
        set(hndl,'Enable','On');
    else
        set(hndl,'Enable','Off');
    end
end

%check if we are on Window mode
if length(hndl)==12
    if get(hndl(7),'Value')==3%selected Pwindow-Mode
       set(hndl([2 3 8 9]),'Enable','Off');
    else       
       set(hndl([2 3 8 9]),'Enable','On');
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function advancedKeyPress(source, event)

global config

seisView       = findobj('Tag', 'SeismoFigure', 'Type','figure');
filter_cboxes  = findobj('Tag', 'check');
windowBatch    = findobj('Tag', 'WindoBatchOff');
hfilter        = findobj('Tag', 'hfilter');
hwindow        = findobj('Tag', 'hwindow');

if strcmp( event.Key, 'return') || strcmp( event.Character, 'a')
    close(source);
    if ~isempty(seisView)
        figure(seisView);
    end
    
else
    switch event.Character
        
        case 'f'    % set batch processing filter (like clicking checkbox)
            value   = 1 - get( hfilter, 'value');
            set(hfilter, 'value', value);
            config.batch.useFilterInBatch = value;
            if value == 1;
                set(filter_cboxes,'Enable','On');
            elseif value == 0;
                set(filter_cboxes,'Enable','Off');
            end
        
        case 'w'    % set batch processing window (like clicking checkbox)
            value   = 1 - get( hwindow, 'value');
            set(hwindow, 'value', value);
            config.batch.useWindowsInBatch = value;
            for i=1:length(windowBatch)
                if value == 1;
                    set(windowBatch,'Enable','On');
                elseif value == 0;
                    set(windowBatch,'Enable','Off');
                end
            end
           
        case {'0' '1' '2' '3' '4' '5' '6' '7' '8' '9'}  % set individual filters
            if config.batch.useFilterInBatch == 1;
                value = 1 - get( filter_cboxes(str2double(event.Character)+1), 'value');
                set(filter_cboxes(str2double(event.Character)+1), 'value', value);
                config.filterset( str2double(event.Character),5 ) = value;
            end
    end
end
