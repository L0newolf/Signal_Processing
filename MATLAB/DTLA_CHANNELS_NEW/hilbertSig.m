function [x] = hilbertSig(xr,len)
% Computes analytic signal

h  = zeros(len,1);
xi = zeros(len,1);

x = fft(xr,len);

if (mod(len,2)==0)
  % even and nonempty
  h(1) = 1;
  h(len/2+1)= 1;
  for i=2:len/2
      h(i) = 2;
  end

else 
  % odd and nonempty
  h(1) = 1;
  for i=2:(len+1)/2
      h(i) = 2;
  end

end

for i=1:len
    xi(i) = x(i)*h(i,1);
end

x=ifft(xi);

end
