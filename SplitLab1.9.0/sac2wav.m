 function sac2wav(sacfile)
 
% function sac2wav(sacfile,speed_factor,scale,t1,t2,hp_flag)
% function sac2wav(sacfile,wavfile,speed_factor,scale,t1,t2)

%% sac2wav
% matlab function to convert SAC data into
% sound waves using matlab's audiowrite program
% uses the SacLab functions 

% Guilhem BARRUOL, April 2016

% if nargin < 6, hp_flag = 1; end
% % if nargin < 5, t2 = 2000; end
% % if nargin < 4, t1 = 0; end
% if nargin < 3, scale = 1; end
% if nargin < 2, speed_factor = 400; end
% if nargin < 1, sacfile = 'YV.RR49.00.BDH.M.2012.318.235929.SAC'; end

%-----------user parameters-----------------
f1=0.5          ;     % lower corner frequency
f2=25         ;     % upper corner frequency
Filt_order=2  ;     % filter order
zero_phase=0  ;     % zero phase
speed_factor = 400;
scale = 1;
%sacfile = 'YV.RR49.00.BDH.M.2012.318.235929.SAC';

wavfile = [sacfile,'.wav'];

%% reading sac data
[data] = readsac(sacfile);
pas=data.DELTA;
% sampling rate
nsamp = 1/data.DELTA;
%nsamp = 100;

disp(['--> Transforming file ' ,sacfile, ' filtered [' ,num2str(f1,'%d'),'-' num2str(f2,'%d'),']Hz at speed: ' num2str(speed_factor,'%d'),'x']);

%% --------filtrage des données 
if f2 ~= 0 || f1 ~= 0
    if zero_phase ~= 1      % Causal filter
        [B,A]=butter(Filt_order,[2*pas*f1 2*pas*f2]);
        data.DATA2=filter(B,A,data.DATA1);
    else                    % Zero phase filter
        % The order is divided by 2, as filtfilt doubles the order
        Filt_ord = fix(Filt_order/2);
        [B,A]=butter(Filt_ord,[2*pas*f1 2*pas*f2]);
        data.DATA2=filtfilt(B,A,data.DATA1);
    end

else
   if f2 == 0
      msg = 'f2 = 0 -> signal not filtered... ';
   else
      msg = 'f1 = 0 -> signal not filtered... ';
   end
end

% remove mean
data.DATA3 = data.DATA2 - mean(data.DATA2);

% normalize by the maximum amplitude
max_data = max(abs(data.DATA3));
data.DATA4 = data.DATA3./max_data.*scale;
FS = floor(nsamp*speed_factor);
NBITS = 16;

%% create audio file
audiowrite(wavfile,data.DATA4,FS);

