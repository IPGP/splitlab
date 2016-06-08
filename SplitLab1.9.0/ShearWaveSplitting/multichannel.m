function makeSIplotsv2
% function to calculate the apparent phi & dt of a station from multichannel analysis (Chevrot, 2000)

global config


%close('Multichannel analysis')

plot_title = sprintf('Multichannel analysis -- Station %s', config.stnname);
ofile      = sprintf('%s/SI_%s', config.savedir, config.stnname);

out = SL_Results_getvalues;

%% Generation of the splitting intensities matrix before weighted mean
SI(:,1) = out.back;
SI(:,2) = out.SI(:,1);
SI(:,3) = out.SI(:,2);

%% Computation of weighted SI in 10° azimuthal bins
[SI(:,1),j] = sort(SI(:,1));
SI(:,2)     = SI(j,2);
SI(:,3)     = SI(j,3);
    
[xx,dd,dd_err,~] = runwmean(SI(:,1),SI(:,2),SI(:,3),10);

bazm   = xx(dd~=0)';
SIm    = dd(dd~=0);
SIerrm = dd_err(dd~=0);


%% Determinantion of best fitting phi & dt
[~,dt,phi,ddt,dphi,~,~]=fit_sin_new(SIm,bazm,SIerrm);


%% Saving of the the results
config.mean_res.phiSI = [phi dphi];
config.mean_res.dtSI  = [dt ddt];

filename = fullfile(config.projectdir,config.project);
save(filename,'config');


%% Plot of the data and curves:
    % Plot of the stacked SI measurements
    tit = ['Multichannel analysis of ', config.project];
    figSI = findobj('type', 'figure', 'Name', tit);
    if isempty(figSI)
        figure('Name', tit, 'NumberTitle', 'off');
    else
        figure(figSI)
        clf
    end

    errorbar(bazm,SIm,2*SIerrm,'ko','Markersize',5,'MarkerFaceColor','r');
    hold on;

    % plot best fit sinusoid
    az  = (0:pi/100:2*pi);
    app = dt*sin(2*(az-phi*(pi/180)));
    plot(az*(180/pi),app,'k','LineWidth',1);

    % figure
    fontsize = get(0,'FactoryAxesFontsize');
    title({plot_title;...
           ['\phi = ', num2str(round(phi)),' ± ', num2str(round(dphi)),';  \deltat = ', num2str(dt,2),' ± ',num2str(ddt,1)]},...
           'Fontsize',fontsize+5,...
           'FontName','Courier');

    axis([0 360 -config.maxSplitTime config.maxSplitTime]);
    set(gca, 'Xtick', 0:45:360, 'Ytick', linspace(-config.maxSplitTime, config.maxSplitTime, 5), 'xMinorTick', 'on', 'yminorTick', 'on');
    xlabel('Backazimuth (°)', 'FontSize', fontsize+5);
    ylabel('Splitting Intensity (s)', 'FontSize', fontsize+5);

    print(figSI,'-dpng',ofile,'-r300');