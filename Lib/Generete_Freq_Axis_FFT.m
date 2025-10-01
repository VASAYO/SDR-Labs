function f = Generete_Freq_Axis_FFT(Length, Fs)

if mod(Length, 2) == 0
    f = (-Length/2 : Length/2-1)' / Length * Fs;
else
    f = (-Length/2+0.5 : Length/2-0.5)' / Length * Fs;
end
