function Packages_Offsets = Package_Synchronization(FSignal, sps)
% Функция выполняет синхронизацию с началами пакетов
% 
% Входные параметры:
%   FSignal - сигнал с выхода согласованного фильтра;
%   sps     - отношение частоты дискретизации и символьной скорости.
%
% Выходные параметры:
%   Packages_Offsets - массив сдвигов до пакетов в сигнале.

% Длина преамбулы
    PreLen = 127;
% Массив частотных отстроек
    FVals = [(0:3480:20e3), 20e3];
    FVals = [fliplr(-FVals(2:end)) FVals];
% Символьная скорость
    Rs = 500e3;

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
        1