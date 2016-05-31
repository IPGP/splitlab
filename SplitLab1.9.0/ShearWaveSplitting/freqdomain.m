 

i=8100:8355;
figure(11)
i=960:1023;
plot(i, thiseq.Amp.SG(i),'r',i, thiseq.Amp.SH(i),'b');

%%
figure(11)
[a,b]=getFilteredSeismograms(thiseq);
A=fft(a(i));
B=fft(b(i));
plot(unwrap(angle(A)),'b')
hold on
plot(-unwrap(angle(B)),'r')
hold off