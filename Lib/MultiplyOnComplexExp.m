function Out = MultiplyOnComplexExp(In, f, Fs)
%MULTIPLYONCOMPLEXEXP Умножение сигнала на комплексную экспоненту

Out = In .* exp(1j*2*pi*f * (cumsum(ones(size(In)))-1)/Fs);
