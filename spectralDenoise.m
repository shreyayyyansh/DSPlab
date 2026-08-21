// Denoise 
function y = spectralDenoise(x, fs, noiseSeconds)

if nargin < 3, noiseSeconds = 0.5; end 
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
    clean = max(mag - NF, 0.05*mag); 
    rec = real(ifft(clean .* exp(1i*ph)));
    y(s:s+win-1) = y(s:s+win-1) + rec; 
end
y = y(1:numel(x));
y = y / max(abs(y) + eps); 
end