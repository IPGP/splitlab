function matrdseed
% Matlab GUI for rdseed tool, uses java version "jrdseed" 


%locate the JAVA executable file:
p       = mfilename('fullpath');
jarpath = fileparts(p);
jarfile = dir(fullfile(jarpath,'Jrdseed*.jar'));

if isempty(jarfile)
    if exist('Q:\PhD\Matlab\JrdseedVer0.06.jar','file')
        jarfile='JrdseedVer0.06.jar';
        jarpath='Q:\PhD\Matlab\';
    elseif exist('D:\Programs\Jrdseed0.09.jar','file')
        jarfile='Jrdseed0.09.jar';
        jarpath='D:\Programs\';
    else
        disp(' ')
        disp(' ')
        disp('Jrdseed can be downloaded from the <a href="http://www.iris.edu/manuals/#2" >IRIS website</a>')
        disp(['Please save the .jar file to:  ' jarpath])
        disp(' ')
        [jarfile, jarpath] = uigetfile('*.jar', 'Jrdseed*.jar not found! Please locate it.', 'Jrdseed*.jar');
        if isnumeric(jarfile)
            return %Pressed CANCEL
        end
    end
else
    jarfile = jarfile(end).name;
end

%% ------------------------------------------------------------------------
fig = findobj('type', 'figure','Name', 'matRDseed');
if isempty(fig)
    pos = get(0,'DefaultFigurePosition');
    bg  = get(0,'DefaultUiControlBackGroundColor');
   pos(3:4) = [300 100];
   fig = figure('NumberTitle', 'Off','Position',pos,...
       'Name', 'matRDseed', 'Menubar','none','units','pixel','Color', bg);
else
    figure(fig)
    clf
end


%% locate SEED file--------------------------------------------------------
uicontrol('Units','pixel',...
    'Style','text',...
    'Position',[40 75 250 20],...
    'String','SEED file to extract: ',...
    'horizontalAlignment','left');
hSEEDedit = uicontrol('Units','pixel',...
    'Style','Edit',...
    'BackgroundColor','w',...
    'Position',[40 60 250 20],...
    'ToolTipString','Locate the SEED file to extract ',...
    'String', [pwd filesep '?.seed'],...
    'Callback','');

str = '{''*.seed'',''*.seed - seed files'';  ''*.*'',''*.* - All files''}';
def = '''*.seed''';
 uicontrol('Units','pixel',...
    'Style','Pushbutton',...
    'Position',[10 60 25 20],...
    'ToolTipString','Browse',...
    'String', '...',...
    'Userdata',hSEEDedit,...
    'Callback',['[tmp1,tmp2]=uigetfile(' str ',''SEED file'', ' def ');',...
    'if isstr(tmp2),',...
    '  set(get(gcbo,''Userdata''), ''String'',fullfile(tmp2,tmp1));',...%update edit field
    'end, clear tmp*']);

%%
 uicontrol('Units','pixel',...
    'Style','Pushbutton',...
    'Position',[180 15 50 25],...
    'ToolTipString','',...
    'Tag', fullfile(jarpath,jarfile),...
    'String', 'OK',...
    'Userdata',hSEEDedit,...
    'Callback',@executejarfile);
 uicontrol('Units','pixel',...
    'Style','Pushbutton',...
    'Position',[240 15 50 25],...
    'String', 'Cancel',...
    'Callback','close(gcbf)');

 uicontrol('Units','pixel',...
    'Style','Pushbutton',...
    'Position',[10 15 50 25],...
    'String', 'Help',...
    'Tag', fullfile(jarpath,jarfile),...
    'Callback',@executejarfile);



%%%
function executejarfile(src,event)
hndl     = get(src, 'UserData');
jarfile  = get(src, 'Tag'); 
p       = mfilename('fullpath');
jarpath = fileparts(p);


if strcmp(get(src,'String'),'Help')
   disp(' ')
   disp(' ')
    disp('Jrdseed can be downloaded from the <a href="http://www.iris.edu/software/downloads" >IRIS website</a>')
    disp(['Please save the .jar file to:  ' jarpath])
    disp(' ')
    options = ' -u';
else
    options  = [' -d -o 1 -f ' get(hndl, 'String')];
    close(gcbf)
end
commandwindow

commandstring = ['!java -jar ' jarfile options];
disp(' ')
disp(' ')
disp( commandstring)
eval( commandstring);
