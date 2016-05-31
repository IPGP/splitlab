%%
function out = checkmattaupclass
global thiseq eq config



jpath = javaclasspath('-all');
f     = strfind(jpath,'matTaup.jar');
e     = cellfun('isempty',f);
pjt   = ~isempty(config);


if all(e) % no match found in classpath
    % => we assume matTaup is on PATH variable
    p = fileparts(which('taup.m'));
    if isempty(p)
        disp('Error: Could not establish matTaup java path. No phases will be calculated.')
        out = false;
        return
    else
        if pjt
            thisprj = fullfile(config.projectdir, config.project);
        end


        fprintf(2,'The matTaup JAVA Classes will now be loaded.\n')
        fprintf(2,'Please wait...')

        if exist([p  filesep 'matTaup.jar'],'file')
        javaaddpath([p  filesep 'matTaup.jar'])
        else
            disp('Error: Could not find MATTAUP.JAR')
            out =0;
            return
        end


        evalin('base','global eq thiseq config');
        evalin('caller','global eq thiseq config') %these have been cleard previously by javaaddpath....
        if pjt
            
            load('-mat',thisprj)
            assignin('caller', 'config', config);
            assignin('caller', 'eq', eq);
        end
        fprintf(2,' Done\n')
        fprintf(2,'Java classes of matTaup have been loaded for this session of Matlab.\n')
        fprintf(2,'You can now continue with your work\n\n')

        out=-1;
    end
else
    out =true;
end