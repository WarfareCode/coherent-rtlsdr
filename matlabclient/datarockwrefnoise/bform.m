%Coherent-RTL-SDR

%Analyze results saved by measurement_script in parent...

%uses Data space to figure units converter from mathworks:
%https://se.mathworks.com/matlabcentral/fileexchange/10656-data-space-to-figure-units-conversion


%addpath(genpath('functions'))
clear all; close all;
addpath('../functions');

FESR = 1e6; % 2048000;
scope = dsp.SpectrumAnalyzer(...
    'Name',             'Spectrum',...
    'Title',            'Spectrum', ...
    'SpectrumType',     'Power',...
    'FrequencySpan',    'Full', ...
    'SampleRate',        FESR, ...
    'YLimits',          [-50,5],...
    'SpectralAverages', 50, ...
    'FrequencySpan',    'Start and stop frequencies', ...
    'StartFrequency',   -FESR/2, ...
    'StopFrequency',    FESR/2);

%First dataset, with reference noise on:
mdata1 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22; %measurement number.
         0,-15,-30,-45,-60,-75,-75,-90,-105,-120,-120,-135,-150,-165,-180,-195,0,-30,-60,-90,-120,-150,-180;%x
           6.3*ones(1,23); % d was 6.3meter, in all
         -1.35*ones(1,16), 0*ones(1,7)]; %y; on floor, center patch was at 1.35m

truedoa1 = (180/pi)* atan([(mdata1(2,:)/100)./mdata1(3,:);
                          mdata1(4,:)./mdata1(3,:)]);

%dataset with automatic switching..., transmitter on floor again                      
mdata2 = [23,24,25,26,27,28,29,30,31,32,33;
         0,-30,-60,-60,-90,-120,-120,-150,-150,-180,-180;
         6.3*ones(1,11);
         -1.35*ones(1,11)];

%transmitter on box, 0.15 from floor level     
mdata3 =[41,40,39,38,37,36,34,35;
         0,-30,-60,-90,-120,-150,-180,-180;
         6.3*ones(1,8);
         -1.20*ones(1,8)];

%transmitter ~1.35m from floor
mdata4 =[42,43,44,45,46,47,48;
         0,-30,-60,-90,-120,-150,-180;
         6.3*ones(1,7);
         0*ones(1,7)];     

%Choose dataset and calculate true doas.     
mdata = mdata4;

truedoa = (180/pi)* atan([(mdata(2,:)/100)./mdata(3,:);
                          mdata(4,:)./mdata(3,:)]);
                     

%Matlab steervec() compatible element position matrix:
dx = (0:6)'*0.5;
dy = (2:-1:0)'*0.5;
epos=[repmat(dy',1,7);repelem(dx',3)];

b = fir1(128,1/16);


%number of signals
K=3;
%use direct augmentation
DA=1;

for nn= 1:length(mdata)
    load(['meas' num2str(mdata(1,nn)) '.mat']);

    X = X(:,end:-1:2);
    
    X = filter(b,1,X); %limit bandwidth
    %scope(X);

    [P,Nx,Ny] = pmusic(X,epos,K,DA);
    
    %find the peak:
    [m,idx]  = max(P(:));
    [idxx idxy] = ind2sub(size(P),idx);
    
    alphas = -90:90; betas  = -90:90;
    clf;
    imagesc(alphas,betas,10*log10(P)); colorbar;
    
    %add the true DOA as annotation
    xa        = [truedoa(1,nn) truedoa(1,nn)-1];
    ya        = [truedoa(2,nn) truedoa(2,nn)-1];
    
    [xaf,yaf] = ds2nfu(xa,ya); %see link in header.
    annotation('textarrow',xaf,yaf,'String','TRUE','Color','red');
    

   % annotation('textarrow',[0.128 0.128],...
   %[0.105 0.105],'String','TRUE','Color','red');

    minn = 10*log10(min(P,[],'all'));
    ttl = sprintf('%d X %d array. Peak location: %d, %d. Nse floor: %d dB\n True doa: %d, %d',Nx,Ny, ...
          round(idxx-91), round(idxy-91),round(minn),round(truedoa(1,nn)),round(truedoa(2,nn)));
    title(ttl);
    xlabel('Azimuth [deg]');
    ylabel('Elevation [deg]');
    
    drawnow;
    pause(1);
end