function res = minus(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('minus',x,y);
else
    res=bsxfun(@minus,x,y);
end