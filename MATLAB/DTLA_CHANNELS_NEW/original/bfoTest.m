clear

%% load data sets
[data,Fs] = readDTLA('/Users/Anshu/120512_150759.dat',1:24,0,2);

%% figure out signal frequency
% [Pxx,f] = spectral(data(:,1),8192,Fs);
% Pxx(1:128) = 0;
% [dummy,ndx] = max(Pxx);
% freq = f(ndx);
% fprintf(1,'Found a signal with frequency %0.0f Hz\n',freq);

freq = 3000;

%% beamform
[bfo,angles] = beamform(data,Fs,freq);%,'mvdr');

%% display beamformer output
imagesc((1:size(bfo,1))/Fs,rad2deg(angles),20*log10(abs(bfo)'));
colorbar
clim = get(gca,'CLim');
set(gca,'CLim',[ceil(clim(2))-20 ceil(clim(2))]);
xlabel('Time / s');
ylabel('Angle / deg');
grid on