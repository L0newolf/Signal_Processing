function [ numErr,SER ] = computeSER( dataIn,dataOut )

SER = 0;

for i=1:length(dataIn)
    if(dataIn(i) ~= dataOut(i))
        SER = SER+1;
    end
end
numErr=SER;
SER = SER/length(dataIn);

end

