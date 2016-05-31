function phase = calcphase
%calculate travel-times for earthquake
global thiseq config

if strcmp(config.studytype, 'Teleseismic')
    %% USE matTaup and Teleseismic phases!

   
    % Convert cell to comma-separated string as used by matTaup toolbox:
    xx  = config.phases{1};
    for i=2:length(config.phases);
        xx=strcat(xx, ',', config.phases{i});
    end;
    phases=xx;

    try
        tt = taupPath(config.earthmodel, thiseq.depth, phases, 'deg',thiseq.dis);
    catch
        disp('Problem with calcutation phase arrivals!')
        disp('Please check selected phases');
        phase=[];
        return
    end


    % In some cases, several arrivals of the same phase are calculated in a
    % short time difference. Find these, and just take the first occurence:
    if length(tt)>1
        idx=1;
        for k =2:length(tt)
            N1 = tt(k).phaseName;
            N2 = tt(k-1).phaseName;
            t1 = tt(k).time;
            t2 = tt(k-1).time;

            SameName = strcmp(N1,N2);
            lag      = abs(t1-t2);
            if ~(SameName & lag<1);
                % remove double arrivlas, which seems to be a bug in matTaup
                % phases with same name must be one seconds appart to be preserved
                idx(end+1)=k;
            end
        end
        tt = tt(idx);
    end
    %now sort for arrival time
    [phase.ttimes,sid] = sort(cell2mat({tt.time}));
    phase.Names        = {tt(sid).phaseName};

    %% calculate inclination and takeoff for each phase from data
    for iii = 1:length(tt)
        ii = sid(iii);
        cx = (6371-tt(ii).path.depth).*sin(tt(ii).path.distance/180*pi);
        cy = (6371-tt(ii).path.depth).*cos(tt(ii).path.distance/180*pi);

        dx = cx(2) - cx(1);
        dy = cy(2) - cy(1);
        phase.takeoff(iii) = 90 + atan2(dy,dx)*180/pi; %counter Clockwise from vertical downward

        dx = cx(end) - cx(end-1);
        dy = cy(end) - cy(end-1);
        phase.inclination(iii) = 90 - thiseq.dis - atan2(dy,dx)*180/pi ; %Counter Clockwise from vertical (at station) downward
    end






%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else%% config.earthmodel=='homogeneous')
    %% USE homogenoeus halfspace to estimate phase arrivals"
    if strcmp(config.studytype,'Reservoir')
        dis = thiseq.geodis3D/1000;%velocity is given in km/s...
        inc=thiseq.geoinc;
    else
        dis = thiseq.geodis3D;
        inc=thiseq.geoinc;
    end
    bazi = mod(thiseq.bazi,360);

    phase.ttimes      = dis./[config.Vp,config.Vs] ;
    phase.Names       = {'model P', 'model S'};
    phase.inclination = [inc  inc];
    phase.bazi        = [bazi bazi];
    
%     Anisotropy = config.Vs*1000 / thiseq.geodis3D_MET * dt * 100

end





    
    

