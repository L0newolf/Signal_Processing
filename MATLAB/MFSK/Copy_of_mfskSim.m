clear all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD MFSK PARAMS
run('loadParams');

numLoops = 100;



%% SIM LOOP 
for a=1:numLoops

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input Bits

rng(a);
inBits = zeros(1,numBits);
for i=1:numBits
    inBits(i) = mod(randi(10000),2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MODULATION

txSigBuf = [];

loopCount = floor(numBits/bitsPerSymb);
loopRemBits = mod(numBits,bitsPerSymb)/bitsPerFreq;

if(loopRemBits ~= 0)
    numSymbols = loopCount +1;
else
    numSymbols = loopCount;
end

curSymbolTx = zeros(numSymbols,samplesPerSymb);
timeStep = 1/Fs;

bitsPtr = 1;

for i=1:loopCount
    
    [ curSymbolTx(i,:) ] = genSamples( inBits,bitsPtr,freqTones,tonesPerBand,samplesPerSymb,timeStep,maxFreqBands );
    bitsPtr = bitsPtr + 2*maxFreqBands;
    
end

if (loopRemBits ~= 0)
    [ curSymbolTx(numSymbols,:) ] = genSamples( inBits,bitsPtr,freqTones,tonesPerBand,samplesPerSymb,timeStep,loopRemBits );
end

%%APPLY WINDOW AT TX
for i=1:numSymbols
    curSymbolTx(i,:) = curSymbolTx(i,:).*win;
end


for i=1:numSymbols
    txSigBuf = [txSigBuf curSymbolTx(i,:)];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CHANNEL SIMULATION

noiseMult = 1.7;
run('loadNoise');
noise = noise(1:length(txSigBuf));

[ isiWin ] = (genIsiWin( Fs,StopTime ))';
txSigIsi = conv(txSigBuf,isiWin);
txSigIsi = txSigIsi(1:length(txSigBuf));

% rxSigBuf = txSigBuf+noiseMult*noise';
% rxSigBufNoProc = txSigBuf+noiseMult*noise';

rxSigBuf = txSigIsi+noiseMult*noise';
rxSigBufNoProc = txSigIsi+noiseMult*noise';

figure(4);
stem((isiWin));
plotSpecgrams( samplesPerSymb,nFFT,Fs,txSigBuf,5,2,1,'NO ISI' );
plotSpecgrams( samplesPerSymb,nFFT,Fs,txSigIsi,5,2,2,'WITH ISI' );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEMODULATION

loopCount = floor(numBits/bitsPerSymb);
loopRemBits = mod(numBits,bitsPerSymb)/bitsPerFreq;

if(loopRemBits ~= 0)
    numSymbols = loopCount +1;
else
    numSymbols = loopCount;
end

curSymbolRx = zeros(numSymbols,samplesPerSymb);
for i=1:numSymbols
    startPtr = samplesPerSymb*(i-1)+1;
    curSymbolRx(i,:) = rxSigBuf(startPtr:startPtr+samplesPerSymb-1);
end

%%APPLY WINDOW AT RX
for i=1:numSymbols
    curSymbolRx(i,:) = curSymbolRx(i,:).*win;
end

timeStep = 1/Fs;

outBitsPtr = 1;
outBits = [];

for i=1:loopCount
    [ curBits ] = getDemodBits( curSymbolRx(i,:),samplesPerSymb,freqTonesRX,Fs,tonesPerBand,numFreqTones );
    outBits = [outBits curBits];
end

if (loopRemBits ~= 0)
[ curBits ] = getDemodBits( curSymbolRx(numSymbols,:),samplesPerSymb,freqTonesRX,Fs,tonesPerBand,loopRemBits*tonesPerBand );
outBits = [outBits curBits];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SPECTROGRAM PLOTS

numPlots = 3;
figNum = 1;
for i=1:3
    
    switch i
        case 1
            curPlot = txSigBuf;
            plotTitle = 'TX SIGNAL';
        case 2
            curPlot = rxSigBufNoProc;
            plotTitle = 'RX SIGNAL NO POST PROCESSING';
        case 3
            curPlot = rxSigBuf;
            plotTitle = 'RX SIGNAL WITH POST PROCESSING';
    end
    
    plotSpecgrams( samplesPerSymb,nFFT,Fs,curPlot,figNum,numPlots,i,plotTitle );
    
end

%% PLOT TX SIGNAL AND PSD

for i=1:numSymbols
    
    fftTx = abs(fft(curSymbolTx(i,:),nFFT));
    fftTx = 300*(fftTx/(max(fftTx)));
    figure(2);
    subplot_tight(3,2,1,[0.04,0.02,0.04]);
    plot(real(curSymbolTx(i,:)));
    subplot_tight(3,2,3,[0.04,0.02,0.04]);
    plot(freqs,abs(fftTx));
    subplot_tight(3,2,4,[0.04,0.02,0.04]);
    plot(freqs,20 * log(abs(fftTx)));
    
    fftRx = abs(fft(curSymbolRx(i,:),nFFT));
    fftRx = 300*(fftRx/(max(fftRx)));
    figure(2);
    subplot_tight(3,2,2,[0.04,0.02,0.04]);
    plot(real(curSymbolRx(i,:)));
    subplot_tight(3,2,5,[0.04,0.02,0.04]);
    plot(freqs,abs(fftRx));
    subplot_tight(3,2,6,[0.04,0.02,0.04]);
    plot(freqs,20 * log(abs(fftRx)));
    
    %pause(1);
    
end

%% CHECK FOR ERRORS

errCount = 0;
for i=1:length(outBits)
    if (outBits(i) ~= inBits(i))
        errCount = errCount+1;
    end
end

berVal(a) = errCount/numBits;

end

X=['Avg BER : ',num2str(sum(berVal)/length(berVal))];
disp(X);

figure(3);
hold on;
ax = plot(berVal);
hold off;