clear all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD MFSK PARAMS
for freqLoops = 1:1
    for symbLoops = 1:1
        
        % MFSK PARAMETSRS
        Fs = 18000;
        Ts = 1/Fs;
        bandWidth = 14000;
        freqStep = 500;%100*freqLoops + 100;
        symbolRate = 300;%10*symbLoops;
        bitsPerFreq = 2;
        StopTime = 0.0075;
        padDur = 0.0005;
        nFFT = 8192;
        numLoops = 5;
        
        freqs = (1:Fs/nFFT:Fs)';
        
        [ freqTonesRX,freqTones,samplesPerSymb,bitsPerSymb,tonesPerBand,maxFreqBands,numFreqTones ] = loadParams( bandWidth,symbolRate,Fs,freqStep,bitsPerFreq );
        
        
        % Compute window:
        winLen = samplesPerSymb;
        lenFactor = 1;
        [p,win] = srrc(winLen/lenFactor,0.5,lenFactor);
        win(length(win)) = [];
        p(length(p)) = [];
        
        numBits = 50;
        numSamples = 0;
        while(numSamples < Fs)
            numBits = numBits + 8;
            [ numSamples ] = computeSigLen( numBits,padDur,samplesPerSymb,bitsPerSymb,bitsPerFreq,Fs );
        end
        
        numBits = numBits - 8;
        [ numSamples ] = computeSigLen( numBits,padDur,samplesPerSymb,bitsPerSymb,bitsPerFreq,Fs );
        
        if(numSamples > Fs)
            X = ['Number of Samples : ',num2str(numSamples),'  Exceeded Buffer Length'];
            disp(X);
            return;
        else
            X = ['Number of Samples : ',num2str(numSamples),' for symbol rate : ',num2str(symbolRate),' and freq step : ',num2str(freqStep),' and num bits : ',num2str(numBits)];
            disp(X);
        end
        
        bitsCount(symbLoops) = numBits;
        
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
            
            padSamples = floor(padDur*Fs);
            samplesPerSymBlock = samplesPerSymb+padSamples;
            
            curSymbolTx = zeros(numSymbols,samplesPerSymBlock);
            timeStep = 1/Fs;
            
            bitsPtr = 1;
            
            for i=1:loopCount
                
                [ curSymbolTx(i,1:samplesPerSymb) ] = genSamples( inBits,bitsPtr,freqTones,tonesPerBand,samplesPerSymb,timeStep,maxFreqBands );
                bitsPtr = bitsPtr + 2*maxFreqBands;
                
            end
            
            if (loopRemBits ~= 0)
                [ curSymbolTx(numSymbols,1:samplesPerSymb) ] = genSamples( inBits,bitsPtr,freqTones,tonesPerBand,samplesPerSymb,timeStep,loopRemBits );
            end
            
            %%APPLY WINDOW AT TX
            for i=1:numSymbols
                curSymbolTx(i,1:samplesPerSymb) = curSymbolTx(i,1:samplesPerSymb).*win;
            end
            
            for i=1:numSymbols
                txSigBuf = [txSigBuf curSymbolTx(i,:)];
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% CHANNEL SIMULATION
            
            noiseMult = 1;
            run('loadNoise');
            noise = noise(1:length(txSigBuf));
            
            rxSigBuf = txSigBuf;
            [ isiWin ] = genIsiWin( Fs,StopTime );
            rxSigBuf = conv(rxSigBuf,isiWin);
            rxSigBuf = rxSigBuf(1:length(txSigBuf));
            rxSigBuf = rxSigBuf+noiseMult*noise';
            
            rxSigBufNoProc = txSigBuf+noiseMult*noise';
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% DEMODULATION
            
            powerLevels = zeros(numSymbols,numFreqTones);
            loopCount = floor(numBits/bitsPerSymb);
            loopRemBits = mod(numBits,bitsPerSymb)/bitsPerFreq;
            
            if(loopRemBits ~= 0)
                numSymbols = loopCount +1;
            else
                numSymbols = loopCount;
            end
            
            padSamples = floor(padDur*Fs);
            padding = zeros(1,padSamples);
            samplesPerSymBlock = samplesPerSymb+padSamples;
            
            curSymbolRx = zeros(numSymbols,samplesPerSymb);
            
            for i=1:numSymbols
                startPtr = samplesPerSymBlock*(i-1)+1;
                curSymbolRx(i,:) = rxSigBuf(startPtr:startPtr+samplesPerSymb-1);
            end
            
            %%APPLY WINDOW AT RX
            for i=1:numSymbols
                curSymbolRx(i,1:samplesPerSymb) = curSymbolRx(i,1:samplesPerSymb).*win;
            end
            
            timeStep = 1/Fs;
            
            outBitsPtr = 1;
            outBits = [];
            
            for i=1:loopCount
                [ curBits,powerLevels(i,:) ] = getDemodBits( curSymbolRx(i,:),samplesPerSymb,freqTonesRX,Fs,tonesPerBand,numFreqTones );
                outBits = [outBits curBits];
            end
            
            if (loopRemBits ~= 0)
                [ curBits,powerLevels(numSymbols,1:loopRemBits*tonesPerBand) ] = getDemodBits( curSymbolRx(numSymbols,:),samplesPerSymb,freqTonesRX,Fs,tonesPerBand,loopRemBits*tonesPerBand );
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
                        curPlot = noise;
                        plotTitle = 'NOISE SIGNAL';
                    case 3
                        curPlot = rxSigBuf;
                        plotTitle = 'RX SIGNAL WITH POST PROCESSING';
                end
                
                plotSpecgrams( samplesPerSymBlock,nFFT,Fs,curPlot,figNum,numPlots,i,plotTitle );
                
            end
            
            %% PLOT TX SIGNAL AND PSD
            
            for i=1:numSymbols
                
                fftTx = abs(fft(curSymbolTx(i,:),nFFT));
                fftTx = 300*(fftTx/(max(fftTx)));
                figure(2);
                subplot_tight(3,2,1,[0.04,0.02,0.04]);
                plot(real(curSymbolTx(i,:)));
                subplot_tight(3,2,3,[0.04,0.02,0.04]);
                %plot(freqs,abs(fftTx));
                stem(freqTonesRX,20 * powerLevels(i,:));
                subplot_tight(3,2,4,[0.04,0.02,0.04]);
                plot(freqs,20 * log(abs(fftTx)));
                
                fftRx = abs(fft(curSymbolRx(i,:),nFFT));
                fftRx = 300*(fftRx/(max(fftRx)));
                figure(2);
                subplot_tight(3,2,2,[0.04,0.02,0.04]);
                plot(real(curSymbolRx(i,:)));
                subplot_tight(3,2,5,[0.04,0.02,0.04]);
                %plot(freqs,abs(fftRx));
                stem(freqTonesRX,20 * powerLevels(i,:));
                subplot_tight(3,2,6,[0.04,0.02,0.04]);
                plot(freqs,20 * log(abs(fftRx)));
                
                %pause(0.25);
                
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
        
        avgBer(symbLoops) = sum(berVal)/length(berVal);
        
        figure(3);
        hold on;
        ax = plot(berVal);
        hold off;
        
    end
    
    figure(4);
    hold on;
    plot(1:symbLoops,avgBer);
    hold off;
    
    pause(1);
    
end
