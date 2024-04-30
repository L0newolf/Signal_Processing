function [p,response]=srrc(os_froll_offctor,roll_off,lenFractor)

t=-(lenFractor/2):1/os_froll_offctor:(lenFractor/2);

p=zeros(1,length(t));
    for i=1:1:length(t)
        if t(i)==0
            p(i)= (1-roll_off)+4*roll_off/pi;
        else if t(i)==1/(4*roll_off) || t(i)==-1/(4*roll_off)
               p(i)=roll_off/sqrt(2)*((1+2/pi)*sin(pi/(4*roll_off))+(1-2/pi)*cos(pi/(4*roll_off)));
              else
                p(i) = (sin(pi*t(i)*(1-roll_off))+4*roll_off*t(i)*cos(pi*t(i)*(1+roll_off)))/(pi*t(i)*(1-(4*roll_off*t(i))^2));
             end
        end
        
    end
    response=(p/max(p)); 
end