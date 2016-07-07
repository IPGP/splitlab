function varargout=SL_cmtread(default_file)
% Read earthquake database from Harvard-CMT catalogue and saves in SplitLab
% format. You can either create a new catalogue from a local ".ndk"-file
% or update an existing catalogue, chosen in SpliLab's  catalogue panel
%

% The format is ASCII and uses five 80-character lines per earthquake.
% PDE  2005/07/01 03:48:28.7  36.57   71.32  63.1 5.4 0.0 AFGHANISTAN-TAJIKISTAN B
% C200507010348A   B: 61  119  40 S: 63  132  50 M:  0    0   0 CMT: 1 TRIHD:  1.5
% CENTROID:      8.6 0.2  36.79 0.02   71.06 0.02 100.1  1.5 FREE S-20050916103315
% 24 -0.120 0.040 -0.572 0.052  0.693 0.053  0.820 0.037 -0.199 0.045 -2.460 0.046
% V10   2.755 13  51  -0.159 72 276  -2.595 12 144   2.675 187 72    1  97 89  162
%
% See also: SL_eqwindow


%% Here we go...
if nargin==0
    default_file=which('harvardCMT.mat');
end

Answer=questdlg(help('SL_cmtread'),'Help','Goto Harvard CMT search','Update from Server','Local file','Update from Server');
switch Answer
    case 'Goto Harvard CMT search'
            web http://www.globalcmt.org/CMTsearch.html -browser
        return

    case 'Update from Server'
        try
            workbar(.1, 'Connecting to http://www.ldeo.columbia.edu/.../qcmt.ndk')
            pause(.7)
            qcmt=SL_urlread('http://www.ldeo.columbia.edu/~gcmt/projects/CMT/catalog/NEW_QUICK/qcmt.ndk');

            L= length(qcmt)/81/5; %81 characters (including NewLine) and 5 lines per earthquake
            disp([num2str(L) ' earthquakes in the Quick CMT file...'])

            workbar(.3, [num2str(L) ' earthquakes in the Quick CMT file...'])
            pause(1)
            workbar(.4, ['Last earthquake on Server:  ' qcmt(end-399:end-384)])
            pause(2)
        catch
            workbar(1)
            errordlg({'Troubles reading online file. Please check your internet settings',...
                'Could not connect to http://www.ldeo.columbia.edu/~gcmt/projects/CMT/catalog/NEW_QUICK/qcmt.ndk'},'Some sort of trouble')
            disp('Could not connect to http://www.ldeo.columbia.edu/~gcmt/projects/CMT/catalog/NEW_QUICK/qcmt.ndk')
            disp(['error in: ' mfilename('fullpath') ])
            doc urlread
            return
        end
        load(default_file)%file to be updated
        dstr=datestr([cmt.year(end) cmt.month(end) cmt.day(end) cmt.hour(end) cmt.minute(end) cmt.sec(end)]);
            workbar(.5, ['Last earthquake in database:  ' dstr])
            pause(2)
                   
    case 'Local file'
        answer = questdlg('Do you want to create a new catalogue or update the current catalogue?', 'Catalogue', 'New','Update','Cancel','Update');
        switch answer
            case 'Update'
                load(default_file)%file to be updated
            case 'New'
                cmt = struct('ID',[],'year',[],'month',[], 'day',[], 'jjj',[], 'hour',[],'minute',[], 'sec',[], ...
                    'lat',[], 'long',[], 'depth',[],'Mb',[],'MS',[],'M0',[],'Mw',[],'region',[],'strike',[],'dip',[],'rake',[]);
            case 'Cancel'
                return
        end

        [filename, pathname] = uigetfile( {'*.ndk'; '*.*'}, ...
            'Pick the earthquake catalogue file');
        if ~ischar(filename)
            return
        end

        File = fullfile(pathname,['CMT_' filename]);
        default_file = strrep(File ,'.ndk','.mat');

        url = ['file:///' fullfile(pathname,filename)];
        qcmt=urlread(url);
        L= length(qcmt)/81/5; %81 characters (including NewLine) and 5 lines per earthquake
        disp([num2str(L) ' earthquakes in the Quick CMT file...'])

        workbar(.3, [num2str(L) ' earthquakes in the Quick CMT file...'])
        pause(1)
        
    otherwise
        return
end





