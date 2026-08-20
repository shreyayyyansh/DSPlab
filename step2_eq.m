[x, fs] = audioread('test.wav'); x = mean(x,2);

bands = [60 250 1000 4000 12000];
gains = [ 0 -3 0 5 6 ]; 
Q = 1.4; 

y = x; 
for k = 1:numel(bands)
    [b, a] = peakingEQ(bands(k), Q, gains(k), fs);
    y = filter(b, a, y); 
end 

y = y / max(abs(y) + eps); 
sound(y, fs);
audiowrite('test_eq.wav', y, fs); 