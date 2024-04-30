 function [ hCap,hCapComp,debugVals,dataOut ] = robustEqualizer( d,u,r,FsBB,Na,Nc,La,Lc,lambdaSig,mu,numTrainingSymbols,numDataSymbols,pskMVal)
%   Robust Equalizer function
%   Inputs to the function :
%   robustEqualizer( u,r,FsBB,Na,Nc,lambdaSig,mu )
%   u: Transmitted signal
%   r: Received signal
%   FsBB : Baseband sampling frequency
%   Na : Number of acausal taps
%   Nc : Number of a causal taps
%   lambdaSig : Forgetting factor
%   mu : update factor
%
%   Outputs of the function :
%   hCap : Estimated channel
%   debugVals : debug information

%uChEst = resample(u,2*FsBB,FsBB);
uChEst = u;
r=r(1:length(uChEst));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEBUG ONLY
debugVals = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Error Signal Observation window, should be chosen to be smaller than the
% channel coherence time
% Nw is the length of the error signal observation window
channelCoherenceTime = 0.015;
Nw = floor(channelCoherenceTime*FsBB);

% curErrorWin is the error signal observation window
curErrorWin = [];

% Sample correction factor
c = 1.483*(1+(5/(Nw-1))); % Eq.(25)

% Initalize sigma variables to a high value to allow convergence
sigmaRSqr = 1/sqrt(2);
sigmaISqr = 1/sqrt(2);
sigma = 1;

% counter to keep track of the number of samples processed
uCount = Na+1;
eqUCount = Na+Lc+1;

% Since there is no singal before the first sample, the Nc causal samples
% are set to zero, the Na acausal samples are the first Na samples of the
% Tx signal
% Initialize current estimator input signal window
curUEstimator = complex(zeros(Nc+Na,1),zeros(Nc+Na,1));
% for i=1:Na
%     curUEstimator(Nc+i) = uChEst(i);
% end

% Initialize current equalizer input signal window
curUEqualizer = complex(zeros(Nc,1),zeros(Nc,1));

% Current ISI free signal
yBar = complex(zeros(Lc,1),zeros(Lc,1));
yCap = complex(zeros(Lc,1),zeros(Lc,1));

% Initialize the estimated channel array with Na+Nc zeros
hCap = complex(zeros(Na+Nc,1),zeros(Na+Nc,1));
hCapComp = complex(zeros(Na+Nc,length(uChEst)),zeros(Na+Nc,length(uChEst)));

%Initialize the equalizer arrays
eqErr = zeros(length(uChEst),1);
dCap = zeros(length(uChEst),1);
dBar = zeros(length(uChEst),1);
dataOut = zeros(length(uChEst),1);

%forgetting factor
lambdaEq = 1-(1/(4*(La+Lc))) ;
%initial P matrix
delta = 0.1 ;
P = delta * eye (Lc,'like',uChEst ) ;
p = zeros ( Lc , 1 ) ;

updateP = ones(length(uChEst),1);


% Output from the Adaptive resampling
y = r;

% Start iterating over all the samples
for i=1:length(uChEst)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Remove ISI
    
    debugVals.yNoISI(i,1) = y(i) - ctranspose(hCap(1:Nc))*curUEqualizer;
    
    for j=Lc:-1:2
        yBar(j)=yBar(j-1);
    end
    yBar(1) = y(i) - ctranspose(hCap(1:Nc))*curUEqualizer;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Equalizer
    % If the number of samples processed is greater than the number of
    % equalizer taps, start the equalization process
    if(i>=Lc)
        
        % Equalizer Process
        dCap(i,1)=ctranspose(p) * yBar;
        
        dataOut(i,1) = pskdemod(dCap(i,1),pskMVal,pi/pskMVal);
        dBar(i,1) = pskmod(dataOut(i,1),pskMVal,pi/pskMVal);
        
        if(i<numTrainingSymbols)
            eqErr(i) = d(i) - dCap(i,1) ;
        else
            eqErr(i) = dBar(i) - dCap(i,1) ;
        end
        
        if(updateP(i) == 1)
            phi = P*(yBar) ;
            k = (phi)/(lambdaEq + ctranspose(yBar)*P * yBar );
            p = p + k * conj(eqErr(i)) ;
            P = ( P - k*ctranspose(yBar)*P ) / lambdaEq ;
        end
        % End of Equalization process
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Update equalizer Input
    
    if(i<numTrainingSymbols)
        nextVal = uChEst(i);
    else
        nextVal = dBar(i);
    end
    
%     for j=1:Nc-1
%         curUEqualizer(j) = curUEqualizer(j+1);
%     end
%     curUEqualizer(Nc) = nextVal;
    curUEqualizer = vertcat(curUEqualizer(2:Nc),nextVal);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Channel Estimation function
    %[hCap,curUEstimator,curErrorWin,sigmaRSqr,sigmaISqr,debugVals,uCount,updateP(i)] = channelEstimator( y,hCap,curUEstimator,Nw,c,i,curErrorWin,sigmaRSqr,lambdaSig,sigmaISqr,Nc,Na,mu,uChEst,debugVals,uCount );
    
    %Generate current estimator input window
