function [ channelSamples,multiPathTap,tapShift ] = genChannelMultipath( numMultiPath,multipathAttenuation,multiPathDelay,FsBB,symbCount,tapShift )

channelLength = floor((max(multiPathDelay)/1000)*FsBB); % Multipath delay in number of baseband samples
channelSamples =  zeros(channelLength,1); % Initialize Channel samples to zeros
multiPathTap = zeros(numMultiPath,1);
channelSamples(1) = 1.0;                  % Direct path with no attenutaion

%Multipath with attenuation

for i=1:numMultiPath
    
    if (mod(symbCount,300) == 0)
        rng('shuffle');
        rndmNum = abs(rand());
        if(rndmNum > 0.4)
            tapShift = 0;
        elseif(rndmNum>0.15 && rndmNum < 0.4)
            tapShift = -10;
        elseif(rndmNum>0 && rndmNum < 0.15)
            tapShift = -20;
        end
    end
    
    multiPathTap(i) = floor((multiPathDelay(i)/1000)*FsBB)+tapShift;
    channelSamples(multiPathTap(i)) = multipathAttenuation(i);
end

end

