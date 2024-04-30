function [ errCount ] = mfskBer( fftTx,fftRx,freqIdx,maxFreqBands,tonesPerBand )

fftValsTx = zeros(1,length(freqIdx));
fftValsRx = zeros(1,length(freqIdx));
errCount = 0;

for i=1:length(freqIdx)
    fftValsTx(i) = fftTx(freqIdx(i));
    fftValsRx(i) = fftRx(freqIdx(i));
end


figure(2);

subplot_tight(2,1,1,[0.04,0.02,0.04]);
stem(fftValsTx);
subplot_tight(2,1,2,[0.04,0.02,0.04]);
stem(fftValsRx);

for k=1:maxFreqBands
        maxPowTx = 0;
        maxIdxTx = 0;
        maxPowRx = 0;
        maxIdxRx = 0;
        
        for a=1:tonesPerBand
            
            if(fftValsTx((k-1)*tonesPerBand + a) > maxPowTx)
                maxPowTx = fftValsTx((k-1)*tonesPerBand + a);
                maxIdxTx = a;
            end
            
            if(fftValsRx((k-1)*tonesPerBand + a) > maxPowRx)
                maxPowRx = fftValsRx((k-1)*tonesPerBand + a);
                maxIdxRx = a;
            end
        end
        
        if (maxIdxTx ~= maxIdxRx)
            errCount = errCount + 1;
        end        
end
    


end

