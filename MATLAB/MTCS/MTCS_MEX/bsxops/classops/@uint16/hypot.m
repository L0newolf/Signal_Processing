function res = hypot(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('hypot',x,y);
else
    res=bsxfun(@hypot,x,y);
end