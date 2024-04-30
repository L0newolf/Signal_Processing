function [bfo] = beamFormer(data,Fs,freq,angles,numSamples,channel,numAngles)

%% settings
spacing = 0.65;   % m   (spacing between sensors)
slew = 1.58e-6;   % s   (slew per channel)
c = 1500;         % m/s (sound speed, nominal)

windowLen = 256;
startPtr = 0;
numLoops = floor(numSamples/windowLen);

%% normalize and make complex baseband (for narrowband processing)

bfo = zeros(numSamples,numAngles);

curData = dataAnalytic(data,numSamples );

for loop=1:numLoops
    
    for i=1:windowLen
        curData(startPtr+i) = curData(startPtr+i) * exp(-2i*pi*freq*((i/Fs)+ slew*(channel-1)));
    end
    
    for a = 1:numAngles
        w = exp(2i*pi*freq*spacing*((channel-1)/c)*sin(angles(a)));
        
        for k=1:windowLen
            bfo(startPtr+k,a) = bfo(startPtr+k,a) + conj(w) * curData(startPtr+k);
        end
    end
    
    startPtr=startPtr+windowLen-1;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
