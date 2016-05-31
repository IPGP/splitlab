function database_editResults(option)
global eq config

r_box = findobj('tag','ResultsBox');
l_box = findobj('tag','TableList');
rbut  = findobj('Tag','ResultsButton');


lval = get(l_box,'Value');
rval = get(r_box,'Value');

L = get(r_box,'Userdata'); %get displayed results sturcture
switch option
    case 'del'
        button = questdlg('Do you want to delete this result from database?','Confirm delete','Yes','No','Yes');
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

            tmp  = L(L<=rval); %substract header lines from list index
            num  = lval(length(tmp));    %to retrieve index of eq
            val  = rval - tmp(end);      %index of result of eq(num)
            val2 = 1:length(eq(num).results);
            new  = setdiff(val2, val);   %result index different from selected one
            if isempty(new)
                eq(num).results=[];
            else
                eq(num).results = eq(num).results(new);
            end
            %eq(num).results(new);


            str = get(r_box,'String'); % to update text
            len = 1:size(str,1);
            new = len(len~=rval);
            newstr = str(new,:);
            newidx = L(L>rval)-1;
            tmp2 = [tmp, newidx];
            set(r_box,'String',newstr, 'Userdata',tmp2, 'Value',rval-1);

            filename    = fullfile(config.projectdir,config.project);
            save(filename,'eq','config');
            %helpdlg('Result files might still be in the output directory')
        end

    case 'Edit'
        tmp = L(L<rval);
        if isempty(tmp); return; end %nothing selected
        num = lval(length(tmp)); %to retrieve index of eq
        val = rval - tmp(end);   %index of result of eq(num)

        openvar(['eq(' num2str(num) ').results(' num2str(val) ')'])


    case 'select'
        if any(rval == L)
            set(rbut,'Enable','off');
        else
            set(rbut,'Enable','on');
        end

    case 'View'
        tmp = L(L<rval);
        if isempty(tmp); return; end %nothing selected
        num = lval(length(tmp)); %to retrieve index of eq
        val = rval - tmp(end);   %index of result of eq(num)
        resplot =fullfile(config.savedir, eq(num).results(val).resultplot);
        if ispc
            try
                winopen(resplot);
            catch

                e=errordlg({resplot,' ' , lasterr,'',...
                    'Project has been processed one the Computer named',...
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
            asso      = getpref('Splitlab', 'Associations');
            [p,f,ext] = fileparts(resplot);
            found     = strfind(asso(:,1),ext);
            index     = find(~cellfun('isempty',found));
            if strcmp (ext, '.fig');
                commandline = 'open($1);';
            else
                commandline   = ['!' asso{index, 2}];
            end

            commandstring = strrep(commandline, '$1', resplot);
            if strncmp(computer,'MAC',3)
                errordlg('Does not yet work for MACINTOSH... sorry')
                return;
                %need of OSAscript on MACINTOSH:
                commandstring = strrep(commandstring, '!', '!osascript');
            end





            try
                eval(commandstring)
            catch
                e=errordlg({ 'Could not run ', commandstring(2:end),' ',lasterr});
                waitfor(e)
                web(resplot, '-browser')
            end
        end



        %% ========================================================================
    case 'cleanup'
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