%     for j=1:Nc+Na-1
%         curUEstimator(j) = curUEstimator(j+1);
%     end
%     if(i<(numTrainingSymbols+numDataSymbols-Na+1))
%         if(i<(numTrainingSymbols-Na+1))
%             curUEstimator(Na+Nc) = uChEst(i+Na-1);
%         else
%             curUEstimator(Na+Nc) = dBar(i);
%         end
%     else
%         curUEstimator(Na+Nc) = 0;
%     end
    
    if(i<(numTrainingSymbols+numDataSymbols-Na+1))
        if(i<(numTrainingSymbols-Na+1))
            nextVal = uChEst(i+Na-1);
        else
            nextVal = dBar(i);
        end
    else
        nextVal = 0;
    end
    curUEstimator = vertcat(curUEstimator(2:Na+Nc),nextVal);
    
    % Compute the error between the current Rx sample and estimated Rx
    % sample using current Tx window and last estimated channel taps
    curErrVal = (y(i)) - (ctranspose(hCap)*(curUEstimator));
    
    % Update current errSERor observation window
    if(i<=Nw)
        % if error window length is less than oservation window length, add the current error to the window
        curErrorWin = [curErrorWin curErrVal];
    else
        % else rotate the error window and add current error to the beginning of the window
        curErrorWin(1:Nw-1) = curErrorWin(2:Nw);
        curErrorWin(Nw) = curErrVal;
    end
    
    % Compute current sigma value for the current error observation window
    
    %Eq.(21)
    sigmaRSqr = lambdaSig*sigmaRSqr+c*(1-lambdaSig)*median(real(curErrorWin).*real(curErrorWin));
    %Eq.(22)
    sigmaISqr = lambdaSig*sigmaISqr+c*(1-lambdaSig)*median(imag(curErrorWin).*imag(curErrorWin));
    %Eq.(20)
    sigma = sqrt((sigmaRSqr+sigmaISqr)/2);
    
    % Update detection parameters
    epsilon = 2.45*sigma;
    delta = 2.72*sigma;
    tau = 3.03*sigma;
    
    % Compute current q value using IPMAPA
    if(i==length(uChEst))
        [ q,updateP(i) ] = qIPMAPA( curErrVal,epsilon,delta,tau );
    else
        [ q,updateP(i+1) ] = qIPMAPA( curErrVal,epsilon,delta,tau );
    end
    Q = q;
    
    
%     % Compute the G matrix for the last estimated channel
%     beta = 0.5;     % beta value for very sparse channel. TABLE 1
%     delNLMS = 10;   % delta value for NLMS algorithm . TABLE 1
%     [ G,del ] = computeG(hCap,Na+Nc,beta,delNLMS);
%     
%     % Compute current A matrix
%     % Eq.(15)
%     A = G*curUEstimator;
    
    % Compute the G matrix for the last estimated channel
    % Compute current A matrix
    % Eq.(15)
    
    beta = 0.5;     % beta value for very sparse channel. TABLE 1
    delNLMS = 10;   % delta value for NLMS algorithm . TABLE 1
    [ G,A,del ] = computeG(hCap,curUEstimator,Na+Nc,beta,delNLMS);

    % Compute current B matrix
    % Eq.(16)
    if(Q == 0)
        B = 0;
    else
        B = 1/(ctranspose(curUEstimator)*A + del*(1/Q));
    end
    
    % Update estimated channel
    hCap = hCap + (mu*A*B*conj(curErrVal));
    hCapComp(:,i) = hCap;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% DEBUG ONLY
    
    debugVals.Bvals(i,1) = B;
    debugVals.Qvals(i,1) = Q;
    debugVals.sigmaVals(i,1) = sigma;
    debugVals.epsilonVals(i,1) = epsilon;
    debugVals.deltaVals(i,1) = delta;
    debugVals.tauVals(i,1) = tau;
    debugVals.medReal(i,1) = median(real(curErrorWin).*real(curErrorWin));
    debugVals.medImag(i,1) = median(imag(curErrorWin).*imag(curErrorWin));
    debugVals.errVals(i,1) = curErrVal;
    %fprintf('i = %d , est err : %f+i*%f , eq err : %f+i*%f \n',i,real(debugVals.errVals(i,1)),imag(debugVals.errVals(i,1)),real(eqErr(i)),imag(eqErr(i)));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
end

% Complex channel being extimated in the conjugate of the simulated channel
% so take conjugate after the channel has been estimated
hCap = conj(hCap);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEBUG ONLY
debugVals.dCap = dCap;
debugVals.eqErr = eqErr;
debugVals.dBar = dBar;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

