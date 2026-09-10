function y = highpassFilter(x, f0, fs, Q)
% HIGHPASSFILTER Second-order digital high-pass filter.
%
% f0 = cutoff frequency in Hz
% fs = sampling frequency in Hz
% Q  = quality factor

if nargin < 4
    Q = 0.707;
end

x = x(:);

% Normalized angular frequency
w0 = 2*pi*f0/fs;

alpha = sin(w0)/(2*Q);
cosw0 = cos(w0);

% High-pass biquad coefficients
b0 = (1 + cosw0)/2;
b1 = -(1 + cosw0);
b2 = (1 + cosw0)/2;

a0 = 1 + alpha;
a1 = -2*cosw0;
a2 = 1 - alpha;

% Normalize coefficients
b = [b0 b1 b2] / a0;
a = [1 a1/a0 a2/a0];

% Apply filter
y = filter(b, a, x);

end