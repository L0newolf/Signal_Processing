function [ normSig ] = Lpnorm( inSig,p )

realSig = real(inSig);
imSig = imag(inSig);

normSig = (0.5*(realSig.^p+imSig.^p));

end

