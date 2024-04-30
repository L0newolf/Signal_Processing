function [ numSamples ] = computeSigLen( bits,dur,samplesPerSymb,bitsPerSymb,bitsPerFreq,Fs )


padSamples = floor(dur*Fs);

loopCount = floor(bits/bitsPerSymb);
loopRemBits = mod(bits,bitsPerSymb)/bitsPerFreq;

if(loopRemBits ~= 0)
    numSymbols = loopCount +1;
else
    numSymbols = loopCount;
end

samplesPerSymBlock = samplesPerSymb+padSamples;

numSamples = numSymbols*samplesPerSymBlock;

end

