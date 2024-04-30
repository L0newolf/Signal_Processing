close all;
clear;
clc;

%rng('default');             % seed the rng
NT=256;                      % number of tasks (or frequency)
Ni=96*ones(NT,1);             % signal length (n_i) [# of sensors]
m=60;                        % dictionary size     [scanning angles]
Nob=10;                       % number of obervation

PHI=cell(NT,1);
theta=cell(NT,1);
nu=cell(NT,1);
v=cell(NT,1);

ntargets=30;                  % number of sparse targets
q = randperm(m);
qs = q(1:ntargets);           % targets index

% generate the date for the problem
for i=1:NT
    % projection matrix
    PHI{i} = randn(Ni(i), m)+1i*randn(Ni(i), m);

    % True weights
    theta{i} = zeros(m,Nob);
    theta{i}(qs,:)=randn(ntargets, Nob)+1i*randn(ntargets, Nob);

    % noise
    sigma = 0.01;
    nu{i} = sigma*randn(Ni(i),Nob);

    v{i} = PHI{i}*theta{i} + nu{i};
end



% parameters for MTMOCS
eta=1e-8;
a = 1e2/0.1;
b = 1;
maxiter = 10000;
rc = 1;

tic;
[ weights,ML, L0 ] = callMTCS( PHI,v,a,b,Ni,NT,Nob,m,rc,eta,maxiter );
toc;

figure(1);
plot(cumsum(ML)+L0,'-o');

inputData = zeros(NT*m*Nob,1);
outputData = zeros(NT*m*Nob,1);
count = 1;
for i=1:NT
    for j=1:m
        for k=1:Nob
            inputData(count) = theta{i}(j,k);
            outputData(count) = weights(j,i,k);
            count = count+1;
        end
    end
end
error = inputData-outputData;


figure(2);
subplot(2,1,1);
plot(real(error));
ylim([-4 4]);
subplot(2,1,2);
plot(imag(error));
title('Errors between input and output weights');
ylim([-4 4]);
figure(3);
subplot(2,1,1);
plot(real(inputData));
ylim([-4 4]);
subplot(2,1,2);
plot(imag(inputData));
title('Input weights');
ylim([-4 4]);
figure(4);
subplot(2,1,1);
plot(real(outputData));
ylim([-4 4]);
subplot(2,1,2);
plot(imag(outputData));
title('Output weights');
ylim([-4 4]);
