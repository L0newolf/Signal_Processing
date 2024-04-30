function res = power(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('power',x,y);
else
    res=bsxfun(@power,x,y);
end