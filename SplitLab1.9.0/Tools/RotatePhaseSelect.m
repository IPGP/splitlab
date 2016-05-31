function RotatePhaseSelect(src)
global thiseq config

seis=get(src, 'UserData');
val     = get(src,'Value');
if isempty(val)
    return
end

inc     = thiseq.phase.inclination(val);
thiseq.SplitPhase = char(thiseq.phase.Names(val));

if strcmp(char(thiseq.phase.Names(val)), 'P-pol')
    pol = thiseq.phase.bazi(val); %use manually determined backazimuth from P-polarisation
    bazistr = '_{P-pol}';
elseif strcmp(char(thiseq.phase.Names(val)), 'none')   
    pol = 0;
    bazistr = '';
else
    bazistr = '';
    switch config.studytype
        case 'Teleseismic'
            pol = thiseq.bazi;
        case 'Regional'
            pol = thiseq.geobazi;
        case 'Reservoir'
            pol = thiseq.geobazi;
    end
end

thiseq.selectedinc = inc;
thiseq.selectedpol = pol;


if strcmp(thiseq.SplitPhase, 'none')
    thiseq.Amp.SG =  thiseq.Amp.North';
    thiseq.Amp.SH = -thiseq.Amp.East';
    thiseq.Amp.L  =  thiseq.Amp.Vert';
else
    M = rot3D(inc, thiseq.selectedpol); %the rotation matrix               %
    % ENZ = [ thiseq.Amp.East, thiseq.Amp.North, thiseq.Amp.Vert]';
    % HVL = M * ENZ; %rotating                                               %
    %                                          %                                         %
    % thiseq.Amp.SH     = HVL(1,:);
    % thiseq.Amp.SG     = HVL(2,:);
    % thiseq.Amp.L      = HVL(3,:);
    
    Z_E_N   = [thiseq.Amp.Vert,  thiseq.Amp.East,  thiseq.Amp.North]';
    L_SG_SH = M * Z_E_N ;
    
    thiseq.Amp.L      = L_SG_SH(1,:);
    thiseq.Amp.SG     = L_SG_SH(2,:);
    thiseq.Amp.SH     = L_SG_SH(3,:);
    
end

SL_updatefiltered(seis);
s = findobj('Tag','Statusbar');
set(s,'String', sprintf(['Status:  Backazimuth = %6.2f' char(186) '  Inclination = %4.2f' char(186)], pol, thiseq.phase.inclination(val)));

%update title string
tit = findobj('Tag','BackgroundSeisAxesTitle');
str = get(tit, 'String');
no = strfind (str{2}, '\');
tmp = str{2}(no(1)+7:end);
str{2} = sprintf(['Backazimuth' bazistr ': %6.2f\\circ  %s'], pol,  tmp);
set(tit, 'String', str)

%% Setting focus back to figure:
%  http://www.mathworks.com/matlabcentral/newsreader/view_thread/235825
%   robot = java.awt.Robot;
%   pos = get(gcbf, 'Position');
%   set(0, 'PointerLocation', pos(1:2));
%   robot.mousePress(java.awt.event.InputEvent.BUTTON1_MASK);
%   robot.mouseRelease(java.awt.event.InputEvent.BUTTON1_MASK);

% warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
% javaFrame = get(get(src, 'Parent'),'JavaFrame');
% javaFrame.getAxisComponent.requestFocus;
