function rotate_seismographIcon
% redraw the icon of seismograph orientation in Splitlab Configuration
% The Orientation of the seismograph is displayed as lines, which are 
% adjusted to any mis-orientation or wrong connected component. These
% options are chosen in the GENERAL panel of the SplitLab Configuration.
% This file simply plots the effects of the chosen options for verication.

% A. Wüstefeld, 03.07.06

global config


arrows = findobj('Tag','Seimograph Orientation Arrows');
labels = findobj('Tag','Seimograph Orientation Labels');

Xl = [0 .7];
Yl = [.7 0];

Xa = [0   0 .65];
Ya = [.65 0 0  ];

r = config.rotation/180*pi;
M = [ cos(r) sin(r);
     -sin(r) cos(r)];
 
aNew  = M * [Xa; Ya]; %arrows
lNew  = M * [Xl; Yl]; %labels
if config.SwitchEN
    ax = aNew(2,:) * config.signE;
    ay = aNew(1,:) * config.signN;
     
    lx = lNew(2,:) * config.signE;
    ly = lNew(1,:) * config.signN;
else
    ax = aNew(1,:) * config.signE;
    ay = aNew(2,:) * config.signN;
    
    lx = lNew(1,:) * config.signE;
    ly = lNew(2,:) * config.signN;
end
lpos =[lx;ly];


set(arrows,'Xdata',ax,'Ydata',ay);




labelN = findobj('Tag','Seimograph Orientation Labels','string','N');
labelE = findobj('Tag','Seimograph Orientation Labels','string','E');

set(labelN,'Position', lpos(:,1));%north
set(labelE,'Position', lpos(:,2));%east