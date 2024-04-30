function res = and(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('and',x,y);
else
    res=bsxfun(@and,x,y);
end