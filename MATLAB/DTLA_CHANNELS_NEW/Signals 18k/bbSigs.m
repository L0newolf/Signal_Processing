clear all;

Fd = 108000;
Fs = 18000;
Fc = 6000;
BW = 4000;

t0 = 0;
t1 = 0.04;

t=t0:1/Fd:t1; %time base - upto 1 second
t=t(1:length(t)-1);

f0=Fc-(BW/2);% starting frequency of the chirp
f1=Fc+(BW/2); %frequency of the chirp at t1=1 second
x = chirp(t,f0,t1,f1);

figure(1);
specgram(x,256,Fd);

y = pb2bb(x',Fs,Fc,Fd);

f = fopen('textFiles/LFM.txt','wt');
fprintf(f, '%0.5f,%0.5f\n', (real(y)),(imag(y)));
fclose(f);

figure(2);
specgram(y,32,Fs);