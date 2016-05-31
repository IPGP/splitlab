function [filename, pathname] = uigetfiles(filterspec, title, varargin)
% uigetfiles: Multiple open file dialog box
%    [filename, pathname] = uigetfiles(filterspec, title, 'option',value, ...)
%    displays a dialog box for the user to fill in, and returns the
%    filename and path strings. Multiple choices are possible, as well as
%    directory names. Both returned values are then char or cellstr.
%    This function behaves exactly as uigetfile, but in multiple and dir mode
%
%    Use strcat(pathname, filesep, filename) to obtain full file name.
%
%    options may be: 'Location', [x y]
%                or  [x y]
%            and     'MultiSelect', 'on'|'off'
%
% See also: uigetfile, uigetdir
%
% Part of: iFiles utilities (ILL library)
% Author:  E. Farhi <farhi@ill.fr>. June, 2007.

% calls: none

filename={}; pathname={}; Location=[]; MultiSelect=[];
if nargin < 1, filterspec = ''; end
if nargin < 2, title = 'Select Files to Open'; end
if nargin > 2
  for i=1:length(varargin)
    if ischar(varargin{i}) & i < length(varargin)
      if strcmp(lower(varargin{i}), 'location'), Location = varargin{i+1}; i=i+1; continue; end
      if strcmp(lower(varargin{i}), 'multiselect'), MultiSelect = varargin{i+1}; i=i+1; continue; end
    end
    if isnumeric(varargin{i}) & i < length(varargin)
      if isnumeric(varargin{i+1}), Location = [ varargin{i} varargin{i+1} ]; i=i+1; continue; end
    end
  end
end

if isstruct(filterspec) % callback use
  object  = findall(0, 'Tag','UIGetFiles');
  UD      = get(object,'UserData');
  NL       = sprintf('\n');
  switch filterspec.action
  case 'show'
    UD = UIGetFilesMain(0);
  case 'update'
