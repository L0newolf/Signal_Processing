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

dataIn = randi([0 pskMVal-1], numSymbols, 1);
d = pskmod(dataIn, pskMVal, pi/pskMVal);

velocity = 1;
soundV = 1500;
delta = (velocity/soundV);
initialDist = 1000;

%% resample to introduce Doppler

% ADDING DOPPLER IN PASSBAND
dPB = bb2pb(d,FsBB,Fc,FsPB);
Fd = round(FsPB/(1+delta)/100)*100;
rx = resample(dPB,FsPB,Fd);
r = pb2bb(rx,FsBB,Fc,Fd);

rxSig = awgn(d,50);
scatterplot(rxSig);

rxSig = awgn(r,50);
scatterplot(rxSig);

%----------------------------------------------------------------------------------%
%----- ADAPTIVE RESAMPLING -------%

rPrime = resample(r,2,1);
K1= 10e-3;

dTilda = d;

figure();

for i = 1:length(d)
    
    if(i==1)
        
        Ival(i) = 1;
        phi(i) = 1;
        y(i,1) = rPrime(2*i-1)*exp(-1i);
        dCap(i,1) = y(i,1);
        
    else
        
        theta(i-1) = imag(dCap(i-1)*conj(dTilda(i-1)));
        Ival(i) = Ival(i-1) + K1*theta(i-1);
        phi(i) = phi(i-1) + 2*pi*(Fc/FsBB)*(Ival(i)-1);
        y(i,1) = (Ival(i)*rPrime(2*i-1)+(Ival(i)-1)*rPrime(2*i))*exp(-1i*phi(i));
        dCap(i,1) = y(i,1);
        
    end

    
    
    subplot_tight(3,2,1,[0.04,0.02,0.04]);
    plot(abs(Ival));
    title('I');
    
%     subplot_tight(3,2,2,[0.04,0.02,0.04]);
%     plot((phi));
%     hold on;

    if(i>1)
    subplot_tight(3,2,3,[0.04,0.02,0.04]);
    plot(abs(theta));
    title('theta');
    end
        
    subplot_tight(3,2,4,[0.04,0.02,0.04]);
    plot(abs(y));
    title('y');
    
        
%     subplot_tight(3,2,5,[0.04,0.02,0.04]);
%     plot(inpPhi(1:length(phi)));
%     hold off;
%     title('phi');
    
%     subplot_tight(3,2,6,[0.04,0.02,0.04]);
%     plot(abs(d(1:length(y))));
%     title('d');
    
%     figure(2);
%     subplot_tight(3,1,1,[0.04,0.02,0.04]);
%     rxSig = awgn(d(1:length(dCap)),100);
%     plot(real(rxSig),imag(rxSig),'*');
%     axis equal
% 
%     rxSig = awgn(r(1:length(dCap)),100);
%     figure(2);
%     subplot_tight(3,1,2,[0.04,0.02,0.04]);
%     plot(real(rxSig),imag(rxSig),'*');
%     axis equal
% 
%     rxSig = awgn(dCap,100);
%     figure(2);
%     subplot_tight(3,1,3,[0.04,0.02,0.04]);
%     plot(real(rxSig),imag(rxSig),'*');
%     axis equal

    %drawnow;
%     
     fprintf('d: ');zprintf(d(i));fprintf('r: ');zprintf(r(i));fprintf('y: ');zprintf(y(i));
%     if(i>1)
%     fprintf('theta: %f ',theta(i-1));
%     end
%     fprintf('inp phi: %f ',inpPhi(i));fprintf('phi: %f ',phi(i));fprintf('inp phase shift: ');zprintf(exp(-1i*inpPhi(i)));
%     fprintf('phase shift: ');zprintf(exp(-1i*phi(i)));
    fprintf('\n');
    asd = 1;
end

%----------------------------------------------------------------------------------%

rxSig = awgn(dCap,100);
scatterplot(rxSig);

%% settings

v= 0.5;
snr = 50;

Fs = 500e3;     % sampling frequency (Hz)
c = 1540;       % sound speed (m/s)
pad = 1000;     % padding delay (samples)
f1 = 18e3;      % sweep low freq (Hz)
f2 = 38e3;      % sweep high freq (Hz)
T = 15e-3;      % sweep length (s)

%% generate the sweeps
A = sqrt(2);    % choose amplitude for unit power signal
up = A*chirp(0:1/Fs:T,f1,T,f2);
dn = A*chirp(0:1/Fs:T,f2,T,f1);
tx = [up dn];

%% resample to introduce Doppler
Fd = round(Fs/(1+v/c)/100)*100;     % round off to the nearest 100 Hz for resample to work
rx = resample([zeros(1,pad) tx],Fs,Fd);
% if ~mod(snr,3)
  bwf = (f2-f1)/(Fs/2);             % compute bandwidth factor for SNR as the noise
  rx = awgn(rx,snr+10*log10(bwf));  % is spread over the Nyquist bandwidth
