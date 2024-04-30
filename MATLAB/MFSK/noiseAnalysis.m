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

% Compute window:
winLen = samplesPerSymb;
lenFactor = 1;
[p,win] = srrc(winLen/lenFactor,0.75,lenFactor);
win(length(win)) = [];
p(length(p)) = [];
%close(1);
figure(1);
hold on;
plot(win);
plot(p);
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LOAD THE SIGNAL RECEIVED DURING TRIALS


figure(5);

tx_tank_data = load('data/tx_tank.txt');
tx_tank_cplx = complex(tx_tank_data(:,1),tx_tank_data(:,2));

maxVal = max(max(tx_tank_data));

numSymbols = ceil(numBits/bitsPerSymb);
for i=1:numSymbols
    tx_tank_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i) = tx_tank_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);%.*win';
end
divFact = (max(real(tx_tank_cplx)));
tx_tank_cplx = tx_tank_cplx/divFact ;
tx_tank_cplx = tx_tank_cplx*maxVal;

noise = load('data/noise.txt');
noise_cplx = complex(noise(:,1),noise(:,2));

subplot_tight(3,2,1,[0.04,0.02,0.04]);
spectrogram(tx_tank_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(3,2,2,[0.04,0.02,0.04]);
plot(((1:length(tx_tank_cplx(:,1)))/18000)',real(tx_tank_cplx));

subplot_tight(3,2,3,[0.04,0.02,0.04]);
spectrogram(noise_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(3,2,4,[0.04,0.02,0.04]);
plot(((1:length(noise_cplx(:,1)))/18000)',real(noise_cplx));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

testSignal = tx_tank_cplx(1:numSymbols*samplesPerSymb);
%testSignal = testSignal + 2*noise_cplx(1:length(testSignal));
for i=1:numSymbols
    testSignal(samplesPerSymb*(i-1)+1:samplesPerSymb*i) = testSignal(samplesPerSymb*(i-1)+1:samplesPerSymb*i).*win';
end
figure(5);
subplot_tight(3,2,5,[0.04,0.02,0.04]);
spectrogram(testSignal,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(3,2,6,[0.04,0.02,0.04]);
plot(((1:length(testSignal(:,1)))/18000)',real(testSignal));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

powLevelsTx = zeros(numFreqTones,1);
powLevelsTest = zeros(numFreqTones,1);

errCount = 0;

for i=1:numSymbols
    
    symbolCount(i) = i;
    
    curSig_tx = tx_tank_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_tx = fft(curSig_tx,nFFT);
    
    curSig_test = testSignal(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_test = Lpnorm(fft(curSig_test,nFFT),1.7);
    %fft_test = abs(fft(curSig_test,nFFT));
    fft_test = 300*(fft_test/(max(fft_test)));
    
    figure(4);
    subplot_tight(3,2,1,[0.04,0.02,0.04]);
    plot(real(curSig_tx));
    str = ['Time Stamp =',num2str((1/numSymbols)*i)];
    text(1,4.5,str,'FontSize',16);
    subplot_tight(3,2,3,[0.04,0.02,0.04]);
    plot(freqs,abs(fft_tx));
    subplot_tight(3,2,4,[0.04,0.02,0.04]);
    plot(freqs,20 * log(abs(fft_tx)));
    
    subplot_tight(3,2,2,[0.04,0.02,0.04]);
    plot(real(curSig_test));
    str = ['Time Stamp =',num2str((1/numSymbols)*i)];
    text(1,4.5,str,'FontSize',16);
    subplot_tight(3,2,5,[0.04,0.02,0.04]);
    plot(freqs,abs(fft_test));
    subplot_tight(3,2,6,[0.04,0.02,0.04]);
    plot(freqs,20 * log(abs(fft_test)));
    
    pause(0.25);
    
%     for j=1:length(freqTonesIdx)
%         powTxIdx(j) = abs(fft_tx(freqTonesIdx(j)));
%         powRxIdx(j) = abs(fft_test(freqTonesIdx(j)));
%     end
%     
%     figure(2);
%     subplot_tight(2,1,1,[0.04,0.02,0.04]);
%     stem(powTxIdx/max(powTxIdx));
%     subplot_tight(2,1,2,[0.04,0.02,0.04]);
%     stem(powRxIdx/max(powRxIdx));

    A=1;
end

X = sprintf('BER = %f ',errCount/numBits);
disp(X);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%