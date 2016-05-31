%% sac2wav_loop
% matlab script to convert several SAC files  into
% sound waves using matlab's audiowrite program
% call the sac2wav function

% Guilhem BARRUOL, April 2016

%% ------------------------------- directory and name definition ----------
%stnm='OBS_whale_detection'   ;        % station name
%direc='/home/michi/Schreibtisch/Praktikum_La_Reunion/OBS_whale_detection/'; % define the upper directory
direc='/Users/guilhem/Documents/Reunion/RHUM-RUM_Ship-noise/';
cd(direc);  % directory with station

%--------------------------------------------------------------------------

g=dir('dat*'); % liste les directory contenant les fichiers à traiter

%% ----------- boucle sur chaque directory (par exemple 1/mois) -----------

for r=1:length(g);      
    
    if g(r).isdir == 1;     % teste si le nom est bien une directory           
    c=strcat(char(direc), char(g(r).name));
    cd(c);                    % go in the data directory
    d=dir('*.SAC');       % list the directory and search the vertical SAC file
    end

%% ----------- boucle sur chaque sismo de chaque directory
for s=1:length(d)       %  
   sac2wav(d(s).name); % lecture fichier et structure SAC
end

cd('..')

 end
