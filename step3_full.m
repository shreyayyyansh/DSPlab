[x, fs] = audioread('test.wav'); x = mean(x,2);

useDenoise = true; 
useNotch = true; 
notchFreq = 50; 

% Adaptive bands within Nyquist limit
if fs <= 11025
    bands = [80 300 1000 2200 3600];
else
    bands = [60 250 1000 4000 12000];
end
gains = [0 -8 0 10 12];
Q = 0.9;

y = x;
if useDenoise, y = spectralDenoise(y, fs, 0.5, 1.8, 0.01); end 
if useNotch
    y = notchfilter(y, notchFreq, fs, 30);      % 50 Hz Hum
    if fs > 250
        y = notchfilter(y, 2*notchFreq, fs, 30); % 100 Hz Harmonic Buzz
    end
end 

for k = 1:numel(bands) 
    if bands(k) < (fs/2)
        [b, a] = peakingEQ(bands(k), Q, gains(k), fs);
        y = filter(b, a, y);
    end
end

% Smart Limiter
peakVal = max(abs(y));
if peakVal > 0.98, y = y / peakVal * 0.98; end

sound(y, fs);
audiowrite('test_clean.wav', y, fs);
disp('Done. Saved test_clean.wav with active denoising, notch hum removal, and 5-band EQ');