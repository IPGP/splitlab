function [f]=mt_spiking(S,reg);

% Calcul du spike t
n=length(S);
m=0;
p=0;
for i=1:1:n
    m=m+i*abs(S(i));
    p=p+abs(S(i));
end
t=floor(m/p);
no=floor(n/2);
%t=t+80;
%Sp=zeros(no);
%
for d=1:1:no
    r(d)=0;
    for i=d:1:n
        r(d)=r(d)+S(i)*S(i-d+1);
    end
end
%
% Spike=zeros(1,no);
% Spike(t)=1;
% g1=conv(S,Spike);
for i=1:1:t
    g(i)=S(t-i+1);
end
for i=t+1:1:no
    g(i)=0;
end
%reg=0.01;
%[r(1),reg,r(1)*(1+reg)]
r(1)=r(1)*(1+reg);
f=mt_levinson(r,g);

% f=mt_levinson(r,g1(1:1:length(g)));
% size(r)
% size(g)
%  figure;plot(S);hold on; plot(g,'k');
%  title(['Spike', num2str(t),' longueur signal, ',num2str(length(S))]);
%  