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

figure(1);

tx_tank_data = load('data/tx_tank.txt');
tx_tank_cplx = complex(tx_tank_data(:,1),tx_tank_data(:,2));



subplot_tight(2,2,1,[0.04,0.02,0.04]);
spectrogram(tx_tank_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(2,2,2,[0.04,0.02,0.04]);
plot(((1:length(tx_tank_cplx(:,1)))/18000)',real(tx_tank_cplx));

rx_tank_data = load('data/rx_tank.txt');
rx_tank_cplx = complex(rx_tank_data(:,1),rx_tank_data(:,2));


% subplot_tight(3,2,3,[0.04,0.02,0.04]);
% spectrogram(rx_tank_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
% subplot_tight(3,2,4,[0.04,0.02,0.04]);
% plot(((1:length(rx_tank_cplx(:,1)))/18000)',real(rx_tank_cplx));



rx_trials_data = load('data/rx_trials.txt');
rx_trials_cplx = complex(rx_trials_data(:,1),rx_trials_data(:,2));

subplot_tight(2,2,3,[0.04,0.02,0.04]);
spectrogram(rx_trials_cplx,samplesPerSymb,0,nFFT,Fs,'yaxis');
subplot_tight(2,2,4,[0.04,0.02,0.04]);
plot(((1:length(rx_trials_cplx(:,1)))/18000)',real(rx_trials_cplx));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numSymbols = ceil(numBits/bitsPerSymb);

powLevelsTx = zeros(numFreqTones,1);
powLevelsTank = zeros(numFreqTones,1);
powLevelsTrials = zeros(numFreqTones,1);

errCountTank = zeros(numSymbols,maxFreqBands);
errCountTrials = zeros(numSymbols,maxFreqBands);


% Compute Hanning window:
nm = 0:samplesPerSymb-1;   % time indices for window computation
win = (1/samplesPerSymb) * (cos((pi/samplesPerSymb)*(nm-(samplesPerSymb-1)/2))).^2;  % Hanning window = "raised cosine"
win = win';

% win = hamming(samplesPerSymb);

for i=1:numSymbols
    
    symbolCount(i) = i;
    
    curSig_tx = tx_tank_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i).*win;
    fft_tx = 20 * log(abs(fft(curSig_tx,nFFT)));
    
    curSig_rx = rx_tank_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_rx = 20 * log(abs(fft(curSig_rx,nFFT)));
    
    curSig_tr = rx_trials_cplx(samplesPerSymb*(i-1)+1:samplesPerSymb*i);
    fft_tr = 20 * log(abs(fft(curSig_tr,nFFT)));
    
    figure(4);
    
    str = ['Time Stamp =',num2str((1/numSymbols)*i)];
    
    %     subplot_tight(3,2,1,[0.04,0.02,0.04]);
    %     plot(freqs,fft_rx);
    %     subplot_tight(3,2,2,[0.04,0.02,0.04]);
    %     plot(real(curSig_rx));
    
    subplot_tight(2,2,1,[0.04,0.02,0.04]);
    semilogy(freqs,fft_tx);
    subplot_tight(2,2,2,[0.04,0.02,0.04]);
    plot(real(curSig_tx));
    text(1,4.5,str,'FontSize',16);
    
    subplot_tight(2,2,3,[0.04,0.02,0.04]);
    semilogy(freqs,fft_tr);
    subplot_tight(2,2,4,[0.04,0.02,0.04]);
    plot(real(curSig_tr));
    
    pause(5);
    
    for j=1:numFreqTones
        idx = freqTonesIdx(j);
        powLevelsTx(j) = fft_tx(idx);
        powLevelsTank(j) = fft_rx(idx);
        powLevelsTrials(j) = fft_tr(idx);
    end
    
    for k=1:maxFreqBands
        maxPowTx = 0;
        maxIdxTx = 0;
        maxPowTank = 0;
        maxIdxTank = 0;
        maxPowTrials = 0;
        maxIdxTrials = 0;
        
        for a=1:tonesPerBand
            
            if(powLevelsTx((k-1)*tonesPerBand + a) > maxPowTx)
                maxPowTx = powLevelsTx((k-1)*tonesPerBand + a);
                maxIdxTx = a;
            end
            
            if(powLevelsTank((k-1)*tonesPerBand + a) > maxPowTank)
                maxPowTank = powLevelsTank((k-1)*tonesPerBand + a);
                maxIdxTank = a;
            end
            
            if(powLevelsTrials((k-1)*tonesPerBand + a) > maxPowTrials)
                maxPowTrials = powLevelsTrials((k-1)*tonesPerBand + a);
                maxIdxTrials = a;
            end
            
        end
        
        if (maxIdxTx ~= maxIdxTank)
            errCountTank(i,k) = errCountTank(i,k) + 1;
        end
        
        if (maxIdxTx ~= maxIdxTrials)
            errCountTrials(i,k) = errCountTrials(i,k) + 1;
        end
        
    end
    A=1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
