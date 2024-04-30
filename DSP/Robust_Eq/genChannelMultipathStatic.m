function [ channelSamples,multiPathTap ] = genChannelMultipathStatic( numMultiPath,multipathAttenuation,multiPathDelay,FsBB )

channelLength = floor((max(multiPathDelay)/1000)*FsBB); % Multipath delay in number of baseband samples
channelSamples =  zeros(channelLength,1); % Initialize Channel samples to zeros
multiPathTap = zeros(numMultiPath,1);
channelSamples(1) = 1.0;                  % Direct path with no attenutaion
%Multipath with attenuation
for i=1:numMultiPath
    multiPathTap(i) = floor((multiPathDelay(i)/1000)*FsBB);
    channelSamples(multiPathTap(i)) = multipathAttenuation(i);
end

end

