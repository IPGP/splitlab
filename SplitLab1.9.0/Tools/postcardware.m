function postcardware
F=mfilename('fullpath');
p=fileparts(F);

[im, map] = imread([p filesep 'postcard.gif']);



postcardtxt = {'Splitlab is PostCard ware!',...
    ['If you like SplitLab, if you work with it, or simply want to make me happy, ',...
    'please send a postcard of the place you live at to:'],...
    ' ',....
    '\bfAndreas Wuestefeld\rm',...
    '  Dept. of Earth Sciences, University of Bristol',...
    '  Wills Memorial Building',...
    '  Queen''s Road',...
    '  BRISTOL BS8 1RJ',...
    '  \bfUnited Kingdom\rm',...
    ' ',....
    'A collection of postcards will be presented on the SplitLab homepage '};


createmode.WindowStyle='modal';
createmode.Interpreter='tex';
h=msgbox(postcardtxt, 'PostCard Ware', 'custom', im, map,createmode);

set(h,'Color', 'w','units','Pixel');
pos = get(h,'position');

t0=now;
while ishandle(h)
    color = rand(1,3);
    if 3 > sum(color<.5)
        set(h,'Color', color)
        pause(1)
    end
end
dt = (now-t0)*24*3600;

if dt <3
    str= {'Wow, that was quick!', sprintf('Only \\bf%.2f seconds\\rm to read the PostCard reminder!!',dt)};
    msgbox(str,'Wow...' , 'help', createmode);
end

