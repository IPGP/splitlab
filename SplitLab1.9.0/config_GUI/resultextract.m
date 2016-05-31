function out=resultextract

global config eq
    for i = 1 : length(eq)
        x(i)=~isempty(eq(i).results);
    end
    res = find(x==1) ;
    
%%    
err=[];
g=[]; f=[]; p=[];
null=[]; nonull=[];
Phases=struct();

out=[];


%the field are ordered with 
%  1st column: eq-index
%  2nd column: result-index
%
for i = 1:length(res)
    num = res(i);
    for j=1:length(eq(num).results)
        if strcmp('trash', lower(eq(num).results(j).quality))
            tr(num) = j;
        else
            phase = eq(num).results(j).SplitPhase;
            switch phase
                case 'SKS'
                    P=1;
                case 'PKS'
                    P=2;
                case 'SKKS'
                    P=3;
                case 'sSKS'
                    P=1;
                case 'pSKS'
                    P=1;
                otherwise
                    P=999;
            end
            switch lower(eq(num).results(j).quality)
                case 'good'
                    g = [g; num j P];
                case 'fair'
                    f = [f; num j P];
                case 'poor'
                    p = [p; num j P];
            end
            switch eq(num).results(j).Null
                case 'Yes'
                    null = [null; num j P];
                case 'No'
                    nonull=[nonull; num j P];
            end
        %append to "out" cell array:
        try
        eqid = sprintf('%04.0f.%03.0f.%02.0f',eq(num).date(1),eq(num).date(7),eq(num).date(4))
        catch
            eqid = sprintf('%04.0f.%03.0f.%02.0f',eq(num).year,eq(num).jjj,eq(num).hour)
        end
        out(end+1,:) = {...
            eqid,...
            eq(num).bazi,...
            eq(num).results(j).filter,...
            eq(num).results(j).f - eq(num).results(j).a,...
            eq(num).results(j).phiSC,...
            eq(num).results(j).phiRC,...
            eq(num).results(j).dtSC,...
            eq(num).results(j).dtRC,...
            eq(num).results(j).SplitPhase,...
            eq(num).results(j).quality,...
            eq(num).results(j).Null...
            }; 
       end
    end
end