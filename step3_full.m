[x, fs] = audioread('test.wav'); x = mean(x,2);

useDenoise = true; 
useNotch = true; 
notchFreq = 50; 

bands = [60 250 1000 4000 12000];
gains = [ 0 -3 0 5 6 ];
Q = 1.4;

y = x;
if useDenoise, y = spectralDenoise(y, fs, 0.5); end 
if useNotch, y = notchFilter(y, notchFreq, fs, 30); end 

for k = 1:numel(bands) 
    [b, a] = peakingEQ(bands(k), Q, gains(k), fs);
    y = filter(b, a, y);
end

y = y / max(abs(y) + eps);
sound(y, fs);
audiowrite('test_clean.wav', y, fs);
disp('Done. Saved test_clean.wav');