function localTrash(hFig,evt)
global config thiseq eq


button = questdlg({'The current earthquake will be removed', 'from this project database.', 'Are you sure?'}, ...
    'Remove earthquake','Yes','Cancel','Yes');
switch button
    case 'Yes';
        fname = fullfile(config.savedir,['trashfiles_' config.stnname '.log' ]);
        fid   = fopen(char(fname),'a+');
        fprintf(fid,'%s\n%s\n%s\n',thiseq.seisfiles{1}, thiseq.seisfiles{2}, thiseq.seisfiles{3});
        fclose(fid);
        
        if ispc
            try
                pathstr = fileparts(mfilename('fullpath'));
                [y,Fs,bits] = wavread(fullfile(pathstr, 'Papierkorb.wav'));
                wavplay(y*2,Fs,'async' )
            end
        end

        idx = thiseq.index;
        L   = [1:idx-1 idx+1:length(eq)];        
        eq  = eq(L);
        SL_SeismoViewer(idx)
        
        databaseViewer = findobj('Type','Figure', 'Name','Database Viewer');
        if ~isempty(databaseViewer)
           SL_databaseViewer
        end
        
    case 'Later'
end




