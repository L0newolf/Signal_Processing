clear all;
clc;

tStart = 573;
tDur = 10;
numChannels = 15;

powerThreshold = 0.4;

Fs=1/(1.6e-6*26);
nFFT = 512;
overlap = 500;

startSample=floor(tStart*Fs);
numSample=floor(Fs*tDur);
freqStep = Fs/nFFT;

durPerBlock = 1;
samplesPerBlock = floor(Fs*durPerBlock);
numLoops = floor(numSample/samplesPerBlock);

t=tStart:durPerBlock:tStart+tDur;
t(length(t)) = [];

%% READ DATA

[data,Fs] = readDTLA('/Users/anshu/Desktop/DTLA/data/120712_145335.dat',1:24,tStart,tDur);

%% FIGURE OUT THE SIGNAL FREQUENCY

% figure(3);
% specgram(data(:,1),1024,Fs);
% title('spectrum recorded signal');

guard = 100;
freq = 3000;
Hb = fir1(128,[freq-guard freq+guard]/(Fs/2));
N = size(data,2);

% for j = 1:N
%     datafilt(:,j) = filter(Hb,1,data(:,j));
% end
% figure(1);
% specgram(datafilt(:,1),1024,Fs,kaiser(900,5),800);
% title('spectrum after band pass filtering at 3KHz');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DETECT SIGNAL IN BAND PASS FILTERED DATA

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
bfoSub = [];

Plength = floor(nFFT/2)+1;
F = (0:Plength-1)'*(Fs/nFFT);

for i=1:numLoops
    curSig = data(curPtr:curPtr+samplesPerBlock-1,:);
    curPtr=curPtr+samplesPerBlock;
    
    for j = 1:numChannels
        curSig(:,j) = filter(Hb,1,curSig(:,j));
    end
    
    sig = curSig(:,1);
    
    [maxPow,sigFreq,dataFFT]  = findSigFreq( sig,Fs,nFFT,samplesPerBlock,overlap );
    
    totalPower = totalPower + maxPow;
    avgPow = totalPower/i;
    
    if (i==1)
        freqBFO = sigFreq;
    else
        freqBFO = (1-beta) * freqBFO + beta * sigFreq;
        
    end
    
    
    samplesToUse = samplesPerBlock/2;
    effectiveFs = Fs/2;
    
    for q=1:numChannels
        for k=1:samplesToUse
            curSig(k,q) = curSig(2*k,q);
        end
    end
    
    
    
    
    %%%%%%%% Frequency Domain Beamforming %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    angles = deg2rad(-90:6:90);
    
    startPtr = 1;
    
    bfoSub_real_new = zeros(samplesToUse,length(angles),numChannels);
    bfoSub_imag_new = zeros(samplesToUse,length(angles),numChannels);
    
    for q=1:numChannels
        [bfoSub_real_new(:,:,q),bfoSub_imag_new(:,:,q)] = beamFormer(curSig(:,q),effectiveFs,freqBFO,q,angles,samplesToUse);
    end

    bfoSub_real=sum(bfoSub_real_new,3);
    bfoSub_imag= sum(bfoSub_imag_new,3);
    bfoSub = 20*log10(abs(complex(bfoSub_real,bfoSub_imag)));
    
    maxVal = 0;
    angleIdx = 0;
    timeIdx = 0;
    
    for q=1:samplesToUse
        for w=1:length(angles)
            if(bfoSub(q,w)>maxVal)
                maxVal = bfoSub(q,w);
                timeIdx = q;
                angleIdx = w;
            end
        end
    end
    
    maxTime = durPerBlock*(i-1)+(timeIdx/effectiveFs);
    
    maxAng = rad2deg(angles(angleIdx));
    dispVar = sprintf('Max power detected at %0.2f angle at time %0.2f  for freq %0.2f',maxAng,maxTime,freqBFO);
    disp(dispVar);
    
    
    figure(1);
    imagesc((1:size(bfoSub,1))/effectiveFs,rad2deg(angles),bfoSub');
    colorbar
    clim = get(gca,'CLim');
    set(gca,'CLim',[ceil(clim(2))-20 ceil(clim(2))]);
    xlabel('Time / s');
    ylabel('Angle / deg');
    grid on
    title('BFO from real-time simulation');
    
end

