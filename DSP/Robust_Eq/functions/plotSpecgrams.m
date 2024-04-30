function [] = plotSpecgrams( samplesPerSymb,nFFT,Fs,data,figNum,numPlots,plotNum,plotTitle )

figure(figNum);
subplot_tight(numPlots,2,2*plotNum-1,[0.05,0.03,0.04]);
spectrogram( data,samplesPerSymb,0,nFFT,Fs,'yaxis');
colorbar('off');
subplot_tight(numPlots,2,2*plotNum,[0.05,0.03,0.04]);
plot(real(data));
title(plotTitle);
%set(gca,'xtick',[],'ytick',[])

end

