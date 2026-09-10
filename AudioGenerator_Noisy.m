% AudioGenerator_Noisy.m
% Generates a realistic noisy audio sample with:
% 1. Initial 0.5s noise-only profile (for spectralDenoise training)
% 2. Noticeable 50 Hz electrical hum
% 3. Noticeable white noise hiss
% 4. Handel chorus melody at 16000 Hz sampling rate (wider bandwidth)

disp('Generating realistic noisy audio...');

% 1. Load Handel demo audio
load handel; % provides y and Fs (8192 Hz)

% Resample to 16000 Hz for better frequency response (up to 8 kHz Nyquist)
targetFs = 16000;
y_resamp = resample(y, targetFs, Fs);
Fs = targetFs;

% 2. Add 0.6 seconds of silence/background room noise at the beginning
% This allows spectralDenoise to sample pure noise without eating the music!
silenceSamples = round(0.6 * Fs);
y_padded = [zeros(silenceSamples, 1); y_resamp];

% Time vector
t = (0:length(y_padded)-1)' / Fs;

% 3. Add realistic 50 Hz power hum (and 100 Hz harmonic)
hum = 0.08 * sin(2 * pi * 50 * t) + 0.03 * sin(2 * pi * 100 * t);

% 4. Add background white noise (hiss)
whiteNoise = 0.025 * randn(size(y_padded));

% 5. Mix components together
y_noisy = y_padded + hum + whiteNoise;

% Normalize to prevent digital clipping
y_noisy = y_noisy / max(abs(y_noisy) + eps) * 0.95;

% Save to test_noisy.wav and overwrite test.wav for immediate demo
audiowrite('test_noisy.wav', y_noisy, Fs);
audiowrite('test.wav', y_noisy, Fs);

fprintf('Created test_noisy.wav and updated test.wav (%d Hz, %.1f seconds)\n', Fs, length(y_noisy)/Fs);
fprintf('Contains: 0.6s noise-only leader + 50Hz mains hum + background hiss.\n');
