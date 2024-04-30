function [ channelSamples,multiPathTap,r ] = genChannelMultipathAmp( numMultiPath,multipathAttenuation,multiPathDelay,FsBB,symbCount,r )

channelLength = floor((max(multiPathDelay)/1000)*FsBB); % Multipath delay in number of baseband samples
channelSamples =  zeros(channelLength,1); % Initialize Channel samples to zeros
multiPathTap = zeros(numMultiPath,1);

a = 0.1;
b = 0.05;

channelSamples(1) = 1.0;
for i=1:numMultiPath
    rng('shuffle');
    if (mod(symbCount,300) == 0)
        r = (b-a).*rand() + a;
    end
    multiPathTap(i) = floor((multiPathDelay(i)/1000)*FsBB);
    channelSamples(multiPathTap(i)) = multipathAttenuation(i)+complex(r,r);
end

end

