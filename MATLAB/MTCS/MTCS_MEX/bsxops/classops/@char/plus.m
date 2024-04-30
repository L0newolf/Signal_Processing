function res = plus(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('plus',x,y);
else
    res=bsxfun(@plus,x,y);
end