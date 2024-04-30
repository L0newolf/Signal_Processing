clear all;
clc;

tStart = 75;
tDur = 15;
Fs=1/(1.6e-6*26);

t=tStart:1/Fs:tStart+tDur;
t(length(t)) = [];

durWin = 0.05;
samplesWin = floor(Fs*durWin);

detThreshold = 0.14;

%% CHIRP TO BE DETECTED

chirpDur = 1;
chirpLen = floor(chirpDur*Fs);
tc = 0:1/Fs:chirpLen/Fs;
freqLower = 2600;
freqUpper = 3600;
chirpSig = chirp(tc,freqLower,chirpLen/Fs,freqUpper)';
chirpSig = 0.04*chirpSig;
chirpSig(length(chirpSig))=[];
chirpPow = chirpSig.'*chirpSig;

%% SIGNAL WITH A CHIRP

[data,~] = readDTLA('/Users/anshu/Desktop/DTLA/data/051413_223115.dat',1,tStart,tDur);

guard = 500;
Hb = fir1(128,[freqLower-guard freqUpper+guard]/(Fs/2));
data = filter(Hb,1,data);
figure(1);
specgram(data,1024,Fs);

%% MATCHED FILTERING FOR CHIRP

filtCoeff = flipud(chirpSig(:));

numLoops = floor((length(data)-(chirpLen))/samplesWin);

nextStart = 1;
curSig = data(1:chirpLen);
matchTotal = 0;

for i=1:numLoops
    matchOpt(i) = max(filter(filtCoeff,1,curSig));
    matchOpt(i) = matchOpt(i)/chirpPow;
    matchTotal = matchTotal+matchOpt(i);
    matchAvg(i) = matchTotal/i;
    
    alpha(i) = matchOpt(i)/(matchAvg(i)*100);
    
    if (alpha(i)>detThreshold)
        dVar = sprintf('Found chirp at starting sample %d',nextStart);
        disp(dVar);
    end
    
    timeStamp(i,1) = t(nextStart); 
    nextStart = 1+(i*samplesWin);
    curSig = data(nextStart:nextStart+chirpLen-1);
end

figure(3);
plot(timeStamp,matchOpt,'-rd','LineWidth',2,'MarkerSize',8);
hold on;
plot(timeStamp,matchAvg,'-bs','LineWidth',2,'MarkerSize',8);
plot(timeStamp,alpha,'-gs','LineWidth',2,'MarkerSize',8);
hold off;