clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MFSK PARAMETSRS
Fs = 18000;
Ts = 1/Fs;
bandWidth = 14000;
freqStep = 500;
symbolRate = 50;
bitsPerFreq = 2;
numBits = 80*8;

freqLower = -bandWidth/2;
freqUpper = bandWidth/2;
symbolDuration = 1/symbolRate;
samplesPerSymb = (symbolDuration*Fs);
numFreqTones = bandWidth/freqStep;
tonesPerBand = 2^bitsPerFreq;
maxFreqBands = floor(numFreqTones/tonesPerBand);
bitsPerSymb = bitsPerFreq*maxFreqBands;
freqTones(1)=freqLower;
freqTonesRX(1) = Fs+freqLower;
for i=2:numFreqTones
    freqTones(i) = freqTones(i-1)+freqStep;
    if(freqTones(i) < 0 )
        freqTonesRX(i) = Fs + freqTones(i);
    else
        freqTonesRX(i) = freqTones(i);
    end
end
freqTones = freqTones';

nFFT = 8192;
freqs = (1:Fs/nFFT:Fs)';
freqTonesIdx = round((freqTonesRX/Fs)*nFFT) + 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LOAD THE SIGNAL RECEIVED DURING TRIALS

figure(5);

tx_tank_data = load('data/tx_tank.txt');
tx_tank_cplx = complex(tx_tank_data(:,1),tx_tank_data(:,2));

subplot_tight(3,2,1,[0.04,0.02,0.04]);
spectrogram(tx_tank_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(3,2,2,[0.04,0.02,0.04]);
plot(((1:length(tx_tank_cplx(:,1)))/18000)',real(tx_tank_cplx));

rx_trials_data = load('data/rx_trials.txt');
rx_trials_cplx = complex(rx_trials_data(:,1),rx_trials_data(:,2));

subplot_tight(3,2,3,[0.04,0.02,0.04]);
spectrogram(rx_trials_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(3,2,4,[0.04,0.02,0.04]);
plot(((1:length(rx_trials_cplx(:,1)))/18000)',real(rx_trials_cplx));

%%%%%%%%%%%%%%%%% CLIPPING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
avgMag = 0;

beta = 0.75;
for i=1:length(rx_trials_cplx)
    curMag = abs(rx_trials_cplx(i));
    avgMag = (avgMag*(i-1) + curMag)/i;
    thresholdFactor = beta*avgMag + (1-beta)*curMag;
end

limFact = 3;
thresholdFactor = limFact*thresholdFactor;

for i=1:length(rx_trials_cplx)
    curMag = abs(rx_trials_cplx(i));
    multFact = thresholdFactor/curMag;
    if (curMag > thresholdFactor)
        rx_clipped(i,1) = rx_trials_cplx(i)*multFact;
    else
        rx_clipped(i,1) = rx_trials_cplx(i);
    end
end

subplot_tight(3,2,5,[0.04,0.02,0.04]);
spectrogram(rx_clipped,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(3,2,6,[0.04,0.02,0.04]);
plot(((1:length(rx_clipped(:,1)))/18000)',real(rx_clipped));

A=1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numSymbols = ceil(numBits/bitsPerSymb);

powLevelsTx = zeros(numFreqTones,1);
powLevelsTank = zeros(numFreqTones,1);
powLevelsTrials = zeros(numFreqTones,1);

errCountTank = zeros(numSymbols,maxFreqBands);
errCountTrials = zeros(numSymbols,maxFreqBands);

% Compute Hanning window:
winLen = samplesPerSymb;
nm = 0:winLen-1;   % time indices for window computation
lenFactor = 1;
win = srrc(winLen/lenFactor,0.7,lenFactor);
win(length(win)) = [];

hold off;

errCount = 0;
errCountClip = 0;

for i=1:numSymbols
    
    symbolCount(i) = i;
    
    curSig_tx = tx_tank_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_tx = abs(fft(curSig_tx,nFFT));
    
    curSig_tr = rx_trials_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_tr = abs(fft(curSig_tr,nFFT));
    
    curSig_clip = rx_clipped(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_clip = abs(fft(curSig_clip,nFFT));
    
    figure(4);
    subplot_tight(4,2,1,[0.04,0.02,0.04]);
    plot(real(curSig_tr));
    subplot_tight(4,2,2,[0.04,0.02,0.04]);
    plot(real(curSig_clip));
    str = ['Time Stamp =',num2str((1/numSymbols)*i)];
    text(1,4.5,str,'FontSize',16);
    
    subplot_tight(4,2,3,[0.04,0.02,0.04]);
    plot(freqs,abs(fft_tx));
    subplot_tight(4,2,4,[0.04,0.02,0.04]);
    plot(freqs,20 * log(abs(fft(curSig_tx,nFFT))));
    
    subplot_tight(4,2,5,[0.04,0.02,0.04]);
    plot(freqs,fft_tr);
    subplot_tight(4,2,6,[0.04,0.02,0.04]);
    plot(freqs,20 * log(abs(fft(curSig_tr,nFFT))));
    
    subplot_tight(4,2,7,[0.04,0.02,0.04]);
    plot(freqs,fft_clip);
    subplot_tight(4,2,8,[0.04,0.02,0.04]);
    plot(freqs,20 * log(abs(fft(curSig_clip,nFFT))));
    
    %pause(3);
    
    errNorm = mfskBer( fft_tx,fft_tr,freqTonesIdx,maxFreqBands,tonesPerBand );
    errClip = mfskBer( fft_tx,fft_clip,freqTonesIdx,maxFreqBands,tonesPerBand );
    
    errCount = errCount+errNorm;
    errCountClip = errCountClip+errClip;
    
    errDiff(i) = errNorm - errClip;
    
    if(errDiff(i) < 0)
        A=1;
    end
    
    if(errDiff(i) > 0)
        A=1;
    end
    
end

figure(7);
stem(errDiff);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(6);

for i=1:numSymbols
    
    symbolCount(i) = i;
    
    curSig_tx = tx_tank_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_tx = abs(fft(curSig_tx,nFFT));
    
    curSig_tr = rx_trials_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_tr = abs(fft(curSig_tr,nFFT));
    
    curSig_clip = rx_clipped(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_clip = abs(fft(curSig_clip,nFFT));
    
    subplot_tight(4,2,1,[0.04,0.02,0.04]);
    hold on;
    plot(real(curSig_tr));
    subplot_tight(4,2,2,[0.04,0.02,0.04]);
    hold on;
    plot(real(curSig_clip));
    
    
    subplot_tight(4,2,3,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,abs(fft_tx),'Color',[rand(),rand(),rand()]);
    subplot_tight(4,2,4,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,20 * log(abs(fft(curSig_tx,nFFT))),'Color',[rand(),rand(),rand()]);
    
    subplot_tight(4,2,5,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,fft_tr,'Color',[rand(),rand(),rand()]);
    subplot_tight(4,2,6,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,20 * log(abs(fft(curSig_tr,nFFT))),'Color',[rand(),rand(),rand()]);
    
    subplot_tight(4,2,7,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,fft_clip,'Color',[rand(),rand(),rand()]);
    subplot_tight(4,2,8,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,20 * log(abs(fft(curSig_clip,nFFT))),'Color',[rand(),rand(),rand()]);
    
end
hold off;