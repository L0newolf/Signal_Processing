function [ hCap,hCapComp,debugVals,dataOut ] = adaptiveRobustEq( d,u,r,FsBB,Na,Nc,La,Lc,lambdaSig,mu,numTrainingSymbols,numDataSymbols,pskMVal )

%uChEst = resample(u,2*FsBB,FsBB);
uChEst = u;
r=r(1:length(uChEst));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEBUG ONLY
debugVals = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end

