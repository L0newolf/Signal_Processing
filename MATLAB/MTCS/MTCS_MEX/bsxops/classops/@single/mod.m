function res = mod(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('mod',x,y);
else
    res=bsxfun(@mod,x,y);
end