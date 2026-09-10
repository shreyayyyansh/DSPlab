[x, fs] = audioread('test.wav'); x = mean(x,2);

% Adaptive bands within Nyquist limit
if fs <= 11025
    bands = [80 300 1000 2200 3600];
else
    bands = [60 250 1000 4000 12000];
end
gains = [0 -8 0 10 12]; % Distinct, audible gain shaping
Q = 0.9;                 % Broader bandwidth for clear acoustic impact

y = x; 
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
audiowrite('test_eq.wav', y, fs);
disp('Saved test_eq.wav with prominent equalizer response'); 
