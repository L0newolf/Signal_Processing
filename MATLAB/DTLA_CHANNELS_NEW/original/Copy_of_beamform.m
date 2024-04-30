function [bfo,angles] = beamform(data,Fs,freq)

%% settings
spacing = 0.65;   % m   (spacing between sensors)
slew = 1.58e-6;   % s   (slew per channel)
c = 1500;         % m/s (sound speed, nominal)

angles = deg2rad(-90:90);
bfo = zeros(size(data,1),length(angles));

numSamples = size(data,1);
numAngles = length(angles);
%% filter data
guard = freq/5;
Hb = fir1(128,[freq-guard freq+guard]/(Fs/2));

sensors = size(data,2);
for j = 1:sensors
    data(:,j) = filtfilt(Hb,1,data(:,j));
end

%% normalize and make complex baseband (for narrowband processing)
%scale = max(data,[],1);
scale = sqrt(mean(data.^2,1));
scale(scale == 0) = 1;
for j = 1:sensors
    data(:,j) = hilbert(data(:,j)/scale(j));
end



%% narrowband beamforming (To be done in eCPU)

for k=1:numSamples
    for j = 1:sensors
        data(k,j) = data(k,j) * exp(-2i*pi*freq*(k/Fs + slew*(j-1)));
        for a = 1:numAngles
            d = exp(2i*pi*freq*spacing*(j-1)/c*sin(angles(a)));
            bfo(k,a) = bfo(k,a) + conj(d) * data(k,j);
        end
    end 
end
