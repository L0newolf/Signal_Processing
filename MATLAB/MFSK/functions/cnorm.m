% CNORM Element-wise complex p-norm
%
% y = cnorm(x, p)
%
% Author: Mandar Chitre
% Last modified: Sep 12, 2015

function y = cnorm(x, p)

y = (abs(real(x)).^p + abs(imag(x)).^p).^(1/p);