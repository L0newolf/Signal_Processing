function res = rdivide(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('rdivide',x,y);
else
    res=bsxfun(@rdivide,x,y);
end