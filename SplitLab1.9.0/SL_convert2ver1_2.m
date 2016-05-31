function SL_convert2ver1_2
global config eq
%%
for k=1:length(eq)
    for r=1:length(eq(k).results)
        eq(k).results(r).Spick = [eq(k).results(r).a   eq(k).results(r).f];
        
        % get numerical automatic Quality
        if strcmp(eq(k).results(r).method, 'Minimum Energy')
            eq(k).results(r).Q     = NullCriterion(...
                eq(k).results(r).phiSC(2),...
                eq(k).results(r).phiRC(2),...
                eq(k).results(r).dtSC(2),...
                eq(k).results(r).dtRC(2));
        else           
            eq(k).results(r).Q     = NullCriterion(...
                eq(k).results(r).phiEV(2),...
                eq(k).results(r).phiRC(2),...
                eq(k).results(r).dtEV(2),...
                eq(k).results(r).dtRC(2));
        end
        
        % convert error
        eq(k).results(r).phiEV = [eq(k).results(r).phiEV(2)  mean(diff(mod(eq(k).results(r).phiEV+180,180) ))];
        eq(k).results(r).phiSC = [eq(k).results(r).phiSC(2)  mean(diff(mod(eq(k).results(r).phiSC+180,180) ))];
        eq(k).results(r).phiRC = [eq(k).results(r).phiRC(2)  mean(diff(mod(eq(k).results(r).phiRC+180,180) ))];
        
        eq(k).results(r).dtEV = [eq(k).results(r).dtEV(2)    mean(diff(eq(k).results(r).dtEV ))];
        eq(k).results(r).dtSC = [eq(k).results(r).dtSC(2)    mean(diff(eq(k).results(r).dtSC ))];
        eq(k).results(r).dtRC = [eq(k).results(r).dtRC(2)    mean(diff(eq(k).results(r).dtRC ))];
                
        
        % get New Format Quality string
        if strcmp('No',  eq(k).results(r).Null)
            eq(k).results(r).Qstr  = [eq(k).results(r).quality  '    '];
        else
            eq(k).results(r).Qstr  = [eq(k).results(r).quality  'Null'];
        end
        eq(k).results(r).Qstr(1)=upper(eq(k).results(r).Qstr(1));
        
        
        
    end
end
        