%% macro to calculate the piercing point of SKS splitting measurements 
% the output files are ready to be plotted with GMT
%%

% cd('/Volumes/SISMO/barruol/Alpes/SWISS/TORNY/') %directory with projects
%cd('/Users/guilhem/Documents/Alpes/projects_backup/') %directory with projects
%cd ('/Users/guilhem/Documents/Reunion/Indian_SKS/projects_backup/') %directory with projects
%cd ('/Users/guilhem/Documents/Antarctica/Papier_SKS_RF_ARLITA_2014/SKS_projects_mean/') %directory with projects
cd ('/Users/guilhem/Documents/Reunion/Iles_Eparses/sismo_data/SKS_iles_eparses/Eparses_SKS_projects/') %directory with projects

%cd('/Users/mickaelbonnin/Documents/Anatolia/Piercing_point/ETSE/');
%cd('/Users/mickaelbonnin/Documents/ALPS/Splitlab_projects/');

exp='Eparses'; % experiment name (for the subsequent file naming)

%for i=[0]                % loop over the piercing depths: i=min:step:maxdepth (in km)
%%


for i=0:50:650                % loop over the piercing depths: i=min:step:maxdepth (in km)
    
Gfile  = fopen([exp,'_piercepoints_',num2str(i),'km_good.txt'],  'w');    %file with good values
GTable  = fopen([exp,'_Good_table.txt'], 'w');    %table with good values
FTable  = fopen([exp,'_Fair_table.txt'], 'w');    %table with fair values
PTable  = fopen([exp,'_Poor_table.txt'], 'w');    %table with fair values    
fprintf(GTable,'Station\tDate\tBaz\tLat\tLong\tphi\tdphi\tdt\tddt\tAuto_Q\tManual_Q\n');
fprintf(FTable,'Station\tDate\tBaz\tLat\tLong\tphi\tdphi\tdt\tddt\tAuto_Q\tManual_Q\n');
fprintf(PTable,'Station\tDate\tBaz\tLat\tLong\tphi\tdphi\tdt\tddt\tAuto_Q\tManual_Q\n');

NTable = fopen('Nulls_table.txt', 'w');    %table with good values
fprintf(NTable,'Station\tDate\tBaz\tLat\tLong\tAuto_Q\tManual_Q\n');    

Ffile  = fopen([exp,'_piercepoints_',num2str(i),'km_fair.txt'],  'w');    %file with fair values
Pfile  = fopen([exp,'_piercepoints_',num2str(i),'km_poor.txt'],  'w');    %file with poor values
GNfile = fopen([exp,'_piercepoints_',num2str(i),'km_goodNull.txt'], 'w'); %file with good Null values
FNfile = fopen([exp,'_piercepoints_',num2str(i),'km_fairNull.txt'], 'w'); %file with fair Null values


manual=1;     %1=Use manual quality   0=Use Automatic quality


d=dir('*.pjt');             % list the directory and search the pjt file

for s=1:length(d)
    load(d(s).name,'-mat')
    disp(config.project)    % display the project name
    m=0;
 
    for k = 1:length(eq)    % Loop over each event with result
    
        for val=1:length(eq(k).results)     %Loop over number of results per event
            thisphase = eq(k).results(val).SplitPhase;
