function sf = myFilter (B,A,s)

na = length(A);
nb = length(B);
NZeros = max(na,nb)-1;
sf = zeros(1,NZeros+length(s));
s0 = [zeros(1,NZeros) s];
M1 = fliplr(B/A(1));
M2 = fliplr(A(2:na)/A(1));
for i = NZeros+1:length(s0)
    sf(i) = M1*s0(i-nb+1:i)'-M2*sf(i-na+1:i-1)';
end
sf = sf(NZeros+1:end);