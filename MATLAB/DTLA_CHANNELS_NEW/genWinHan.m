function [ win ] = genWinHan( len )
%genWinHan Generate a hanning window of length len

halfLen = len/2;
for i=1:halfLen
    val = .5*(1 - cos(2*pi*(i)/(len+1))); 
    win(i,1)= val;
    win(len-i+1,1) = val;
end

end

