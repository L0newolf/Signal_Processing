function res = times(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('times',x,y);
else
    res=bsxfun(@times,x,y);
end