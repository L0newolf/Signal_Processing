function [ ] = plotResultsArray( results )

close all;
clearvars -except results;

numLoops = size(results);

set(0,'DefaultFigureWindowStyle','docked');

figure();
for i=1:numLoops
    
    subplot_tight(3,2,1,[0.04,0.02,0.04]);
    plot(real(results{i}.u));
    hold on;
    plot(imag(results{i}.u));
    title('TX Signal');
    
    subplot_tight(3,2,2,[0.04,0.02,0.04]);
    plot(abs(results{i}.h));
    title('Channel multipath');
    
    subplot_tight(3,2,3,[0.04,0.02,0.04]);
    plot(real(results{i}.channelDelayedSignal));
    hold on;
    plot(imag(results{i}.channelDelayedSignal));
    title('Signal with channel multipath delay');
    
    subplot_tight(3,2,4,[0.04,0.02,0.04]);
    plot(real(results{i}.noise));
    hold on;
    plot(imag(results{i}.noise));
    title('SaS Noise');
    
    subplot_tight(3,2,5,[0.04,0.02,0.04]);
    plot(real(results{i}.r));
    hold on;
    plot(imag(results{i}.r));
    title('RX Signal with multipath delay and noise');
    
    subplot_tight(3,2,6,[0.04,0.02,0.04]);
    plot(real(results{i}.r));
    hold on;
    plot(imag(results{i}.r));
    title('Input to channel estimator');
    
end

channelLen = length(results{1}.h);
Nc=results{1}.Nc;
channel = [results{1}.h' zeros(1,Nc+1-channelLen)];
figure();
subplot_tight(1,1,1,[0.04,0.02,0.04]);
plot(abs(channel)','*','MarkerSize',10,'linewidth',2);
hold on;
for i=1:numLoops
    Nc=results{i}.Nc;
    hCapC=flipud(abs(results{i}.hCap(1:Nc+1)));
    plot(hCapC,'x','MarkerSize',10,'linewidth',2);
    hold on;
end 
title('Simulated and Estimated channel causal taps');
hold off;



figure();
subplot_tight(1,1,1,[0.04,0.02,0.04]);
for i=1:numLoops
    Nc=results{i}.Nc;
    channelLen = length(results{i}.h);
    channel = [results{i}.h' zeros(1,Nc+1-channelLen)];
    hErr=abs(flipud(abs(results{i}.hCap(1:Nc+1)))-abs(channel)');
    plot(hErr,'o','MarkerSize',10,'linewidth',2);
    hold on;
end 
set(gca, 'YScale', 'log');
title('Error between Simulated and Estimated channel causal taps');
hold off;


figure();
for i=1:numLoops
    
    subplot_tight(2,2,1,[0.04,0.02,0.04]);
    plot(abs(results{i}.Bvals));
    hold on;
    title('B');
    
    subplot_tight(2,2,2,[0.04,0.02,0.04]);
    plot(abs(results{i}.Qvals));
    hold on;
    title('Q');
    
    subplot_tight(2,2,3,[0.04,0.02,0.04]);
    plot(results{i}.sigmaVals);
    hold on;
    plot(results{i}.epsilonVals);
    plot(results{i}.deltaVals);
    plot(results{i}.tauVals);
    plot(abs(results{i}.errVals));
    legend('sigmaVals','epsilonVals','deltaVals','tauVals','errors');
    title('sigma,epsilon,delta and tau');
    
    subplot_tight(2,2,4,[0.04,0.02,0.04]);
    plot(results{i}.medReal);
    hold on;
    plot(results{i}.medImag);
    set(gca, 'YScale', 'log');
    legend('median real err win','median imag err win');
    title('medians of error window');
end
hold off;


figure();
subplot_tight(1,1,1,[0.04,0.02,0.04]);
for i=1:numLoops
    plot(abs(results{i}.yNoISI-results{i}.u-results{i}.noise));
    hold on;
end
hold off;
set(gca, 'YScale', 'log');
title('Error between Tx signal and ISI free Rx ( removed added noise)');

figure();
subplot_tight(1,1,1,[0.04,0.02,0.04]);
for i=1:numLoops
    plot(abs(results{i}.d-results{i}.dCap));
    hold on;    
end
hold off;
set(gca, 'YScale', 'log');
title('Error in Tx(d) and Eq(dCap) symbols');

figure();
subplot_tight(1,1,1,[0.04,0.02,0.04]);
for i=1:numLoops
    plot(abs(results{i}.u-results{i}.dBar));
    hold on;    
end
hold off;
title('Error in genrated(u) and estimated(dBar) symbols');

figure();
subplot_tight(1,1,1,[0.04,0.02,0.04]);
for i=1:numLoops
    plot(results{i}.dataIn-results{i}.dataOut,'+','MarkerSize',10,'linewidth',2);
    hold on;    
end
hold off;
title('Bit Errors');


end

