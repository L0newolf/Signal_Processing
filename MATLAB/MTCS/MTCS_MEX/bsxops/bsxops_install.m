function bsxops_install
% function bsxops_install
% PURPOSE: Installation package bsxops
%
% Author: Bruno Luong <brunoluong@yahoo.com>
% Last update: 18/April/2009

bsxopsroot=fileparts(mfilename('fullpath'));
addpath(bsxopsroot);
savepath;
bsxops(0);

end
