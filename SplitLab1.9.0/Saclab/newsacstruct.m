function s = newsacstruct(x,y)
% S = NEWSACSTRUCT(Amp); returns an SAC structure with all fields
% initiated to their undefined (default) values.. N defaults to 1. 
%

%	Xiaoning Yang 2008 (modified from subfunction init_sac of readsac.m
% in the MATSEIS package)

% check arguments.
if (nargin < 1)
   n = 1;
end



% initialize output structure.
sacfields = {'FILENAME'; 'DELTA'; 'DEPMIN'; 'DEPMAX'; 'SCALE'; 'ODELTA'; ...
   'B'; 'E'; 'O'; 'A'; 'INTERNAL1'; 'T0'; 'T1'; 'T2'; 'T3'; 'T4'; 'T5'; ...
   'T6'; 'T7'; 'T8'; 'T9'; 'F'; 'RESP0'; 'RESP1'; 'RESP2'; 'RESP3'; ...
   'RESP4'; 'RESP5'; 'RESP6'; 'RESP7'; 'RESP8'; 'RESP9'; 'STLA'; 'STLO'; ...
   'STEL'; 'STDP'; 'EVLA'; 'EVLO'; 'EVEL'; 'EVDP'; 'MAG'; 'USER0'; ...
   'USER1'; 'USER2'; 'USER3'; 'USER4'; 'USER5'; 'USER6'; 'USER7'; 'USER8'; ...
   'USER9'; 'DIST'; 'AZ'; 'BAZ'; 'GCARC'; 'INTERNAL2'; 'INTERNAL3'; ...
   'DEPMEN'; 'CMPAZ'; 'CMPINC'; 'XMINIMUM'; 'XMAXIMUM'; 'YMINIMUM'; ...
   'YMAXIMUM'; 'UNUSED1'; 'UNUSED2'; 'UNUSED3'; 'UNUSED4'; 'UNUSED5'; ...
   'UNUSED6'; 'UNUSED7'; 'NZYEAR'; 'NZJDAY'; 'NZHOUR'; 'NZMIN'; 'NZSEC'; ...
   'NZMSEC'; 'NVHDR'; 'NORID'; 'NEVID'; 'NPTS'; 'INTERNAL4'; 'NWFID'; ...
   'NXSIZE'; 'NYSIZE'; 'UNUSED8'; 'IFTYPE'; 'IDEP'; 'IZTYPE'; 'UNUSED9'; ...
   'IINST'; 'ISTREG'; 'IEVREG'; 'IEVTYP'; 'IQUAL'; 'ISYNTH'; 'IMAGTYP'; ...
   'IMAGSRC'; 'UNUSED10'; 'UNUSED11'; 'UNUSED12'; 'UNUSED13'; 'UNUSED14'; ...
   'UNUSED15'; 'UNUSED16'; 'UNUSED17'; 'LEVEN'; 'LPSPOL'; 'LOVROK'; ...
   'LCALDA'; 'UNUSED18'; 'KSTNM'; 'KEVNM'; 'KHOLE'; 'KO'; 'KA'; 'KT0'; ...
   'KT1'; 'KT2'; 'KT3'; 'KT4'; 'KT5'; 'KT6'; 'KT7'; 'KT8'; 'KT9'; 'KF'; ...
   'KUSER0'; 'KUSER1'; 'KUSER2'; 'KCMPNM'; 'KNETWK'; 'KDATRD'; ...
   'KINST'; 'DATA1';};

cl = cell(size(sacfields,1),n);
cl(2:111, :) = {nan};
cl(112:end-1, :) = {' '};
s = cell2struct(cl, sacfields, 1);

    indep = x;
    dep   = y;
    filename = [];
    
            s.FILENAME = [];
            s.B = indep(1);
            s.E = indep(end);
            s.NPTS = length(dep{i});
            s.NVHDR = 6;
            df = diff(diff(indep{i}));
            if ~any(df)
                s(i).DELTA = diff(indep{i}(1:2));
                s(i).LEVEN = true;
                if isreal(dep{i})
                    s(i).IFTYPE = 'ITIME';
                    s(i).DATA1 = dep{i};
                else
                    s(i).IFTYPE = 'IRLIM';
                    s(i).DATA1 = real(dep{i});
                    s(i).DATA2 = imag(dep{i});
                end
            else
                s(i).LEVEN = false;
                s(i).IFTYPE = 'IXY';
                s(i).DATA1 = dep{i};
                s(i).DATA2 = indep{i};
            end
        end
    else
        if iscell(dep)
            error(' Both independent and dependent variables should be vectors/matrices !!!')
        end
        if size(indep, 1) == 1
            indep = indep(:);
            dep = dep(:);
        end
        filename = [];
        nfiles = size(dep,2);
        s = sacstruct(nfiles);
        for i = 1:nfiles
            s(i).FILENAME = [];
            s(i).B = indep(1, i);
            s(i).E = indep(end, i);
            s(i).NPTS = size(dep, 1);
            s(i).NVHDR = 6;
            df = diff(diff(indep(:, i)));
            if ~any(df)
                s(i).DELTA = diff(indep(1:2, i));
                s(i).LEVEN = true;
                if isreal(dep(:, i))
                    s(i).IFTYPE = 'ITIME';
                    s(i).DATA1 = dep(:, i);
                else
                    s(i).IFTYPE = 'IRLIM';
                    s(i).DATA1 = real(dep(:, i));
                    s(i).DATA2 = imag(dep(:, i));
                end
            else
                s(i).LEVEN = false;
                s(i).IFTYPE = 'IXY';
                s(i).DATA1 = dep(:, i);
                s(i).DATA2 = indep(:, i);
            end
        end
    end
    
    status =s;
    return
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



