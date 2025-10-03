function Out = Bandpass_FFT_Filter(In, Fs, CentralF, BW)

fft_tmp = fftshift(fft(In));
f = Generete_Freq_Axis_FFT(length(fft_tmp), Fs);
fft_tmp(abs(f - CentralF) > BW/2 & abs(f + CentralF) > BW/2) = 0;

Out = ifft(ifftshift(fft_tmp));
