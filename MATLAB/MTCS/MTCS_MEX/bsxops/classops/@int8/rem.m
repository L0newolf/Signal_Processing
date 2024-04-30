function res = rem(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('rem',x,y);
else
    res=bsxfun(@rem,x,y);
end