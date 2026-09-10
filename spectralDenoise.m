% Spectral Denoise (STFT Spectral Subtraction with Over-subtraction & Floor)
function y = spectralDenoise(x, fs, noiseSeconds, alpha, beta)

if nargin < 3, noiseSeconds = 0.5; end 
if nargin < 4, alpha = 1.8; end   % Over-subtraction factor (1.0 = standard, 2.0+ = aggressive)
if nargin < 5, beta = 0.01; end   % Spectral floor (prevents musical noise artifacts)
x = x(:); 

win = 1024; 
hop = win/2; 
w = hann(win); 

nNoise = max(1, floor(noiseSeconds*fs));
noise = x(1:min(nNoise, numel(x)));
NF = zeros(win,1); cnt = 0;
for s = 1:hop:(numel(noise)-win)
    seg = noise(s:s+win-1) .* w;
    NF = NF + abs(fft(seg));
    cnt = cnt + 1;
end
if cnt > 0, NF = NF / cnt; end 

y = zeros(numel(x)+win, 1);
for s = 1:hop:(numel(x)-win)
    seg = x(s:s+win-1) .* w;
    S = fft(seg);
    mag = abs(S); ph = angle(S);
    clean = max(mag - alpha * NF, beta * mag); 
    rec = real(ifft(clean .* exp(1i*ph)));
    y(s:s+win-1) = y(s:s+win-1) + rec; 
end
y = y(1:numel(x));

% Smart anti-clipping limiter (avoids amplifying silence/cuts back to 1.0)
peakVal = max(abs(y));
if peakVal > 0.95
    y = y / peakVal * 0.95;
end
end