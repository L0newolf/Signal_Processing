clear all;


Fs = 18000;
Fc = -3000;
BW = 6000;

t0 = 0;
t1 = 0.04;

t=t0:1/Fs:t1; %time base - upto 1 second
t=t(1:length(t)-1);

f0=Fc;% starting frequency of the chirp
f1=Fc+BW; %frequency of the chirp at t1=1 second
x = mychirp(t,f0,t1,f1);

f = fopen('textFiles/LFM.txt','wt');
fprintf(f, '%0.5f,%0.5f\n', (real(x)),(imag(x)));
fclose(f);

w = gausswin(length(x))';
xGaus = x.*w;
f = fopen('textFiles/LFMGaussian.txt','wt');
fprintf(f, '%0.5f,%0.5f\n', (real(xGaus)),(imag(xGaus)));
fclose(f);


w = hamming(length(x))';
xHam = x.*w;
f = fopen('textFiles/LFMHamming.txt','wt');
fprintf(f, '%0.5f,%0.5f\n', (real(xHam)),(imag(xHam)));
fclose(f);

figure(3);
specgram(xGaus,32,Fs);

figure(5);
specgram(xHam,32,Fs);

figure(4);
subplot_tight(3,1,1,[0.04,0.02,0.04]); plot(xGaus);
subplot_tight(3,1,2,[0.04,0.02,0.04]); plot(real(x));
subplot_tight(3,1,3,[0.04,0.02,0.04]); plot(real(xHam));

%% NLFM signals

t=t0:1/Fs:(t1/4); 
t=t(1:length(t)-1);
f0=Fc;
f2=Fc+floor(BW/2);
x1 = mychirp(t,f0,(t1/4),f2);

t=(t1/4):1/Fs:t1; 
t=t(1:length(t)-1);
f0=Fc+floor(BW/2);
f2=Fc+BW;
x2 = mychirp(t,f0,t1,f2);

xnlfm=[x1 x2];

figure(6);
specgram(xnlfm,32,Fs);

f = fopen('textFiles/NLFM.txt','wt');
fprintf(f, '%0.5f,%0.5f\n', (real(xGaus)),(imag(xGaus)));
fclose(f);