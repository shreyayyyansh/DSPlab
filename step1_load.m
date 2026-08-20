% step1_load.m 
[x, fs] = audioread('test.wav');   

if size(x, 2) > 1                  
    x = mean(x, 2);               
end

fprintf('Loaded %d samples at %d Hz (%.1f seconds)\n', ...
        numel(x), fs, numel(x)/fs);

sound(x, fs);                      