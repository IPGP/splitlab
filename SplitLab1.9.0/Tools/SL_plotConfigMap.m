function SL_plotConfigMap
global config



tmp = gca;
ax = get(gcf,'UserData');
axes(ax);
%  a = imread('MODISworld_00.jpg');
%  O = ones(size(a));
%  A = [O;a;O];%  A = [flipdim(flipdim(a,1),2); a ; flipdim(flipdim(a,1),2)];
A = get(ax,'UserData');

[ny, nx, nz] = size(A);
x = round((config.slong + 180)/360*nx) ;
y = ny/3*2-round((config.slat  +  90)/540*ny) + 1;

xx = x-100:x+100;
yy = y+100:-1:y-100;
xx(xx>nx) = xx(xx>nx) - nx;
xx(xx<=0) = xx(xx<=0) + nx;

% yy(yy>ny) = yy(yy>ny) - ny;
% yy(yy<=0) = yy(yy<=0) + ny;


try
    TOPO  = uint16(A(yy, xx,:)) * 1.3;%%multiplication lights it up a bit
    TOPO(TOPO>255)=255;
    im = findobj('Type', 'image','Parent',ax,'Tag','Karte');
    if isempty(im)
        image([-1 1], [-1 1], uint8(TOPO),'Tag','Karte');
    else
        set(im, 'CData', uint8(TOPO))
    end
    set(ax, 'YDir','Normal')

    if isempty(get(ax,'UserData'))
        set(ax, 'UserData',A)
    end
catch
    disp('Some troubles plotting map...')
end
axes(tmp)
