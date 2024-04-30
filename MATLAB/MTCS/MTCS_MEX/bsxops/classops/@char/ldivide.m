function res = ldivide(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('ldivide',x,y);
else
    res=bsxfun(@ldivide,x,y);
end