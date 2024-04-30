clear;
close all;

%Number of loops for running number of sims per SNR
numLoops = 1;

SNR = 30;

%% DECLARE AND ALLOCATE ALL ARRAYS AND INPUT PARAMETERS

FsBB = 3e3;             % Baseband sampling frequency
FsPB = 250e3;           % Passband Sampling frequency
symbolRate = 3e3;       % Symbol Rate
Fc = 17e3;              % Carrier frequency
pskMVal = 4;            % PSK M value
rrcRolloff = 0.7;       % RRC roll off
lambdaSig = 0.99;       % Forgetting factor

numTrainingSymbols = 3000;
numDataSymbols = 1000;
numSymbols = numTrainingSymbols+numDataSymbols;      % number of symbols


mu = zeros(numLoops,1); % Update factor used for updating the channel estimate

numTapsEstimator = 793; % Number of taps in the channel estimator
Nc = zeros(numLoops,1); % Number of causal taps of channel estimator
Na = zeros(numLoops,1); % Number of Acausal Taps of channel estimator

numTapsEqualizer = 26; % Number of taps in the equalizer
Lc = zeros(numLoops,1); % Number of causal taps of equalizer
La = zeros(numLoops,1); % Number of Acausal Taps of equalizer

% Arrays for savving variables and results
results = cell(numLoops,1);
dataIn = cell(numLoops,1);
dataOut = cell(numLoops,1);
d = cell(numLoops,1);
u = cell(numLoops,1);
channelSamples = cell(numLoops,1);
channelDelayedSignal = cell(numLoops,1);
r = cell(numLoops,1);
y = cell(numLoops,1);
hCap = cell(numLoops,1);
Bvals = cell(numLoops,1);
Qvals = cell(numLoops,1);
sigmaVals = cell(numLoops,1);
epsilonVals = cell(numLoops,1);
deltaVals = cell(numLoops,1);
tauVals = cell(numLoops,1);
medReal = cell(numLoops,1);
medImag = cell(numLoops,1);
errVals = cell(numLoops,1);
noise = cell(numLoops,1);

% Parameters to be used in each loop of the simulation
for i=1:numLoops
    mu(i,1) = 0.1;
    Nc(i,1) = 792;
    Na(i,1) = numTapsEstimator-Nc(i,1);
end

% Parameters to be used in each loop of the simulation
for i=1:numLoops
    Lc(i,1) = 24;
    La(i,1) = numTapsEqualizer-Lc(i,1);
end


%% TRANSMITTER

for outLoop = 1:numLoops
    
    % Generate random sets input data, each data value represnts one
    % symbol, each data value is [0,3] as a pskMval of 4 i.e. QPSK is used
    rng(outLoop);
    dataIn{outLoop} = randi([0 pskMVal-1], numSymbols, 1);
    
    % Modulate data with PSK, random dataset genrated above is used to
    % generate the symbols, pskmod is a Matlab function
    d{outLoop} = pskmod(dataIn{outLoop}, pskMVal, pi/pskMVal);
    
    % % Raised cosine filter design
    % span = 2;       % Filter span
    % sps = 1;        % Samples per symbol
    % rrcFilter = rcosdesign(rrcRolloff, span, sps,'normal');
    % % Filter with raised cosine
    % filtData = upfirdn(d, rrcFilter, sps);
    % u = filtData;
    
    % u is the modulated QPSK signal that will be transmitted
    u{outLoop} = d{outLoop}; %modulated TX signal
end

