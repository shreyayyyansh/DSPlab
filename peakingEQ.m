function [b, a] = peakingEQ(f0, Q, gainDB, fs)

A = 10^(gainDB / 40);    
w0 = 2 * pi * f0 / fs;   
alpha = sin(w0) / (2*Q);  

b = [1 + alpha*A,  -2*cos(w0),  1 - alpha*A];
a = [1 + alpha/A,  -2*cos(w0),  1 - alpha/A];

a0 = a(1);
b = b / a0;
a = a / a0;
end