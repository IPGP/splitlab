function  mergepjt(file1, file2)
% Merge the two Splitlab projects file1 and file2 to a new project
% file1 and file2 contains the complete path to the projects to be joined.
% In fact file2 is appended to file1 and the whole is saved as a new
% project. The configuration of file1 persists.
%
% Attention: the seismogram repository directories of the same!
%
%usage: mergepjt('c:\example1.pjt', 'd:\path\to\pjt\example2.pjt')


% A.W. March 2007

fprintf('\nreading file: %s\n', file1);
pjt1 = load('-mat', file1);
fprintf('reading file: %s\n\n', file2);
pjt2 = load('-mat', file2);


if ~strcmp(pjt1.config.datadir, pjt2.config.datadir)   
    disp(' ')
    disp('ATTENTION:')
    disp('Cannot merge projects')
    disp('Seismogram directories are not the same:')
    disp(['  dir1: ', pjt1.config.datadir])
    disp(['  dir2: ', pjt2.config.datadir]) 
    error('Seismic data directories of the two projects differ! Aborting!')   
    return
end



config = pjt1.config; 
eq     = pjt1.eq;

L1 = length(eq); 
L2 = length(pjt2.eq) + 1; 

% joining the two eq databases
for k = 1:length(pjt2.eq)
    eq(L1+k) = pjt2.eq(k);
end

m = msgbox(sprintf('Succesfully merged the two files. New project has now %.0f earthquakes\n', length(eq)));
waitfor(m)


%% saving
newproj = strrep(config.project, '.pjt', '_new.pjt');
str ={'*.pjt', '*.pjt - SplitLab projects files';
    '*.mat', '*.mat - MatLab files';
    '*.*',     '* - All files'};
[tmp1,tmp2]=uiputfile( str ,'Save as Project file', ...
    [config.projectdir, filesep, newproj]);

if isstr(tmp2)
    oldpjt = config.project ;
    config.projectdir = tmp2;
    config.project    = tmp1;
    
    save(fullfile(tmp2,tmp1),    'config','eq')
end
