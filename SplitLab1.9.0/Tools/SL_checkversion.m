%SL_checkversion
global config
if not(ispref('Splitlab'))
    SL_preferences([])
    SplitlabConfiguration = getpref('Splitlab','Configuration');
    SplitlabAssociations  = getpref('Splitlab','Associations');
    SplitlabHistory       = getpref('Splitlab','History');
    disp(' **** Splitlab Preferences sucessfully created ****')
end

if isempty(config)
    evalin('base','global eq thiseq config');
    config = getpref('Splitlab', 'Configuration');   
    d=datevec(now);
    config.twin = [3 1 1976 d([3 2 1])];
end



default  = SL_defaultconfig;
N    = fieldnames(default) ;

updated=struct([]);
%% set non existing fields to default values
for k = 1:length(N)
    thisfield = N{k};
    if ~strcmp(thisfield,'version')
        
        
        if ~isfield(config, thisfield)
            config.(thisfield)     = default.(thisfield);
            updated(1).(thisfield) = default.(thisfield);
        else
            
            
            
            if isstruct(default.(thisfield))
                    NN    = fieldnames(default.(thisfield)) ;
                for kk = 1:length(NN)
                    thissubfield = NN{kk};
                    if ~isfield(config.(thisfield), thissubfield)
                        config.(thisfield).(thissubfield)     = default.(thisfield).(thissubfield);
                        updated(1).(thisfield).(thissubfield) = default.(thisfield).(thissubfield);
                    end
                end
            end
            
        end
    end
end

    
%%    
    
if size(config.filterset,2)==4;               config.filterset(:,5)=1;          end


if ~isempty(updated)
    disp(' ')
    disp('Project version does not match the current splitlab version!')
    disp('The following fields are added to or updated in your configuration:')
    disp(' ')
    disp('  config')
    strucdisp(updated,2,1,7)
end

%% check preferences
% this is necessary on multiuser environments. 
if ~ispref('Splitlab')
    SL_preferences(SL_defaultconfig)
end
if ~ispref('Splitlab','History')
    addpref('Splitlab','History', {})
end


%% check for weired xcorr error on MAC

z1 = [0 0 1 0 0];
z2 = [0 1 0 0 0];
C = xcorr(z1,z2, 'coeff');

[a,b] = max(C);


if a==1     && b==6
    config.isWeiredMAC = 0;
elseif a==1 && b==4
    config.isWeiredMAC = 1;
    warning('MATLAB:xcorr',['Your seems to have an issue with the Cross-Correlation function.\n'...
        ' <a href="http://www.gm.univ-montp2.fr/splitting/MACandXCORR.html">MORE HELP</a>\n'...
        'Please contact the SplitLab Team'])
else
    error('Cross-correlation function behaves even more weired than expected. Please contact the SplitLab Team')
end