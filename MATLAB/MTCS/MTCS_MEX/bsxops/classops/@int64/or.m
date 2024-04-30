function res = or(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('or',x,y);
else
    res=bsxfun(@or,x,y);
end