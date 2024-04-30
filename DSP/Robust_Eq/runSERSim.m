clear;
close all;

profile on;

%Number of SNR vals to use
numSNRVals = 20;

%Number of loops for running number of sims per SNR
numItrs = 10;
channelLength = 0;

%% DECLARE AND ALLOCATE ALL ARRAYS AND INPUT PARAMETERS

FsBB = 3e3;             % Baseband sampling frequency
FsPB = 250e3;           % Passband Sampling frequency
symbolRate = 3e3;       % Symbol Rate
Fc = 17e3;              % Carrier frequency
pskMVal = 4;            % PSK M value
rrcRolloff = 0.7;       % RRC roll off
lambdaSig = 0.99;       % Forgetting factor

numTrainingSymbols = 1000;
numDataSymbols = 100000;
numSymbols = numTrainingSymbols+numDataSymbols;      % number of symbolsrestar

numTapsEstimator = 793; % Number of taps in the channel estimator
Nc = 792; % Number of causal taps of channel estimator
Na = numTapsEstimator-Nc; % Number of Acausal Taps of channel estimator
mu = 0.1; % Update factor used for updating the channel estimate

numTapsEqualizer = 26; % Number of taps in the equalizer
Lc = 24; % Number of causal taps of equalizer
La = numTapsEqualizer-Lc; % Number of Acausal Taps of equalizer

% % Raised cosine filter design
% span = 2;       % Filter span
% sps = 1;        % Samples per symbol
% rrcFilter = rcosdesign(rrcRolloff, span, sps,'normal');

%%Channel Parameters
numMultiPath = 1;
multipathAttenuation = [0.45+i*0.45];    % Attenutaion from the multipath reflection
multiPathDelay = [120];            % Simulated multipath delay in millisecs

debugVals = cell(numSNRVals,1);
SNR = zeros(numSNRVals,1);
SER = zeros(numSNRVals,1);
compRes = cell(numSNRVals,1);


for snrLoop = 1:numSNRVals
    
    SNR(snrLoop) = 10+snrLoop ;
    
    % Arrays for saving variables and results
    results = cell(1,1);
    hCapAvg = zeros(Na+Nc,1);
    
    fprintf('Running for snrLoop: %d SNR: %d \n',snrLoop,SNR(snrLoop));
    
    for itrLoop = 1:numItrs
        
        %% TRANSMITTER
        
        % Generate random sets input data, each data value represnts one
        % symbol, each data value is [0,3] as a pskMval of 4 i.e. QPSK is used
        rng('shuffle');
        dataIn = randi([0 pskMVal-1], numSymbols, 1);
        
        % Modulate data with PSK, random dataset genrated above is used to
        % generate the symbols, pskmod is a Matlab function
        d = pskmod(dataIn, pskMVal, pi/pskMVal);
        
        % % Filter with raised cosine
        % u is the modulated QPSK signal that will be transmitted
        % filtData = upfirdn(d, rrcFilter, sps);
        % u = filtData;
        
        u = d; %modulated TX signal
        
        %% CHANNEL DELAY AND MULTIPATH
        
        % Simulate channel muti-path with passband TX signal , convolve the
        % channel samples with the TX signal to generate the multipath delayed
        % signal
        
        channelDelayedSignal = zeros(numSymbols,1);
        tapShift = 0;
        r=0.0;
        
        for i=1:numSymbols
            % Direct Path for current signal
            channelDelayedSignal(i) = u(i); 
            
            % Generate the channel taps for current symbol
            [ channelSamples,multiPathTap ] = genChannelMultipathStatic( numMultiPath,multipathAttenuation,multiPathDelay,FsBB );
            %[ channelSamples,multiPathTap,tapShift ] = genChannelMultipath( numMultiPath,multipathAttenuation,multiPathDelay,FsBB,i,tapShift );
            %[ channelSamples,multiPathTap,r ] = genChannelMultipathAmp( numMultiPath,multipathAttenuation,multiPathDelay,FsBB,i,r );
            
            
            hComp(:,i) = channelSamples;
            
            % Add the multipath components
            for j=1:numMultiPath
                if(i-multiPathTap(j)+1>0)
                    channelDelayedSignal(i)=channelDelayedSignal(i)+channelSamples(multiPathTap(j))*u(i-multiPathTap(j)+1);
                end
            end
        end
        
        
        
        %% NOISE
        % Initialize noise samples to zeros
        noise = zeros(round(size(channelDelayedSignal)));
        
        % Parameters for generating SaS noise
        alpha = 1.5;
        beta = 0;
        delta = 10;
        
        Eb = 0;
        temp = mean(hComp,2);
        for j=1:length(temp)
            Eb = Eb+abs(temp(j))^2;
        end
        
        gamma = 0.5*sqrt(Eb/10^(SNR(snrLoop)/10));
        %Generate the passband SaS noise
        sasNoise = stblrnd(alpha,beta,gamma,delta,floor(length(noise)*(FsPB/FsBB)),1);
        
        %Converts passband noise to an equivalent baseband noise
        noise = (pb2bb(sasNoise,FsBB,Fc,FsPB));
        
        %% RECEIVER
        
        % Received signal is the sum of channel delayed signal and the baseband
        % noise generated
        
        r=channelDelayedSignal+noise;
        
        % No adaptive resampling done here, y is the output coming out of adaptive
        % resampling, so upsample to 2*FsBB
        % y = resample(r,2*FsBB,FsBB);
        
        % RX signal
        y = r;
        
        
        %% CHANNEL ESTIMATION
        
        
        
        % y(n) is sampled at twice the rate of the received signal after adaptive
        % resampling. This is being maintained for continuity
        % For Channel estimation process, u(n) will also need to be upsampled at
        % 2*FsBB
        
        % Call the channel estimation function
        % Inputs to the function :
        % channelEstimator( u,y,FsBB,Na,Nc(itrLoop),lambdaSig,mu )
        % u: Transmitted signal
        % y: Received signal
        % FsBB : Baseband sampling frequency
        % Na : Number of acausal taps
        % Nc : Number of a causal taps
        % lambdaSig : Forgetting factor
        % mu : update factor
        %
        % Outputs of the function :
        % hCap : Estimated channel
        % debugVals : debug information
        
        
        [ hCap,hCapComp,results,dataOut ] = robustEqualizer( d,u,y,FsBB,Na,Nc,La,Lc,lambdaSig,mu,numTrainingSymbols,numDataSymbols,pskMVal );
        
        % Save the simulated and estimated channel to the debug results for
        % analysis
