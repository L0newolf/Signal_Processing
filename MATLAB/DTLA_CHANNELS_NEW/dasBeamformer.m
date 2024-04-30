function [bfo,angles] = dasBeamformer( data,Fs,numChannels )

spacing = 0.65;   % m   (spacing between sensors)
slew = 1.58e-6;   % s   (slew per channel)
c = 1500;         % m/s (sound speed, nominal)

angles = deg2rad(-90:90);
slews = (0:numChannels-1)*slew;

for i=1:numChannels
    delays(i,:) = (((i-1)*spacing)/c)*sin(angles);
end

for i=1:length(angles)
    delays(:,i) = delays(:,i)+slews';
end

sampleSteps = -round(delays*Fs);

bfo = zeros(size(data,1),length(angles));

for a=1:length(angles)
    for j=1:length(data)
        for n=1:numChannels
            curPtr = j+sampleSteps(n,a);
            if(curPtr <= 0 || curPtr > length(data))
                curData = 0;
            else
                curData = data(curPtr,n);
            end
            bfo(j,a) = bfo(j,a)+curData;
        end
    end
end
end