%     o = get(filterspec.object, 'Value')
    UIGetFilesMain(filterspec.object);
  case 'action' % {'Options','Help','Edit files','New Dir','Hidden Files'}
    switch (get(filterspec.object, 'Value'))
    case 2  % Help
      uigetfiles(struct('action','help'));
    case 3
      uigetfiles(struct('action','edit'));
    case 4
      uigetfiles(struct('action','new folder'));
    case 5
      uigetfiles(struct('action','delete files'));
    case 6
      uigetfiles(struct('action','toggle hidden files'));
    end
    set(filterspec.object, 'Value',1)
  case 'new folder'
      a=inputdlg(pwd,'Create a New Folder');
      if length(a)
        mkdir(a{1});
        UIGetFilesMain(0);
      end
  case 'go up'
    cur_dir = pwd;
    try
      cd(UD.Path);
      cd('..');
    catch
    end
    UD.Path = [ pwd filesep ];
    set(UD.Handle.Path, 'String', [ UD.Path UD.File UD.Filter ]);
    set(UD.Handle.List, 'Value', []);
    set(object,'UserData', UD);
    UIGetFilesMain(0);
    cd(cur_dir);
  case 'delete'
    delete(object);
  case 'select all'
    s = get(UD.Handle.List, 'String');
    set(UD.Handle.List, 'Value', 1:length(s));
    UIGetFilesMain(0);
  case 'deselect all'
    set(UD.Handle.List, 'Value', []);
    UIGetFilesMain(0);
  case 'previous'
    string = get(UD.Handle.Previous, 'UserData');
    selection = listdlg('ListString', string, 'ListSize', [300 160], ...
      'Name', 'Select a directory from the history', 'SelectionMode', 'single');
    if ~isempty(selection)
      UD.Path = [ string{selection} filesep ];
      set(UD.Handle.Path, 'String', UD.Path);
      set(object,'UserData', UD);
      UIGetFilesMain(0);
    end
  case 'keypressed'
    key = get(object, 'CurrentCharacter');
    switch (lower(key))
    case 'o'
      uigetfiles(struct('action','ok'));
    case 'c'
      uigetfiles(struct('action','cancel'));
    case 'e'
      uigetfiles(struct('action','edit'));
    case 'h'
      uigetfiles(struct('action','help'));
    case 'n'
      uigetfiles(struct('action','new folder'));
    case 'a'
      uigetfiles(struct('action','select all'));
    case 'd'
      uigetfiles(struct('action','deselect all'));
    case 'u'
      uigetfiles(struct('action','go up'));
    end
  case 'help'
    this_location = fileparts(which(mfilename));
    this_location = [ this_location filesep 'doc' filesep 'uigetfiles.html' ];
    disp([ 'iFiles/uigetfiles: URL=file:' this_location ]);
    web(this_location);
  case 'edit'
    string = get(UD.Handle.List, 'String');
    value  = get(UD.Handle.List, 'Value');
    for index=1:length(value)
      tmp = [ UD.Path filesep UIstrstrip(string{value(index)}) ];
      if ~isempty(dir(tmp))
        edit(tmp);
      end
    end
  case 'delete files'
    string = get(UD.Handle.List, 'String');
    value  = get(UD.Handle.List, 'Value');
    if length(value)
      tmp = {['Path:' UD.Path], ...
           'Do you really want to delete these', ...
           [num2str(length(value)) ' selected files (' ...
            num2str(sum(UD.List.Bytes(value))) ' bytes)' ], ...
            [ 'including ' num2str(sum(UD.List.Isdir(value))) ' directories ?' ], '', ...
            'Only empty directories may be deleted'};
      ButtonName=questdlg(tmp, ...
                         'Delete selection (files/directories) ?', ...
                         'Yes','No','No');
      if strcmp(ButtonName, 'Yes')
        w = warning;
        warning off;
        for index=1:length(value)
          tmp_file = UIstrstrip(string{value(index)});
          tmp_path = [ UD.Path filesep ];
          tmp      = [ tmp_path tmp_file ];
          if ~strcmp(tmp_file, '.') & ~strcmp(tmp_file, '..')
            delete(tmp);
          end
        end
        warning(w);
        set(UD.Handle.List, 'Value', []);
        UD.List.Value = [];
        set(object,'UserData', UD);
        UIGetFilesMain(0);
      end
    end
  case 'handle list'
    string = get(UD.Handle.List, 'String');
    value  = get(UD.Handle.List, 'Value');
    if isempty(string), return; end
    if ~iscell(string), return; end
    if strcmp(get(object, 'SelectionType'), 'open') & ~isempty(value)
      string = [ UD.Path filesep UIstrstrip(string{value(1)}) ];

      if isdir(string);
        UD.Path = string;
        if string(end-1) == '.'
          % this is a . or ..
          cur_dir = pwd;
          cd(UD.Path);
          UD.Path = [ pwd filesep ];
          cd(cur_dir);
        end
        set(UD.Handle.List, 'Value', []);
        set(UD.Handle.Path, 'String', UD.Path);
        set(object,'UserData', UD);
        UIGetFilesMain(0);
      else % is file
        uigetfiles(struct('action','ok'));
      end
    else % select
      UD.List.Value = get(UD.Handle.List, 'Value');
      if ~isempty(UD.List.String)
      set(UD.Handle.List, 'ToolTipString', ...
        ['Path:' UD.Path NL 'Filter:' UD.Filter NL num2str(length(UD.List.String)) ' items (' ...
         num2str(sum(UD.List.Isdir)) ' directories)' NL ...
         num2str(sum(UD.List.Bytes)) ' bytes' NL ...
         num2str(length(UD.List.Value)) ' selected (' ...
         num2str(sum(UD.List.Bytes(UD.List.Value))) ' bytes)']);
       end
    end
  case 'ok'
    previous = get(UD.Handle.Previous, 'UserData');
    p = UD.Path; index = strmatch(p, char(previous), 'exact');
    if isempty(index),
      previous = { p, previous{:} };
      previous = previous(1:min(10, length(previous))); % keep last 10
      set(UD.Handle.Previous, 'UserData', previous);
    end
    set(UD.Handle.OK, 'UserData', 'ok');
    uiresume(object); % exit uigetfiles
  case 'cancel'
    previous = get(UD.Handle.Previous, 'UserData');
    p = UD.Path; index = strmatch(p, char(previous), 'exact');
    if isempty(index),
      previous = { p, previous{:} };
      previous = previous(1:min(10, length(previous))); % keep last 10
      set(UD.Handle.Previous, 'UserData', previous);
    end
    set(UD.Handle.OK, 'UserData', 'cancel');
    uiresume(object); % exit uigetfiles
    set(object,'Visible','off');
  case 'toggle hidden files'
    if UD.ShowHidden == 1, UD.ShowHidden=0; else UD.ShowHidden=1; end
    set(object,'UserData', UD);
    UIGetFilesMain(0);
  case 'resize'
    % resize dialog
    if ~isempty(UD)
      fig_pos = get(UD.Handle.Figure, 'Position');
      w = fig_pos(3); h = fig_pos(4);
      bw4 = floor((fig_pos(3)-20)/4/5)*5; % button height for 4 per row
      bw2 = floor((fig_pos(3)-10)/3/5)*5; % button height for 2 per row
      bh = 20;  % button height
      set(UD.Handle.Path, 'Position',     [5           h-bh-5    w-bh-5 bh]);
      set(UD.Handle.Previous, 'Position', [w-bh-5      h-bh-5    bh bh]);
      
      set(UD.Handle.txtSortAs, 'Position',[5           h-2*bh-10 bw4/2 bh]);
      set(UD.Handle.Sort, 'Position',     [bw4/2+5     h-2*bh-10 bw2 bh]);
      set(UD.Handle.txtFilter, 'Position',[bw4/2+bw2+10 h-2*bh-10 bw4/2 bh]);
      set(UD.Handle.Filter, 'Position',   [bw4+bw2+15  h-2*bh-10 bw2 bh]);
      
      set(UD.Handle.Action, 'Position',   [10          h-3*bh-15 bw4 bh]);
      set(UD.Handle.Up, 'Position',       [15+bw4      h-3*bh-15 bw4 bh]);
      set(UD.Handle.Select, 'Position',   [2*bw4+20    h-3*bh-15 bw4 bh]);
      set(UD.Handle.DeSelect, 'Position', [3*bw4+25    h-3*bh-15 bw4 bh]);
      
      set(UD.Handle.List, 'Position',     [5           bh+10     w-10 h-4*bh-30]);
      
      set(UD.Handle.OK, 'Position',       [bw2/2 5 bw2 bh]);
      set(UD.Handle.Cancel, 'Position',   [bw2/2+bw2+10 5 bw2 bh]);
    end
  otherwise
    disp(['Unsupported action: ' filterspec.action ]);
  end
  filename = UD;
  return
