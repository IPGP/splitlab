 function [phiRC, dtRC, Cmap, correctFastSlowRC, corrected_SG_SH,  Eresult] =...
     splitRotCorr(SG, SH,  pickwin, maxtime, sampling, isBatch, StepsPhi, isWeiredMAC)


% shear wave splitting using the Rotation-Correlation method
%  (e.g. Bowman and Ando,1987)
%
% INPUTS:
%    Q,T      = Sv and Sh seismogram components in Ray system as column vectors
%    bazi     = backazimuth
%    pickwin  = indices to pick
%    sampling = sampling of seismograms records (in seconds)
%
% OUTPUTS:
%    Cmatrix = correlation map of test directions
%    phiRC   = best estimated fast axis (RC-method)
%    dtRC    = best estimated delay time (RC-method)
%    correctFS_RC = vector of corrected components:
%                   first column:  Fast
%                   second column: Slow

maxlags = ceil(maxtime/sampling); %only +-4 seconds relevant
zerolag = length(pickwin);

if zerolag<maxlags
    disp('  Warning: Picked S-window smaller than maximum delay time. Consider repicking!')
    maxlags = zerolag-1;
end
%updated 20.02.09 to allow SG-SH input.

% test rotations are counter-clockwise rotation of SG-SH
%  -90:  T ==  SG; Q == -SH 
%    0:  T ==  SH; Q ==  SG
%   90:  T == -SG; Q ==  SH




phi_test = (-90:StepsPhi:90)/180*pi;
phi_test = phi_test(1:end-1);

M(1,1,:) =   cos(phi_test);       M(1,2,:) =  -sin(phi_test);
M(2,1,:) =   sin(phi_test);       M(2,2,:) =  cos(phi_test);


%% Rotate and correlate
%cross-covariance function (equal to mean-removed cross-correlation) of Q and T on test direction
if ~isBatch
    sbar=findobj('Tag','Statusbar');
    pp = get(sbar,'Position');
    set(sbar, 'BackgroundColor',[.9 .9 .9])
end

Cmatrix = zeros(length(phi_test),2*maxlags+1);
for p=1:length(phi_test)
%% mb 2015/11/24
        %this statusbar update slightly slows proccessing down, so only use
        %it in single mode...
%    if ~isBatch
%            set(sbar, 'position', [pp(1) pp(2) pp(3)*p/length(phi_test) pp(4)])
%            drawnow
%    end
%% mb 2015/11/24
    
    
    %test slow-fast seismograms
    FS_Test = M(:,:,p) * [SG, SH]';

    %cross-correlate Slow with Fast component:    
    Cmatrix(p,:) = xcorr(FS_Test(1,pickwin), FS_Test(2, pickwin), maxlags, 'coeff' );
end
if ~isBatch; set(sbar, 'BackgroundColor','w');end



%% ATTENTION %%%%%%
%There is an (undocumented) inconsistency in Matlab between some UNIX/MAC and Windows machines!
%The XCORR function uses a different lag time! We have contacted Mathworks
%but they couldn't fix that phenomenon!
%try the following code on your machine:

%%%BEGIN CODE%%%
% z1 = [0 0 1 0 0];
% z2 = [0 1 0 0 0];
% C = xcorr(z1,z2, 'coeff');
% 
% [a,b] = max(C)
%%%END CODE%%% 

% if b = 6 then everything is fine
% some machines however give b=4; in thiscase please uncomment the
% following line:
% (this is now checked on startup...)
if isWeiredMAC
     Cmatrix = fliplr(Cmatrix);
end



 
[~,idx]           = max((Cmatrix(:)));%abs
[phiidx,shiftidx] = ind2sub(size(Cmatrix), idx);
phiRC             = phi_test(phiidx)/pi*180; % fast axis in SH-SG system
shift             = shiftidx-maxlags-1;      % shift samples relative to zerolag


%% find if correlated or anti-correlated

S = sign(Cmatrix(idx));%negative means Fast and slow are anti-correlated

if shift<0
    % fast-axis arrives after slow-axis; %substracting 90?
    dtRC    = -shift*sampling;
    phiRC   = mod(phiRC, 180);
    Cmap    = fliplr(Cmatrix(:, 1:(maxlags+1))); %only use left side on map
    shift   = -shift;
    theta   = phiRC/180*pi;

else %shift>0
    % fast-axis arrives before slow-axis; the standard
    phiRC   = mod(phiRC+90, 180);
    dtRC    = shift*sampling;
    Cmap    = Cmatrix(:, maxlags+1:end); %only use right side on map
    Cmap    = circshift(Cmap, [round(length(phi_test)/2), 0] );
    theta   = (phiRC)/180*pi;
end
Cmap  = Cmap * -S;
shift = shift * S;
phiRC=mod(phiRC,180);
if phiRC>90
    phiRC = phiRC-180; %put in -90:90
end



Eresult = min(Cmap(:));



%% output seismograms in fast/slow directions
M     = [cos(theta)  -sin(theta);
         sin(theta)   cos(theta)];
FS_Test  = M * [SG, SH]' ;   % extended window
tmpFast  = FS_Test(1,pickwin);
tmpSlow  = FS_Test(2,pickwin+shift);


correctFastSlowRC(:,1)  = tmpFast; %fast component in pick window
correctFastSlowRC(:,2)  = tmpSlow; %slow component in shifted pick window


corrected_SG_SH = M' * [tmpFast;  tmpSlow];
corrected_SG_SH = corrected_SG_SH';
