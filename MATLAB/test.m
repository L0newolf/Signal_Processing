clear all;

A = rand(1,1);

B = rand(8,10);

B(1,3) = A(1,1);
B(1,5) = A(1,1);
B(3,2) = A(1,1);

B(5,2) = A(1,1);
B(5,3) = A(1,1);
B(5,4) = A(1,1);

B(4,2) = A(1,1);
B(4,3) = A(1,1);
B(4,4) = A(1,1);

B(5,2) = A(1,1);



[C,which] = intersect(A,B);

[sortCom,sortIdx] = intersectFunc(A,B);

sortCom = sortCom';
sortIdx = sortIdx';

diffCom = C - sortCom;
diffIdx = which - sortIdx;