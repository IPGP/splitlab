function [sigfil] = filtbuth(f,n,delta,sig)

fn=1/(2*delta);
Wn=f/fn;
[B,A]=butter(n,Wn,'low');
a=size(sig);
ntra=a(1);

for k=1:ntra
%  sigfil(k,:)=filter(B,A,sig(k,:));
  sigfil(k,:)=filtfilt(B,A,sig(k,:));
end
