%% MATLAB
%  script to splitagain ALL 'pjt' files in the directory below.

target_files = rdir('/Users/john/Dropbox/JOHNS_WORK/programming/splitlab/', '*.pjt');

for s=1:length(target_files)
	load( char(target_files(s)), '-mat');
    fprintf('Working on file: %s ..\n', config.project);    	% display the project name
    splitagain;
end

fprintf('Finished splitting again all.\n');
clear target_files;