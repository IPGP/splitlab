function [phiSC, dtSC, phiEV, dtEV,  Emap, correctFastSlow, corrected_SG_SH, Eresult, gamma] =...
    splitSilverChan(SG, SH, pickwin, sampling, maxtime, option, isBatch, StepsPhi, StepsDT)

% Andreas Wüstefeld 12.03.06
% updated 20.02.09 to allow SG-SH input.

% test rotations are counter-clockwise rotation of SG-SH
%  -90:  T ==  SG; Q == -SH 
%    0:  T ==  SH; Q ==  SG
%   90:  T == -SG; Q ==  SH

phi_test = ((-90:StepsPhi:90))/180*pi;
phi_test = phi_test(1:end-1);

dt_test  = 0:StepsDT:ceil(maxtime/sampling); % test delay times (in samples)

M(1,1,:) =   cos(phi_test);       M(1,2,:) =  -sin(phi_test);
M(2,1,:) =   sin(phi_test);       M(2,2,:) =   cos(phi_test);

%initilize Energy matrix for speed:
Ematrix = zeros(length(phi_test), length(dt_test));
l1=zeros(size(Ematrix));
l2=zeros(size(Ematrix));
% eigvec = zeros([size(Ematrix) 2]);

if ~isBatch;
    sbar=findobj('Tag','Statusbar');
    pp = get(sbar,'Position');
    set(sbar, 'BackgroundColor',[.9 .9 .9])
end


%% Rotation and shift
for p=1:length(phi_test)
    MM=M(:,:,p);
    FS_Test =  MM * [SG, SH]';% Test fast/slow direction
    tmpFast = FS_Test(1,pickwin);

%% mb 2015/11/24
    %this statusbar update slightly slows proccessing down, so only use it in single mode...
