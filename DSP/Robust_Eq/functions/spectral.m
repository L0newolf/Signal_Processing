function [P, f, scale_f] = spectral(varargin)

%   Freq spectral estimate.
%   [Pxx, f, scale_f] = spectral(X,NFFT,Fs,WINDOW_type,dflag) estimates the Power
%   Spectral of a discrete-time signal vector X using fft
%
%   x-checked accurate to 0.5dB with SR760 fft analyser
%   for Hann, Uniform & Flattop windows; fs = 256000; nfft = 1024
%
%   X is divided into sections, each of which is detrended
%   (according to the detrending flag, if specified), then windowed by
%   the WINDOW parameter, window length is NFFT.
%
%   It can be further transformed into other estimates
%       amplitude spectrum = sqrt(Pxx)                  Unit(rms)
%       amplitude spectrum density = sqrt(Pxx/scale_f)  Unit(rms)/sqrt(Hz)
%       power spectrum = Pxx                            Unit(rms)^2
%       power spectrum density = Pxx/scale_f            Unit(rms)^2/Hz
%
%   The magnitude squared of the length NFFT DFTs of the sections are averaged to form
%   Pxx.  Pxx is length NFFT/2+1 for x of real number. WINDOW is windows type as in
%   'window' function, it take the lenght of the NFFT. Fs is the sampling
%   frequency which doesn't affect the spectrum estimate but is used
%   for scaling the X-axis of the plots.
%
%   Windows supported;
%   @blackman       - Blackman window.
%   @blackmanharris - Minimum 4-term Blackman-Harris window.
%   @flattopwin     - Flat Top window.
%   @hamming        - Hamming window.
%   @hann           - Hann window.
%   @rectwin        - Rectangular window.
%
%   Suggestion of windows use
%   sine or combination of sin -> Hann
%   sine (amplitude acc is very important) -> Flattop note: could shape the adj sig
%   Narrowband rand sig -> Hann
%   Broadband (white noise) -> Uniform
%   Closely spaced sine -> Uniform, Hamming
%   Unknown sig -> Hann
%
%   DFLAG can be 'linear', 'mean' ('constant') or 'none' by default
%   specifies a detrending mode for the prewindowed sections of X.
%
%   spectral with no output arguments plots the PSD in the current figure window,
%   with confidence intervals if you provide the P parameter.
%
%   The default values for the parameters are NFFT = 256 (or LENGTH(X),
%   whichever is smaller), NOVERLAP = 0, WINDOW = HANNING(NFFT), Fs = 2.
%
%   Author:
%       Koay Teong Beng, Tan Eng Teck
%   Reference
%   (1) The fundamentals of fft-based signal Analysis & measurement (NI AppNote 041)
% spectral3 updates:
%       (1) Took care of odd even nfft numbers
%       (2) Minor bug fixes on the folding of fft estimates to single sided
%           to exclude bins that fall exactly on nyquist
%       (3) Changed the coherent gain calculation method to mean(wind)
%
% $Revision: 1.2 $


error(nargchk(1,5,nargin))
x = varargin{1};
[msg,nfft,fs,win,noverlap,Coherent_gain,nPow_BW,dflag] = simp_chk(varargin(2:end),x);
error(msg)

% % Scaling factor, uniform = 1, hann = 0.5, hamming = 0.54, Flat Top = 0.22
% % Blackman_Harris = 0.42, Exact Blackman = 0.43, Blackman = 0.42
% Coherent_gain = 0.5;
% % noise power BW, uniform = 1, hann = 1.5, hamming = 1.36, Flat Top = 3.77
% % Blackman_Harris = 1.71, Exact Blackman = 1.69, Blackman = 1.73
% nPow_BW = 1.5;


x = x(:);

win_length = length(win);
index = 1:win_length;
Plength = floor(nfft/2)+1;
Pxx = zeros(Plength,1);
k = floor((length(x)-noverlap)/(length(win)-noverlap)); % Number of windows
% same as floor(length(x)/length(win)) when noverlap =0
for i = 1:k
    if strcmp(dflag,'none')
        xnw = win.*x(index);
    else
        xnw = win.*detrend(x(index),dflag);
    end
    index = index + win_length;     % work on next window
    mfft = fft(xnw,nfft);       % in complex plane
    % Double sided Power spectrum unit(rms)^2 de-normalised from nfft points and corrected
    % for coherent gain (amplitude changes) due to windowing
    mPxx = mfft.*conj(mfft)/(nfft*Coherent_gain)^2;  % same as (abs(mfft)/(nfft*Coherent_gain))^2
    Pxx = Pxx + mPxx(1:Plength);
end
Pxx = Pxx/k;        % divided for average values

%Pxx(1) = Pxx(1);   % preserve the dc (it is real number)
if mod(nfft,2) == 0
    Pxx(2:nfft/2) = Pxx(2:nfft/2)*2;        % Single sided Power spectrum unit(rms)^2
    %Pxx(nfft/2+1) = Pxx(nfft/2+1); %the last bin is exactly at Nyquist, real number also don't have to multiply
else
    Pxx(2:(nfft+1)/2) = Pxx(2:(nfft+1)/2)*2;    % Single sided Power spectrum unit(rms)^2
