function [ effDataRate ] = getEffDataRate( dataRate,ber )

len = length(ber);

for i=1:len
    if (ber(i) == 0.0 )
        codeRate = 1;
    elseif (ber(i) < 0.01)
        codeRate = 1/2;
    elseif (ber(i) > 0.01 && ber(i) < 0.11)
        codeRate = 1/3;
    elseif (ber(i) > 0.11 && ber(i) < 0.16)
        codeRate = 1/6;
    else
        codeRate = 0;
    end
    
    effDataRate(i) = floor(codeRate * dataRate);
end

end

