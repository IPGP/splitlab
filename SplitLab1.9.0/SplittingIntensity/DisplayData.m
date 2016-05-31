% display data 
function [i]=DisplayData(t,R,T,titre1,titre2)


subplot(2,1,2);hold on;title(titre2);
for i=1:1:size(T,1)
    plot(t,5*T(i,:)+i)
end
subplot(2,1,1);hold on;title(titre1);
for i=1:1:size(R,1)
    plot(t,R(i,:)+i)
end

xlim([t(1),t(length(t))]);
box on;
linkaxes