end

% Handle filters
if ~ischar(filterspec) & ~iscellstr(filterspec)
  warning('iFiles/uigetfiles: "filterspec" should be a char or cell string array.')
  return
end


filterdefault = {...
    '*.m','Matlab function/script'; ...
    '*.mat','Matlab workspace'; ...
    '*.fig','Matlab figure'; ...
    '*.dat','Data files [text]'; ...
    '*.txt','Text files containing data'; ...
    '*.sci','Scilab function'; ...
    '*.sce','Scilab script'; ...
    '*.zip','ZIP compressed file'; ...
    '*.gz','GZip compressed file'; ...
    '*.Z','LZW Compress file'; ...
    '*.pro','IDL procedure/script'; ...
    '*.h5' ,'HDF5 hierarchical data formaf'; ...
    '*.nc' ,'NetCDF binary file'; ...
    '*.fits','FITS image format'; ...
    '*.jpg','JPEG image'; ...
    '*.tiff','TIFF image'; ...
    '*.png','PNG image'};

if strcmp(filterspec,'*') | strcmp(filterspec,'*.*')
  filterspec = [];
end

if isempty(filterspec)
  filterspec = filterdefault;
end
if ischar(filterspec)
  filterspec = cellstr(filterspec);
end
if length(filterspec) == size(filterspec,2)
  filterspec = transpose(filterspec);
end

% in case filter is also a path...
% a/b/c.m or .m or *.m or a/b/c
my_ext = '';
dir_start = '';
if length(filterspec) == 1
  [pathstr, name, ext, versn] = fileparts(filterspec{1});
  if isdir([pathstr name])
    dir_start = [pathstr name filesep ];
  elseif isdir(pathstr)
    dir_start = [ pathstr filesep ];
  else dir_start = [ pwd filesep ]; end
  if ~isempty(ext)
    dir_start = [ dir_start filesep name ext versn ];
    my_ext = [ '*' ext ];
    if isempty(strmatch(my_ext, filterdefault(:,1)))
      filterspec = cell(size(filterdefault) + [1 0]);
      filterspec(1:size(filterdefault,1),:) = filterdefault;
      filterspec{size(filterdefault,1)+1,1} = my_ext;
    end
  end
end

if size(filterspec,1) == 1
  newfilter = cell(size(filterspec,2),2);
  newfilter(:,1) = filterspec;
  filterspec = newfilter;
end

for index = 1:size(filterspec,1)
  if isempty(filterspec{index,2})
    filterspec{index,2} = [ filterspec{index,1} ' files' ];
  end
