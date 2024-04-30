function res = eq(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('eq',x,y);
else
    res=bsxfun(@eq,x,y);
end