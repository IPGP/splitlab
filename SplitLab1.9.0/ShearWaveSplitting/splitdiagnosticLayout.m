function [axH, axRC, axSC, axSeis] = splitdiagnosticLayout(Synfig)


set(Synfig,'KeypressFcn', @DiagnosticKeyPress)
good = sprintf('Good\t(g)');
m1 = uimenu(Synfig,'Label', 'Quality');
q(1) = uimenu(m1, 'Label', 'Good    ', 'Callback', @q_callback);
q(2) = uimenu(m1, 'Label', 'Fair    ', 'Callback', @q_callback);
q(3) = uimenu(m1, 'Label', 'Poor    ', 'Callback', @q_callback);
q(4) = uimenu(m1, 'Label', 'FairNull', 'Callback', @q_callback);
q(5) = uimenu(m1, 'Label', 'GoodNull', 'Callback', @q_callback);
set(q, 'Userdata', q)

m2 = uimenu(Synfig,'Label', 'Result');
n(1) = uimenu(m2, 'Label', 'Save',       'Accelerator', 's', 'Callback', 'saveresult;');
n(2) = uimenu(m2, 'Label', 'Discard',    'Accelerator', 'd', 'Callback', 'close(gcbf)');
n(3) = uimenu(m2, 'Label', 'Add remark', 'Accelerator', 'r', 'Callback', ...
    'n = thiseq.resultnumber; thiseq.tmpresult.remark = char(inputdlg(''Enter a remark to this result'', ''Remark'',1,{thiseq.tmpresult.remark})); clear n;');
set(n(1:2), 'Userdata', n(1:2))

m3 = uimenu(Synfig, 'Label', 'Figure');
uimenu(m3, 'Label', 'Save current figure',  'Accelerator','z', 'Callback', @localSavePicture);
uimenu(m3, 'Label', 'Print current figure', 'Accelerator','p', 'Callback', 'printdlg(gcbf)');
uimenu(m3, 'Label', 'Close (Esc)',          'Accelerator','q', 'Separator', 'on', 'Callback', 'close(gcbf)');
%uimenu(m3, 'Label', 'Page setup',           'Callback', 'pagesetupdlg(gcbf)');
uimenu(m3, 'Label', 'Print preview',        'Callback', 'printpreview(gcbf)');

set(Synfig,'UserData',{n,q});


%% create Axes
% borders
fontsize = get(gcf,'FactoryAxesFontsize');
panel1   = uipanel('Units', 'normalized', 'Position', [.025 .39  .96 .36], 'BackgroundColor', 'w', 'BorderType', 'line', 'HighlightColor','k');
panel2   = uipanel('Units', 'normalized', 'Position', [.025 .015 .96 .36], 'BackgroundColor', 'w', 'BorderType', 'line', 'HighlightColor','k');

%clf
axSeis   = axes('Parent', gcf, 'Units', 'normalized', 'Position', [.08 .78 .19 .2], 'Box', 'on', 'Fontsize', fontsize);

axRC(1)  = axes('Parent', panel1, 'Units', 'normalized', 'Position', [.04 .07 .20 .8],  'Box', 'on', 'Fontsize', fontsize);
axRC(2)  = axes('Parent', panel1, 'Units', 'normalized', 'Position', [.30 .07 .20 .8],  'Box', 'on', 'Fontsize', fontsize);
axRC(3)  = axes('Parent', panel1, 'Units', 'normalized', 'Position', [.52 .07 .20 .8],  'Box', 'on', 'Fontsize', fontsize);
axRC(4)  = axes('Parent', panel1, 'Units', 'normalized', 'Position', [.76 .12 .20 .75], 'Box', 'on', 'Fontsize', fontsize,'Layer', 'top');

