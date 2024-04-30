function [  ] = plotBER( SNR,BER )

figure();
subplot_tight(1,1,1,[0.04,0.02,0.04]);

newLen = (1000)*length(SNR);
snrPlot = min(SNR):1/newLen:max(SNR);
berPlot = spline(SNR,BER,snrPlot);

plot(snrPlot,berPlot);
title('BER vs SNR plot');
set(gca, 'YScale', 'log');
grid on;
end