%% update file:
%now I have to do something quick and dirty :-(
% sometimes in the catalogue, the Hypocenter reference catalog
% (first 4 characters of the earthquake) is not assigned, ie blank
%matlab seems to have troubel if field only contains white spaces
%so I replace the first for characters in eacht 5th line with XXXX
%indices to letters to be replaced: 81 letters (including \n), 5 lines

rep = 1:81*5:length(qcmt);
rep = [rep rep+1 rep+2 rep+3];
qcmt(rep)='X';
%% END OF QUICK AND DIRTY

workbar(.6, 'Reading databases')
pause(1)
format  = '%*4c%4f/%2f/%2f %2f:%2f:%4.1f%.2f%.2f%.1f%.1f%.1f%[^\n]\n'; % skip 4 catalog letters, then DATE TIME LAT LONG DEPTH Mb MS REGION;
format  = [format '%s%*[^\n]\n%*[^\n]\n'];%read ID and skip second and third row
format  = [format '%2f%*[^\n]\n'];% read in Moment tensor exponent; skip the rest
format  = [format '%*49c%f%f%f%f%*f%*f%*f'];%skip first 49 letters, then read sclar moment, strike; dip; rake
%second Nodal plane is ignored
[A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R] = strread(qcmt,format);


%%
if strcmp('Update from Server', Answer)
    
    ind=[];
    MM=length(M);
    for k = 1:MM
        workbar(k/MM, 'comparing databases')
        match = strmatch(M{k},cmt.ID);
        if isempty(match)
            ind=[ind k];
        end
    end
    if isempty(ind)
        workbar(1)
        last= datestr([A(end), B(end),C(end), D(end),E(end), F(end)]);
        h=helpdlg({'Found no new earthquakes! Sorry...',...
            ['Last earthqauke in QuickCMT file:   ' last] });
        waitfor(h)
        return
    end
    workbar(.99,['Found ' num2str(length(ind)) ' new earthquakes!'])
else
    ind =1:length(L);
    workbar(.99,['Loaded ' num2str(length(A)) ' new earthquakes!'])
end

%%
pause(1)

year = A(ind);
year(year>60 & year <100) = year(year>60 & year<100)+1900; %make two digit conversion for older catalogs
year(year<60 )            = year(cmt.year<60)+2000;        %
jjj = dayofyear(year',B(ind)',C(ind)')'; %julian day

cmt.year     = [cmt.year;   year];
cmt.month    = [cmt.month;  B(ind)];
cmt.day      = [cmt.day;    C(ind)];
cmt.jjj      = [cmt.jjj;    jjj];
cmt.hour     = [cmt.hour;   D(ind)];
cmt.minute   = [cmt.minute; E(ind)];
cmt.sec      = [cmt.sec;    F(ind)];
cmt.lat      = [cmt.lat;    G(ind)];
cmt.long     = [cmt.long;   H(ind)];
cmt.depth    = [cmt.depth;  I(ind)];
cmt.Mb       = [cmt.Mb;     J(ind)];
cmt.MS       = [cmt.MS;     K(ind)];
M0=O(ind).*10.^N(ind);%[scalar_magnitude*10^(exponent)]
Mw=log10(M0)/1.5 - 10.73; %Mw, following Kanamori (1977)
cmt.M0       = [cmt.M0;     M0 ]; %
cmt.Mw       = [cmt.Mw;     Mw ];

cmt.region   = [cmt.region;  char(L(ind))];
cmt.ID       = [cmt.ID;      char(M(ind))];
cmt.strike   = [cmt.strike;  P(ind) ];
cmt.dip      = [cmt.dip;     Q(ind) ];
cmt.rake     = [cmt.rake;    R(ind) ];

workbar(1)


%%




%%
%save datebase:
[FileName,PathName] = uiputfile('*.mat','Save Catalogue', default_file);
if ischar(FileName)
    fname=fullfile(PathName,FileName);
    save(fname,'cmt')
    
     last= datestr([A(end), B(end),C(end), D(end),E(end), F(end)]);
    helpdlg({['File "' fname '" with ' num2str(length(cmt.year)) ' earthquakes sucsessfully written'],' ' ,...
            ['Last earthqauke in QuickCMT file:   ' last] }, 'Update sucsess')
end
% end

if nargout==1
    varargout{1}=cmt;
end


