function [ y ] = upsampleAndHold( x,olfFs,newFs )

[r] = length(x);
factor = newFs/olfFs;
y = zeros(1,floor(factor*r));

count=1;
for i=1:r
    y(count) = x(i);
    y(count+1) = x(i);
    count = count+2;
end

end