%         results.h = channelSamples;
%         results.hCap = hCap;
%         results.hCapComp = hCapComp;
%         results.Nc = Nc;
%         results.Na = Na;
%         results.mu = mu;
%         results.d = d;
%         results.u = u;
%         results.y = y;
%         results.r = r;
%         results.noise = noise;
%         results.channelDelayedSignal = channelDelayedSignal;
%         results.SNR = SNR(snrLoop);
%         results.dataIn = dataIn;
%         results.dataOut = dataOut;
%         results.numTrainingSymbols = numTrainingSymbols;
%         results.numDataSymbols = numDataSymbols;
        
        [ numErr,SERnow ] = computeSER( dataIn(numTrainingSymbols+1:numSymbols),dataOut(numTrainingSymbols+1:numSymbols) );
        SER(snrLoop) = SER(snrLoop)+SERnow;
        hCapAvg = hCapAvg+hCap;
        fprintf('Finished iteration : %d symbol errors : %d \n',itrLoop,numErr);
        
    end
    hCapAvg = hCapAvg/numItrs;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% DEBUG
    
    SER(snrLoop) = SER(snrLoop)/numItrs;
    
%     debugVals{snrLoop}.results = results;
%     debugVals{snrLoop}.SNR = SNR(snrLoop);
%     debugVals{snrLoop}.SER = SER(snrLoop);
%     debugVals{snrLoop}.hCapAvg = hCapAvg;
    
    fprintf('Finished for snrLoop: %d SNR: %d SER : %f \n',snrLoop,SNR(snrLoop),SER(snrLoop));
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEBUG PLOTS

% Save the results
%
% save debugVals.mat debugVals;

% for i=1:numSNRVals
%     plotRes{i,1} = debugVals{i}.results;
% end
%  plotResultsArray(plotRes);


% imgY = 0:1/FsBB:(numSymbols/FsBB);
% imgX = 0:1000/FsBB:((length(hCapComp(:,1))/(FsBB/1000)));
% imgX(length(imgX)) = [];
% imgY(length(imgY)) = [];
% 
% figure();
% imagesc(imgX,imgY,fliplr(abs(hCapComp)'),'CDataMapping','scaled');
% xlabel('Delay( ms )');
% ylabel('Time( s )');
% 
% imgY = 0:1/FsBB:(numSymbols/FsBB);
% imgX = 0:1000/FsBB:((length(hComp(:,1))/(FsBB/1000)));
% imgX(length(imgX)) = [];
% imgY(length(imgY)) = [];
% 
% figure();
% ax2 = subplot_tight(2,1,1,[0.05,0.03,0.05]);
% surf(imgX,imgY,(abs(hComp)'),'FaceAlpha',0.5,'EdgeColor','interp');
% zlim(ax2,[0.001 1]);
% xlabel('Delay( ms )');
% ylabel('Time( s )');
% title('Simulated channel');
% 
% ax2 = subplot_tight(2,1,2,[0.05,0.03,0.05]);
% len = length(hComp(:,1));
% surf(imgX,imgY,fliplr(abs(hCapComp(Na+Nc-len+1:Na+Nc,:))'),'FaceAlpha',0.5,'EdgeColor','interp');
% zlim(ax2,[0.001 1]);
% xlabel('Delay( ms )');
% ylabel('Time( s )');
% title('Estimated channel');
% 
% figure();
% ax2 = subplot_tight(1,1,1,[0.07,0.05,0.07]);
% len = length(hComp(:,1));
% diffH = abs(abs(hComp)' - fliplr(abs(hCapComp(Na+Nc-len+1:Na+Nc,:))'));
% surf(imgX,imgY,diffH,'FaceAlpha',0.5,'EdgeColor','interp');
% zlim(ax2,[0.001 1]);
% set(gca, 'ZScale', 'log');
% xlabel('Delay( ms )');
% ylabel('Time( s )');
% title('Error between simulated and Estimated channel');

plotBER( SNR,SER );

profile viewer;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%