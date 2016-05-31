function [f]=mt_levinson(r,g)

% autocorrelation : r
% cross correlation signal*wavelet : g
% 
m=(length(r));
f(1)=g(1)/r(1);
a(1)=r(2)/r(1);
for i=2:1:m
    gn=r(1);
    if i==m;
        z1=0;
    else
        z1=r(i+1);
    end
    z2=g(i);
    for j=2:1:i;
        gn=gn-r(j)*a(j-1);
        z1=z1-r(j)*a(i-j+1);
        z2=z2-r(j)*f(i-j+1);
    end;
    a(i)=z1/gn;
    f(i)=z2/gn;
    ii=i-1;
    for j=1:1:ii
        b(j)=a(j)-a(i)*a(ii-j+1);
        f(j)=f(j)-f(i)*a(ii-j+1);
    end
    for j=1:1:ii
        a(j)=b(j);
    end;
    f(1);
end;