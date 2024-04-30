classdef bsxdouble < double
    methods
        
        % Constructor
        function obj = bsxdouble(data)
            if nargin == 0
                data = [];
            end
            obj = obj@double(data);
        end
      
        function res = and(x,y)
            x = double(x);
            y = double(y);
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('and',x,y);
            else
                res=bsxfun(@and,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = atan2(x,y)
            x = double(x);
            y = double(y);           
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('atan2',x,y);
            else
                res=bsxfun(@atan2,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = eq(x,y)
            x = double(x);
            y = double(y);             
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('eq',x,y);
            else
                res=bsxfun(@eq,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = ge(x,y)
            x = double(x);
            y = double(y);            
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('ge',x,y);
            else
                res=bsxfun(@ge,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = gt(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('gt',x,y);
            else
                res=bsxfun(@gt,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = hypot(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('hypot',x,y);
            else
                res=bsxfun(@hypot,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = ldivide(x,y)
            x = double(x);
            y = double(y);  
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('ldivide',x,y);
            else
                res=bsxfun(@ldivide,x,y);
            end
            res = bsxdouble(res);
        end
        
        function varargout = max(varargin)
            
            if nargin==2
                x = double(varargin{1});
                y = double(varargin{2});
                if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                    varargout{1}=builtin('max',x,y);
                else
                    varargout{1}=bsxfun(@max,x,y);
                end
            else
                varargin{1} = double(varargin{1});
                if nargout==0
                    out={[]};
                else
                    out=cell(1,nargout,1);
                end
                [out{:}]=builtin('max',varargin{:});
                varargout=out;
            end
            varargout{1} = bsxdouble(varargout{1});
        end
        
        function varargout = min(varargin)
            
            if nargin==2
                x = double(varargin{1});
                y = double(varargin{2});
                if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                    varargout{1}=builtin('min',x,y);
                else
                    varargout{1}=bsxfun(@min,x,y);
                end
            else
                varargin{1} = double(varargin{1});
                if nargout==0
                    out={[]};
                else
                    out=cell(1,nargout,1);
                end
                [out{:}]=builtin('min',varargin{:});
                varargout=out;
            end
            varargout{1} = bsxdouble(varargout{1});
        end
        
        function res = minus(x,y)
            x = double(x);
            y = double(y);            
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('minus',x,y);
            else
                res=bsxfun(@minus,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = mod(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('mod',x,y);
            else
                res=bsxfun(@mod,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = ne(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('ne',x,y);
            else
                res=bsxfun(@ne,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = or(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('or',x,y);
            else
                res=bsxfun(@or,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = plus(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('plus',x,y);
            else
                res=bsxfun(@plus,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = power(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('power',x,y);
            else
                res=bsxfun(@power,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = rdivide(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('rdivide',x,y);
            else
                res=bsxfun(@rdivide,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = rem(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('rem',x,y);
            else
                res=bsxfun(@rem,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = times(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('times',x,y);
            else
                res=bsxfun(@times,x,y);
            end
            res = bsxdouble(res);
        end
        
        function res = xor(x,y)
            x = double(x);
            y = double(y); 
            if isequal(size(x),size(y)) || isscalar(x) || isscalar(y)
                res=builtin('xor',x,y);
            else
                res=bsxfun(@xor,x,y);
            end
            res = bsxdouble(res);
        end
    end
end
