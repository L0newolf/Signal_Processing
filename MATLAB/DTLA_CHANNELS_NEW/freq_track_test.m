clear all;
clc;

%% CONSTANTS AND SETTINGS
tStart = 0;
tDur = 90;
numChannels = 24;

powerThreshold = 3.3;

Fs=24000;
nFFT = 512;
overlap = 500;

startSample=floor(tStart*Fs);
numSample=floor(Fs*tDur);
freqStep = Fs/nFFT;

durPerBlock = 0.1;
samplesPerBlock = floor(Fs*durPerBlock);
numLoops = floor(numSample/samplesPerBlock);

t=tStart:durPerBlock:tStart+tDur;
t(length(t)) = [];

%% GENERATE TEST SIGNAL

testSig = zeros(numSample,1);
freq = 4000;

j=1;
while j<length(testSig)
    if (mod(j,Fs) == 0)
        if (j < (length(testSig) - 1000))
            for i=1:1000
                testSig(j+i) = 1.5*sin(freq*i);
            end
            j = j+1000;
        end
    end
    j=j+1;
end
testSig = awgn(testSig,10) ;

%% TRACK FREQUENCY 
curPtr = 1;
curCount = 0;
avgPower = 0;
offSet = 0;
totalPower = 0;

freqBFO=[];
freqDet = [];
power = [];
totalPow = 0;
beta = 0.1;

Plength = floor(nFFT/2)+1;
F = (0:Plength-1)'*(Fs/nFFT);

guard = 200;
Hb = fir1(128,[freq-guard freq+guard]/(Fs/2));

for i=1:numLoops
    curSig = testSig(curPtr:curPtr+samplesPerBlock-1);
    curPtr=curPtr+samplesPerBlock;
    
    sigTemp = curSig;
    
    for j = 1:numChannels
        curSig = filter(Hb,1,curSig);
    end
    
    sig = curSig;
    [ maxPow(i),avgPow(i),sigFreq(i) ]  = fftOverlap( sig,Fs,nFFT,samplesPerBlock,overlap );
       
    if (i==1)
        freqBFO(i) = sigFreq(i);
    else
        lambda(i) = abs((maxPow(i)-avgPow(i))/avgPow(i));
        if( lambda(i) > powerThreshold)
            freqBFO(i) = (1-beta) * freqBFO(i-1) + beta * sigFreq(i);
        else
            freqBFO(i) = freqBFO(i-1);
        end
    end
    
end

figure(5);
plot(t,maxPow,'-rd','LineWidth',2,'MarkerSize',8);
hold on;
plot(t,avgPow,'-bs','LineWidth',2,'MarkerSize',8);
hold off;
title('power values detected at diff sig blocks in filetred data');

figure(2);
plot(t,sigFreq,'-rd','LineWidth',2,'MarkerSize',8);
hold on;
plot(t,freqBFO,'-bs','LineWidth',2,'MarkerSize',8);
hold off;
title('freq detected at diff sig blocks in filetred data');
