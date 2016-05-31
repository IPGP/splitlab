function SL_preferences(config)
% set SplitLab configuration on this computer from current config structure
% Splitlab searches first for computer specific preferences. If none are set,
% SL_defaultconfig is executed
%
% See also SETPREF SL_DEFAULTCONFIG


def  = SL_defaultconfig;

if isempty(config)
    config=def;
end
conf = rmfield(config,{'version'});  



%% ========================================================================
if ~ispref('Splitlab')
   addpref('Splitlab','Configuration', conf)
else
   setpref('Splitlab','Configuration', conf); 
end
 



if ~ispref('Splitlab','History')
   addpref('Splitlab','History', {})
end



%second row is only for non-PCs
%on PCs files are opened with Matlabs "winopen" function
if ~ispref('Splitlab','Associations')
    example = [matlabroot filesep 'bin' filesep 'matlab -r $1'];
    addpref('Splitlab','Associations',...
    {'.ai',  'gimp $1';
    '.eps',  '/usr/local/bin/gv -landscape $1';
    '.fig',  '$1';   
    '.jpg',  'xv $1';
    '.pdf',  'acroread $1';   
    '.ps',   '/usr/local/bin/gv -landscape $1';
    '.png',  'xv $1'; 
    '.tiff', 'xv $1';
    '.xls',  '~/OpenOffice/soffice $1';
    '.csv',  'more $1';
    '.kml',  'googleearth $1'}...
       )
end




disp('<a href="matlab:getpref(''Splitlab'',''Associations''),SplitLabPreferences=getpref(''Splitlab'',''Configuration''), ">Show SplitLabPreferences</a>') 

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