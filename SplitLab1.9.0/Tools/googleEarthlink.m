function googleEarthlink(lat, long, Name,File,description)
%generate GoogleEarth Placemark at specified location

if ~iscell(Name)
    Name={Name};
end

if ~iscell(description)
    description=cellstr(description);
end
description = strrep(description,'&','&amp;');
description = strrep(description,'<','&lt;');
description = strrep(description,'>','&gt;');

fid = fopen(File,'w');
fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid,'<kml xmlns="http://earth.google.com/kml/2.0">\n');
if length(lat)>1
    fprintf(fid,'    <Folder>\n');
    fprintf(fid,'    <open>1</open>\n');
    fprintf(fid,'      <name>SplitLab</name>\n');
end

for k=1:length(lat)
    fprintf(fid,'      <Placemark>\n');
    if ~isempty(description)
        fprintf(fid,'      <description><![CDATA[<b>Lat: %f   Long: %f </b> ',lat(k),long(k));
        for m=1:length(description)
        fprintf(fid,'        <br>%s\n ',description{m}');
        end
        fprintf(fid,'        ]]></description>\n');
    end
    fprintf(fid,'      <name>%s</name>\n',Name{k});
    fprintf(fid,'      <LookAt>\n');
    fprintf(fid,'        <longitude>%f</longitude>\n',long(k));
    fprintf(fid,'        <latitude>%f</latitude>\n',lat(k));
    fprintf(fid,'        <range>35000.</range>\n');
    fprintf(fid,'        <tilt>40.</tilt>\n');
    fprintf(fid,'        <heading>0</heading>\n');
    fprintf(fid,'      </LookAt>\n');
    fprintf(fid,'      <visibility>1</visibility>\n');
    fprintf(fid,'      <open>1</open>\n');
    fprintf(fid,'      <styleUrl>#khStyle652</styleUrl>\n');
    fprintf(fid,'      <Style>\n');
    fprintf(fid,'       <IconStyle>\n');
    fprintf(fid,'          <Icon>\n');
    fprintf(fid,'            <href>root://icons/palette-3.png</href>\n');
    fprintf(fid,'            <x>224</x>\n');
    fprintf(fid,'            <y>128</y>\n');
    fprintf(fid,'            <w>32</w>\n');
    fprintf(fid,'            <h>32</h>\n');
    fprintf(fid,'          </Icon>\n');
    fprintf(fid,'        </IconStyle>\n');
    fprintf(fid,'      </Style>\n');
    fprintf(fid,'      <Point>\n');
    fprintf(fid,'        <extrude>0</extrude>\n');
    fprintf(fid,'        <tessellate>0</tessellate>\n');
    fprintf(fid,'        <altitudeMode>clampToGround</altitudeMode>\n');
    fprintf(fid,'        <coordinates>%f,%f,0</coordinates>\n',long(k),lat(k));
    fprintf(fid,'      </Point>\n');
    fprintf(fid,'    </Placemark>\n');
end
if length(lat)>1
    fprintf(fid,'    </Folder>\n');
end

fprintf(fid,'</kml>');
fclose(fid);


%%
if ispc
    Answer=questdlg({'Placemarker file witten to disk!',File, ' ',...
        'Do you want to start GoogleEarth?'}, ...
        'Start Google', ...
        'Yes','No','Yes');
    switch Answer
        case 'Yes'
            if ispc
                try
                    winopen(File)
                catch

                    errordlg({'Problems opening file ', File, ...
                        'The system error message is:',...
                        ' ' ,['"' lasterr '"'],' ',...
                        'Do you have GoogleEarth installed??'})
                end
            else
                asso      = getpref('Splitlab','Associations');
                [p,f,ext] = fileparts(File);
                found     = strfind(asso(:,1),ext);
                index     = find(~cellfun('isempty',found))
                if strcmp (ext, '.fig');
                    commandline = 'open($1);';
                else
                    commandline   = ['!' asso{2,index}];
                end
                commandstring = strrep(commandline, '$1', File);
                try
                    eval(commandstring)
                catch
                    e=errordlg({ 'Could not run ', commandstring(2:end),' ',lasterr});
                    waitfor(e)
                end
            end
    end
else
    helpdlg({'Placemarker file witten to disk!',File})
    disp('Placemarker file witten to disk:')
    disp(File)
end

