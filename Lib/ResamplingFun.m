function OutData = ResamplingFun(InData, SampFreq, NewSampFreq)
% Функция, содержащая процесс передискретизации сигнала

    % Длина исходного сигнала
        inLen = length(InData);
    % Длина передискретизированного сигнала
        outLen = round(inLen * (NewSampFreq / SampFreq));
    % Сравнение начальной и конечной длин сигнала
    if outLen >= inLen
        % Определение N и M
            M = outLen;
            N = inLen;
        % ДПФ исходного сигнала
            buf_fft = fft(InData);
        % Инициализация ДПФ нового сигнала
            out_fft = zeros(M, 1);
        % Дополнение ДПФ нулями
            if mod(N, 2) == 0
                out_fft(1:N/2) = buf_fft(1:N/2);
                out_fft(N/2+1) = buf_fft(N/2+1)/2;
                out_fft(N/2+2 : N/2+M-N) = 0;
                out_fft(N/2+M-N+1) = buf_fft(N/2+1)/2;
                out_fft(N/2+M-N+2 : M) = buf_fft(N/2+2 : N);
            else
                out_fft(1:(N+1)/2) = buf_fft(1:(N+1)/2);
                out_fft((N+1)/2+1 : (N+1)/2+M-N) = 0;
                out_fft((N+1)/2+M-N+1 : M) = ...
                    buf_fft((N+1)/2+1 : N);
            end
        % ОДПФ нового сигнала с нормировкой
            OutData = ifft(out_fft) * (M/N);

    elseif outLen < inLen
        % Определение N и M
            M = inLen;
            N = outLen;
        % ДПФ исходного сигнала
            buf_fft = fft(InData);
        % Инициализация ДПФ нового сигнала
            out_fft = zeros(N, 1);
        % Отбрасывание отсчётов ДПФ
            if mod(N, 2) == 0
                out_fft(1:N/2) = buf_fft(1:N/2);
                out_fft(N/2+1) = 2*buf_fft(N/2+1);
                out_fft(N/2+2:N) = buf_fft(N/2+M-N+2:M);
            else
                out_fft(1:(N+1)/2) = buf_fft(1:(N+1)/2);
                out_fft((N+1)/2+1:N) = buf_fft((N+1)/2-N+M+1:M);
            end
        % ОДПФ нового сигнала с нормировкой
            OutData = ifft(out_fft);
        % Нормировка по мощности
            OutData = OutData * (N/M);
        % Исправление ошибок, если сигнал должен быть
        % действительный
            if isreal(InData)
                OutData = real(OutData);
            end
    end
end