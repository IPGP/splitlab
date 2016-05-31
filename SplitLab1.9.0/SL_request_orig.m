function SL_request
%create file for earthquake data request.
% The standard mail client of the computer is being opened to sent a seismgramm
% request. Furthermore, the requst is saved in a text file as defined by 
% the global variable fullfile(config.savedir, config.project '.req')
% Supported :  NetDC, breqFast, AutoDRM and plain text
% the user can add custom formats 

%  by A. Wuestefeld,
%  Univ. Montpellier, France
%  10.03.2005

% Added on 12.04.06: relative phase time support


global config eq

if ~strcmp(config.request.usermail(end-2),'.') ...
        && ~strcmp(config.request.usermail(end-3),'.')...
        || isempty(findstr('@',config.request.usermail))
    errordlg({config.request.usermail, 'is not a valid reply email adress.', 'Please check!'}, 'Email error')
    return
end

if isempty(config.request.institut) 
    errordlg({'Please give information about your institution.', 'Please check!'}, 'Email error')
    return
end


filen= fullfile(config.savedir,[config.project '.req']);
if exist(filen,'file')==2
    qstring={filen,'already exist....'};
    button = questdlg(qstring,'File exist','Overwrite','Save As','Cancel','Cancel');
    if strcmp(button,'Cancel'), 
        return,
    elseif strcmp(button,'Save As')
      [fname, pname] = uiputfile('*.req','Request file',filen);
      if ~fname
          return
      else 
          filen = fullfile(pname,fname);
      end
    end
    
end

%% define request times
date=zeros(length(eq),7);
for a=1:length(eq); 
    date(a,:)=[eq(a).date(1) eq(a).date(2) eq(a).date(3) eq(a).date(4) eq(a).date(5) eq(a).date(6) eq(a).date(7)];
end

d = datenum(date(:,1), date(:,2), date(:,3), date(:,4), date(:,5),0);

pretime  = datenum(0,0,0,0,0,config.request.reqtime(1)); 
duration = datenum(0,0,0,0,0,config.request.reqtime(2)); 
reqstart = round(datevec(d-pretime));
reqend   = round(datevec(d+duration)); 