% comment GB april2014 to use both SKS and SKKS values iles eparses
%            if ~strcmp('SKS', thisphase)    % exit if not SKS phase
%                break
%            end
            m=m+1;

            if manual==1
                if     strcmp('GoodNull',eq(k).results(val).Qstr)
                    N=1; Q=1;
                elseif strcmp('FairNull',eq(k).results(val).Qstr)
                    N=1; Q=2;
                elseif strcmp('Good    ',eq(k).results(val).Qstr)
                    N=0; Q=1;
                elseif strcmp('Fair    ',eq(k).results(val).Qstr)
                    N=0; Q=2;
                else
                    N=0; Q=3;
                end
                
            else %  'Automatic' levels between good, fair and poor may be changed
                if eq(k).results(val).Q < -0.5                                      %out.goodN
                    N=1; Q=1;
                elseif (eq(k).results(val).Q <0. && eq(k).results(val).Q > -0.5)    %out.fairN
                    N=1; Q=2;
                elseif eq(k).results(val).Q >0.7                                    %out.good
                    N=0; Q=1;
                elseif (eq(k).results(val).Q <0.7 && eq(k).results(val).Q > 0.3)    %out.fair
                    N=0; Q=2;
                else                                                                %out.poor
                    N=0; Q=3;
                end
            end


            disp(['station ',config.stnname,' event ' ,eq(k).dstr,' (JD=',num2str(eq(k).date(7)), ' ID=',num2str(k),')',...
                ' Phase ',eq(k).results(val).SplitPhase,' N=',num2str(N),...
                ' Q=',num2str(Q),' ',eq(k).results(val).Qstr,' depth= ',num2str(i)]);

            stn   = config.stnname;
            date  = eq(k).dstr;
            baz   = eq(k).bazi;
            Elat  = eq(k).lat;
            Elong = eq(k).long;
            phi   = eq(k).results(val).phiEV(1);
            dphi  = eq(k).results(val).phiEV(2);
            dt    = eq(k).results(val).dtEV(1);
            ddt   = eq(k).results(val).dtEV(2);
            AQ    = eq(k).results(val).Q;
            MQ    = eq(k).results(val).Qstr;
            
            P     = taupPierce(config.earthmodel,...
                eq(k).depth,...
                thisphase,...
                'sta', [config.slat config.slong],...
                'evt', [eq(k).lat eq(k).long], 'pierce',i, 'nodiscon'); % make the TauPpierce command for each piercing depth i
            
            dd = P(1).pierce.depth;
            %f  = find(2700<dd & dd<3000); %find Core-Mantle boundary
            f  = find(dd==i);
            f  = f(end); %consider only receiver-side pierce point
            PLat = P(1).pierce.latitude(f);
            PLon = P(1).pierce.longitude(f);
            
%
% for the null, either to plot baz or phi. 
% here we choose the baz and put all dt to 2.00
%

dt=dt*1; % factor in case of small dt, to plot in GMT at a larger scale

            if     Q==1 && N==1
                dt=2.00;
                fprintf(GNfile,'%8.3f %8.3f %6.2f %.2f %s %s-%s\n', PLat, PLon, baz, dt, config.stnname, eq(k).dstr, num2str(eq(k).date(7)));
            elseif Q==2 && N==1
                dt=2.00;
                fprintf(FNfile,'%8.3f %8.3f %6.2f %.2f %s %s-%s\n', PLat, PLon, baz, dt, config.stnname, eq(k).dstr, num2str(eq(k).date(7)));
            elseif Q==1 && N==0
                fprintf(Gfile,'%8.3f %8.3f %6.2f %.2f %s %s-%s\n', PLat, PLon, phi, dt, config.stnname, eq(k).dstr, num2str(eq(k).date(7)));
            elseif Q==2 && N==0
                fprintf(Ffile,'%8.3f %8.3f %6.2f %.2f %s %s-%s\n', PLat, PLon, phi, dt, config.stnname, eq(k).dstr, num2str(eq(k).date(7))); 
            elseif Q==3 && N==0
                fprintf(Pfile,'%8.3f %8.3f %6.2f %.2f %s %s-%s\n', PLat, PLon, phi, dt, config.stnname, eq(k).dstr, num2str(eq(k).date(7)));      
            end
            
            if Q==1 && N==0
                fprintf(GTable,'%-5s\t%-s\t%-5.1f\t%-7.2f\t%-7.2f\t%-6.2f\t%-5.2f\t%-4.2f\t%-4.2f\t%-5.3f\t%-s\n', stn, date, baz, Elat, Elong, phi, dphi, dt, ddt, AQ, MQ);
            end
            if Q==2 && N==0
                fprintf(FTable,'%-5s\t%-s\t%-5.1f\t%-7.2f\t%-7.2f\t%-6.2f\t%-5.2f\t%-4.2f\t%-4.2f\t%-5.3f\t%-s\n', stn, date, baz, Elat, Elong, phi, dphi, dt, ddt, AQ, MQ);
            end
            if Q==3 && N==0
                fprintf(PTable,'%-5s\t%-s\t%-5.1f\t%-7.2f\t%-7.2f\t%-6.2f\t%-5.2f\t%-4.2f\t%-4.2f\t%-5.3f\t%-s\n', stn, date, baz, Elat, Elong, phi, dphi, dt, ddt, AQ, MQ);
            end
            if Q==1 && N==1 || Q==2 && N==1
                fprintf(NTable,'%-5s\t%-s\t%-6.2f\t%-7.2f\t%-7.2f\t%-4.2f\t%-s\n', stn, date, baz, Elat, Elong, AQ, MQ);
            end
        end
    end
end
end

fclose all;