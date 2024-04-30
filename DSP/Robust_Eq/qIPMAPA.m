function [ q,updateP ] = qIPMAPA( e,epsilon,delta,tau )
%qIPMAPA Function to compute the Q matrix using IPMAPA algorithm

eAbs = abs(e);

% Eq.(19)
if(eAbs>=0 && eAbs<epsilon)
    q = 1;
    updateP = 1;
elseif(eAbs>=epsilon && eAbs<delta)
    q=epsilon/eAbs;
    updateP = 1;
elseif(eAbs>=delta && eAbs<tau)
    q=epsilon*((eAbs-tau)/(delta-tau))*(1/eAbs);
    updateP = 1;
else
    q=0;
    updateP = 0;
end

end