end

% Builds main interface or make it visible

fig = UIGetFilesBuild('multiple'); % multiple (or single)
UD  = get(fig,'UserData');

if ~isempty(MultiSelect)
  if strcmp(MultiSelect, 'on')  MultiSelect = 1; end
  if strcmp(MultiSelect, 'off') MultiSelect = 0; end
  UD.MultiSelect = MultiSelect;
  set(fig,'UserData', UD);
end

% customize dialog
% title, position, filters, directories list and start dir...
set(fig, 'Name', title);
if ~isempty(Location)
  pos = get(fig,'Position');
  pos(1:2) = Location;
  set(fig, 'Position', pos);
end
% tranfert filters
if isunix, ext = '*'; else ext = '*.*'; end
this_index = 0;
newfilter = cell(size(filterspec,1)+1,1);
for index=1:size(filterspec,1)
  newfilter{index} = [ filterspec{index,1} ' ' filterspec{index,2} ];
  if ~isempty(my_ext)
    if ~isempty(strmatch(my_ext, filterspec{index,1}))
      this_index = index;
    end
  end
end
newfilter{size(filterspec,1)+1} = [ ext ' All files'];
% locate user filter in list
set(UD.Handle.Filter, 'String', newfilter);
if this_index
  set(UD.Handle.Filter, 'Value', this_index);
else
  set(UD.Handle.Filter, 'Value', size(filterspec,1)+1);
end

% init start path
if ~isempty(dir_start)
  set(UD.Handle.Path, 'String', dir_start);
end

% set up path cache (HOME, pwd)
previous = get(UD.Handle.Previous, 'UserData');
p = [ matlabroot filesep ]; index = strmatch(p, char(previous), 'exact');
if isempty(index), previous = { p, previous{:} }; end
p = [getenv('HOME') filesep ]; index = strmatch(p, char(previous), 'exact');
if isempty(index), previous = { p, previous{:} }; end
p = [pwd filesep ]; index = strmatch(p, char(previous), 'exact');
if isempty(index), previous = { p, previous{:} }; end

previous = previous(1:min(10, length(previous))); % keep last 10
set(UD.Handle.Previous, 'UserData', previous);

% show/update Dialog
UD = UIGetFilesMain(0);

% wait for ok/cancel event
uiwait(fig);

UD = get(fig, 'UserData');

% we get here from a uiresume (OK/Cancel buttons and callbacks)
if strcmp(get(UD.Handle.OK, 'UserData'), 'ok')
  % set output values
  string = UD.List.Names;
  value  = get(UD.Handle.List, 'Value');
  if ~isempty(value) & ~isempty(string)
    filename = string(value);
    pathname = cell(size(filename));
    pathname(:) = { UD.Path };
    if length(filename) == 1 | UD.MultiSelect == 0
      filename = filename{1};
      pathname = pathname{1};
    else
      filename = filename';
      pathname = pathname';
    end
  end
end
set(fig, 'Visible', 'off');

% ==========================================================================
% private inline function: UIGetFilesBuild
% ==========================================================================

function fig = UIGetFilesBuild(smode)

% smode=2 multiple, 1 for single
if ischar(smode)
  switch(smode)
  case 'multiple'
    smode = 2;
  otherwise
    smode = 1;
  end
end

% Does the Dialog exist already ?
fig = findall(0, 'Tag', 'UIGetFiles');

if length(fig)  % yes: exists -> raise
  figure(fig);
  set(fig, 'Visible','on','HandleVisibility','off');
  UD = get(fig, 'UserData');
