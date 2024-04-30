function [ outSig ] = filtSignal( filtCoeff,filtLen,inSig,numSamples)


for k=1:numSamples
    tmp = 0;
    for i=1:filtLen
        j=k-i;
        if (j>0)
            tmp = tmp + filtCoeff(i)*inSig(j);
        end
    end
    outSig(k) = tmp;
end

end

