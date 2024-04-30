function [ outBits,powerLevels ] = getDemodBits( curSymbol,samplesPerSymb,freqTonesRX,Fs,tonesPerBand,numFreqTones )

outBitsPtr = 1;
outBits = [];

for j=1:numFreqTones
    powerLevels(j) = goertzelFunc( curSymbol,samplesPerSymb,freqTonesRX(j),Fs );
    
    if(mod(j,tonesPerBand) == 0)
        
        maxVal = 0;
        maxIdx = 0;
        
        for k=1:tonesPerBand
            if(powerLevels(j-tonesPerBand+k) > maxVal)
                maxVal = powerLevels(j-tonesPerBand+k);
                maxIdx = k;
            end
        end
        
        switch maxIdx
            case 1
                outBits(outBitsPtr) = 0;
                outBits(outBitsPtr+1) = 0;
            case 2
                outBits(outBitsPtr) = 0;
                outBits(outBitsPtr+1) = 1;
            case 3
                outBits(outBitsPtr) = 1;
                outBits(outBitsPtr+1) = 0;
            case 4
                outBits(outBitsPtr) = 1;
                outBits(outBitsPtr+1) = 1;
        end
        
        outBitsPtr = outBitsPtr+2;
        
    end
end

end