else
  % build main figure
  %
  NL= sprintf('\n');
  fig = figure('HitTest','off','MenuBar','none', ...
               'CloseRequestFcn','uigetfiles(struct(''action'',''cancel''));', ...
               'Tag','UIGetFiles','Name','Select File(s) to open', ...
               'NumberTitle','off','Unit','pixels', ...
               'KeyPressFcn','uigetfiles(struct(''action'',''keypressed''));',...
               'ResizeFcn','uigetfiles(struct(''action'',''resize''));');
  tmp = get(fig, 'Position'); tmp(3:4) = [300 400];
  set(fig, 'Position', tmp);
  UD.Handle.Figure = fig;

  % build Path uicontrol+ previous choices
  h = uicontrol('Style','edit','Tag','UIGetFiles.Path', ...
                'Position',[5 375 265 20],'String','Path', ...
                'HorizontalAlignment','left', 'FontWeight','bold', ...
                'ForegroundColor','blue','ToolTipString', ...
                  ['You may enter here any path or file name' NL ...
                   'possibly with wildcards (*,?).'], ...
                'callback','uigetfiles(struct(''action'',''update'',''object'',gcbo));');
  UD.Handle.Path = h;
  h = uicontrol('Style','pushbutton','Tag','UIGetFiles.Previous', ...
                'Position',[275 375 20 20],'String','>', 'FontWeight','bold', ...
                'ForegroundColor','blue','ToolTipString',...
                  ['Click here to select a previous' NL...
                   'or pre-defined directory path.'], ...
                'UserData', {}, ...
                'callback','uigetfiles(struct(''action'',''previous''));');
  UD.Handle.Previous = h;
  % Sort as ...   Filter
  h = uicontrol('Style','text','FontWeight','bold',  ...
                'Position',[5 350 55 20],'String','Sort as');
  UD.Handle.txtSortAs = h;
  h = uicontrol('Style','popupmenu', 'Tag','UIGetFiles.Sort',...
                'FontWeight','bold','Position',[60 350 90 20],...
                'HorizontalAlignment','left', 'String',...
                  {'Unsorted','Name','Date','Size','Extension'},...
                'ToolTipString',...
                  ['Click here to select how to' NL ...
                   'sort the directory items.' NL 'Date and Size sorting are slower.' ], ...
                'callback','uigetfiles(struct(''action'',''show''));');
  UD.Handle.Sort = h;
  h = uicontrol('Style','text', 'FontWeight','bold', ...
                'Position',[155 350 35 20],'String','Filter');
  UD.Handle.txtFilter = h;
  h = uicontrol('Style','popupmenu', 'Tag','UIGetFiles.Filter',...
                'FontWeight','bold', 'Position',[190 350 100 20],...
                'HorizontalAlignment','left', ...
                'String',{'* (All files)'}, ...
                'ToolTipString',...
                  ['Click here to select the filter' NL ...
                   'to apply to items, if not specified' NL...
                   'in the Path definition.'], ...
                'callback','uigetfiles(struct(''action'',''update'',''object'',gcbo));');
  UD.Handle.Filter = h;
  % New directory, go up, select all, deselect all
  h = uicontrol('Style','popupmenu', 'Tag','UIGetFiles.Action',...
                'Position',[10 325 65 20],...
                'String',{'Options','Help','Edit files','New Dir','Delete files','Hidden files'},'ToolTipString',...
                  [ 'Click here to:' NL ...
                    '* Access HTML help about iFiles/uigetfiles' NL ...
                    '* Edit selected files' NL ...
                    '* Create a new folder' NL ...
                    '* Delete selected files/directories' NL ...
                    '* Show/hide hidden files' NL ...
                    '' NL ...
                    'iFiles/uigetfiles, Dec 6th, 2007' NL  '(c) ILL. E. Farhi <farhi@ill.fr>' ], ...
                'callback','uigetfiles(struct(''action'',''action'',''object'',gcbo));');
  UD.Handle.Action = h;
  h = uicontrol('Style','pushbutton', 'Tag','UIGetFiles.Up',...
                'Position',[80 325 65 20],'String','Go Up',...
                'ForegroundColor',[ 0 0.0 1 ],...
                'ToolTipString',...
                  ['Click here to go up one' NL ...
                   'level in directories.'], ...
                'callback','uigetfiles(struct(''action'',''go up''));');
  UD.Handle.Up = h;
  h = uicontrol('Style','pushbutton', 'Tag','UIGetFiles.Select',...
                'Position',[150 325 65 20],'String','Select All',...
                'ToolTipString',...
                  'Click here to select all items.', ...
                'callback','uigetfiles(struct(''action'',''select all''));');
  UD.Handle.Select = h;
  h = uicontrol('Style','pushbutton', 'Tag','UIGetFiles.DeSelect',...
                'Position',[220 325 65 20],'String','DeSelect',...
                'ToolTipString',...
                  'Click here to deselect all items.', ...
                'callback','uigetfiles(struct(''action'',''deselect all''));');
  UD.Handle.DeSelect = h;
  % List
  h = uicontrol('Style','list', 'Tag','UIGetFiles.List',...
                'Position',[5 30 290 290], ...
                'String',{'.','..','directory list'}, ...
                'callback','uigetfiles(struct(''action'',''handle list''));');
  UD.Handle.List = h;
  % List contectual Popup menu
  % New directory, go up, select all, deselect all
  cmenu = uicontextmenu;
  set(UD.Handle.List, 'UIContextMenu', cmenu);
  uimenu(cmenu, 'Label', 'Select all', 'callback','uigetfiles(struct(''action'',''select all''));');
  uimenu(cmenu, 'Label', 'Deselect all', 'callback','uigetfiles(struct(''action'',''deselect all''));');
  uimenu(cmenu, 'Label', 'Upper directory', 'callback','uigetfiles(struct(''action'',''go up''));');
  uimenu(cmenu, 'Separator','on','Label', 'Help', 'callback','uigetfiles(struct(''action'',''help''));');
  uimenu(cmenu, 'Label', 'Edit files', 'callback','uigetfiles(struct(''action'',''edit''));');
  uimenu(cmenu, 'Label', 'Create new folder', 'callback','uigetfiles(struct(''action'',''new folder''));');
  uimenu(cmenu, 'Label', 'Delete files/directories', 'callback','uigetfiles(struct(''action'',''delete files''));');
  uimenu(cmenu, 'Label', 'Show/hide hidden files', 'callback','uigetfiles(struct(''action'',''toggle hidden files''));');
  % Ok cancel
  h = uicontrol('Style','pushbutton', 'Tag','UIGetFiles.OK',...
                'Position',[40 5 100 20],'String','OK',...
                'ForegroundColor',[ 0 0.5 0 ],'ToolTipString',...
                  [ 'Click here to accept selection' NL 'Multiple selections are possible (Shift and Ctrl-click)' ], ...
                'callback','uigetfiles(struct(''action'',''ok''));', ...
                'FontWeight','bold');
  UD.Handle.OK = h;
  h = uicontrol('Style','pushbutton', 'Tag','UIGetFiles.Cancel',...
                'ForegroundColor','red','Position',[160 5 100 20],'String','Cancel',...
                'ToolTipString',...
                  'Click here to cancel selection', ...
                'callback','uigetfiles(struct(''action'',''cancel''));');
  UD.Handle.Cancel = h;
  UD.Previous = {};
  UD.Path     = pwd;
  UD.Filter   = '';
  UD.File     = '';
  UD.Updated  = 1;
  UD.Dir_Path = '';
  UD.Dir_orig = '';
  UD.Dir_ext  = '';
  UD.Sort     = '';
  UD.ShowDates = 0;
  UD.ShowSizes = 0;
  UD.MultiSelect=1;
  UD.ShowHidden =0;

  set(UD.Handle.List, 'Max', smode, 'Min', 0);

  set(fig, 'UserData', UD, 'HandleVisibility','off');