%% CHANNEL DELAY AND MULTIPATH
for outLoop = 1:numLoops
    
    %     numMultiPath = 10;
    %     multipathAttenuationReal = [0.25 0.15 0.1 0.33 0.25 0.42 0.4 0.16 0.3 0.26];    % Attenutaion from the multipath reflection
    %     multipathAttenuationImag = [0.25 0.15 0.1 0.33 0.25 0.42 0.4 0.16 0.3 0.26];    % Attenutaion from the multipath reflection
    %     multipathAttenuation = complex(multipathAttenuationReal,multipathAttenuationImag);
    %     multiPathDelay = [25 35 50 75 80 100 125 150 175 200];            % Simulated multipath delay in millisecs
    
    numMultiPath = 2;
    multipathAttenuationReal = [0.35 0.15];    % Attenutaion from the multipath reflection
    multipathAttenuationImag = [0.35 0.15];    % Attenutaion from the multipath reflection
    multipathAttenuation = complex(multipathAttenuationReal,multipathAttenuationImag);
    multiPathDelay = [120 150];            % Simulated multipath delay in millisecs
    
    channelLength = floor((max(multiPathDelay)/1000)*FsBB); % Multipath delay in number of baseband samples
    channelSamples{outLoop} =  zeros(channelLength,1); % Initialize Channel samples to zeros
    channelSamples{outLoop}(1) = 1.0;                  % Direct path with no attenutaion
    
    %Multipath with attenuation
    for i=1:numMultiPath
        multiPathSample = floor((multiPathDelay(i)/1000)*FsBB);
        channelSamples{outLoop}(multiPathSample) = multipathAttenuation(i);
    end
    
    % Simulate channel muti-path with passband TX signal , convolve the
    % channel samples with the TX signal to generate the multipath delayed
    % signal
    channelDelayedSignal{outLoop} = conv(channelSamples{outLoop},u{outLoop});
    channelDelayedSignal{outLoop} = channelDelayedSignal{outLoop}(1:length(u{outLoop}));
    
    %% NOISE
    
    % Initialize noise samples to zeros
    noise{outLoop} = zeros(round(size(channelDelayedSignal{outLoop})));
    
    % Parameters for generating SsS noise
    alpha = 1.5;
    beta = 0;
    gamma = sqrt(1/(4*log2(pskMVal)*10^(SNR/10)));
    delta = 0;
    
    %Generate the passband SaS noise
    sasNoise = stblrnd(alpha,beta,gamma,delta,floor(length(noise{outLoop})*(FsPB/FsBB)),1);
    
    %Converts passband noise to an equivalent baseband noise
    noise{outLoop} = (pb2bb(sasNoise,FsBB,Fc,FsPB));
    
    %% RECEIVER
    
    % Received signal is the sum of channel delayed signal and the baseband
    % noise generated
    
    r{outLoop}=channelDelayedSignal{outLoop}+noise{outLoop};
    
    % No adaptive resampling done here, y is the output coming out of adaptive
    % resampling, so upsample to 2*FsBB
    % y{outLoop} = resample(r{outLoop},2*FsBB,FsBB);
    
    % RX signal
    y{outLoop} = r{outLoop};
    
    
    
end

%% CHANNEL ESTIMATION

for outLoop = 1:numLoops
    
    % y(n) is sampled at twice the rate of the received signal after adaptive
    % resampling. This is being maintained for continuity
    % For Channel estimation process, u(n) will also need to be upsampled at
    % 2*FsBB
    
    % Call the channel estimation function
    % Inputs to the function :
    % channelEstimator( u{outLoop},y{outLoop},FsBB,Na(outLoop),Nc(outLoop),lambdaSig,mu(outLoop) )
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
    
    
    [ hCap{outLoop},results{outLoop},dataOut{outLoop} ] = robustEqualizer( d{outLoop},u{outLoop},y{outLoop},FsBB,Na(outLoop),Nc(outLoop),La(outLoop),Lc(outLoop),lambdaSig,mu(outLoop),numTrainingSymbols,numDataSymbols,pskMVal );
    
    % Save the simulated and estimated channel to the debug results for
    % analysis
    results{outLoop}.h = channelSamples{outLoop};
    results{outLoop}.hCap = hCap{outLoop};
    results{outLoop}.Nc = Nc(outLoop);
    results{outLoop}.Na = Na(outLoop);
    results{outLoop}.mu = mu(outLoop);
    results{outLoop}.d = d{outLoop};
    results{outLoop}.u = u{outLoop};
    results{outLoop}.y = y{outLoop};
    results{outLoop}.r = r{outLoop};
    results{outLoop}.noise = noise{outLoop};
    results{outLoop}.channelDelayedSignal = channelDelayedSignal{outLoop};
    results{outLoop}.SNR = SNR;
    results{outLoop}.dataIn = dataIn{outLoop};
    results{outLoop}.dataOut = dataOut{outLoop};
    results{outLoop}.numTrainingSymbols = numTrainingSymbols;
    results{outLoop}.numDataSymbols = numDataSymbols;
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEBUG PLOTS

% Save the results
save results.mat results;
plotResultsArray(results);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

