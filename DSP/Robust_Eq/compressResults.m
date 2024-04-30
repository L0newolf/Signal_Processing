function [] = compressResults( debugVals )

numSNR = length(debugVals);
numItr = length(debugVals{1}.results);

comRes = cell(numSNR,1);
% 
% for i=1:numSNR
%     comRes{i}.yNoISI = zeros(length(debugVals{1}.results{1}.yNoISI));
%     comRes{i}.Bvals = zeros(length(debugVals{1}.results{1}.Bvals));
%     comRes{i}.Qvals = zeros(length(debugVals{1}.results{1}.Qvals));
%     comRes{i}.sigmaVals = zeros(length(debugVals{1}.results{1}.sigmaVals));
%     comRes{i}.epsilonVals = zeros(length(debugVals{1}.results{1}.epsilonVals));
%     comRes{i}.deltaVals = zeros(length(debugVals{1}.results{1}.deltaVals));
%     comRes{i}.tauVals = zeros(length(debugVals{1}.results{1}.tauVals));
%     comRes{i}.medReal = zeros(length(debugVals{1}.results{1}.medReal));
%     comRes{i}.medImag = zeros(length(debugVals{1}.results{1}.medImag));
%     comRes{i}.errVals = zeros(length(debugVals{1}.results{1}.errVals));
%     comRes{i}.dCap = zeros(length(debugVals{1}.results{1}.dCap));
%     comRes{i}.eqErr = zeros(length(debugVals{1}.results{1}.eqErr));
%     comRes{i}.dBar = zeros(length(debugVals{1}.results{1}.dBar));
%     comRes{i}.h = zeros(length(debugVals{1}.results{1}.h));
%     comRes{i}.hCap = zeros(length(debugVals{1}.results{1}.hCap));
%     comRes{i}.Nc = zeros(length(debugVals{1}.results{1}.Nc));
%     comRes{i}.Na = zeros(length(debugVals{1}.results{1}.Na));
%     comRes{i}.mu = zeros(length(debugVals{1}.results{1}.mu));
%     comRes{i}.d = zeros(length(debugVals{1}.results{1}.d));
%     comRes{i}.u = zeros(length(debugVals{1}.results{1}.u));
%     comRes{i}.y = zeros(length(debugVals{1}.results{1}.y));
%     comRes{i}.r = zeros(length(debugVals{1}.results{1}.r));
%     comRes{i}.noise = zeros(length(debugVals{1}.results{1}.noise));
%     comRes{i}.channelDelayedSignal = zeros(length(debugVals{1}.results{1}.channelDelayedSignal));
%     comRes{i}.SNR = zeros(length(debugVals{1}.results{1}.SNR));
%     comRes{i}.dataIn = zeros(length(debugVals{1}.results{1}.dataIn));
%     comRes{i}.dataOut = zeros(length(debugVals{1}.results{1}.dataOut));
%     comRes{i}.numTrainingSymbols = zeros(length(debugVals{1}.results{1}.numTrainingSymbols));
%     comRes{i}.numDataSymbols = zeros(length(debugVals{1}.results{1}.numDataSymbols));
%     comRes{i}.BER = zeros(length(debugVals{1}.results{1}.BER));
% end

for i=1:numSNR
    for j=1:numItr
        comRes{i}.yNoISI = comRes{i}.yNoISI+(debugVals{i}.results{j}.yNoISI)/numItr;
%         comRes{i}.Bvals = zeros(length(debugVals{1}.results{1}.Bvals));
%         comRes{i}.Qvals = zeros(length(debugVals{1}.results{1}.Qvals));
%         comRes{i}.sigmaVals = zeros(length(debugVals{1}.results{1}.sigmaVals));
%         comRes{i}.epsilonVals = zeros(length(debugVals{1}.results{1}.epsilonVals));
%         comRes{i}.deltaVals = zeros(length(debugVals{1}.results{1}.deltaVals));
%         comRes{i}.tauVals = zeros(length(debugVals{1}.results{1}.tauVals));
%         comRes{i}.medReal = zeros(length(debugVals{1}.results{1}.medReal));
%         comRes{i}.medImag = zeros(length(debugVals{1}.results{1}.medImag));
%         comRes{i}.errVals = zeros(length(debugVals{1}.results{1}.errVals));
%         comRes{i}.dCap = zeros(length(debugVals{1}.results{1}.dCap));
%         comRes{i}.eqErr = zeros(length(debugVals{1}.results{1}.eqErr));
%         comRes{i}.dBar = zeros(length(debugVals{1}.results{1}.dBar));
%         comRes{i}.h = zeros(length(debugVals{1}.results{1}.h));
%         comRes{i}.hCap = zeros(length(debugVals{1}.results{1}.hCap));
%         comRes{i}.Nc = zeros(length(debugVals{1}.results{1}.Nc));
%         comRes{i}.Na = zeros(length(debugVals{1}.results{1}.Na));
%         comRes{i}.mu = zeros(length(debugVals{1}.results{1}.mu));
%         comRes{i}.d = zeros(length(debugVals{1}.results{1}.d));
%         comRes{i}.u = zeros(length(debugVals{1}.results{1}.u));
%         comRes{i}.y = zeros(length(debugVals{1}.results{1}.y));
%         comRes{i}.r = zeros(length(debugVals{1}.results{1}.r));
%         comRes{i}.noise = zeros(length(debugVals{1}.results{1}.noise));
%         comRes{i}.channelDelayedSignal = zeros(length(debugVals{1}.results{1}.channelDelayedSignal));
%         comRes{i}.SNR = zeros(length(debugVals{1}.results{1}.SNR));
%         comRes{i}.dataIn = zeros(length(debugVals{1}.results{1}.dataIn));
%         comRes{i}.dataOut = zeros(length(debugVals{1}.results{1}.dataOut));
%         comRes{i}.numTrainingSymbols = zeros(length(debugVals{1}.results{1}.numTrainingSymbols));
%         comRes{i}.numDataSymbols = zeros(length(debugVals{1}.results{1}.numDataSymbols));
%         comRes{i}.BER = zeros(length(debugVals{1}.results{1}.BER));
    end
end

end

