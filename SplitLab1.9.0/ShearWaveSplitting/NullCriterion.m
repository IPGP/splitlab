function Q=NullCriterion(phiSC, phiRC, dtSC, dtRC, varargin)
% automatically detect Nulls and quality of measurement
%
% This is a modified null criterion: Quality is numerical value
% representing the distance to extreme points:
% Quality of nulls is the (negative) distance from point 0/1
% Quality of non-nulls is the distance from point 1/0




x1 =  dtSC(:);
x2 =  dtRC(:);
y1 = phiSC(:);
y2 = phiRC(:);

x1(x1==0)=1e-5;
X = (x2(:)./x1(:));
Y = mod( abs(y1(:)-y2(:)), 90);
Y(Y>45)=90-Y(Y>45);
Y = Y/45;

Dist=zeros(2,length(X));Q=[];
Dist(1,:) =  sqrt(  X.^2 + (Y-1).^2 ) / sqrt(.5) ;
Dist(2,:) =  sqrt(  (X-1).^2 + Y.^2 ) / sqrt(.5);
[D,i]=min((Dist));
D(D>1)=1;
Q(i==1)=-1*(1-D(i==1));
Q(i==2)= 1*(1-D(i==2));


% set all noisy transverse components to fair Nulls
if nargin==5
    SNR_T = varargin{1};
    noisy = SNR_T(:) < 3 ;
    Q(noisy)  = 0;
end