end
F = (0:length(Pxx)-1)'*(fs/nfft);

% Pxx_psd = Pxx/((fs/nfft)*nPow_BW);          % Power Spectrum density unit(rms)^2/Hz
%
% Axx = sqrt(Pxx);                            % Amplitude Spectrum unit(rms)
% Axx_asd = Axx/sqrt((fs/nfft)*nPow_BW);      % Amplitude Spectrum density unit(rms)/sqrt(Hz)

%
% setup output data
if nargout == 0
    Pyy = 10*log10(Pxx);                         % plot spectrum
    %Pyy_psd = 10*log10(Pxx_psd);                % spectrum density
    %figure(3);
    % plot(mPxx(1:nfft/2+1)/(Fs/nfft));
    
    % --- modified by mandar ---
    plot(F,Pyy-10*log10((fs/nfft)*nPow_BW));
    grid on
    if fs == 2
        xlabel('Normalized Frequency');
    else
        xlabel('Frequency (Hz)');
    end
    ylabel('Power Spectral Density (dB/Hz)');
    % --- end modification ---
    
elseif nargout == 1
    P = Pxx;
elseif nargout == 2
    P = Pxx;
    f = F;
else
    P = Pxx;
    f = F;
    scale_f = (fs/nfft)*nPow_BW;           % (fs/nfft) is freq estimates bin width while nPow_BW is noise power BW factor
end



function [msg,nfft,Fs,wind,noverlap,Coherent_gain,nPow_BW,dflag] = simp_chk(P,x)
% helper function
%   expecting simp_chk({NFFT,Fs,WINDOW_type,dflag},x)

msg = [];

if length(P) == 0
    % psd(x)
    % degault values
    nfft = min(length(x),256);
    Fs = 2;
    wind = hanning(nfft);
    noverlap = 0;
    nPow_BW = 1.5;
    Coherent_gain = 0.5;
    dflag = 'none';
elseif length(P) == 1
    % psd(x,nfft)
    nfft = min(length(x),P{1});
    Fs = 2;
    wind = hanning(nfft);
    noverlap = 0;
    nPow_BW = 1.5;
    Coherent_gain = 0.5;
    dflag = 'none';
elseif length(P) == 2
    %spectral(x,nfft,fs)
    nfft = min(length(x),P{1});
    Fs = P{2};
    wind = hanning(nfft);
    noverlap = 0;
    nPow_BW = 1.5;
    Coherent_gain = 0.5;
    dflag = 'none';
else
    %spectral(x,nfft,fs,@win)
    %spectral(x,nfft,fs,@win,dflag)
    nfft = min(length(x),P{1});
    Fs = P{2};
    noverlap = 0;
    switch lower(P{3})
        case '@blackman'
            nPow_BW = 1.73;
%             Coherent_gain = 0.42;
        case '@blackmanharris'
            nPow_BW = 1.71;
%             Coherent_gain = 0.42;
        case '@flattopwin'
            nPow_BW = 3.77;
%             Coherent_gain = 0.22;
        case '@hamming'
            nPow_BW = 1.36;
%             Coherent_gain = 0.54;
        case '@hann'
            nPow_BW = 1.5;
%             Coherent_gain = 0.5;
        case '@rectwin'
            nPow_BW = 1;
%             Coherent_gain = 1;
        otherwise
            % hanning
            nPow_BW = 1.5;
%             Coherent_gain = 0.5;
            P{3} = '@hann';
    end
    eval(['wind = feval(' P{3} ',nfft);']);
    Coherent_gain=mean(wind); % to get exact value of coherent gain as there
                              % could be some small variation with window
                              % length
    if length(P) == 4
        dflag = P{4};
    else
        dflag = 'none';
    end
end

% NOW do error checking
if (nfft<length(wind)),
    msg = 'Requires window''s length to be no greater than the FFT length.';
end
if (noverlap >= length(wind)),
    msg = 'Requires NOVERLAP to be strictly less than the window length.';
end
if (nfft ~= abs(round(nfft)))|(noverlap ~= abs(round(noverlap))),
    msg = 'Requires positive integer values for NFFT and NOVERLAP.';
end
% if ~isempty(p),
%     if (prod(size(p))>1)|(p(1,1)>1)|(p(1,1)<0),
%         msg = 'Requires confidence parameter to be a scalar between 0 and 1.';
%     end
% end
if length(x)<=1
    msg = 'Input data must be a vector, not a scalar.';
    x = [];
elseif min(size(x))~=1 | ~isnumeric(x) | length(size(x))>2
    msg = 'Requires vector (either row or column) input.';
end
% if (nargin>2) & ( (min(size(y))~=1) | ~isnumeric(y) | length(size(y))>2 )
%     msg = 'Requires vector (either row or column) input.';
% end
% if (nargin>2) & (length(x)~=length(y))
%     msg = 'Requires X and Y be the same length.';
% end

dflag = lower(dflag);
if strncmp(dflag,'none',1)
    dflag = 'none';
elseif strncmp(dflag,'linear',1)
    dflag = 'linear';
elseif strncmp(dflag,'mean',1)
    dflag = 'constant';  %'mean';
else
    dflag = 'constant';     % mean
    %    msg = 'DFLAG must be ''linear'', ''mean'', or ''none''.';
end
 