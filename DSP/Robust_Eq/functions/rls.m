
clear all
close all
hold off
% Number of system points
N=2000;

%inp = randn(N,1);
d = complex(randn(N,1),randn(N,1));

%channel system order (you can change the sysorder value and you don't need to change anything in the algorithm )
Lc = 10 ;

%add some noise
y = awgn(d,6,'measured') ;

%begin of the algorithm
%forgetting factor
lambdaEq = 0.9995 ;		
%initial P matrix
delta = 0.1 ;		 
P = delta * eye (Lc,'like',d ) ;
p = zeros ( Lc  , 1 ) ;

for i = Lc : N 
    
	curYEq = y(i:-1:i-Lc+1) ;
    curdEq = d(i:-1:i-Lc+1) ;
    
    dCap(i,1)=ctranspose(p) * curYEq;
    eqErr(i) = d(i) - dCap(i,1) ;
    
    phi = P*(curdEq) ;
	k = (phi)/(lambdaEq + ctranspose(curdEq)*P * curdEq );
	p = p + k * conj(eqErr(i)) ;
	P = ( P - k*ctranspose(curdEq)*P ) / lambdaEq ;
    
end 

e1 = d - dCap;

hold on
plot(abs(y),'g')
plot(abs(dCap),'r');
plot(abs(d),'b');
title('System output') ;
xlabel('Samples')
ylabel('True and estimated output')
legend('Tx Symbols d','Est Symbols y','unfiltered symbols inp');

figure
semilogy((abs(eqErr))) ;
hold on;
semilogy((abs(e1))) ;
hold off;
title('Error curve') ;
xlabel('Samples');
ylabel('Error value');
legend('e','e1');


