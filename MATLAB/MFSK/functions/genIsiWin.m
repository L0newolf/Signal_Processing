function [ isiWin ] = genIsiWin( Fs,StopTime )

dt = 1/Fs;
divFact = 40;
isiWin = exp((Fs/divFact)*(StopTime-dt:-dt:0))';
isiWin=isiWin/max(isiWin);

i=1;
while (i<length(isiWin))
    skipNum = randi(divFact,1,1);
        for j=1:skipNum
            isiWin(i+j) = 0;
        end
    i=i+skipNum+1;
end


end

