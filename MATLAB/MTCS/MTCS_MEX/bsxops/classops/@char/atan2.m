function res = atan2(x,y)

if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
    res=builtin('atan2',x,y);
else
    res=bsxfun(@atan2,x,y);
end