end
if smode > 0
  if smode ~= get(UD.Handle.List, 'Max')
    set(UD.Handle.List, 'Value', []);
    UD.List.Value = [];
    set(UD.Handle.List, 'Max', smode, 'Min', 0);
    set(fig, 'UserData', UD);
  end
end
%if smode > 0, set(UD.Handle.List, 'Max', smode); end
set(UD.Handle.OK, 'UserData', '');

% ==========================================================================
% private inline function: UIGetFilesMain
% ==========================================================================

function UD = UIGetFilesMain(object)
% UIGetFilesMain(object)
%
% Main function used in callbacks from uigetfiles Dialog
% Updates List items from path/extensions and sort choice
% Triggered by: Path, Filter, Sort
%
% Objects: with tags 'UIGetFiles.$'
% UD.Handle.Path
% UD.Handle.Filter
% UD.Handle.Sort
% UD.Handle.List

fig = findall(0, 'Tag','UIGetFiles');
if isempty(fig), return;
else
  if length(fig) > 1
    delete(fig(2:end));
    fig = fig(1);
  end
end
if object == 0
  object = fig;
  if ishandle(fig), figure(fig); end
end

% set cursor
set(fig, 'Pointer','watch');

% retrieve UserData from Figure
UD = get(fig, 'UserData');

% handle dir path update from edit line or filter change
my_tag = get(object, 'Tag');
if strcmp(my_tag, 'UIGetFiles.Path') | strcmp(my_tag, 'UIGetFiles.Filter')

  % retrieve full_path from uicontrol (may contain file name/extension)
  full_path = get(UD.Handle.Path , 'String');

  % retrieve extension from uicontrol
  ext_index = get(UD.Handle.Filter , 'Value');
  ext_list  = get(UD.Handle.Filter , 'String');
  if ext_index>0 & ext_index<length(ext_list) & iscellstr(ext_list)
    ext     = strtok(ext_list{ext_index},' ');
  else
    if isunix, ext = '*'; else ext = '*.*'; end
  end

  % if full_path is a file/dir/anything
  if isdir(full_path)
    dir_path = full_path;
    file_name= [];
  else
    [dir_path, file_name, my_ext, versn] = fileparts(full_path);
    if length(my_ext) & ~strcmp(my_tag, 'UIGetFiles.Filter'), ext = ['*' my_ext versn]; end
  end

  % store in UD
  UD.Path = dir_path;
  UD.Filter= ext;
  UD.File  = file_name;
