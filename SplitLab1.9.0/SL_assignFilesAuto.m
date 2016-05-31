function [new_eq, success] = SL_assignFilesAuto( eqin)%, calculateTTimes, calculateEnergy )
%Assining automatically 3 component SAC files to earthquakes.
% Compare the filenames (assumed to reflect the start time of seismograms)
% in the directory defined by config.datadir with the hypocentral time,
% which is stored in structure eqin.date. The search tolerance is given by
% config.searchdt. Furthermore, a static offset can be set.
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
% output is the updated eq struture and a logical variable success stating if files are found
%
%   See also SL_assignFilesManual sort_components getFileAndEQseconds calcEnergy calcphase


%  by A. Wuestefeld,
%  Univ. Montpellier, France
%  10.03.2005


global config
if isempty(eqin)
    errordlg('Please search earthquakes first...','No earthquakes in list')
    new_eq   = eqin;
    nomatch  = [];
    notthree = [];
    success =0;
    return
end




workbar(0,'Searching files for earthquake ...','done...')

F=list(fullfile(config.datadir, config.searchstr));
ff=char(F);
if isempty(ff)
    h=warndlg({'Searching seimogramms was not successfull.',...
        'Please check configuration and naming of files and directory',...
        'Current search pattern: ' ,'',...
        fullfile(config.datadir, config.searchstr), ''},...
        'Files not found!!');
    new_eq   = eqin;
    nomatch  = [];
    notthree = [];
    workbar(1)
    success = false;
    return
else
    success = true;
end

%% Prepare search times
[FIsec, FIyyyy, EQsec, Omarker] = getFileAndEQseconds(ff,eqin,config.offset);

%% search routine
dt = config.searchdt; % seconds of search interval in each direction...
nomatch = [];
match   = [];
nn      = 0;
not3File= [];
not3EQ  = [];
new_eq  =eqin(1); %preallocation for fieldnames; values are overwritten

%% looking for eqtime-dt < filetime < eqtime+dt
% select_SKS =~isempty(strmatch('SKS',config.phases));
% select_CMT = strcmp(config.catformat,'CMT');
% if all([calculateEnergy, select_CMT, ~select_SKS])
%     w=warndlg('SKS is not a selected Phase!! Skipping calculation of SKS-energy');
%     waitfor(w)
% end




len   = length(eqin);
for i = 1:len
    str  = ['Searching file for earthquake ' eqin(i).dstr];
    head = ['done... found ' num2str(nn)];
    workbar(i/len, str, head)

    c1 = EQsec(i)-dt < FIsec;       % within tolerance (dt)
    c2 = FIsec       < EQsec(i)+dt; % within tolerance (dt)
    c3 = FIyyyy==eqin(i).date(1);   % same year
    id = find( c1 & c2 & c3);       % index of file(s)
    match = [match;id(:)];
    if isempty(id)
        %indices to files which not matching any earthquake
        nomatch  = [nomatch; i];
    elseif length(id) ~=3
        %filenames with not 3 components matching an hypotime
        not3File = [not3File; id(:)];
        not3EQ   = [not3EQ;i];
    else
        nn = nn + 1;

        %% copy old structure
        new_eq(nn)=eqin(i);
        %% add new fields:
        [files, sortindex] = sort_components(F(id));
        new_eq(nn).seisfiles = files';
        new_eq(nn).offset    = FIsec(id(sortindex))-Omarker(id(sortindex)) - EQsec(i)+config.offset;

    end
end
if nn== 0;
    new_eq=[];
end
%%
% if length(unique(match)~=length(match))
%     warndlg({'Some files have been associated to more than one earthquake!',...
%         'You have been warned!'})
% end


%indices of remaining files, wich could not be associtated
restfiles   = setdiff(1:length(F), match);
manualfiles = union(restfiles,not3File);

%if any([~isempty(nomatch), ~isempty(notthree)])
set(gcbo, 'UserData', []);

if length(new_eq)==0
    h= warndlg({'Found no matching files for earthquakes!',...
        'Please check: ','  - station parameters', '  - request offset time', '  - search string',' ',...
        'File search on Windows is not case sentive!',...
           'Also, the "?" wildcard may act ambiguously.',...
           'Please use a maximum uniqueness for your search string'}, 'No Match');
    waitfor(h)
    success = 0;
else
    if ~isempty(not3File)
        h= helpdlg({['Automatically found ' num2str(length(new_eq)) ' earthquakes'],...
            'Please assign problematic files manually'}, 'Info');
        waitfor(h)
        manual_eq = SL_assignFilesManual( eqin(not3EQ), F(manualfiles));

        new_eq=[new_eq, manual_eq];
        h= helpdlg('Please don''t forget to save the database...', 'Info');
        waitfor(h)
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
