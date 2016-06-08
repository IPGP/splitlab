function splitWolfeSilver
% Function to calculate apparent phi & dt of a station using the stacking of energy maps (Wolfe and Silver, 1998).

global eq config

plot_title = sprintf('Stacked energy map of T -- Station %s',config.stnname);
ofile      = sprintf('%s/WolfeSilver_%s',config.savedir,config.stnname);


%% Initialize Esurf matrix (the matrix where error maps will be stacked)
thiseq = readseis3D(config,eq(1));     % looks for delta of the seismograms (1/sampling freq.)  

delta      = thiseq.dt;                % delta of the seismogram
stepdt     = config.StepsDT;           % steps in samples for the delays 
stepphi    = config.StepsPhi;          % steps in degrees for the phi
mSplitTime = config.maxSplitTime;      % maximum splitting delay chosen by the user

dt_mod = 0:(stepdt*delta):mSplitTime;  % vector containing the delays steps 

lphi = length(-90:stepphi:90)-1;   % size of the phi vector
ldt  = length(dt_mod);             % size of the dt vector

if dt_mod(ldt) ~= mSplitTime
    ldt = ldt+1;
end

Esurf = zeros(lphi,ldt);

ndf = 0;
K=2;
for i = 1:length(eq) % Loop over each event with result
    if isempty(eq(i).results);        
    else
        for val = 1:length(eq(i).results)     % Loop over number of results per event
            thiseq = eq(i).results(val);
            if ~strcmp('Poor    ',thiseq.Qstr)
                Emap = thiseq.ErrorSurface(:,:,1);
                lmin = min(Emap(:));
                ndf = ndf + thiseq.ndfSC;
                Esurf = Esurf + (Emap/lmin);
            else
                continue
            end
        end
    end
end

% Energy Map
Ematrix=Esurf;
Ematrix(end+1,:) = Ematrix(1,:);

[m,i] = min(Ematrix);
[n,j] = min(m);
Eresult=n;
Ecrit = Eresult*(1+K*sign(Eresult) / (ndf-K)*inv_f(K,ndf-K));

%% reconstruct grid
f     = size(Ematrix);
dphi  = 180/(f(1)); %grid size in phi direction
dt    = config.maxSplitTime/(f(2)-1);   %grid size in dt direction
    
[cols, rows] = incontour(Ematrix,Ecrit);
    
errbar_phi = (rows-1) * dphi-90;
errbar_phi = mod(errbar_phi+180,180);
errbar_phi = 0.25*abs(diff(mod(errbar_phi,180)));
errbar_t   = (cols-1) * dt;
errbar_t   = 0.25*abs(diff(errbar_t));


%% plotting
ts = linspace(0,mSplitTime,f(2));
ps = linspace(-90,90,f(1));

phi = ps(i(j));
dt  = ts(j); 

maxi = max(abs(Ematrix(:)));
mini = min(abs(Ematrix(:)));
nb_contours = floor((1 - mini/maxi)*7);

config.mean_res.phiWS = [phi errbar_phi(1)];
config.mean_res.dtWS  = [dt errbar_t(1)];
filename = fullfile(config.projectdir,config.project);
save(filename,'config','eq');

tit = ['Stacked energy map of ', config.project];
figSW = findobj('type', 'figure', 'Name', tit);
if isempty(figSW)
    figure('Name', tit, 'NumberTitle', 'off');
else
    figure(figSW)
    clf
end

[~,h] = contourf(ts,ps,-Ematrix,-[Ecrit Ecrit]);
hold on;
contour(ts, ps, Ematrix, nb_contours);
colormap(gray)
line([0 config.maxSplitTime], [ps(i(j)) ps(i(j))], 'Color', 'k')
line([ts(j) ts(j)], [-90 90], 'Color', 'k')
hold off;

fontsize = get(0, 'FactoryAxesFontsize');
titlefontsize = fontsize+3;

title({plot_title,...
       ['\phi = ', num2str(round(phi)),' � ', num2str(round(errbar_phi(1))),';  \deltat = ', num2str(dt,2),' � ',num2str(errbar_t(1),1)]},....
       'Fontname', 'Courier',...
       'FontSize', titlefontsize+2);

axis([0 config.maxSplitTime -90 90])
set(gca, 'Xtick', linspace(0,config.maxSplitTime,5), 'Ytick',-90:30:90, 'xMinorTick', 'on', 'yminorTick', 'on')
xlabel('\deltat (s)', 'Fontsize', fontsize+5)
ylabel('\phi (�)', 'Fontsize', fontsize+5)
set(h, 'FaceColor', [1 1 1]*.90, 'EdgeColor', 'k', 'linestyle', '-', 'linewidth', 1.5)

print(figWS, '-dpng', ofile, '-r300');

%%
function data = inv_f(~, nu2)
%using tablelook up for finding the Inverse of the F cumulative
%distribution function. First Degree of Freedom in our case is always 2
%(2 independant parameter: phi, dt. The second degree of fredom was estimated
% from transverse component

if nu2>100, nu2 = 100; end %using last value in table, no big change

%table created with MATLAB statistics Toolbox Command:
% fdata = finv(0.95,2,1:100)';
data=[...
    199.5000
    19.0000
    9.5521
    6.9443
    5.7861
    5.1433
    4.7374
    4.4590
    4.2565
    4.1028
    3.9823
    3.8853
    3.8056
    3.7389
    3.6823
    3.6337
    3.5915
    3.5546
    3.5219
    3.4928
    3.4668
    3.4434
    3.4221
    3.4028
    3.3852
    3.3690
    3.3541
    3.3404
    3.3277
    3.3158
    3.3048
    3.2945
    3.2849
    3.2759
    3.2674
    3.2594
    3.2519
    3.2448
    3.2381
    3.2317
    3.2257
    3.2199
    3.2145
    3.2093
    3.2043
    3.1996
    3.1951
    3.1907
    3.1866
    3.1826
    3.1788
    3.1751
    3.1716
    3.1682
    3.1650
    3.1619
    3.1588
    3.1559
    3.1531
    3.1504
    3.1478
    3.1453
    3.1428
    3.1404
    3.1381
    3.1359
    3.1338
    3.1317
    3.1296
    3.1277
    3.1258
    3.1239
    3.1221
    3.1203
    3.1186
    3.1170
    3.1154
    3.1138
    3.1123
    3.1108
    3.1093
    3.1079
    3.1065
    3.1052
    3.1038
    3.1026
    3.1013
    3.1001
    3.0989
    3.0977
    3.0966
    3.0954
    3.0943
    3.0933
    3.0922
    3.0912
    3.0902
    3.0892
    3.0882
    3.0873];

data=data(nu2);

