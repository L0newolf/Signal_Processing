function [ pdrVal ] = getPDR( ber )

len = length(ber);

for i=1:len
    if (ber(i) == 0.0 )
        pdrVal(i) = 9;
    elseif (ber(i) < 0.001)
        pdrVal(i) = 8;
    elseif (ber(i) > 0.001 && ber(i) < 0.005)
        pdrVal(i) = 7;
    elseif (ber(i) > 0.005 && ber(i) < 0.01)
        pdrVal(i) = 6;
    elseif (ber(i) > 0.01 && ber(i) < 0.015)
        pdrVal(i) = 5;
    else
        pdrVal(i) = 0;
    end
end

end