%    if ~isBatch
%            set(sbar, 'position', [pp(1) pp(2) pp(3)*p/length(phi_test) pp(4)])
%            drawnow
%    end
%% mb 2015/11/24

    for t=length(dt_test):-1:1
        shift = dt_test(t); % shift index
        tmpSlow = FS_Test(2,pickwin+shift);

        % rotate back to Radial-Transversal-system
        % M' == inv(M), but faster :-)
        corrected_SGSH = MM' * [tmpFast; tmpSlow];

        % Energy on transverse component
        % E = sum(corrected_Transv^2);
        Ematrix(p,t) = corrected_SGSH(2,:) * corrected_SGSH(2,:)';
             
        % ORIGINAL MATLAB (Slow, due to input checking)
        % covar = cov(corrected_SHSG(1,:),corrected_SHSG(2,:));
        
        % IMPROVED COVARIANCE FUNCTION(We know the input)
        x    = corrected_SGSH(1,:)';
        y    = corrected_SGSH(2,:)';
        m     = size(x,1);
        xc    = [x-sum(x,1)/m  y-sum(y,1)/m];  % Remove mean
        covar =  (xc' * xc) / (m-1);
        
        % EIGENVALUE ESTIMATE
        [~, lambda]  = eig(covar);        
        l1(p,t)        = lambda(2,2);
        l2(p,t)        = lambda(1,1);
    end
end


%% OPTIONS:
[indexPhiSC,indexDtSC] = find(Ematrix==min(Ematrix(:)), 1);

shift  = dt_test(indexDtSC); % samples
dtSC   = shift * sampling; % seconds

switch option
    % Get results for Eigenvalue methods and minimum Energy method
    % indexPhi and indexDt contain the selected method, for which
    % the fast and slow components are later recalculated

    case 'Minimum Energy'
        % using SC values for rotation of matrix
        indexPhi = indexPhiSC;
        indexDt  = indexDtSC;
        % using min(lambda2*lambda1) as default EV method
        [~, ind]                = min(l2(:) .* l1(:));
        [indexPhiEV, indexDtEV] = ind2sub(size(l2), ind);

        Emap = cat(3,Ematrix,  l2.*l1); % stack as another layer of the matrix (==3rd dimension)

    case 'Eigenvalue: max(lambda1 / lambda2)'
        [~, ind]                = max(l1(:)./l2(:));
        [indexPhiEV, indexDtEV] = ind2sub(size(l2), ind);
        indexPhi = indexPhiEV;
        indexDt  = indexDtEV;

        Emap = cat(3,Ematrix,  -(l1./l2)); % stack as another layer of the matrix (==3rd dimension)

    case 'Eigenvalue: min(lambda2)'
        [~, ind]                = min(l2(:));
        [indexPhiEV, indexDtEV] = ind2sub(size(l2), ind);
        indexPhi = indexPhiEV;
        indexDt  = indexDtEV;

        Emap = cat(3,Ematrix,  l2); % stack as another layer of the matrix (==3rd dimension)

    case 'Eigenvalue: max(lambda1)'
        [~, ind]                = max(l1(:));
        [indexPhiEV, indexDtEV] = ind2sub(size(l2), ind);
        indexPhi = indexPhiEV;
        indexDt  = indexDtEV;

        Emap = cat(3,Ematrix,  -l1); % stack as another layer of the matrix (==3rd dimension)

    case 'Eigenvalue: min(lambda1 * lambda2)'
        [~, ind]                = min(l1(:) .* l2(:));
        [indexPhiEV, indexDtEV]   = ind2sub(size(l2), ind);
        indexPhi = indexPhiEV;
        indexDt  = indexDtEV;

        Emap = cat(3,Ematrix,  l2.*l1   );

    case 'Eigenvalue: min(lambda2 / lambda1)'
        [~, ind]                = min(l2(:) ./ l1(:));
        [indexPhiEV, indexDtEV]   = ind2sub(size(l2), ind);
        indexPhi = indexPhiEV;
        indexDt  = indexDtEV;

        Emap = cat(3,Ematrix,  l2./l1   );

    otherwise
        error(['Unknown Splitting Option: ' option])
end

shift  = dt_test(indexDtEV); % samples
dtEV   = shift * sampling;   % seconds

phi_test_min = (phi_test(indexPhiEV)/ pi * 180); % fast axis in SH-SG system, relative to SG
phiEV        = mod(phi_test_min,  180);
if phiEV>90
    phiEV = phiEV-180; %put in -90:90
end


phi_test_min = (phi_test(indexPhiSC)/ pi * 180);  % fast axis in SH-SG-system, relative to SG
phiSC        = mod((phi_test_min), 180);
if phiSC>90
    phiSC = phiSC-180; %put in [-90:90]
end

%% Project energy maps
Eresult(1) = Emap(indexPhiSC, indexDtSC, 1);
Eresult(2) = Emap(indexPhiEV, indexDtEV, 2);


%% seismograms in fast/slow directions
shift = dt_test(indexDt);
% [indexPhi indexPhiSC indexPhiEV]
FS_Test  = M(:,:,indexPhi) * [SG, SH]' ;   % extended window
tmpFast  = FS_Test(1,pickwin);
tmpSlow  = FS_Test(2,pickwin+shift);

correctFastSlow(:,1)  = tmpFast; %fast component in pick window
correctFastSlow(:,2)  = tmpSlow; %slow component in shifted pick window

corrected_SG_SH = M(:,:,indexPhi)' * [ tmpFast; tmpSlow];
corrected_SG_SH = corrected_SG_SH';


%% initial polarisation in respect to SG 
%  this is always the initial polarisation of the corrected seismogram for
%  the selected method (EV or MinEnergy)
[vec,lambda] = eig(cov(corrected_SG_SH));
[~, ind]    = max(diag(lambda));
eigenSG      = vec(1,ind);
eigenSH      = vec(2,ind);
% eigenvalue function sometimes gives left-handed coordinate system
% this can be determined with the ... determinate :-)
%   det(lefthanded)  = -1;
%   det(righthanded) = +1;
gamma =   atan2(eigenSH, eigenSG) / pi * 180;
 det(vec) ;
% gamma = mod(gamma,180);
% if gamma>90
%     gamma=gamma-180;
% end
% gamma
