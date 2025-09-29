function Out = Take_IQ_Derivative(In, Fs)
% Функция вычисляет производную сигнала при помощи преобразования ДПФ
%
% In - вектор-столбец с отсчётами сигнала;
% Fs - частота дискретизации сигнала;
%
% Out - вектор-столбец с отсчётами первой производной сигнала.


% fft 
    fftsamps = fftshift(fft(In));

% Ось частот
    L = length(fftsamps);
    if mod(L, 2) == 0
       f = (-L/2 : L/2-1)' * Fs / L;
    else
       f = (-L/2+0.5 : L/2-0.5)' * Fs / L;
    end

% Дифф-вание в частотной области
    fftdiff = fftsamps * 1j*2*pi .* f;

% ifft
    Out = ifft(ifftshift(fftdiff));
end
