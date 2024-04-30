clear all;
clc;

tStart = 60;
tDur = 30;
Fs=1/(1.6e-6*26);

t=tStart:1/Fs:tStart+tDur;
t(length(t)) = [];

durWin = 0.05;
samplesWin = floor(Fs*durWin);

detThreshold = 0.9;

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

[data,~] = readDTLA('/Users/anshu/Desktop/DTLA/data/051413_223115.dat',1:24,tStart,tDur);

N=size(data,2);
guard = 500;
Hb = fir1(128,[freqLower-guard freqUpper+guard]/(Fs/2));

for i=1:N
    data(:,i) = filter(Hb,1,data(:,i));
    figure(1);
    specgram(data(:,i),1024,Fs);
end


%% MATCHED FILTERING FOR CHIRP

filtCoeff = flipud(chirpSig(:));

numLoops = floor((length(data(:,1))-(chirpLen))/samplesWin);

nextStart = 1;
curSig = data(1:chirpLen,:);

for j=1:N
    for i=1:numLoops
            matchOpt(i,j) = max(filter(filtCoeff,1,curSig(:,j)));
            matchOpt(i,j) = matchOpt(i,j)/chirpPow;
            timeStamp(i,j) = t(nextStart); 
            nextStart = 1+(i*samplesWin);
            curSig(:,j) = data(nextStart:nextStart+chirpLen-1,j);
    end
    maxMatch(j) = max(matchOpt(:,j));
end

figure(3);
plot(maxMatch);