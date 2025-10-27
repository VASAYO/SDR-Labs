function Preamble = GeneratePreambule(PreambleLength)
% Функция генерирует преамбулу заданного размера в виде
% m-последовательности
% 
% Входные переменные: 
%   PreambuleLength - длина преамбулы 
% 
% Выходные переменные:
%   Preample - вектор-строка сгенерированной m-последовательности

% Расчет нужной длины m-последовательности
    mlseqLength = 2^ceil(log2(PreambleLength + 1)) - 1;
% Генерация m-последовательности
    mlseqBits = mlseq(mlseqLength);
% Изъятие нужного количества элементов из m-последователньости
    Preamble = mlseqBits(1:PreambleLength);


