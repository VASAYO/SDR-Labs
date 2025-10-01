function [SpdEst, FreqVector] = GetSPDEstFun(Signal, SampFreq, WelchSize)
% Функция оценки СПСМ методом Уэлча
% 
% Входные параметры:
%   * Signal - вектор-столбец сигнала
%   * SampFreq - частота дискретизации сигнала
%   * WelchSize - длина кадра, на которые будет разбиваться сигнал
%
% Выходные параметры: Вектор значений оценки СПСМ сигнала SpdEst и вектор
% соответствующих частот FreqVector. SpdEst нормирован таким образом, чтобы
% сумма всех значений была равна средней мощности сигнала

    % Проверка ввода длины кадра сигнала
        if nargin <= 2
            if length(Signal) >= 1e4
                WelchSize = 1e4;
            else
                WelchSize = length(Signal);
            end
        end

    % Проверка значения welch_size
        if mod(WelchSize, 2) ~= 0
            WelchSize = WelchSize + 1;
            warning(['(Welch_estimate) Значение welch_size ', ...
                'изменено: %d --> %d'], WelchSize-1, WelchSize);
        end

    % Отбрасывание отсчётов в конце сигнала
        buf_sig = Signal(1:end - mod(length(Signal), WelchSize));
    % Дробление сигнала на кадры длиной welch_size/2
        sigChunked = reshape(buf_sig, WelchSize/2, []);
    % Формирование отрезков с перекрытием 50 %
        segments = [sigChunked(:, 1:end-1);...
                    sigChunked(:, 2:end)];
    % Оконное взвешивание (Hamming)
        segmentsHamm = segments .* repmat(hamming(WelchSize), 1,...
            size(segments, 2));
    % Вычисление ДПФ каждого сегмента
        fftData = fftshift(fft(segmentsHamm));
    % СМП сегментов
        segmentsSPD = abs(fftData).^2 / WelchSize;
    % Усреднение сегментов с нормировкой на энергию окна
        SpdEst = mean(segmentsSPD, 2) / sum(hamming(WelchSize).^2);
    % Ось частот
        L = length(SpdEst);
        if mod(L, 2) == 0
           FreqVector = (-L/2 : L/2-1) * SampFreq / L;
        else
           FreqVector = (-L/2+0.5 : L/2-0.5) * SampFreq / L;
        end
end