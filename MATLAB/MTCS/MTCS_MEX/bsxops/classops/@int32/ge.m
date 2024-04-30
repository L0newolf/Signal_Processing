function res = ge(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('ge',x,y);
else
    res=bsxfun(@ge,x,y);
end