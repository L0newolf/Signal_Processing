clear all;
%close all;

Fs=1/(1.6e-6*26);
freq = 5027;
guard = 500;
filtOrd = 128;

Hb = fir1(filtOrd,[freq-guard freq+guard]/(Fs/2),'bandpass');
figure(1);
freqz(Hb,1);


beta = 3.6;
desFilt= genFilt(beta,filtOrd+1,2*(freq/Fs),2*((2*guard)/Fs));
figure(2);
freqz(desFilt,1);

% [data1,data,Fs] = readDTLA('/Users/anshu/Desktop/DTLA/120512_151712.dat',1:24,0,30);
% 
% N = size(data,2);
% for j = 1:N
%   %data2(:,j) = filtfilt(desFilt,1,data(:,j));
%   data2(:,j) = filtSignal( desFilt,length(desFilt),data(:,j),length(data(:,j)));
%   data3(:,j) = filter(desFilt,1,data(:,j));
%   err(:,j) = data2(:,j) - data3(:,j);
% end
% 
% nfft =8192;
% f = 0:Fs/(nfft):(Fs-1);
% 
% figure(1);
% fft1=fft(data2(:,1),nfft);
% p1 = unwrap(angle(fft1)); 
% plot(f,p1);
% figure(3);
% plot(f,abs(fft1));
% 
% figure(2);
% fft2=fft(data3(:,1),nfft);
% p2 = unwrap(angle(fft2)); 
% plot(f,p2);
% figure(4);
% plot(f,abs(fft2));

%figure(3);
%specgram(data2(:,1),1024,Fs);

%figure(4);
%specgram(data3(:,1),1024,Fs);
