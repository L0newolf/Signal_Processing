function [ analyticData ] = dataAnalytic( data,numSamples )

    scale = 0;
    for j=1:numSamples
        scale = scale+(data(j)*data(j));
    end
    scale = sqrt(scale/numSamples);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    datafft = fft(data/scale);
    for i=floor(length(datafft)/2):length(datafft)
        datafft(i) = 0;
    end
    
    for i=1:length(datafft)/2
        datafft(i) = 2*datafft(i);
    end
    
    analyticData = ifft(datafft);   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
end

