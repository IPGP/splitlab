function exportfiguredlg(varargin)
% displays a dialog to export a figure to common formats
% exportfiguredlg(fig, defaultname, defaultdir, resolution)
% first input argument is the handle to the figure to export, the
% defaultname gives the filename suggested in dialog, and defaultdir the
% suggested directory. With no input arguments, the current figure will be 
% exported, the default directory is users home directory. However, the
% selected path is kept during the matlab session for subsequent calls of
% this function.

% © 2006 Andreas Wüstefeld, Université de Montpellier, France

persistent exportdir resolution 

if nargin ==0
    fig         = gcf;
    defaultname ='untitled.fig';
end
if nargin ==1
    fig         = varargin{1};
    defaultname ='untitled.fig';
end
if nargin ==2
    fig         = varargin{1};
    defaultname = varargin{2};
end
if nargin < 3
    if isempty(exportdir)
        if ispc
            exportdir =  getenv('USERPROFILE');
        else
            home= '~';
        end
    end
end
if nargin < 4
    if isempty(resolution)
         resolution = 150;%DPI default
    end
end

if nargin == 3
    fig         = varargin{1};
    defaultname = varargin{2};
    exportdir   = varargin{3};
else
    fig         = varargin{1};
    defaultname = varargin{2};
    exportdir   = varargin{3};
    resolution  = varargin{4};
end
%%
[dummy, file, ext] = fileparts(defaultname);
if dummy==0
    return%user abborted
end
if isempty(ext)
  ext = '.fig';
  defaultname = [defaultname ext];
end
defaultfile = fullfile(exportdir, defaultname); 



descriptions = {'*.ai','Adobe Illustrator file (*.ai)';...
    '*.eps','PostScript color (*.eps)';...
    '*.fig','Matlab Figure (*.fig)'; ...
    '*.jpg','JPEG image (*.jpg)'; ...
    '*.pdf','AdobePDF format (*.pdf)';...
    '*.png','Portable Networks Graphics file (*.png)'; ...
    '*.ps','PostScript b/w (*.ps)';...
    '*.tiff','TIFF image (*.tiff)';...
    '*.*',  'All Files (*.*)'};

% now see, which format in list is desired
s = size(descriptions,1);

formats = char(descriptions(:,1));
formats = formats(:,2:end); %Cut first letter (*)
match   = strmatch(ext,formats);
order   = setdiff(1:s, match);

%now reorder, so that the default format is always first in list
descriptions  = descriptions([match order],:);




[filename, TMPexportdir] = uiputfile(descriptions, ...
    'Save as',...
    defaultfile) ;
if isequal(filename,0) | isequal(TMPexportdir,0)
    return
else
   exportdir  = TMPexportdir;
   figstr  = ['-f' num2str(fig)];
   
   F = fullfile(exportdir,filename);
   [dummy, dummy,ext] = fileparts(filename);
   
    resolutionString = ['-r' num2str(resolution)]; 
    
    switch ext
        case '.ai'
            print(figstr, '-dill', '-noui',F);
        case '.eps'
            print(figstr,  '-depsc2', '-cmyk',   resolutionString, '-noui','-tiff', '-loose','-painters',F);
            print(figstr,  '-depsc2', '-cmyk',   resolutionString, '-noui','-tiff','-painters',F);
        
        case '.fig'
            saveas(fig, F)
        case '.jpg'
            print(figstr,  '-djpeg', resolutionString, '-noui', '-painters', F);
        case '.pdf'
            print(figstr,  '-dpdf',  '-noui', '-cmyk', '-painters',F);
        case '.png'
            print(figstr,  '-dpng', resolutionString, '-noui',  '-painters',F);         
        case '.ps'
            print(figstr,  '-dps2',   '-adobecset','-r300', '-noui','-loose', '-painters',  F);
        case '.tiff'
            print(figstr,  '-dtiff', resolutionString, '-noui', F);
        otherwise
            errordlg('Unrecognized file extension! Aborting!', 'Naming error')
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