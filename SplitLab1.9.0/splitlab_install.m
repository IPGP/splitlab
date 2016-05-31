function splitlab_install
beep





fprintf('\n')
fprintf('\n')
fprintf('\n')
fprintf(2,'===============================================================\n')
fprintf('Installation is not neccesary! \n')
fprintf('Simply add the splitlab folder and its sub-folders to your matlab path, \n')
fprintf('and type splitlab on the command line! \n')
fprintf('\n')
fprintf('Linux, Unix and MAC user may want to add this to your .bashrc: \n')
fprintf('   #SPLITLAB \n')
fprintf('   alias splitlab=''cd; matlab -nodesktop -r splitlab''  \n')
fprintf('\n')
fprintf('PC users can register splitlab projects and SAC files with their system\n')


%% $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
reply='';
while isempty(strfind('YN',upper(reply)))
    reply = input('Do you want to create a link in your startup sequence? Y/N [Y]: ', 's');
    if isempty(reply)
        reply = 'Y';
    end
end
% if strcmpi(reply,'Y')
%     [path,sufile]=fileparts(which('startup.m'));
%     if isempty(sufile)
%         if ispc
%             path= [matlabroot '\work'];
%         else
%             path=pwd;
%         end
%         sufile='startup';
%     end
%     fid=fopen([path filesep sufile '.m'],'a+');
%     fprintf(fid , '\ndisp('' <a href="matlab:splitlab">Run SplitLab</a>'')\n');
%     fclose(fid);
%     disp(['Link created in ' path filesep sufile '.m']);
% end


%%
if ispc
    reply='';
    while isempty(strfind('YN',upper(reply)))
        reply = input('Do you want to register .PJT and .SAC files? Y/N [Y]: ', 's');
        if isempty(reply)
            reply = 'Y';
        end
    end
    if strcmpi(reply,'N')
        fprintf('Thank you for using splitlab\n')
        fprintf('\n')
        fprintf('\n')
        return
    end
end

%% Registering SAC-files and Splitlab-projects (Windows only)
if strcmpi('MAC',computer)
    disp('http://9stmaryrd.com/2008/05/16/158')
end

if ispc
%     [a,b]= dos('ftype SplitLabProject');
%     if a==2  %Does not exist in registry


        [pathstr,name,ext,versn] = fileparts(mfilename('fullpath'));
        disp(' ')
        disp(' ')
        disp('Registering SplitLab-Project Files: ')
        dos('assoc .pjt=SplitLabProject');
        dos('assoc .sac=SACfile');
%         [xxx,xxx] = dos(['ftype SACfile=']);
        dos(['ftype SplitLabProject=' matlabroot '\bin\win32\matlab.exe -minimize -memmgr fast -r openpjt(''"%1"'');"global thiseq";splitlab']);
        disp(' ')
        disp(' ')
        disp('registering SAC- and PJT-icons:')
        disp('SplitlabProject')
        dos(['reg add HKCR\SplitLabProject\DefaultIcon /ve /f /d "' pathstr '\Tools\project.ico"']);
        disp(' ')
        disp(' ')
        disp('SAC')
        dos(['reg add HKCR\SACfile\DefaultIcon /ve /f /d "' pathstr '\Tools\sacfile.ico"']);
        %     disp('registering file types:')
        [xxx,xxx] = dos(['reg add HKCR\SplitLabProject /ve /f /t REG_SZ /d "SplitLab Project"']);
        [xxx,xxx] = dos(['reg add HKCR\SACfile /ve /f /t REG_SZ /d "SAC seismogram"']);
        
        disp(['ftype SplitLabProject=' matlabroot '\bin\win32\matlab.exe -minimize -memmgr fast -r openpjt(''"%1"'');"global thiseq";splitlab']);
        disp('assoc .pjt=SplitLabProject');
        disp('assoc .sac=SACfile');
        disp(['reg add HKCR\SplitLabProject\DefaultIcon /ve /f /d "' pathstr '\Tools\project.ico"']);
        disp(['reg add HKCR\SplitLabProject /ve /f /t REG_SZ /d "SplitLab Project"'])
        disp(['reg add HKCR\SACfile /ve /f /t REG_SZ /d "SAC seismogram"']);
%     end
end
fprintf('\n')
fprintf('\n')
fprintf('... Finished\n')
fprintf('\n')
fprintf('\n')