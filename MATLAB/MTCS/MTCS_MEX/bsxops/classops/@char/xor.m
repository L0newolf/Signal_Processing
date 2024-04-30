function res = xor(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('xor',x,y);
else
    res=bsxfun(@xor,x,y);
end