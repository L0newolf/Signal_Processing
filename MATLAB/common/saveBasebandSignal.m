% SAVEBASEBANDSIGNAL Save baseband complex signal for txsig transmission
%
% saveBasebandSignal(filename, x, p)
%   filename is the name of the saved text file
%   x is the complex baseband signal to transmit
%   p true to generate a scheme 3 preamble (optional)
%
% Author: Mandar Chitre

function saveBasebandSignal(filename, x, p)

if nargin < 3
  p = false;
end

%% settings
fc = 25500;
bw = 0.8;
prelen = 768;
pregap = 32;
win = 0.02;

%% derived useful quantities
fd = 2/3*fc;

%% generate m-sequence
probe = mseq(2, 13, 1, 1);
probe = resample(probe, fd, fd*bw);
probe = probe/max(abs(probe));
probe = 32767*probe + 32767i*probe;
probe = round(tukeywin(length(probe), win) .* probe);

%% generate preamble
c = pi * bw;
t = (0:prelen-1)';
a = c * t.*(1-t/prelen/2);
pre = 32767*cos(a) + 32767i*cos(a);
pre = round(tukeywin(length(pre), win) .* pre);

%% scale the signal
x = x(:);
s = max([real(x); imag(x)]);
x = 32767*x/s;

%% combine preamble + signal
if p
  x = [pre; zeros(pregap,1); x];
end

%% encode the signal
x = [round(real(x)) round(imag(x))]';
f = fopen(filename,'wt');
fprintf(f, '%i\n', x(:));
fclose(f);