%end
%% estimate delays
% hilbert added to get the envelope of the xcorr for more robust estimation
[dummy,d1] = max(abs(hilbert(xcorr(rx,up))));
[dummy,d2] = max(abs(hilbert(xcorr(rx,dn))));
d = (d2-d1)/Fs - T;

%% estimate Doppler from delay
s = (f2-f1)/T;
D = (d/2)*s;        % Doppler (Hz) at carrier frequency

%% compare against expected Doppler at carrier frequency
f = (f1+f2)/2;    % carrier frequency
D1 = (Fd/Fs)*f - f; % estimated Doppler (Hz) at carrier frequency
%legend(D,D1);


% 
% % dDopp1 = resample(d,floor((1+velocity/soundV)*10000),10000);
% % for count=1:length(dDopp1)
% %     dDopp1 = dDopp1*exp(-1i*2*pi*Fc*(velocity/soundV));
% % end
% % 
% % for count=1:length(dDopp1)
% %     inpPhi(count,1) = 2*pi*doppFreq*((count/FsBB));
% %     dDopp(count,1) = dDopp1(count)*exp(1i*inpPhi(count,1));
% % end
% 
% dPass = bb2pb(d,FsBB,Fc,FsPB);
% Fd = round(FsPB/(1+velocity/soundV)/100)*100; 
% dDopp1 = resample(dPass,FsPB,Fd);
% dDopp = pb2bb(dDopp1,FsBB,Fc,FsPB);
% 
% r = dDopp;
% 
% rxSig = awgn(d,50);
% scatterplot(rxSig);
% 
% rxSig = awgn(r,50);
% scatterplot(rxSig);
% 
% %----------------------------------------------------------------------------------%
% %----- ADAPTIVE RESAMPLING -------%
% 
% rPrime = resample(r,2,1);
% K1= 10e-3;
% 
% dTilda = d;
% 
% figure();
% 
% for i = 1:length(r)
%     
%     if(i==1)
%         
%         Ival(i) = 1;
%         phi(i) = 1;
%         y(i,1) = rPrime(2*i-1)*exp(-1i);
%         dCap(i,1) = y(i,1);
%         
%     else
%         
%         theta(i-1) = imag(dCap(i-1)*conj(dTilda(i-1)));
%         Ival(i) = Ival(i-1) + K1*theta(i-1);
%         phi(i) = phi(i-1) + 2*pi*(Fc/FsBB)*(Ival(i)-1);
%         y(i,1) = (Ival(i)*rPrime(2*i-1)+(Ival(i)-1)*rPrime(2*i))*exp(-1i*phi(i));
%         dCap(i,1) = y(i,1);
%         
%     end
% 
%     
%     
%     subplot_tight(3,2,1,[0.04,0.02,0.04]);
%     plot(abs(Ival));
%     title('I');
%     
% %     subplot_tight(3,2,2,[0.04,0.02,0.04]);
% %     plot((phi));
% %     hold on;
% 
%     if(i>1)
%     subplot_tight(3,2,3,[0.04,0.02,0.04]);
%     plot(abs(theta));
%     title('theta');
%     end
%         
%     subplot_tight(3,2,4,[0.04,0.02,0.04]);
%     plot(abs(y));
%     title('y');
%     
%         
% %     subplot_tight(3,2,5,[0.04,0.02,0.04]);
% %     plot(inpPhi(1:length(phi)));
% %     hold off;
% %     title('phi');
%     
%     subplot_tight(3,2,6,[0.04,0.02,0.04]);
%     plot(abs(d(1:length(y))));
%     title('d');
%     
% %     figure(2);
% %     subplot_tight(3,1,1,[0.04,0.02,0.04]);
% %     rxSig = awgn(d(1:length(dCap)),100);
% %     plot(real(rxSig),imag(rxSig),'*');
% %     axis equal
% % 
% %     rxSig = awgn(r(1:length(dCap)),100);
% %     figure(2);
% %     subplot_tight(3,1,2,[0.04,0.02,0.04]);
% %     plot(real(rxSig),imag(rxSig),'*');
% %     axis equal
% % 
% %     rxSig = awgn(dCap,100);
% %     figure(2);
% %     subplot_tight(3,1,3,[0.04,0.02,0.04]);
% %     plot(real(rxSig),imag(rxSig),'*');
% %     axis equal
% 
%     %drawnow;
%     
%     fprintf('d: ');zprintf(d(i));fprintf('r: ');zprintf(r(i));fprintf('y: ');zprintf(y(i));
%     if(i>1)
%     fprintf('theta: %f ',theta(i-1));
%     end
% %     fprintf('inp phi: %f ',inpPhi(i));fprintf('phi: %f ',phi(i));fprintf('inp phase shift: ');zprintf(exp(-1i*inpPhi(i)));
% %     fprintf('phase shift: ');zprintf(exp(-1i*phi(i)));
%     fprintf('\n');
%     asd = 1;
% end
% 
% %----------------------------------------------------------------------------------%
% 
% rxSig = awgn(dCap,100);
% scatterplot(rxSig);
