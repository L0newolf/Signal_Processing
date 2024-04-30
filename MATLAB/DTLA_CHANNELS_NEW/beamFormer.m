
function [bfo_real,bfo_imag] = beamFormer(data,Fs,freq,channel,angles,numSamples)

%% settings
spacing = 0.65;   % m   (spacing between sensors)
slew = 1.58e-6;   % s   (slew per channel)
c = 1500;         % m/s (sound speed, nominal)

numLoops = 16;
windowLen = floor(numSamples/numLoops);

%% normalize and make complex baseband (for narrowband processing)

sigData = dataAnalytic(data,numSamples );

bfo = zeros(numSamples,length(angles));

% fileID = fopen('/Users/anshu/Dropbox/DTLA_CPP/hib_opt_mat.txt','a');
% for i=1:length(sigData)
%     fprintf(fileID,'%2.5f\n',sigData(i,1));
%     fprintf(fileID,'%2.5f\n',sigData(i,2));
% end
% fclose(fileID);

for loops = 1:numLoops
    startPtr = (loops-1)*windowLen+1;
    for a = 1:length(angles)
        w = exp(2i*pi*freq*spacing*((channel-1)/c)*sin(angles( a)));
        for k = 1:windowLen
            temp = complex(sigData(startPtr+k,1),sigData(startPtr+k,2));
            temp = temp * exp(-2i*pi*freq*(startPtr+k)/Fs);
            temp = temp * exp(-2i*pi*slew*(channel-1)*freq);
            bfo(startPtr+k,a) = conj(w) * temp;
        end
    end  
end

bfo_real = real(bfo);
bfo_imag = imag(bfo);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end