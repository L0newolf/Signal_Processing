function [ G,A,del ] = computeG(hCap,curU,gDim,beta,delNLMS)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%computeG Compute G matrix for the current estimated channel

eta = 0.005;

G = zeros(gDim,gDim);

% Compute Lp1 norm of the estimated channel
hCapR = abs(real(hCap));
hCapI = abs(imag(hCap));

hCapMod = sum(hCapR)+sum(hCapI);

% Compute the elements of the G matrix
% Eq.(57)

%Gv = ((1-beta)/(2*gDim))+(((1+beta)*(hCapR+hCapI))/(2*hCapMod+eta));
G = diag(((1-beta)/(2*gDim))+(((1+beta)*(hCapR+hCapI))/(2*hCapMod+eta)));

% for i=1:gDim
%     G(i,i) = ((1-beta)/(2*gDim))+(((1+beta)*(abs(real(hCap(i)))+abs(imag(hCap(i)))))/(2*hCapMod+eta));
% end

% Compute  the delta parameter 
del = ((1-beta)/(2*gDim))*delNLMS;

A = G*curU;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% eta = 0.005;
% 
% hCapReal = abs(real(hCap));
% hCapImag = abs(imag(hCap));
% 
% curUReal = (real(curU));
% curUImag = (imag(curU));
% 
% A = zeros(gDim,1);
% 
% %[GC,AReal,AImag,del] = computeGC(hCapReal,hCapImag,curUReal,curUImag,gDim,beta,delNLMS,eta);
% % G = diag(GC);
% % A = complex(AReal,AImag);
% 
% hCapMod = sum(hCapReal)+sum(hCapImag);
% hCapRealGPU = hCapReal.*ones(gDim,1,'gpuArray');
% hCapImagGPU = hCapImag.*ones(gDim,1,'gpuArray');
% curURealGPU = curUReal.*ones(gDim,1,'gpuArray');
% curUImagGPU = curUImag.*ones(gDim,1,'gpuArray');
% 
% [GGPU,ARealGPU,AImagGPU,del] = computeGACuda(hCapRealGPU,hCapImagGPU,curURealGPU,curUImagGPU,gDim,beta,delNLMS,eta,hCapMod);
% %G = diag(GGPU);
% G = gather(GGPU);
% AReal = gather(ARealGPU);
% AImag = gather(AImagGPU);
% A = complex(AReal,AImag);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

