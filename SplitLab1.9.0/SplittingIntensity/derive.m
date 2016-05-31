function [der] = derive(sig,delta)

a = size(sig);
nsta = a(1);
npoint = a(2);

for j=1:nsta
  der(j,1) = 0.0;
  der(j,npoint) = 0.0;
  for k = 2:npoint-1 
    der(j,k) = (sig(j,k+1)-sig(j,k-1))/(2*delta);
  end
end

