function out = SL_Results_getvalues
%find events with selected criteria and assings automatic Quality

global  eq

for i = 1 : length(eq) %just look again for evetns with results
    x(i) = ~isempty(eq(i).results);
end

res = find(x==1) ;
if isempty(res)
    out=[];
    return
end

selected = getappdata(gcf);


%%
out.good  = [];
out.fair  = [];
out.poor  = [];
out.goodN = [];
out.fairN = [];

k=0;
for i = 1:length(res)% Loop over each event with result
    num = res(i);
    for val=1:length(eq(num).results)%Loop over number of results per event
        thisphase = eq(num).results(val).SplitPhase;

        if isempty(thisphase); break; end
        %check if result phase corresponds to any of the selected phase
        correspond = ~isempty(strmatch(thisphase, selected.phases, 'exact'));
        if correspond
            k=k+1;
            if strcmp(selected.method, 'Manual')
                Q = eq(num).results(val).Qstr;
                %                 N = eq(num).results(val).Null;
                if selected.Quality(1) && strcmp(Q,'Good    ') && selected.Nulls(2)
                    out.good(end+1) = k;
                elseif selected.Quality(2) && strcmp(Q,'Fair    ') && selected.Nulls(2)
                    out.fair(end+1) = k;
                elseif selected.Quality(3) && strcmp(Q,'Poor    ')
                    out.poor(end+1) = k;
                elseif selected.Quality(1) && strcmp(Q,'GoodNull') && selected.Nulls(1)
                    out.goodN(end+1) = k;
                elseif selected.Quality(2) && strcmp(Q,'FairNull') && selected.Nulls(1)
                    out.fairN(end+1) = k;
                else
                    k=k-1;
                    break
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            else % strcmp(selected.method, 'Automatic')
                QQ=eq(num).results(val).Q;
                if (QQ >.85)                 && selected.Quality(1)  && selected.Nulls(2)
                    out.good(end+1) = k;
                elseif (QQ >.65 & QQ<=.85)  && selected.Quality(2)  && selected.Nulls(2)
                    out.fair(end+1) = k;
                elseif (QQ >-.65 & QQ<=.65)  && selected.Quality(3)
                    out.poor(end+1) = k;
                elseif (QQ <-.85)            && selected.Quality(1)  && selected.Nulls(1)
                    out.goodN(end+1) = k;
                elseif (QQ >=-.85 & QQ<-.65) && selected.Quality(2)  && selected.Nulls(1)
                    out.fairN(end+1) = k;
                else
                    k=k-1;
                    break
                end
            end

            out.evt(k)    = eq(num).date(1)*1000 + eq(num).date(7) + eq(num).date(4)/100;
            out.back(k)   = eq(num).bazi;

            out.dtSC(k,:)   = eq(num).results(val).dtSC;
            out.phiSC(k,:)  = eq(num).results(val).phiSC;

            out.phiRC(k,:)  = eq(num).results(val).phiRC;
            out.dtRC(k,:)   = eq(num).results(val).dtRC;

            out.phiEV(k,:)  = eq(num).results(val).phiEV;
            out.dtEV(k,:)   = eq(num).results(val).dtEV;

            out.SI(k,:)     = eq(num).results(val).SI;
            out.WS(:,:,k)   = eq(num).results(val).ErrorSurface(:,:,1);
            out.ndfSC(k,:)  = eq(num).results(val).ndfSC;
            
            out.inc(k)   = eq(num).results(val).incline;
            out.Omega(k) = mod(abs(out.phiSC(k)-out.phiRC(k)), 90);
            out.Phas{k}  = eq(num).results(val).SplitPhase;
            SNR_T(k)     = eq(num).results(val).SNR(2);
        end
    end
end

count = [length(out.good) length(out.fair) length(out.poor) length(out.fairN) length(out.goodN)];

if k==0
    warndlg('No result matches selected criteria, sorry!')
    out=[];
    return
end

disp(['Number of results: ' num2str(k)]);


fprintf(' good fair poor fairNull goodNull \n');
fprintf(' %3.0f  %3.0f  %3.0f    %3.0f      %3.0f   \n\n', count);




