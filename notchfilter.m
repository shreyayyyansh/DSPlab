function y = notchfilter(x, f0, fs, Q)

w0 = 2*pi*f0/fs;
alpha = sin(w0)/(2*Q);

b = [1, -2*cos(w0), 1]; 
a = [1+alpha, -2*cos(w0), 1-alpha];

b = b / a(1); a = a / a(1);
y = filter(b, a, x);
end