end % Path/Filter event

if isempty(UD.Path)
  UD.Path = [ pwd filesep ];
else
  if UD.Path(end) ~= filesep, UD.Path  = [ UD.Path filesep ]; end
end
if isempty(UD.Filter)
  if isunix, UD.Filter = '*'; else UD.Filter = '*.*'; end
end
this_filter = UD.Filter;
% if this_filter(1) == '*' & length(this_filter) > 1
%   this_filter(1) = '';
% end
if length(UD.File) > 1 | (length(UD.File) == 1 & this_filter(1) == '*')
  if UD.File(end) == '*', UD.File(end) = ''; end
end
dir_path = [ UD.Path UD.File this_filter ];

if ~strcmp(get(UD.Handle.Path, 'String'), dir_path)
  set(UD.Handle.Path, 'String', dir_path);
end

% extract directory list
NL       = sprintf('\n');
set(UD.Handle.Path, 'String', dir_path);

% check dir_path with previous call
if ~strcmp(UD.Dir_Path, dir_path)
  % if changed, dir(), deselect all, init sort order to []
  dir_list   = dir(dir_path);
  UD.Sort    = [];
  if ~isempty(dir_list), UD.Dir_orig = dir_list; end
  UD.Updated = 1;
  UD.Dir_ext = '';
else
  UD.Updated = 0;
end

