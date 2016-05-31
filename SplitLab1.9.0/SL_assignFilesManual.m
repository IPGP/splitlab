function out=SL_assignFilesManual(eqin, files)
%Assining automatically 3 component SAC files to earthquakes.
% Compare the filenames (passed as a cell array and assumed to reflect the
% start time of seismograms) with the hypocentral time, which is stored in
% structure eqin.date. The search tolerance is given by config.searchdt.
% Furthermore, a static offset can be set.
%
%Eartquakes where not exactly 3 components could be found are dismissed
%fields of eq structure changed here are:
%   eq.offset    - offset between begining of file and hypo time
%   eq.seisfiles - name of files, ordered as {East, North, Vertical}
%
%   eq.phase.ttimes  - sorted vector of  travel times as returned by  "taupPath"
%   eq.phase.Names   - cells of corresponding phase names
%   eq.phase.takeoff - vector of takeoff angle of phase at hypocentre
%                      counter-clockwise from vertical downward
%   eq.inclination   - vector of inclination angle of phase at station
%                      counter-clockwise from vertical (at station) downward
%   eq.energy        - radiation energy of SKS-phase in ray direction
%                      (e.g. Stein & Wyssession, 1999)
%
% output is the updated eq struture
%
%   See also SL_assignFilesAuto sort_components getFileAndEQseconds calcEnergy calcphase


global config

%% Prepare search times
[FIsec, FIyyyy, EQsec, Omarker] = getFileAndEQseconds(char(files), eqin, config.offset);

%% Prepare earthquake list
nomatchstr = getNomatchstr(eqin);


%     P = get(0,'DefaultFigurePosition');
h = dialog('Position',[340   278   600   420],...
    'Name', 'Associate manually');


filelist = uicontrol('Style','Listbox','Position',[10 50 275 340],...
    'Max',999,'BackgroundColor','w','Parent',h,...
    'String',files);
nomatchlist = uicontrol('Style','Listbox', 'Position',[320 50 270 340],...
    'BackgroundColor','w', 'Parent',h,...
    'String',nomatchstr);
uicontrol('Style','text','Position',[315 390 275 20],...
    'Parent',h, 'String','Ambigous earthquakes in catalogue' );
uicontrol('Style','text', 'Position',[10 390 275 20],...
    'Parent',h,'String','Ambigous Files' );
uicontrol('Style','text', 'Position',[10 5 490 30],...
    'Parent',h,'String','These ambiguities arise if no 3 components for one earthquake could been found. You can overcome this, by changing Offset and Tolerance, delete some files or just simply ignore it. ' );
assobut = uicontrol('Style','Pushbutton', 'Position',[520 10 50 20],...
    'Parent',h,'String','OK', 'Callback',' close(gcbf)');

load icon
uicontrol('Units','pixel','Parent',h,...
    'Style','Pushbutton',...
    'Position',[290 300 25 20],...
    'cdata', icon.folder,...
    'ToolTipString','Explore Data directory',...
    'Callback','if ispc, dos([''explorer '' config.datadir '' &'']); else; tmp2=pwd;cd config.datadir; filebrowser; end');
uicontrol('Units','pixel','Parent',h,...
    'Style','Pushbutton',...
    'Position',[290 330 25 20],...
    'cdata', icon.next,...
    'ToolTipString','Assign files to earthquake',...
    'Tag','Assign',...
    'Callback',@manualAssignHelper);

uicontrol('Units','pixel','Parent',h,...
    'Style','Pushbutton',...
    'Position',[290 260 25 20],...
    'cdata', icon.trash,...
    'ToolTipString','Remove SAC files from system',...
    'Tag','Delete',...
    'Callback',@manualAssignHelper);

%%
% The Data are temporarily saved as USERDATA of the Dialog figure.
% After each assignment, the Lists and USERDATA are updated (without the
% selected) and the assingments are trasmitted from the subfuction to this
% main function as varaible "out" (see ASSIGNIN of the Matlab Manual)
UD.filelist    = filelist;
UD.nomatchlist = nomatchlist;
UD.eqin        = eqin;
UD.EQsec       = EQsec;
UD.infiles     = files;
UD.FIsec       = FIsec;
UD.Omarker     = Omarker;
UD.manual_eq   = struct([]);


set(h,'UserData', UD)

waitfor(h)
if ~exist('out','var')
    out=[];
end
end%of function







%% SUBFUNCTIONS   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function manualAssignHelper(src,evt)
global config
% length(eqin)

delmode=strcmp(get(src,'Tag'), 'Delete');


%get indices to list entries which will be displayed
%first run: display all
%later, those already selected will not be displayed
UD = get(gcbf, 'UserData');

filelist  = UD.filelist;
nomatchlist = UD.nomatchlist;
eqin      = UD.eqin;
EQsec     = UD.EQsec;
infiles   = UD.infiles;
FIsec     = UD.FIsec;
Omarker   = UD.Omarker;


f = get(filelist,'Value');
e = get(nomatchlist, 'Value');
if ~delmode
    if any([length(f)~=3 length(e)~=1])
        errordlg('Please select 3 seismogram files and the corresponding earthquake!','Selection error')
        return
    end
end

new_eq = eqin(e);
[files, sortindex] = sort_components(infiles(f));
if ~delmode
    if length(sortindex)~=3
        errordlg('Please select 3 different components')
        return
    end
else
    sortindex=1:length(f);
end

new_eq.seisfiles = files';
new_eq.offset    = FIsec(f(sortindex))-Omarker(f(sortindex)) - EQsec(e)+config.offset;


if delmode
    for k=1:length(f)
        thisfile = fullfile(config.datadir, infiles{f(k)}) ;
        if exist(thisfile,'file')
            disp(['removing  ' thisfile])
            delete(            thisfile )
        else
            disp(['WARNING: ' thisfile ' doesn''t exist...'])
        end
    end
end

%remove selection from list
ind_f = setdiff(1:length(infiles), f);
if isempty(ind_f)
    set(filelist,'String', [],'Value',[]);
else
    set(filelist,'String', infiles(ind_f),'Value',[]);
end

ind_e = setdiff(1:length(eqin), e);
if isempty(ind_e)
    set(nomatchlist,'String', [],'Value',[]);
else
    set(nomatchlist,'String', getNomatchstr(eqin(ind_e)),'Value',1);
end

%% new userdata
if isempty(UD.manual_eq)
    UD.manual_eq = new_eq;
else
    UD.manual_eq(end+1) = new_eq;
end

% UD.manual_eq(end+1)   = new_eq;%add this to userdata cell
UD.eqin        = eqin(ind_e);
UD.EQsec       = EQsec(ind_e);
UD.infiles     = infiles(ind_f);
UD.FIsec       = FIsec(ind_f);

set(gcbf, 'UserData', UD)
assignin('caller','out', UD.manual_eq)





end %of subfunction
%% XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
function str = getNomatchstr(eqin)
global config

nomatchstr={};

if strcmp(config.catformat,'CMT')
    for k = 1:length(eqin)
        str{k} = sprintf('%04.0f.%03.0f %02.0f:%02.0f - %s',eqin(k).date([1 7 4 5]), eqin(k).region);
    end
else    for k = 1:length(eqin)
        str{k} = sprintf(['%04.0f.%03.0f %02.0f:%02.0f   %7.2f' char(186) 'N %7.2f' char(186) 'E '],eqin(k).date([1 7 4 5]), eqin(k).lat, eqin(k).long);
    end
end
end

%% This program is part of SplitLab
% © 2006 Andreas Wüstefeld, Université de Montpellier, France
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