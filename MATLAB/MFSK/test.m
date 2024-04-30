clear all;

%% Time specifications:
Fs = 18000;                   % samples per second
StopTime = 0.01;             % seconds

[ isiWin ] = genIsiWin( Fs,StopTime );

figure(6);
stem(isiWin);