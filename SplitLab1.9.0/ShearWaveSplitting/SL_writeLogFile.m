function SL_writeLogFile(option, config, thiseq)
% OPTION='LOG'  writes the constant logfile for every atemptped splitting measurement
% OPTION='DATA' writes the datafile for accepted measurements
% see ./saveresults



    DATE  = sprintf('%4.0f.%03.0f',thiseq.date(1),thiseq.date(7));
    switch upper(option)
        case 'LOG'
            fname = [config.savedir, filesep, 'all_results_',config.project(1:end-4),'.log'];
        case 'DATA'
            if strcmp(thiseq.Qstr(5:8),'Null')
                fname = fullfile(config.savedir,['splitresultsNULL_' config.project(1:end-4) '.dat' ]);
            else
                fname = fullfile(config.savedir,['splitresults_'     config.project(1:end-4) '.dat' ]);
            end
        otherwise
            warning('Unknown log file option. Skipping...')
    end
            
    
    xst   = exist(fname, 'file');
    fid   = fopen(fname,'a');
    if fid ==-1
        errordlg ({'Problems while opening logfile:',fname,' ', 'Please check output directory'})
    else
%         if ~xst;
%             fprintf(fid,'Splitting results' );
%             fprintf(fid,'\ndate     sta  phase  geobaz    baz   inc    filter    RC                       dtRC             SC                       dtSC             EV                       dtEV            autoQ\n' );
%         end
        fseek(fid, 0, 'eof'); %go to end of file
  
       fields = {...
           sprintf( '%s', datestr(thiseq.date(1:6),31)   )   ...    1    Date
           sprintf( '%s', config.stnname                 )   ...    2    StationName
           sprintf( '%f', config.slat                    )   ...    3
           sprintf( '%f', config.slong                   )   ...    4
           sprintf( '%f', config.selev                   )   ...    5
           sprintf( '%f', thiseq.lat                     )   ...    6
           sprintf( '%f', thiseq.long                    )   ...    7
           sprintf( '%f', thiseq.depth                   )   ...    8
           sprintf( '%f', thiseq.dis                     )   ...    9
           sprintf( '%f', thiseq.Mw                      )   ...   10
            ...            
           sprintf( '%f', thiseq.geoinc                  )   ...   12                                              
           sprintf( '%f', thiseq.geobazi                 )   ...   13
           sprintf( '%f', thiseq.bazi                    )   ...   14
           sprintf( '%f', thiseq.geodis3D                )   ...   15
           sprintf( '%s', thiseq.SplitPhase              )   ...   16
           sprintf( '%f', thiseq.selectedpol             )   ...   17
           sprintf( '%f', thiseq.selectedinc             )   ...   18
           sprintf( '%f', thiseq.filter(1)               )   ...   19            
           sprintf( '%f', thiseq.filter(2)               )   ...   20
            ...
           sprintf( '%f', thiseq.tmpresult.phiRC(1)      )   ...   21
           sprintf( '%f', thiseq.tmpresult.phiRC(2)      )   ...   22
           sprintf( '%f', thiseq.tmpresult.dtRC(1)       )   ...   23
           sprintf( '%f', thiseq.tmpresult.dtRC(2)       )   ...   24
           sprintf( '%f', thiseq.tmpresult.phiEV(1)      )   ...   25
           sprintf( '%f', thiseq.tmpresult.phiEV(2)      )   ...   26 
           sprintf( '%f', thiseq.tmpresult.dtEV(1)       )   ...   27
           sprintf( '%f', thiseq.tmpresult.dtEV(2)       )   ...   28
           sprintf( '%f', thiseq.tmpresult.strikes(1)    )   ...   29 RC strike
           sprintf( '%f', thiseq.tmpresult.strikes(3)    )   ...   30 EV strike
            ...
           sprintf( '%f', thiseq.tmpresult.dips(1)       )   ...   31
           sprintf( '%f', thiseq.tmpresult.dips(3)       )   ...   32
           sprintf( '%f', thiseq.tmpresult.inipol        )   ...   33
           sprintf( '%f', thiseq.tmpresult.SNR(2)        )   ...   34
           sprintf( '%f', thiseq.Q                       )   ...   35 Automatic quality
           sprintf( '%s', thiseq.Qstr                    )   ...   36 Manual quality
           sprintf( '%s', thiseq.tmpresult.domfreq       )   ...   37 Dominant frequency on EV-corrected Q-component
            } ;
        
        
        fprintf(fid, '%s\t', fields{1:end-1});
        fprintf(fid, '%s', fields{end}); %no "tab" at last entry
        fprintf(fid, '\n');
        fclose(fid);
    end
   
    
    
    
    %%
    function fields = possibleFields
        global config thiseq

        
        