axSC(1)  = axes('Parent', panel2, 'Units', 'normalized', 'Position', [.04 .07 .20 .8],  'Box', 'on', 'Fontsize', fontsize);
axSC(2)  = axes('Parent', panel2, 'Units', 'normalized', 'Position', [.30 .07 .20 .8],  'Box', 'on', 'Fontsize', fontsize);
axSC(3)  = axes('Parent', panel2, 'Units', 'normalized', 'Position', [.52 .07 .20 .8],  'Box', 'on', 'Fontsize', fontsize);
axSC(4)  = axes('Parent', panel2, 'Units', 'normalized', 'Position', [.76 .12 .20 .75], 'Box', 'on', 'Fontsize', fontsize,'Layer', 'top');


% header axes:
axH = axes('Parent', gcf, 'Units', 'normalized', 'Position', [.27 .8 .46 .14]);
axis off


%% SUBFUNCTION menu
%% ---------------------------------
function q_callback(src,~)
% quality menu callback

global thiseq

% 1) set menu markers
tmp1 = get(src,'Userdata');
set(tmp1(tmp1~=src),'Checked','off');
set(src,'Checked','on'),
thiseq.Qstr=get(src,'Label');

% 2) set figure header entries
tmp1 = findobj('Tag','FigureHeader');
tmp2 = get(tmp1,'String');
tmp3 = tmp2{end};
tmp3(37:44)=thiseq.Qstr;
tmp2(end) = {tmp3};
set(tmp1,'String',tmp2);


%% ---------------------------------
%function n_callback(src,~)
%null menu callback
%global thiseq
% 1) set menu markers
%tmp1 = get(src,'Userdata');
%set(tmp1(tmp1~=gcbo),'Checked','off');
%set(gcbo,'Checked','on')
%thiseq.AnisoNull=get(gcbo,'Label');

% 2) set figure header entries
%tmp1 = findobj('Tag','FigureHeader');
%tmp2 = get(tmp1,'String');
%tmp3 = tmp2{end};
%tmp3(52:54) = thiseq.AnisoNull;
%tmp2(end) = {tmp3};
%set(tmp1,'String',tmp2);

%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
function localSavePicture(hFig,evt)
global config thiseq
defaultname = sprintf('%s_%4.0f.%03.0f.%02.0f.result.',config.stnname,thiseq.date([1 7 4]));
defaultextension = strrep(config.exportformat,'.','');
exportfiguredlg(gcbf, [defaultname defaultextension],config.savedir,config.exportresolution)


%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
function DiagnosticKeyPress(src,evnt)
global thiseq

hndl = get(src,'UserData'); % handles to menu entries
hndl = hndl{2};
%if strcmp(evnt.Key,'home') || strcmp(evnt.Key,'escape') || strcmp(evnt.Key,'delete')
%    close(gcbf);
%    return;
%end 

switch evnt.Character
    case 'g'
        h=hndl(1);
%         set(hndl{2}(1)  , 'Checked','on');
%         set(hndl{2}(2:3), 'Checked','off');
        thiseq.Qstr='Good   ';
    case 'f'      
        h=hndl(2);  
%         set(hndl{2}(1)  , 'Checked','on');
%         set(hndl{2}(2:3), 'Checked','off');
        thiseq.Qstr='Fair    ';
    case 'p'
        h=hndl(3);
%         set(hndl{2}(1)  , 'Checked','on');
%         set(hndl{2}(2:3), 'Checked','off');
        thiseq.Qstr='Poor   ';
    case '0'
        h=hndl(4);
%         set(hndl{2}(2)  , 'Checked','on');
%         set(hndl{2}(1), 'Checked','off');
        thiseq.Qstr='FairNull';
    case 'n'
        h=hndl(5);
%         set(hndl{1}(1)  , 'Checked','on');
%         set(hndl{1}(2), 'Checked','off');
        thiseq.Qstr='GoodNull';
    otherwise
        return
end

q_callback(h,[])

% % 2) set figure header entries
% tmp1 = findobj('Tag','FigureHeader');
% tmp2 = get(tmp1,'String');
% tmp3 = tmp2{end};
% tmp3(29:33) = thiseq.Q;
% tmp3(52:54) = thiseq.AnisoNull;
% tmp2(end) = {tmp3};
% set(tmp1,'String',tmp2);
