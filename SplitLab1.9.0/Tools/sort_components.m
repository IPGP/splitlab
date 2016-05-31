function [outfiles,id] = sort_components(filelist)
%sort filelist such that seismograms are ordered as East, North, Vertical
%

global config


for n=1:length(filelist)
    %comp = lh(filelist(n),'KCMPNM')
    fstr = char(filelist(n));

    switch config.FileNameConvention
        case 'RDSEED'
            % 2012.169.20.32.00.0150.YV.EURO.00.BHE.M.SAC
            %dynamic searching, since sometime a quality letter is given...
            dot  = findstr(fstr,'.');
            pos  = dot(end-1) - 1;
            pos = 37;
            % letter position of Component descriptor in filename
            % here: letter before second but last point
            % use for last letter: comp = fstr(end);
            % eg: 1994.130.06.35.24.9000.GR.GRA1..BHZ.D.SAC
            %     dot is [5 9 12 15 18 23 26 31 32 36 38]
            %     thus, pos would be 35
            
        case 'miniSEED'
            dot = strfind(fstr,'.');
            %pos = dot(end-2)-1;
            pos = 14; % modified GB april 2016
            
        case 'RHUM-RUM'
        % miniSEED format 'YV.RR39.00.BH1.M.2012.318.221725.SAC' 36 car
            dot = strfind(fstr,'.');
            pos = dot(end-4)-1; % modified JRS May 2016
            % display(fstr(pos));

        case 'YYYY.MM.DD.hh.mm.ss.stn.E.sac'
            pos =25;
            
        case 'SEISAN'
            pos = length(fstr)-5;
        
        case {'YYYY.MM.DD-hh.mm.ss.stn.sac.e', 'YYYY.JJJ.hh.mm.ss.stn.sac.e', '*.e; *.n; *.z', 'stn.YYMMDD.hhmmss.e', 'YYYY_MM_DD_hhmm_stnn.sac.e'}
            pos = length(fstr); %using last letter
        
        otherwise
                error('Component descriptor unknown! Aborting')
                return
    end
    

    comp = fstr(pos);
    switch upper(comp)
        case 'E'
            i=1;
        case '2'  % modified JRS May 2016
            i=1;
            display('WARNING:  2-component assumed as "East"');

        case 'N'
            i=2;
        case '1'  % modified JRS May 2016
            i=2;
            display('WARNING:  1-component assumed as "North"');
            
        case 'Z'
            i=3;
        otherwise
            thisfile = mfilename('fullpath');
            thisfile = strrep(thisfile, '\','\\');
            commandwindow
            error(strcat([' Unknown component description "' comp '" in file:\n'],...
                ['     ' fstr(1:pos-1) '<a href="">' fstr(pos) '</a>' fstr(pos+1:end)] ,...
                ['\n Assumed letter position of Component indicator: ' num2str(pos)],...
                [ '\n error in <a href="matlab:edit(''' thisfile ''')">sort_components</a>']),'\n')
    end
    
    outfiles(i)=filelist(n);
    id(i)=n;
end