if ~isempty(UD.Dir_orig)
  % get sort choice
  sort_index = get(UD.Handle.Sort , 'Value');
  sort_list  = char(get(UD.Handle.Sort , 'String'));
  if sort_index>0 & sort_index<=length(sort_list)
    sort_choice     = sort_list(sort_index,:);
  else
    sort_choice     = 'Unsorted';
  end
  sort_choice = deblank(sort_choice);

  if strcmp(sort_choice, 'Date') UD.ShowDates = 1; else UD.ShowDates = 0; end
  if strcmp(sort_choice, 'Size') UD.ShowSizes = 1; else UD.ShowSizes = 0; end
  
  % extract informations from dir items
  dir_name = {dir_list.name};
  if (UD.ShowDates)  dir_date = datenum({dir_list.date}); % this is time consuming
  else dir_date = []; end
  dir_bytes= [dir_list.bytes];
  dir_isdir= [dir_list.isdir];

  % make up a full name+ext+size
  dir_ext = cell(size(dir_list));

  % catenate list items
  if (UD.ShowSizes)  tmp3 = cellstr(strcat(' [', num2str(dir_bytes'), ' bytes]')); % this is time consuming
  else tmp3 = dir_ext; end
  tmp3(find(dir_isdir)) = {' [Directory]'};

  UD.Dir_items = strcat(transpose(dir_name), tmp3, ' (',transpose({dir_list.date}), ')');

  index = 1:length(dir_name);
  % select sort indexes
  switch sort_choice
  case 'Date'
    if (UD.ShowDates)
      [dummy, sort_date] = sort(dir_date);
      index = sort_date;
    end
  case 'Size'
    [dummy, sort_bytes]= sort(dir_bytes);
    index = sort_bytes;
  case 'Extension'
    % extract extensions if necessary
    if isempty(UD.Dir_ext)
      for index=1:length(dir_name)
        [dummy, dummy, ext, versn] = fileparts(dir_name{index});
        dir_ext{index} = [ext versn];
      end
      UD.Updated = 0;
      UD.Dir_ext = dir_ext;
    end
    [dummy, sort_ext]= sort(UD.Dir_ext);
    index = sort_ext;
  case 'Name'
    [dummy, sort_name] = sort(dir_name);
    index = sort_name;
  otherwise % Unsorted

  end
  % remove hidden files if required
  if ~UD.ShowHidden
      index_h= strmatch('.',dir_name(index)); % these are hidden files. deselect them
      hidden = zeros(1,length(index));
      hidden(index_h) = 1;
      index  = index(find(~hidden));
  end

  % reorder
  UD.List.String = UD.Dir_items(index);
  UD.List.Bytes  = dir_bytes(index);
  UD.List.Isdir  = dir_isdir(index);
  UD.List.Names  = dir_name(index);

  % present list content and selection, before new dir update
  value = get(UD.Handle.List, 'Value');
  string= get(UD.Handle.List, 'String');

  % if the existing list has changed, update content (re-order)
  if iscell(string) & iscell(UD.Dir_items)
  if strcmp(cat(2, string{:}), cat(2, UD.Dir_items{:}))
    % update uicontrol/list selection
    tmp1 = zeros(size(string));
    if isempty(UD.Sort), UD.Sort=1:length(index); end
    tmp1(UD.Sort(value)) = 1;
    value = find(tmp1(index));
    value = value(find(value <= length(string)));
  else
    if length(UD.File)  % highlight user file selection as default selection
      value = strmatch(UD.File, string, 'exact');
    end
  end
  end
  % update uicontrol/list content
  UD.Sort       = index;
  UD.List.Value = value;
  if ~isempty(string)
    set(UD.Handle.List, 'Value', value, 'String', UD.List.String);
  else
    set(UD.Handle.List, 'Value', []);
  end

  % set the filter to user's choice
  if UD.Updated
    value = get(UD.Handle.Filter, 'Value');
    string= get(UD.Handle.Filter, 'String');
    this_index = 0;
    for index=1:size(string)
      if ~isempty(UD.Filter)
        if ~isempty(strmatch(UD.Filter, string{index}))
          this_index = index;
        end
      end
    end
    if this_index & this_index ~= value
      set(UD.Handle.Filter, 'Value', this_index);
    end
  end


  if isempty(UD.List.Bytes)
      by =0;
  else
      try
        by =sum(UD.List.Bytes(UD.List.Value));
      catch
        by=0;
      end
  end

  by = num2str(by);

  % update tooltip
  if ~isempty(UD.List.String)
    set(UD.Handle.Path, 'ForegroundColor','blue');
    set(UD.Handle.List, 'ToolTipString', ...
    ['Path:' UD.Path NL 'Filter:' UD.Filter NL num2str(length(UD.List.String)) ' items (' ...
     num2str(sum(UD.List.Isdir)) ' directories)' NL ...
     num2str(sum(UD.List.Bytes)) ' bytes' NL ...
     num2str(length(UD.List.Value)) ' selected (' ...
     by ' bytes)']);
     %num2str(sum(UD.List.Bytes(UD.List.Value))) ' bytes)']);
  elseif strncmp(UD.Path, 'http://', length('http://')) | strncmp(UD.Path, 'ftp://', length('ftp://'))
    set(UD.Handle.Path, 'ForegroundColor','green');
    set(UD.Handle.List, 'String', [ 'Path ' UD.Path UD.File UD.Filter ' is an internet link']);
    set(UD.Handle.List, 'ToolTipString', [ 'Path: ' UD.Path UD.File UD.Filter NL ...
    'is an internet link' ]);
    set(UD.Handle.OK, 'UserData', 'ok');
    set(UD.Handle.List, 'Value', 1);
    UD.List.Names = {[ UD.Path UD.File UD.Filter ]};
    
  else
    set(UD.Handle.Path, 'ForegroundColor','red');
    set(UD.Handle.List, 'String', [ 'Path ' UD.Path UD.File UD.Filter ' is empty/not valid']);
    set(UD.Handle.List, 'ToolTipString', [ 'Path: ' UD.Path UD.File UD.Filter NL ...
    'is not a valid path (does not exist or is empty)' ]);
    set(UD.Handle.List, 'Value', []);
  end
else
  set(UD.Handle.Path, 'ForegroundColor','red');
  set(UD.Handle.List, 'ToolTipString', [ 'Path: ' UD.Path UD.File UD.Filter NL ...
    'Can not view content' NL ...
    '(empty, invalid permissions ?)' ]);
  set(UD.Handle.List, 'String', [ '[Can not access ' UD.Path UD.File UD.Filter ']']);
  set(UD.Handle.List, 'Value', []);
end

set(fig, 'UserData', UD);
set(fig, 'Pointer','arrow');

% function that strips additional [Directory] and (date) from List.String
function string = UIstrstrip(string)

	bracketpos = min(findstr(string, ' ['));
	parentpos  = min(findstr(string, ' ('));
	strippos = min([ length(string) bracketpos parentpos ]);

	string = deblank(string(1:strippos));


