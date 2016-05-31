function [xy, ax] = getCurrentPoint(varargin)
% get current pointer positon in figure
% The Figure Property CurrentPoint gets only updated on clicks. This
% function querries the current position on the screen. If it is above the
% current axes (or the one given as an argument), the x- and y-position in
% data units of that axes are returned. Additionally, the handle of the
% used axes is returned.

if nargin == 1
    ax = varargin{1};
else
    ax = gca;
end
fig = get(ax,'Parent');

% Does not work anymore:
%if get(0,'PointerWindow') ~= fig
%    xy =[];
%    return
%end

U    = get([0,fig,ax], 'Units');
       set([0,fig,ax],'Units', 'pixels')

S    = get(0,'ScreenSize');
posf = get(fig,'Position');
posa = (get(ax, 'Position'));

pt   = get(0,'PointerLocation');
       set(0,   'Units',U{1})
       set(fig, 'Units',U{2})
       set(ax,  'Units',U{3})

       
X1 = posa(1) + posf(1);
X2 = posa(3) + X1;
Y1 = posa(2) + posf(2);
Y2 = posa(4) + Y1;

if (X1 <= pt(1) && pt(1) <= X2   &&   Y1 <= pt(2) && pt(2) <= Y2) 
 xl = xlim;
 yl = ylim;
    
 xp = (pt(1) - X1)   /  (X2 - X1) * (xl(2) - xl(1))    +   xl(1) ;
 yp = (pt(2) - Y1)   /  (Y2 - Y1) * (yl(2) - yl(1))    +   yl(1) ;
 
 xy = [xp yp];
else
    xy =[];
end