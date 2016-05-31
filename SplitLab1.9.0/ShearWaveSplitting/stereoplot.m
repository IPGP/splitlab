function [hndl, marker] = stereoplot(bazi, inc, azim, len, varargin)
%[hndl, marker] = stereoplot(bazi, inc, azim, len)
% plot a stereomap of values, at backazimuth bazi, with inclination inc.
% The direction and length (i.e. delay time) of the marker is determined 
% by azim and len, respectively.
% The optional argument Null is a vector of indices to the values with Null
% charatesistics. these values are plotted as circles at the correspondig 
% backazimuth and inclination. 
%
% Example:
%  Imagine a station with 10 measurements. 
%  The third, fifth and nineth value are Null measurements:
%  [hndl, marker] = stereoplot(bazi, inc, azim, len, [3 5 9])



m = max(inc);
m = round(m/10)*10; %make gridline every 10deg
lim = [-inf 20];
a = axesm ('stereo', 'Frame', 'on', 'Grid', 'on', 'Origin',[90 0],...
    'MlineLocation', 90, 'PlineLocation', 10, 'fLatLimit',lim, 'fLineWidth',1);


if nargin ==5
    Null=varargin{:};
    
else
    Null=[];
end


% Nulls
if ~isempty(Null)
   marker = plotm(90-inc(Null), bazi(Null) ,'ro', 'MarkerSize',7);%,'MarkerFaceColor','r');
   hold on
else
    marker=[];
end
 
 
NNull = setdiff(1:length(inc), Null);%non-Nulls

bazi = bazi(:);
inc  = inc(:);
len  = len(:);
azim = azim(:);

bazi = [bazi(NNull)  bazi(NNull)]';
inc  = [inc(NNull)   inc(NNull)]';
len  = [-len(NNull)  len(NNull)]';
azim = (bazi-[azim(NNull) azim(NNull)]');


%scale marker to output size
len=len*2; %one second == 4degrees (2 deg in both directions)

% Marker

 [latout, lonout] = reckon( 90-inc, bazi, len, azim, 'degrees');
 hndl = plotm(latout, lonout, 'Linewidth', 1.5);
hold off



axis tight

axis off
L = min(abs(axis));
str =strvcat([num2str(m/2)  char(186)], [num2str(m)  char(186)]);
% t   = textm(90-[m/2; m], [45; 45], str, 'FontName','FixedWidth' );
text(0 , -L, 'N','FontName','FixedWidth','HorizontalAlignment','Center','VerticalAlignment','Base');
text(L, 0,   'E','FontName','FixedWidth','HorizontalAlignment','Left','verticalAlignment','middle');

view([0 -90])
hold off