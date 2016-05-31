function  opensac(F)
% Load and display SAC seismograms by clicking using Michael Thornes SacLab
% Andreas Wüstefeld; Feb. 2006


[pathstr,name,ext,versn] = fileparts(F);
name = strrep(name, '..', '.');
N = strrep(name, '.', '_');
New = ['SAC_' N];
try
  SAC = rsac(F);
catch
  SAC = rsacsun(F);  
end
assignin('base',New, SAC);
fprintf('\n\n Loading SAC-file:\n SAC_%s = rsac(''%s'');\n\n',N,F)

lh(SAC) %display SAC-header

figure
p1(SAC); %plot seismogram

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