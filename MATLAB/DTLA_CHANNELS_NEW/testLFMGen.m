function testLFMGen

%% fixed settings
fc = 8000;
fd = 2/3*fc;
fs = 4*fc;

%% variable settings
bw = 75;
len = 70;

%% LFM up-sweep, down-sweep, cross-sweep
%t = 0:len-1;
%x1 = mkint16(exp(1i*pi*bw*(t/len-1).*t));
%x2 = mkint16(exp(1i*pi*bw*(1-t/len).*t));
%x3 = mkint16(exp(1i*pi*bw*(t/len-1).*t)+exp(1i*pi*bw*(1-t/len).*t));

%% create correaltors
x1 = mkLFM(1,bw,len);
% x2 = mkLFM(2,bw,len);
% x3 = mkLFM(3,bw,len);
% x4 = mkLFM(4,bw,len);
% x5 = mkLFM(5,bw,len);
% x6 = mkLFM(6,bw,len);

%% display
figure(1), show(x1);
% figure(2), show(x2);
% figure(3), show(x3);
% figure(4), show(x4);
% figure(5), show(x5);
% figure(6), show(x6);

%% helpers

  function show(x)
    y = resample(x,fs,fd);
    y = real(y.*exp(2i*pi*fc*(0:length(y)-1)/fs));
    figure();
    [y1,f,t,p] = spectrogram(y,128,120,128,fs,'yaxis');
    surf(t,f,10*log10(abs(p)),'EdgeColor','none');
    axis xy; axis tight; colormap(jet); view(0,90);
    xlabel('Time');
    ylabel('Frequency (Hz)');
    figure();
    plot(y);
  end

  %function x = mkint16(x)
  %  mx1 = max(abs(real(x)));
  %  mx2 = max(abs(imag(x)));
  %  mx = max(mx1,mx2);
  %  mx
  %  x = round(32767*real(x)/mx) + 1i*round(32767*imag(x)/mx);
  %end

  function corrBuf = mkLFM(corrType, corrBW, corrLen)
    c = pi * corrBW/100;
    t = 0:corrLen-1;
    if corrType == 1
      a = c * t.*(1-t/corrLen);
      corrBuf = 32767*cos(a) + 32767i*sin(a);
    elseif corrType == 2
      a = c * t.*(1-t/corrLen);
      corrBuf = 32767*cos(a) - 32767i*sin(a);
    elseif corrType == 3
      a = c * t.*(1-t/corrLen);
      corrBuf = 32767*cos(a) + 32767i*cos(a);
    elseif corrType == 4
      a = c * t.*(1-t/corrLen/2);
      corrBuf = 32767*cos(a) + 32767i*cos(a);
    elseif corrType == 5
      a = c * t.*(t/corrLen/2);
      corrBuf = 32767*cos(a) + 32767i*cos(a);
    elseif corrType == 6
      a = c * t.*(1-t/corrLen/2);
      corrBuf = 16383*cos(a) + 16383i*cos(a);
      a = c * t.*(t/corrLen/2);
      corrBuf = corrBuf + 16383*cos(a) + 16383i*cos(a);
    else
      error('Unknown correlator type');
    end
  end

end