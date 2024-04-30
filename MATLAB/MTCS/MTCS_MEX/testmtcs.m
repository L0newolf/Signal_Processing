fileID = fopen('errors.txt','w');
fclose(fileID);

for loops = 1:1000

rng(loops);             % seed the rng
%rng('default');     % seed the rng
%rng('shuffle');    % seed the rng
 
% N = 512;            % signal length
% T = 20;  %40           % number of spikes
% K = [90,70];        % number of CS measurements
% Overlap=10;         % Overlap signal
N = 8;            % signal length
T = 4;  %40           % number of spikes
K = [10,9];        % number of CS measurements
Overlap=2;         % Overlap signal
L=2;
NT=2;
 
% sparse random +/- 1 signal
x1 = zeros(N,L);
x2 = zeros(N,L);
 
% use randperm to implement the random locations of the spikes
q = randperm(N);
% first signal has T random spikes
x1(q(1:T),:) = randn(T,L)+1i*randn(T,L);
% second signal has 75 similarity with first signal
% spikes occurs in the same time locations for T-5 spike out of T spikes
x2(q([1:T-Overlap,T+1:T+Overlap]),:) = randn(T,L)+1i*randn(T,L);
theta={x1,x2};
 
%{
figure;
plot(real(x1)); title('Original Signal 1 (Real Part)');
hold on; plot(real(x2)+.2, ':'); title('Original Signal 2 (Real Part)'); axis tight
hold off
%}
 
%% projection matrix
A1 = randn(K(1),N)+1i*randn(K(1),N);
A1 = bsxfun(@rdivide, A1, std(A1, [], 2));
A2 = randn(K(2),N)+1i*randn(K(2),N);
A2 = bsxfun(@rdivide, A2, std(A2, [], 2));
A{1} = A1;
A{2} = A2;
x{1} = x1;
x{2} = x2;

% noisy observations
sigma = 0.02;
e1 = sigma*(randn(K(1),L)+1i*randn(K(1),L))/sqrt(2);
e2 = sigma*(randn(K(2),L)+1i*randn(K(2),L))/sqrt(2);
y1 = A1*x1 + e1;
y2 = A2*x2 + e2;
y{1} = y1;
y{2} = y2;
 
eta=1e-8;
maxiter=10000;
 
a = 1; b = 1;
 
%% solve 1&2 by MTCS: Multi-Task Problem with {A1,A2}, y
%a = 1e2/0.1; b = 1;
%a=10/var([y{1}; y{2}]); b=10;




 
tstart=tic;
[weightsM] = mtcsMat(A,y,a,b,eta,maxiter);
telapsed=toc(tstart);
fprintf('Time Spent for m  (toARL): %.6fs\n', telapsed);
 
Nob=L;
rc=1; m=N;

fileID1  = fopen('C:\Users\Anshu\Desktop\MTCS_MEX_SINGLE_THREAD\data\PHIreal.txt','w');
fileID2  = fopen('C:\Users\Anshu\Desktop\MTCS_MEX_SINGLE_THREAD\data\PHIimag.txt','w');
for i=1:NT
    for j=1:K(i)
        for k=1:m
            fprintf(fileID1,'%f\n',real(A{i}(j,k)));
            fprintf(fileID2,'%f\n',imag(A{i}(j,k)));
        end
    end
end
fclose(fileID1);
fclose(fileID2);

fileID1  = fopen('C:\Users\Anshu\Desktop\MTCS_MEX_SINGLE_THREAD\data\thetaReal.txt','w');
fileID2  = fopen('C:\Users\Anshu\Desktop\MTCS_MEX_SINGLE_THREAD\data\thetaImag.txt','w');
for i=1:NT
    for j=1:m
        for k=1:Nob
            fprintf(fileID1,'%f\n',real(x{i}(j,k)));
            fprintf(fileID2,'%f\n',imag(x{i}(j,k)));
        end
    end
end
fclose(fileID1);
fclose(fileID2);


fileID1  = fopen('C:\Users\Anshu\Desktop\MTCS_MEX_SINGLE_THREAD\data\vReal.txt','w');
fileID2  = fopen('C:\Users\Anshu\Desktop\MTCS_MEX_SINGLE_THREAD\data\vImag.txt','w');
for i=1:NT
    for j=1:K(i)
        for k=1:Nob
            fprintf(fileID1,'%f\n',real(y{i}(j,k)));
            fprintf(fileID2,'%f\n',imag(y{i}(j,k)));
        end
    end
end
fclose(fileID1);
fclose(fileID2);

figure(2);
plot(cumsum(ML)+L0,'-o');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure(1);
% subplot(211);stem(w); title('Original');
% subplot(212); stem(sum(sum(abs(weightsM).^2,3),2)); title('M (to ARL)');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tstart=tic;
[ weightsARL,ML, L0 ] = callMTCS( A,y,a,b,K,NT,Nob,m,rc,eta,maxiter );
telapsed=toc(tstart);
fprintf('Time Spent for mex(ARL)  : %.6fs\n', telapsed);
 
%%
w=zeros(N,1);
for i=1:NT
    w=w+sum(abs(theta{i}).^2,2);
end

errors = sum(sum(abs(weightsARL).^2,3),2) - sum(sum(abs(weightsM).^2,3),2);

figure(1);
subplot(411);stem(w); title('Original');
subplot(412); stem(sum(sum(abs(weightsM).^2,3),2)); title('M (to ARL)');
subplot(413); stem(sum(sum(abs(weightsARL).^2,3),2)); title('Mex(ARL)');
subplot(414); stem(errors); ylim([-10 10]);title('error');

for g=1:length(errors)
    if (abs(errors(g)) > 1)
        fileID = fopen('errors.txt','a');
        fprintf(fileID,'error for %d\n',loops);
        fclose(fileID);
        break;
    end
end


end