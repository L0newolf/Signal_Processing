close all;
clear all;

Fs = 1000;                    % Sampling frequency
T = 1/Fs;                     % Sample time
L = 1000;                     % Length of signal
t = (0:L-1)*T;                % Time vector
sig = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t); 

hib=hilbert(sig);

hib1 = hilbertSig(sig');

plot(xcorr(hib,hib1));