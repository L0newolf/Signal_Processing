function [ curSymbol ] = genSamples( inBits,bitsPtr,freqTones,tonesPerBand,samplesPerSymb,timeStep,numLoops )

    for j=1:numLoops
        
        curBitsIdx = 2*inBits(bitsPtr)+inBits(bitsPtr+1) + 1;
        bitsPtr = bitsPtr+2;
        curFreq = freqTones(tonesPerBand*(j-1) + curBitsIdx);
        
        if(j==1)
            for k=1:samplesPerSymb
                curVal = 2*pi*curFreq*(k-1)*timeStep;
                curSymbol(k) = complex(cos(curVal),sin(curVal));
            end
        else
            for k=1:samplesPerSymb
                curVal = 2*pi*curFreq*(k-1)*timeStep;
                curSymbol(k) = curSymbol(k) + complex(cos(curVal),sin(curVal));
            end
        end
        
    end

end

