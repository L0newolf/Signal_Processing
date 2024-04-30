function [ power,freq ] = fftOverlap( x,fs,nFFT,samples,overlap )

for i=1:nFFT
index(1,i) = i;
end

Plength = floor(nFFT/2)+1;
power = zeros(Plength,1);
winMov = (nFFT-overlap);
k = floor((samples-overlap)/winMov)-1;
win = blackman( nFFT );
xnw = zeros(nFFT,1);

freq = (0:Plength-1)'*(fs/nFFT);

for i = 1:k
    
    for j=1:nFFT
    xnw(j,1) = win(j,1)*x(index(j));
    end
    index = index + winMov;
    %mfft = fft(xnw,nFFT);
    mfft = pmdft21(xnw,nFFT);
    
    for j=1:Plength
        power(j,1) = power(j,1)+(20*log(abs(mfft(j,1))));
    end
    
end



end