switch config.request.format
    case 'NetDC'
        %example:
        %.DATA * NTW STN * BH? "2000 12 24 12 15 00 " "2000 12 24 12 55 00"
        fmt  = '%4.0f %02.0f %02.0f %02.0f %02.0f 00';
        %        yy    mm     dd     HH      MM   SS
        formatstr =['.DATA * ' config.netw ' ' config.stnname ' * ' config.request.comp ' "' fmt '" "' fmt '"\n'];
        message=[...
            sprintf('.NETDC_REQUEST\n'),...
            sprintf('.NAME %s\n',config.request.user),...
            sprintf('.INST %s\n',config.request.institut),...
            sprintf('.EMAIL %s\n',config.request.usermail),...
            sprintf('.LABEL %s\n',config.project),...
            sprintf('.DISPOSITION PULL\n'),...
            sprintf('.END\n'),...
            sprintf( formatstr, [reqstart(:,1:5),reqend(:,1:5)]')];%Data lines
          message=message(1:end-1);%delete last newline character 
    case 'BreqFast'
        %example:
        %NNX  II 1999 01 04 02 41 57.5 1999 01 04 02 43 57.5  1 BH?
        fmt  = ' %4.0f %02.0f %02.0f %02.0f %02.0f 00.0 ';
        formatstr =[config.stnname ' ' config.netw  fmt fmt ' 1 ' config.request.comp '\n'];
        message=[...
            sprintf('.NAME %s\n',  config.request.user) ,...
            sprintf('.INST %s\n',  config.request.institut),...
            sprintf('.MAIL %s\n',  config.request.adress),...
            sprintf('.EMAIL %s\n', config.request.usermail),...
            sprintf('.PHONE %s\n', config.request.phone),...
            sprintf('.FAX %s\n',   config.request.fax),...
            sprintf('.MEDIA FTP\n'),...
            sprintf('.ALTERNATE MEDIA MEDIA 1/2" tape - 6250\n'),...
            sprintf('.ALTERNATE MEDIA EXABYTE\n'),...
            sprintf('.LABEL %s\n', config.project),...
            sprintf('.QUALITY B\n'),...
            sprintf('.END\n'),...
            sprintf( formatstr, [reqstart(:,1:5),reqend(:,1:5)]')];
    case 'AutoDRM (iris)'
        fmt  = '%4.0f/%02.0f/%02.0f %02.0f:%02.0f:00';
        %        yy    mm     dd     HH      MM   SS
        formatstr =['TIME ' fmt ' TO ' fmt '\n'];
        message = [];
        for i=1:length(eq)
        message=[message;
            sprintf('BEGIN GSE2.0\n'),...
            sprintf('MSG_TYPE REQUEST\n'),...
            sprintf('MSG_ID %s dummy\n',    config.request.user),...
            sprintf('EMAIL %s\n',     config.request.usermail),...
            sprintf('FTP %s\n',     config.request.usermail),...
            sprintf('CHAN_LIST %s\n',  config.request.comp),...
            sprintf('STA_LIST %s\n',  config.stnname),...sprintf('.AUX_LIST *\n'),...
            sprintf(formatstr, [reqstart(i,1:5),reqend(i,1:5)]'),...
            sprintf('WAVEFORM SEED\n'),...
            sprintf('STOP\n\n')];
        end
        message=message';
    case 'ASCII table'
        header    = sprintf('   lat   long   depth  Mw Year JJJ MM DD hh mm ss  bazi  dis\n');
        formatstr = '%7.2f %7.2f %5.1f %3.1f %4.0f %3.0f %02.0f %02.0f %02.0f %02.0f %02.0f %5.1f %5.1f\n';
        message   = sprintf( formatstr, [...
                             [eq(:).lat]', [eq(:).long]', [eq(:).depth]', [eq(:).Mw]',...
                              date(:,1), date(:,7), date(:,2), date(:,3), ...
                              date(:,4), date(:,5), date(:,6),...
                              [eq(:).bazi]' [eq(:).dis]' ]');
        message =[header message];

end

%% write request file
try
    fid = fopen(filen,'w');
    fprintf(fid,message);
    fclose(fid);
catch
    beep
    errordlg({'Can''t write file ' filen})
    return
end

    
%% Mail section
clip=0;
mailsubject = [config.project '-data-request'];
button      = questdlg({'Created request: ', filen,' ','Send request ?'},'Send mail','Mail client', 'View request','Later','Mail client');
switch button
    case 'Later'
        disp('Please send request manually')
    case 'View request'
        edit(filen)  
    case 'Mail client' 
        L = length(eq);
        if L>150 & ~strcmp('ASCII table',config.request.format)
            beep
          w =  warndlg({['Your request is very big (' num2str(L) ' earthquakes).'],'',...
                'The datacenters will process your request faster,'...
                'if you split your request and send several mails.'...
                'Each mail should contain only approximately 150 earthquakes.'},'Warning');
            waitfor(w)
        end
        edit(filen)
        web(['mailto:' config.request.mailto ...  % adress of datacenter
            '?subject=' mailsubject], ...       % subject of mail       
            '-helpbrowser'); 
       
        clipboard('copy', message(:)')
        clip = 1;
end

%% save .ini file
config.request.timestamp=datestr(now);
diaryname=strrep(filen,'.req','.ini');
diary(diaryname)
diary on
%disp(config)
disp('config.request=')
disp(config.request)
disp(['Number of requested earthquakes : ' num2str(length(eq))])
diary off

if clip
        disp(' ')
        disp('Request text has been copied to the system clipboard.')
        disp('You can paste it to your mail client');
        disp(' ')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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