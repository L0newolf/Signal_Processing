function [ powerLevel ] = goertzelFunc( inpSamples,numSamples,targetFreq,Fs )

    k = (0.5 + ((numSamples * targetFreq) / Fs));
    A = (2.0 * 3.1416 * k) / numSamples;
    sinVal = sin(A);
    cosinVal = cos(A);
    B = 2.0 * cosinVal;

    s0re=0;
    s0im=0;
    s1re=0;
    s1im=0;
    s2re=0;
    s2im=0;

    for i=1:numSamples 
        s0re = real(inpSamples(i)) + B*s1re - s2re;
        s0im = imag(inpSamples(i)) + B*s1im - s2im;

        s2re = s1re;
        s2im = s1im;

        s1re = s0re;
        s1im = s0im;
    end

    s0re = B*s1re - s2re;
    s0im = B*s1im - s2im;

    yre = s0re -s1re*cosinVal - s1im*sinVal;
    yim = s0im + s1re*sinVal - s1im*cosinVal;

    powerLevel = abs(0.5*(yre^1.7+yim^1.7));
    %powerLevel = sqrt(yre*yre + yim*yim);
    
end

