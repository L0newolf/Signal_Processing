function [ freqTonesRX,freqTones,samplesPerSymb,bitsPerSymb,tonesPerBand,maxFreqBands,numFreqTones ] = loadParams( bandWidth,symbolRate,Fs,freqStep,bitsPerFreq )

freqLower = -bandWidth/2;
freqUpper = bandWidth/2;
symbolDuration = 1/symbolRate;
samplesPerSymb = floor(symbolDuration*Fs);
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

end

