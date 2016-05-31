function openpjt(thispjt)
% helper function to open SplitLab project files

evalin('base','global eq thiseq config')
global eq config
 
fprintf('\n\n Loading SplitLab project\n   %s\n',thispjt) 
load('-mat',thispjt)



try
if (1.2)> sscanf(config.version(9:11),'%f')
    warning('This project is created with an older version of SplitLab. Result format will be converted...')
    SL_convert2ver1_2
end
end



%update project directory (if perhaps copied form different location...)
[pathstr,name] = fileparts(thispjt);
if strcmp(pathstr,'')
    pathstr=pwd;
end
config.projectdir = pathstr;


d=dir(thispjt);
fprintf('\n   Last modified: %s\n   by             %s\n   containing     %.0f events\n\n', d.date , config.request.user, length(eq))
disp(' <a href="matlab:SL_showeqstats">Show statistics</a>')
disp(' <a href="matlab:splitlab">Run SplitLab</a>')
disp(' <a href="matlab:SL_Results">View results</a>')
fprintf('\n\n') 


%% Update List of recently used projects
pjtlist = getpref('Splitlab','History');
match   = find(strcmp(thispjt, pjtlist));
if isempty(match)% selection not in history
    if length(pjtlist)>10
        pjtlist = {thispjt, pjtlist{1:10}};
    else
        pjtlist = {thispjt, pjtlist{:}};
    end
else
    %re-order list
    L       = 1:length(pjtlist);
    new     = [match setdiff(L,match)];
    pjtlist = pjtlist(new);
end

setpref('Splitlab','History', pjtlist)

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