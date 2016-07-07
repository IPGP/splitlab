function database_editResults(option)
global eq config

r_box = findobj('tag','ResultsBox');
l_box = findobj('tag','TableList');
rbut  = findobj('Tag','ResultsButton');


lval = get(l_box,'Value');
rval = get(r_box,'Value');

L = get(r_box,'Userdata'); %get displayed results sturcture
switch option
    case 'Del'
        button = questdlg({'Do you want to delete this result from database?';'(Also result image and line in ''splitresults*_STAT.dat''-file)'},'Confirm delete','Yes','No','Yes');
        if strcmp(button,'Yes')
            seisfig = findobj('Tag','SeismoFigure');
            if ~isempty(seisfig)
                warndlg(...
                    {'Please close the SeismoViewer to perfom this operation!',...
                    'An open SeismoViewer may cause database conflicts.',...
                    'Please excuse this inconvenience'},...
                    'Close SeismoViewer!');
                return
            end
            tmp  = L(L<=rval);                      %substract header lines from list index
            num  = lval(length(tmp));               %to retrieve index of eq
            val  = rval - tmp(end);                 %index of result of eq(num)
            val2 = 1:length(eq(num).results);
            new  = setdiff(val2, val);              %result index different from selected one
            old_result = eq(num).results(val);       %assigned to use later
            if isempty(new)
                eq(num).results=[];
            else
                eq(num).results = eq(num).results(new);
            end
            
            % to update text
            str = get(r_box,'String');              
            len = 1:size(str,1);
            new = len(len~=rval);
            newstr = str(new,:);
            newidx = L(L>rval)-1;
            tmp2 = [tmp, newidx];
            set(r_box,'String',newstr, 'Userdata',tmp2, 'Value',rval-1);

            %%%%% result strings for later
            %disp( old_result );
            date_compare = sprintf('%04d-%02d-%02d %02d:%02d:', eq(num).date(1),eq(num).date(2),eq(num).date(3),eq(num).date(4),eq(num).date(5) ); % for later
            pha     = old_result.SplitPhase;
            q_auto  = sprintf('%0.4f',old_result.Q);
            q_manu  = old_result.Qstr;

            %%%%% save project with updated results
            filename    = fullfile( config.projectdir,config.project );
            save(filename,'eq','config');
            %helpdlg('Result files might still be in the output directory')
            
            %%%%% delete corresponding '*eps' result image in
            %%%%% 'config.projectdir'  - JRS 1/7/2016
            filename_eps = old_result.resultplot; 
            fullname_eps = fullfile( config.savedir,filename_eps );
            
            %case not found, catch warning
            s = warning('error', 'MATLAB:DELETE:FileNotFound');    
            try
                delete( fullname_eps );
                mess = sprintf('\nDeleted result image:\n%s\n', fullname_eps);
                disp( mess );
            catch
                mess = sprintf('Result image to delete not found:\n%s\n', fullname_eps);
                disp( mess );            
            end
            warning(s);

            %%%%% delete corresponding line in 'splitresults*_STAT.dat'
            %%%%% file in 'config.projectdir' - JRS 1/7/2016
            % if Null or none Null measurement
            if ~isempty( strfind(q_manu,'Null') )      
                fname = sprintf('splitresultsNULL_%s.dat', config.stnname);
            else
                fname = sprintf('splitresults_%s.dat', config.stnname);
            end
            fullname_dat = fullfile(config.savedir,fname);

            % read 'fullname_dat' file
            fileID = fopen( fullname_dat );
            file = textscan(fileID,'%s', 'Delimiter','\n', 'HeaderLines',0);
            fclose( fileID );
            [nn,m] = size( file{1} );   %nn = #rows of cell array 'file'
            
            % open 'fullname_dat' and write all lines but the one to delete
            fileID = fopen(fullname_dat,'w');
            mess = sprintf('Following measurements deleted in ''%s'':', fname);
            disp( mess );
            
            % loop over measurements in file, disp line to delete, print to
            % file all others
            for line_index = 1:nn
                line      = file{1}{line_index};    % get 'q_comare' in file and round
                string    = strsplit( line );
                q_compare = sprintf('%0.4f', round( str2double( string(35) ),4));
                if ~isempty(strfind(line,date_compare)) && ~isempty(strfind(line,pha)) ...
                        && ~isempty(strfind(line,q_manu)) && ~isempty(strfind(q_compare,q_auto)) 
                    disp( line );
                    break;      % case more than 2 identical lines, only one deleted
                else
                    fprintf(fileID,'%s\n', line);
                end
            end
            fclose( fileID );
        end

    case 'Edit'
        tmp = L(L<rval);
        if isempty(tmp); return; end %nothing selected
        num = lval(length(tmp)); %to retrieve index of eq
        val = rval - tmp(end);   %index of result of eq(num)
        openvar(['eq(' num2str(num) ').results(' num2str(val) ')'])

    case 'Select'
        if any(rval == L)
            set(rbut,'Enable','off');
        else
            set(rbut,'Enable','on');
        end

    case 'View'
        tmp = L(L<rval);
        if isempty(tmp); return; end %nothing selected
        num     = lval(length(tmp)); %to retrieve index of eq
        val     = rval - tmp(end);   %index of result of eq(num)
        resplot = fullfile(config.savedir, eq(num).results(val).resultplot);

        if ispc
            try
                winopen(resplot);
            catch

                e=errordlg({resplot,' ' , lasterr,'',...
                    'Project has been processed on the Computer named',...
                    [config.host ' by ' config.request.user],...
                    ['Data request timstamp: ' config.request.timestamp],' ',lasterr },...
                    'Error opening file');
                waitfor(e)
                [filename, pathname] = uigetfile(['*' config.exportformat], 'Search result plot',eq(num).results(val).resultplot);
                if isequal(filename,0)
                else
                    try
                        winopen( fullfile(pathname, filename))
                    catch
                        errordlg( lasterr,'Error')
                    end
                end
            end
        else %UNIX, LINUX or MACINTOSH
            asso          = getpref('Splitlab','Associations');
            [p,f,ext]     = fileparts(resplot);
            found         = strfind(asso(:,1),ext);
            index         = find(~cellfun('isempty',found));
            commandstring = sprintf('!%s %s', asso{index, 2}, resplot);
            
            try
                eval(commandstring)
            catch
                e=warndlg( {lasterr} );
                waitfor(e)
                web(resplot, '-browser')
            end
        end



        %% ========================================================================
    case 'Cleanup'
        for i = 1 : length(eq)
            x(i)=~isempty(eq(i).results);
        end
        res = find(x==1) ;

        button = questdlg({'All earthquakes with no results will be removed from database!',...
            ['  ' num2str(length(res)) '   earthquakes with result'],...
            ['  ' num2str(length(eq)-length(res)) '   earthquakes with no result']},...
            'Confirm delete','Go','Cancel','Cancel');
        if strcmp(button,'Go')
            eq=eq(res);
            config.db_index=1;
            beep
            w = warndlg('Please save the new database!!');
            waitfor(w)

            earth = findobj('Type','Figure','Tag','EarthView');
            close(earth)
            SL_databaseViewer
        end

end
