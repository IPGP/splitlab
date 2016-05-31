function varargout=noisecancellation(inSeis, NoisemaxWin, varargin)
% S=rsacsun('L:\RioTinto\200406-200502\SACraw\Station_20\2004oct20_064810191753_07.N.sac');
% S=rsacsun('L:\RioTinto\200406-200502\SACraw\Station_01\2004aug09_204400116944_02.N.sac');
% S=rsacsun('L:\RioTinto\200406-200502\SACraw\Station_22\2004aug28_175400141552_11.E.sac');
% S=rsacsun('L:\RioTinto\200406-200502\SACraw\Station_15\2004aug29_230435898688_04.Z.sac');
% 
% S1=rsacsun('.\2004oct20_064810191753_07.N.sac');
% S2=rsacsun('.\2004aug28_175400141552_11.E.sac');
% S3=rsacsun('.\2004aug29_230435898688_04.Z.sac');
% S4=rsacsun('.\2004aug09_204400116944_02.N.sac');
if nargout==2 && nargin ~=3
    error ('Need sampling rate as third input argument!')
end




Amp = inSeis(:);
len = length(Amp);
o   = nextpow2(len);
L   = 2^o;

Amp(end+1:L)   = 0;
Noise          = Amp(1:NoisemaxWin);
Noise(end+1:L) = 0;


len2  = round(len*.01); %taper length is 1% of total seismogram length
nn   = 1:len2;
nn2  = (len-len2+1):len;
x    = linspace(pi, 2*pi, len2);
taper  = 0.5 * (cos(x')+1);
taper2 = flipud(taper);

mPA   = 0;
loops = 0;
sam =(2^(o-1))+1;
in=1:sam;
FF=nan((2^(o-1))+1,3);

thres =.7;
nspikes=0;
while loops<4 &length(in)>sam*thres%&nspikes <15; 
    loops=loops+1;
    % taper at begin             taper at end of seismogram
    Amp(nn) = Amp(nn).*taper;    Amp(nn2) = Amp(nn2).*taper2;

    if nargin==3
        smpl=varargin{1};
    else
        smpl=6000;
    end
     f = smpl*(0:2^(o-1))/2^o;


    x=Noise;
    %power spectrum of the noise cross-correlation
    Yfft = fft(x,2^o);
    Px   = Yfft.* conj(Yfft) / 2^o;


    if max(Px)==0
        mm = 1;
    else
        mm = max(Px);
    end
    spec = Px(1:(2^(o-1))+1)/mm;
    
    
     [V,L,in]=ransacfitline([(1:length(spec))' spec   0*spec]', 1/15);
%    in =find(spec<1/15);
%     spike=find(spec<1/15); 
%     nspikes= length(find(diff(spike)~=1))


%     figure(50+loops)
%     plot(f,spec,'b-', f(in),spec(in),'k.')
%     pause(.5)
    %     [loops length(in) sam*thres]

    %check if average power level has spikes
    %     level = mean(Px)/ mm;
    %     if level > 15/100
    %         disp(['no spikes detected for iteration ' num2str(loops)])
    %         break
    %     end

    Afft = fft(Amp,2^o);
    if length(in)<sam*thres%nspikes>15
        break
    end
    Px=Px/mm;

    %     mPA  = (median(Px)/std(Px)*100);
    Fil = 1 - (Px);

    Fil(Fil<0.001)=0.001;
    Fil(Fil>=1)=1;


    % Filtered signal
    Amp   = ifft(Afft.*Fil(:) );
    Noise = Amp(1:NoisemaxWin);
    Noise(end+1:L)=0;


    if nargout~=1
        %spectrum of filter amplitude
        FF(:,loops)    = Fil(1:((2^(o-1))+1));
        % power spectrum of whole trace
        Power(:,loops) = Afft.* conj(Afft);
        Power(:,loops) = Power(:,loops)/max(Power(:,loops));
    end

end

outsignal = Amp(1:len);
if loops ~=4
    Power(:,end+1) = Afft.* conj(Afft);
    Power(:,end)   = Power(:,end)/max(Power(:,end));
end

%%
switch nargout
    case 0
        figure(3)
        clf
        t=1:len;
        subplot(2,1,1)
        plot(t,inSeis+max(abs(inSeis))-mean(inSeis),'r',  t,outsignal-max(abs(outsignal))-mean(outsignal),'k')
        %        xlim([200 600])
        set(gca,'ytick',[])
        xlabel('Samples')
        legend({'Original','Filtered'})


        if nargin==3
            smpl=varargin{1};
        else
            smpl=6000;
        end

        subplot(2,1,2)
        %         Power = .9*[PS(1:((2^(o-1))+1))/max(PS(1:((2^(o-1))+1))),      PI(1:((2^(o-1))+1))/max(PI(1:((2^(o-1))+1))), PA(1:((2^(o-1))+1))/max(PA(1:((2^(o-1))+1)))];
        %         plot(  f, Power(:,1), 'r-',f, Power(:,2) , 'b--',f, Power(:,3) , 'k:')
        Power = .9*Power(1:2^(o-1)+1,:);
        f = smpl*(0:2^(o-1))/2^o;
        f = repmat(f,size(Power,2),1)';
        hndlp=plot(  f, Power);

        hold on

        f = smpl*(0:2^(o-1))/2^o;
        f = repmat(f,loops-1,1)';
        hndlf= plot( f, 1+FF(:,1:loops-1));
        set([hndlp(end)      hndlf(end) ],  'linestyle',':','color','k')
        set([hndlp(1) hndlf(1)],  'linestyle','-','color','r')
        if length(hndlp)>2
            set([hndlp(2) hndlf(2)],'linestyle',':','color',[0 .6 0])
        end
        if length(hndlp)>3
            set([hndlp(3) hndlf(3)],'linestyle',':','color','b')
        end
        if length(hndlp)>4
            set([hndlp(4) ],'linestyle','-','color','c')
        end
        if length(hndlp)>5
            set([hndlp(5) ],'linestyle',':','color','y')
        end
        drawnow

        line([0 max(xlim)] ,[1 1],'color','k')
        hold off
        set(gca,'Ytick', [0 .9 1 2],'Yticklabel' ,'0|1|0|1')
        legtxt={'Initial Spectrum','First run','Second Run','Third run','fourth run','Fifth run'};
        legend(legtxt(1:length(hndlp)))
        xlabel('Frequency [Hz]')



    case 1
        varargout{1} = outsignal;
    case 2

        smpl=varargin{1};
        f = smpl*(0:2^(o-1))/2^o;
        varargout{1} = outsignal;
        varargout{2} = [f', sum(FF,2)-loops+1];
end
