function res = gt(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('gt',x,y);
else
    res=bsxfun(@gt,x,y);
end