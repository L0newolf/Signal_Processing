function varargout = min(varargin)

if nargin==2
    [x,y]=deal(varargin{1:2});
    if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
        varargout{1}=builtin('min',x,y);
    else
        varargout{1}=bsxfun(@min,x,y);
    end
else
    if nargout==0
        out={[]};
    else
        out=cell(1,nargout,1);
    end
    [out{:}]=builtin('min',varargin{:});
    varargout=out; 
end