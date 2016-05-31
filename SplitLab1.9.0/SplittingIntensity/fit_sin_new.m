function [ap,dt,phi,ddt,dphi,cov,rms] = fit_sin_new(pol,azi,sigma)
%sigma=sigma/10;
npt = length(azi);
deg2rad = pi/180;
if npt < 2;
    ap=0;
    dt=0;
    phi=0;
    ddt=0;
    dphi=0;
    cov=0;
    rms=0;
    return
end
x = azi*deg2rad;
x1 = cos(2*x);
x2 = sin(2*x);

sigma = transpose(sigma);
 
% Generation de la matrice A
A = zeros(length(x1),2);
A(:,1) = x1(:)./sigma(:); 
A(:,2) = x2(:)./sigma(:); 

%Generation du vecteur b
b = zeros(1,length(pol));
b(:) = pol(:)./sigma(:);
b=b';
% size(A)
% size(b)
ap=inv(A'*A)*A'*b;
cov=inv(A'*A);
% % Decomposition en valeurs singulieres de
% % la matrice A
% [U,S,V] = svd(A);
% 
% % Determination des parametres
% %ap = zeros(1,4);
% ap = zeros(1,2);
% for j = 1:2
%   u = U(:,j);
%   v = V(:,j);
%   ap = ap+((b*u)/S(j,j))*v';
% end 
% 
% for j = 1:2
%   W(:,j) = V(:,j)/S(j,j);
% end
% 
% cov = W*W';

% Calcul des parametres de splitting
dt(1) = sqrt(ap(1)^2+ap(2)^2);
%phi(1) = 0.5*asin(-ap(1)/dt(1))/deg2rad;
phi(1) = 0.5*atan2(-ap(1)/dt(1),ap(2)/dt(1))/deg2rad;

%Calcul des erreurs
ddt(1) = cov(1,1)*(ap(1)/dt(1))^2+cov(2,2)*(ap(2)/dt(1))^2;
dphi(1) = cov(1,1)*(ap(2)/dt(1)^2)^2+cov(2,2)*(ap(1)/dt(1)^2)^2;
ddt(1) = sqrt(ddt(1));
dphi(1) = sqrt(dphi(1)/(4*deg2rad^2));

%Calcul de la variance des donnees
var = A*ap - b;
var = var'*var/npt;
rms = sqrt(var);
