% Исследование корреляционных свойств м-последовательности
    clc; clear;
    close all;

% Параметры моделирования
    % Символьная скорость преамбулы, Бод
        Rate = 1e6;
    % Длина последоватлеьности
        ML = 2^8 - 1;
    % Диапазон частот, Гц
        fMin = -20e3;
        fMax = 20e3;
    % Число точек сетки частот
        fNum = 1000 + 1;

    % Сетка частот
        df = (fMax - fMin)/(fNum-1);
        FVals = (fMin:df:fMax);

% Генерация м-последовательности
    mseq = (1+1j)*mlseq(ML);

% Построение тела неопределённости
    % Матрица под результат
        CorrRes = zeros(2*(ML-1) + 1, fNum);
    % Массив лагов
        Lags = (-ML+1:ML-1)';
    
    % Цикл по частотам
        for i = 1:fNum
            % Апериодическая АКФ
                CorrRes(:, i) = conv( ...
                    mseq .* exp(1j*2*pi*FVals(i) * (0:ML-1)'/Rate), ...
                    flipud(conj(mseq)) ...
                );
        end

    % Сечения при нулевом временном и частотном сдвиге
        SechT0 = CorrRes(Lags == 0, :).';
        SechF0 = CorrRes(:, FVals == 0);

% Построение графиков
    % Тело неопределённости
        surf(FVals, Lags, abs(CorrRes));

    % Сечения
        figure
        plot(Lags, abs(SechF0));
        title('FVals = 0');

        figure
        plot(FVals, abs(SechT0));
        title('Lags = 0');