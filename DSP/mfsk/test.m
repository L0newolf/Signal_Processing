clear all;

Fs = 18000;
load('txSignal.txt');

count = 1;
for i=1:length(txSignal)/2
    txSig(i) = complex(txSignal(count),txSignal(count+1));
    count = count+2;
end
txSig = txSig';

curSig = txSig(13950-450:13950);

figure(1);
specgram(curSig);

figure(2);
step = Fs/length(curSig);
plot((1:step:Fs)',20*log(abs(fft(curSig))));

load('txFreqs');
load('rxFreqs');

diff = txFreqs - rxFreqs;

load('freqs');
% specify your filter
h = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',950,1e3,1200,1250,60,0.5,60,18000); 
% design a Butterworth filter based on your specifications
d = design(h,'butter');