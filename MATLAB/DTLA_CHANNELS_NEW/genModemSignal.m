clear all;
clc;

corrLen = 35;

corrBW = 75;
fc = 8000;
ft = 24000;

fd = round(2/3*fc);
fs = 4*fc;

c = 3.141592 * corrBW/100.0;
t = 0:corrLen-1;
a = c * t.*(1-t/corrLen);
corrBuf = 32767*cos(a) + 32767i*sin(a);

pbSig = resample(corrBuf,fs,fd);
pbSig = real(pbSig.*exp(2i*pi*fc*(0:length(pbSig)-1)/fs));

pbSig24 = resample(pbSig,ft,fs);

figure(5);
[y,f,t,p] = spectrogram(pbSig24(:),128,120,128,ft,'yaxis');
surf(t,f,10*log10(abs(p)),'EdgeColor','none');
axis xy; axis tight; colormap(jet); view(0,90);
xlabel('Time');
ylabel('Frequency (Hz)');

figure(6);
t1=0:1/ft:(length(pbSig24)/ft);
t1(length(t1))=[];
plot(t1,pbSig24);

savefile = 'txSig.mat';
save(savefile,'pbSig24');
