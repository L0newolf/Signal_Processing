function [ numErr,BER ] = computeBER( dataIn,dataOut,pskMVal )

% bitCount = 1;
% bitPerSym = log2(pskMVal);
% BER = 0;
% 
% for i=1:length(dataIn)
%     curIn = dataIn(i);
%     curOut = dataOut(i);
%     for j=1:bitPerSym
%         bitErr(bitCount) = rem(curOut,2)-rem(curIn,2);
%         if(bitErr(bitCount) ~= 0)
%             BER=BER+1;
%         end
%         curOut=floor(curOut/2);
%         curIn=floor(curIn/2);
%         bitCount=bitCount+1;
%     end
% end
% 
% BER = BER/length(dataIn);

bitPerSym = log2(pskMVal);
curIn = de2bi(dataIn,bitPerSym,[],'left-msb');
curOut = de2bi(dataOut,bitPerSym,[],'left-msb');
bitErr = curOut-curIn;

BER = 0;

for i=1:length(bitErr)
    if(bitErr(i,:) ~= 0)
        BER = BER+1;
    end
end
numErr=BER;
BER = BER/length(curIn);

end

