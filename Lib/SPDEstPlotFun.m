function SPDEstPlotFun(Data, SampFreq, WelchSize)
% Построение графика СПСМ сигнала
%
% Входные параметры:
%   * Data - вектор-столбец отсчётов сигнала
%   * SampFreq - частота дискретизации сигнала
%
% Если число параметров равно 1, то частота дискретизации по умолчанию
% считается равной 1

    % Проверка числа входных аргументов
        if nargin < 3
            WelchSize = 1e4;
        end
        if nargin < 2
            SampFreq = 1;
        end

    % Получение данных для построения
        [YData, XData] = GetSPDEstFun(Data, SampFreq, WelchSize);

    % Создание и настройка рисунка
        plot(XData, 10*log10(YData));
        grid on;
        xlabel('Frequency, Hz');
        ylabel('SPD');
end

