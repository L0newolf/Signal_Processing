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

% TANK DATA WITHOUT WINDOW %
tx_tank_unwindow = load('data/tank_data/500_50_80/no_window/tx_tank.txt');
tx_tank_unwindow_cplx = complex(tx_tank_unwindow(:,1),tx_tank_unwindow(:,2));

rx_tank_unwindow = load('data/tank_data/500_50_80/no_window/rx_tank.txt');
rx_tank_unwindow_cplx = complex(rx_tank_unwindow(:,1),rx_tank_unwindow(:,2));

% TANK DATA WITH R-COS WINDOW %
tx_tank_rcos = load('data/tank_data/500_50_80/rxCos_window/tx_tank.txt');
tx_tank_rcos_cplx = complex(tx_tank_rcos(:,1),tx_tank_rcos(:,2));

rx_tank_rcos = load('data/tank_data/500_50_80/rxCos_window/rx_tank.txt');
rx_tank_rcos_cplx = complex(rx_tank_rcos(:,1),rx_tank_rcos(:,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(4);

subplot_tight(2,2,1,[0.04,0.02,0.04]);
spectrogram(tx_tank_unwindow_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(2,2,2,[0.04,0.02,0.04]);
plot(((1:length(tx_tank_unwindow_cplx(:,1)))/18000)',real(tx_tank_unwindow_cplx));

subplot_tight(2,2,3,[0.04,0.02,0.04]);
spectrogram(tx_tank_rcos_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(2,2,4,[0.04,0.02,0.04]);
plot(((1:length(tx_tank_rcos_cplx(:,1)))/18000)',real(tx_tank_rcos_cplx));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(5);

subplot_tight(2,2,1,[0.04,0.02,0.04]);
spectrogram(rx_tank_unwindow_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(2,2,2,[0.04,0.02,0.04]);
plot(((1:length(rx_tank_unwindow_cplx(:,1)))/18000)',real(rx_tank_unwindow_cplx));

subplot_tight(2,2,3,[0.04,0.02,0.04]);
spectrogram(rx_tank_rcos_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(2,2,4,[0.04,0.02,0.04]);
plot(((1:length(rx_tank_rcos_cplx(:,1)))/18000)',real(rx_tank_rcos_cplx));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(6);

numSymbols = ceil(numBits/bitsPerSymb);

powLevelsUnwindow = zeros(numFreqTones,1);
powLevelsRcos = zeros(numFreqTones,1);

    figure(6);
    
    
for i=1:numSymbols
    
    symbolCount(i) = i;
    
    curSig_unwindow_tx = tx_tank_unwindow_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_unwindow_tx = abs(fft(curSig_unwindow_tx,nFFT));
    
    curSig_unwindow_rx = rx_tank_unwindow_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_unwindow_rx = abs(fft(curSig_unwindow_rx,nFFT));
    
    curSig_rcos_tx = tx_tank_rcos_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_rcos_tx = abs(fft(curSig_rcos_tx,nFFT));
    
    curSig_rcos_rx = rx_tank_rcos_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_rcos_rx = abs(fft(curSig_rcos_rx,nFFT));
    

    subplot_tight(2,2,1,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,real(fft_unwindow_tx));
    str = ['Time Stamp =',num2str((1/numSymbols)*i)];
    text(7500,325,str,'FontSize',16);
    subplot_tight(2,2,3,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,real(fft_unwindow_rx));
    subplot_tight(2,2,2,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,real(fft_rcos_tx));
    subplot_tight(2,2,4,[0.04,0.02,0.04]);
    hold on;
    plot(freqs,real(fft_rcos_rx));
    
    pause(2);
    
end

hold off;