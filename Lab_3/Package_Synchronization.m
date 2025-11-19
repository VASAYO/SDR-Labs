function [Packages_Offsets, Frequency_Offsets] = ...
    Package_Synchronization(FSignal, sps, Flag_LoadResFromMat)
% Функция выполняет синхронизацию с началами пакетов
% 
% Входные параметры:
%   FSignal             - сигнал с выхода согласованного фильтра;
%   sps                 - отношение частоты дискретизации и символьной 
%                         скорости;
%   Flag_LoadResFromMat - флаг, указывающий на необходимость быстрой 
%                         загрузки результата работы функции из .mat файла 
%                         для случая sps = 2.
%
% Выходные параметры:
%   Packages_Offsets  - массив сдвигов до пакетов в FSignal.
%   Frequency_Offsets - массив такой же длины, как и Packages_Offsets, 
%                       содержащий значения грубых оценок частотных 
%                       отстроек до пакетов с соответствующими сдвигами.

% Загрузка результата из файла
    if Flag_LoadResFromMat
        load("Package_Synchronization_Result.mat", ...
            "Packages_Offsets", "Frequency_Offsets");
        return;
    end

% Длина преамбулы
    PreLen = 127;
% Массив частотных отстроек
    FVals = [(0:3480:20e3), 20e3];
    FVals = [fliplr(-FVals(2:end)) FVals];
% Символьная скорость
    Rs = 500e3;
% Значение порога при поиске пакетов
    ThresholdVal = 15;

% Частота дискретизации
    Fs = sps * Rs;

% Генерация отсчётов преамбулы
    Preamble = (1+1j) * mlseq(PreLen);

    % Набор опорных последовательностей с разными частотными сдвигами
        RefSeqs = zeros(PreLen*sps, length(FVals));

        for fIdx = 1:length(FVals)
            RefSeqs(:, fIdx) = upsample(Preamble, sps) .* ...
                exp(1j*2*pi*FVals(fIdx) * (0:size(RefSeqs, 1)-1)' / Fs);
        end

% Корреляция принятого сигнала с опорными последовательностями
    corrRes = ...
        zeros(length(FSignal)-size(RefSeqs, 1)+1, length(FVals));

    for i = 1:length(FVals)
        corrRes(:, i) = ...
            conv(FSignal, flipud(conj(RefSeqs(:, i))), "valid");
    end

% Поиск пакетов и их частотных отстроек
    Processing = abs(corrRes);

    Packages_Offsets = [];
    Frequency_Offsets = [];

    while sum(corrRes > ThresholdVal, "all") > 0
        % Поиск номера строчки и столбца максимального значения корреляции
            [BufMaxByCols, BufIndMaxByCols] = max(Processing);
            [~, BufFreqOffsetInd] = max(BufMaxByCols);

            Packages_Offsets(end+1) = BufIndMaxByCols(BufFreqOffsetInd);
            Frequency_Offsets(end+1) = FVals(BufFreqOffsetInd);

        % Зануление найденного максимума
            Processing(Packages_Offsets(end)-10:Packages_Offsets(end)+10, :) = 0;
    end

% Сортировка найденных пакетов в порядке возрастания
    [Packages_Offsets, I] = sort(Packages_Offsets);
    Frequency_Offsets = Frequency_Offsets(I);
