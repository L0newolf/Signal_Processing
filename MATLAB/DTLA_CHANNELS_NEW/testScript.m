for i=1:1
    [data,Fs]=readDTLA('~/Desktop/DTLA trials May 2016/DTLA/data/051916_131818.dat',8,100,1);
    disp(['Time : ',num2str(i)]);
    figure(1);
    
    [y,f,t,p] = spectrogram(data(:),128,120,128,Fs,'yaxis');
    surf(t,f,10*log10(abs(p)),'EdgeColor','none');
    axis xy; axis tight; colormap(jet); view(0,90);
    xlabel('Time');
    ylabel('Frequency (Hz)');
    
    [b,a]=butter(2,[(6000)/(Fs/2),(10000/(Fs/2))]);
    filtSig = filter(b,a,data);
    figure(2);
    [y,f,t,p] = spectrogram(filtSig(:),128,120,128,Fs,'yaxis');
    surf(t,f,10*log10(abs(p)),'EdgeColor','none');
    axis xy; axis tight; colormap(jet); view(0,90);
    xlabel('Time');
    ylabel('Frequency (Hz)');
    pause(1);
end