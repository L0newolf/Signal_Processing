function [ txSigBuf ] = mfskProcTx( numBits,bitsPerSymb,bitsPerFreq,samplesPerSymb,Fs,inBits,freqTones,tonesPerBand,maxFreqBands )

txSigBuf = [];

loopCount = floor(numBits/bitsPerSymb);
loopRemBits = mod(numBits,bitsPerSymb)/bitsPerFreq;

curSymbol = zeros(1,samplesPerSymb);
timeStep = 1/Fs;

bitsPtr = 1;

for i=1:loopCount
    
    [ curSymbol ] = genSamples( inBits,bitsPtr,freqTones,tonesPerBand,samplesPerSymb,timeStep,maxFreqBands );
    bitsPtr = bitsPtr + 2*maxFreqBands;
    txSigBuf = [txSigBuf curSymbol];
   
end

[ curSymbol ] = genSamples( inBits,bitsPtr,freqTones,tonesPerBand,samplesPerSymb,timeStep,loopRemBits );
txSigBuf = [txSigBuf curSymbol];

end

