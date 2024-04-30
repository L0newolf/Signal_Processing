function [bfo,angles] = beamform(data,Fs,freq,type)

%% defaults
if nargin < 4
  type = 'conven';
end

%% settings
spacing = 0.65;   % m   (spacing between sensors)
slew = 1.58e-6;   % s   (slew per channel)
c = 1500;         % m/s (sound speed, nominal)

%% filter data
guard = freq/5;
Hb = fir1(128,[freq-guard freq+guard]/(Fs/2));

N = size(data,2);
for j = 1:N
  data(:,j) = filtfilt(Hb,1,data(:,j));
end

%% normalize and make complex baseband (for narrowband processing)
%scale = max(data,[],1);
scale = sqrt(mean(data.^2,1));
scale(scale == 0) = 1;
for j = 1:N
  data(:,j) = hilbert(data(:,j)/scale(j));
  data(:,j) = data(:,j) .* exp(-2i*pi*freq*(1:size(data,1))'/Fs);
  data(:,j) = data(:,j) * exp(-2i*pi*slew*(j-1)*freq);
end

%% narrowband beamforming
angles = deg2rad(-90:90);
bfo = zeros(size(data,1),length(angles));
if strcmp(type,'mvdr')
  R = cov(data);
  Rinv = inv(R);
end
for a = 1:length(angles)
  d = exp(2i*pi*freq*spacing*(0:N-1)'/c*sin(angles(a)));
  if strcmp(type,'mvdr')
    w = Rinv*d/(d'*Rinv*d);
  else
    w = d;
  end
  for j = 1:N
    bfo(:,a) = bfo(:,a) + conj(w(j)) * data(:,j);
  end
end
