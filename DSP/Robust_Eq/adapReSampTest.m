clear;
close all;
clc;

zprintf = @(z) fprintf('%f+i%f ', z, z/1i);

pskMVal = 4;            % PSK M value

FsBB = 18e3;             % Baseband sampling frequency
FsPB = 250e3;           % Passband Sampling frequency
Fc = 17e3;              % Carrier frequency

numTrainingSymbols = 10000;
numDataSymbols = 0;
numSymbols = numTrainingSymbols+numDataSymbols;      % number of symbolsrestar


velocity = 5;
soundV = 1500;
delta = (velocity/soundV);


dataIn = randi([0 pskMVal-1], numSymbols, 1);
d = pskmod(dataIn, pskMVal, pi/pskMVal);

% ADDING DOPPLER IN PASSBAND AND CONVERTING BACK TO BASEBAND
dPB = bb2pb(d,FsBB,Fc,FsPB);
Fd = round(FsPB/(1+delta)/100)*100;
rx = resample(dPB,FsPB,Fd);
r = pb2bb(rx,FsBB,Fc,Fd);

rxSig = awgn(d,50);
scatterplot(rxSig);

rxSig = awgn(r,50);
scatterplot(rxSig);