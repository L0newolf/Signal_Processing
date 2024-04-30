%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MFSK PARAMETSRS
Fs = 18000;
Ts = 1/Fs;
bandWidth = 14000;
freqStep = 500;
symbolRate = 50;
bitsPerFreq = 2;
numBits = 458;
StopTime = 0.0075; 
padDur = 0.1;

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
    
    if(freqTones(i) == 0)
        freqTonesRX(i) = Fs;
    end
    
end
freqTones = freqTones';

nFFT = 8192;
freqs = (1:Fs/nFFT:Fs)';
freqTonesIdx = round((freqTonesRX/Fs)*nFFT) + 1;

% Compute window:
winLen = samplesPerSymb;
lenFactor = 1;
[p,win] = srrc(winLen/lenFactor,0.9,lenFactor);
win(length(win)) = [];
p(length(p)) = [];

%Band Stop Filter Window
[b,a] = butter(16,[(bandWidth/Fs) ((Fs-bandWidth)/Fs)],'stop');
freqz(b,a)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%