%% XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
function drawTheoreticLines
handles = guidata(gcbf);
if ~get(handles.show, 'Value');
    return
end
if ~isfield(handles, 'theoLines')||~all(ishandle(handles.theoLines(:))),;
    return
end

phi1 = get(handles.Layer1Phi, 'Value');
phi2 = get(handles.Layer2Phi, 'Value');
dt1  = get(handles.Layer1dt, 'Value');
dt2  = get(handles.Layer2dt, 'Value');
period = get(handles.period, 'Value');

valuestring ={sprintf('Upper Layer: %5.1f\\circ, %.1fs', phi2, dt2);
              sprintf('Lower Layer: %5.1f\\circ, %.1fs', phi1, dt1)};



bazi=0:.5:179;
[phi0, dt0]=twolayermodel(bazi, phi1,dt1, phi2, dt2, period);

phi0 = [phi0; phi0];
dt0  = [dt0; dt0];
bazi = [bazi, bazi+180]';

set(handles.theoLines(:,1), 'Xdata',[bazi], 'Ydata', phi0(:,1), 'Visible', 'on')
set(handles.theoLines(:,2), 'Xdata',bazi, 'Ydata', dt0, 'Visible', 'on')
set(handles.Label, 'String', valuestring);


fig= get(  get(handles.theoLines(1),'Parent'), 'Parent');
figure(fig);
