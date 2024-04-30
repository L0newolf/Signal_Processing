function varargout = max(varargin)

if nargin==2
    [x,y]=deal(varargin{1:2});
    if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
        varargout{1}=builtin('max',x,y);
    else
        varargout{1}=bsxfun(@max,x,y);
    end
else
    if nargout==0
        out={[]};
    else
        out=cell(1,nargout,1);
    end
    [out{:}]=builtin('max',varargin{:});
    varargout=out; 
end