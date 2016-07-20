function [f1, f2, norder,key] = filterdialog(in)
% create dialogbox to input filter frequencies

f1=in(1);
f2=in(2);
norder=in(3);

    %%%%%%%%%% SET WINDOW SIZE AND POSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Always on center of SeismoViewer Window
    winwidth = 270;                                         % Width of filter window
    winheight = 110;                                        % Height of filter window
    screensize = get(gcbf,'Position');                      % Seismoviewer size [xpos ypos width height]
    screenwidth = screensize(3);                            % Seismoviewer width
    screenheight = screensize(4);                           % Seismoviewer height
    figpos = [0.5*(screenwidth-winwidth)+screensize(1), ...
            0.5*(screenheight-winheight)+screensize(2),...
            winwidth, winheight];  

fig = figure('WindowStyle','modal','Position',figpos,'NumberTitle','off','Name','Butterworth Filter','Toolbar','None','menubar','none');



hndl(1) = uicontrol('Units','pixel', 'Style','edit','Parent',fig,...
    'backgroundColor','w','tooltipstring','Enter "0" for lowpass filtering',...
    'Position',[20 70 45 20], 'String', num2str(f1),'callback',@localCallbackOK);
hndl(2) = uicontrol('Units','pixel', 'Style','edit','Parent',fig,...
    'backgroundColor','w','tooltipstring','Enter "inf" for highpass filtering',  ...
    'Position',[110 70 45 20], 'String', num2str(f2),'callback',@localCallbackOK);
hndl(3) = uicontrol('Units','pixel', 'Style','popupmenu','Parent',fig,...
    'backgroundColor','w','tooltipstring','Number of order of the butterworth filter',  ...
    'Position',[200 70 60 20], 'String', num2str((1:9)'),...
    'Value',norder);



%units
uicontrol('Units','pixel', 'Style','text','Parent',fig,...
    'Position',[70 70 15 15], 'String', 'Hz');
uicontrol('Units','pixel', 'Style','text','Parent',fig,...
    'Position',[160 70 15 15], 'String', 'Hz');

%headers
uicontrol('Units','pixel', 'Style','text','Parent',fig,...
    'Position',[ 20 90 45 15], 'String', 'from');
uicontrol('Units','pixel', 'Style','text','Parent',fig,...
    'Position',[110 90 45 15], 'String', 'to');
uicontrol('Units','pixel', 'Style','text','Parent',fig,...
    'Position',[200 90 45 15], 'String', 'order');


%keyboard
uicontrol('Units','pixel', 'Style','text','Parent',fig,...
    'Position',[0 40 140 15], 'String', 'Associate to keyboard');

hndl(4) = uicontrol('Units','pixel', 'Style','popupmenu','Parent',fig,...
    'backgroundColor','w','tooltipstring','Keyboard association',  ...
    'Position',[15 15 80 20], 'HorizontalAlignment','left',...
    'String', strvcat('none', num2str((0:9)')),...
    'Value',1);


% Button
uicontrol('Units','pixel', 'Style','pushbutton','Parent',fig,...
    'Position',[winwidth-120 10 45 25], 'String', 'OK',...
    'callback',@localCallbackOK);

set(fig,'UserData',hndl)
waitfor(fig)

%varibale "key" is externally assigned in callback functions 
    
    

%% ********************************************
function localCallbackOK(src,evt)
chr = double(get(gcbf, 'CurrentCharacter'));

retrn = isempty(chr)||any(chr==[10 13]);
OKbut = strcmpi(get(src,'Style'), 'pushbutton') && strcmpi(get(src,'String'), 'OK');

if ~(retrn || OKbut)
        return
end

hndl = get(gcbf,'UserData');

f1     = str2double(get(hndl(1),'string'));
f2     = str2double(get(hndl(2),'string'));
norder = (get(hndl(3),'Value'));
key    = (get(hndl(4),'Value'));


assignin('caller', 'f1', f1);
assignin('caller', 'f2', f2);
assignin('caller', 'norder', norder);
assignin('caller', 'key', key);
close(gcbf)
