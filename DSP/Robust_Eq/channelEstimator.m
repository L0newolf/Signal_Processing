function [hCap,curU,curErrorWin,sigmaRSqr,sigmaISqr,debugVals,uCount,updateP  ] = channelEstimator( y,hCap,curU,Nw,c,i,curErrorWin,sigmaRSqr,lambdaSig,sigmaISqr,Nc,Na,mu,uChEst,debugVals,uCount )
% channelEstimator channel estimation function


    % Compute the error between the current Rx sample and estimated Rx
    % sample using current Tx window and last estimated channel taps
    curErrVal = (y(i)) - (ctranspose(hCap)*(curU));
    
    % Update current error observation window
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
    [ q,updateP ] = qIPMAPA( curErrVal,epsilon,delta,tau );
    Q = q;
    
    % Compute the G matrix for the last estimated channel
    beta = 0.5;     % beta value for very sparse channel. TABLE 1
    delNLMS = 10;   % delta value for NLMS algorithm . TABLE 1
    [ G,del ] = computeG(hCap,Na+Nc,beta,delNLMS);
    
    % Compute current A matrix
    % Eq.(15)
    A = G*curU;
    
    % Compute current B matrix
    % Eq.(16)
    if(Q == 0)
        B = 0;
    else
        B = 1/(ctranspose(curU)*A + del*(1/Q));
    end
    
    % fprintf('del*(1/Q) = %f ctranspose(curU)*A = %f sum = %f B = inv = %f \n',del*(1/Q),ctranspose(curU)*A,(ctranspose(curU)*A + del*(1/Q)),1/(ctranspose(curU)*A + del*(1/Q)));
    
    % Update estimated channel
    hCap = hCap + (mu*A*B*conj(curErrVal));
    
    % Update the current Tx window
    % Shift all values of the winow to the right
    for j=1:Nc+Na-1
        curU(j) = curU(j+1);
    end
    
    % Check if the current signal window is overflowing
    if(uCount > length(uChEst))
        %The signal window is at the end, so the next acausal samples would be zero as there is no more signal being Tx
        curU(Nc+Na) = complex(0,0);
    else
        % Else update the current signal window with the nect Tx signal
        curU(Nc+Na) = uChEst(uCount);
    end
    uCount=uCount+1;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% DEBUG ONLY
    %
    debugVals.Bvals(i,1) = [B];
    debugVals.Qvals(i,1) = [Q];
    debugVals.sigmaVals(i,1) = [sigma];
    debugVals.epsilonVals(i,1) = [epsilon];
    debugVals.deltaVals(i,1) = [delta];
    debugVals.tauVals(i,1) = [tau];
    debugVals.medReal(i,1) = [median(real(curErrorWin).*real(curErrorWin))];
    debugVals.medImag(i,1) = [median(imag(curErrorWin).*imag(curErrorWin))];
    debugVals.errVals(i,1) = curErrVal;
    
%     figure(8);
%     
%     subplot_tight(4,2,1,[0.04,0.02,0.04]);
%     plot(abs(hCap));
%     title('hCap');
%     
%     subplot_tight(4,2,2,[0.04,0.02,0.04]);
%     plot(abs(curU));
%     title('cur U window');
%     
%     subplot_tight(4,2,3,[0.04,0.02,0.04]);
%     plot(abs(A));
%     hold on;
%     plot(abs((mu*A*B*conj(curErrVal))));
%     hold off;
%     legend('A','hCap delta');
%     title('A');
%     
%     subplot_tight(4,2,4,[0.04,0.02,0.04]);
%     plot(abs(diag(G)));
%     title('G');
%     
%     subplot_tight(4,2,5,[0.04,0.02,0.04]);
%     plot(abs(debugVals.Bvals(1:i)));
%     title('B');
%     
%     subplot_tight(4,2,6,[0.04,0.02,0.04]);
%     plot(abs(debugVals.Qvals(1:i)));
%     title('Q');
%     
%     errorArr = [errorArr curErrVal];
%     subplot_tight(4,2,7,[0.04,0.02,0.04]);
%     plot(debugVals.sigmaVals(1:i));
%     hold on;
%     plot(debugVals.epsilonVals(1:i));
%     plot(debugVals.deltaVals(1:i));
%     plot(debugVals.tauVals(1:i));
%     plot(abs(debugVals.errVals(1:i)));
%     hold off;
%     legend('sigmaVals','epsilonVals','deltaVals','tauVals','errors');
%     title('sigma,epsilon,delta and tau');
%     
%     subplot_tight(4,2,8,[0.04,0.02,0.04]);
%     plot(debugVals.medReal(1:i));
%     hold on;
%     plot(debugVals.medImag(1:i));
%     hold off;
%     legend('median real err win','median imag err win');
%     title('current error window');
%     
%     drawnow;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
end

