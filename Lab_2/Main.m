% Реализовать пакетную передачу данных между двумя HackRF.
%
% Формат данных: текстовая информация.
%
% Параметры системы передачи:
%   1. QPSK модуляция;
%   2. Битовая скорость: 1 Мб/с;
%   3. Символьная скорость: 500 кБод;
%   4. Формирующий фильтр: RRC, beta = 0.35.
%
% Поля пакета:
%   1. Преамбула;
%   2. Номер пакета;
%   3. Количество пакетов;
%   4. Данные;
%   5. CRC;
%   6. Некоторые другие технические данные.
%
% Требования к обработке:
%   - Частотная и фазовая синхронизация (по преамбуле);
%   - Хорошие корреляционные свойства преамбулы;
% 
% Изучить про (м.б. полезно):
%   - CRC;
%   - Послед-ти Уолша, Голда; m-последовательности.
%
% Примечания:
%   - Делать паузы между пакетами;
%   - Эквалайзер не требуется;
% 
% Оценка частотной отстройки:
%   - Стабильность опорного генератора Hack RF составляет 20 ppm;
%   - Положим несущую частоту равной 500 МГц;
%   - Учитывая худший случай, максимальная частотная отстройка при приёме 
%   при неподвижных приёмнике и передатчике составляет 20 кГц.
%

clc; clear;
close all;
addpath('../Lib/');

%% Параметры моделирования
% Битовая скорость
    BitRate = 1e6;
% Параметры RRC
    beta = 0.5;
    span = 10;
    sps = 2;
% Число передаваемых в пакете бит
    BitsPerPackage = 1024;
% Длина синхропоследовательности
    PreLen = 2^7 - 1;
% Нужно ли сохранять отсчёты сигнала в файл
    NeedSaveTxSignal = 0;
% Отношение энергии бита к дисперсии шума, дБ
    EbNo = 10;
% Энергия бита (QPSK)
    Eb = 1 / log2(4);

% Вычисляемые/генерируемые параметры
    % Символьная скорость (QPSK)
        BaudRate = BitRate / 2;
    % Частота дискретизации
        Fs = BaudRate * sps;
    % Период дискретизации
        Ts = 1/Fs;
    % RRC импульс
        RRC = rcosdesign(beta, span, sps);
    % Отстройка частоты и фазы сигнала
        fOffset = (40e3*rand() - 20e3) * 1;
        phiOffset = 2*pi*rand() - pi;
    % Дисперсия шума
        No = Eb / 10^(EbNo/10);


%% Формирование пакета
% Генерация бит
    InputData = randi([0 1], BitsPerPackage, 1);
% Маппинг бит
    Symbols = pskmod(InputData, 4, pi/4, "gray", "InputType", "bit");
% Синхропоследовательность
    Preamble = (1 + 1j) * mlseq(PreLen);

% Объединение символов информационной последовательности и
% синхропоследовательности
    SymbolsPackage = [Preamble; Symbols];

% Формирование сигнала
    SymbolsPackageUpsampled = upsample(SymbolsPackage, sps);
    TxSignal = conv(SymbolsPackageUpsampled(1:end-(sps-1)), RRC);

% Сохранение сигнала в файл
    if NeedSaveTxSignal
        % Повышение частоты дискретизации до рабочей в SDR
            if Fs < 10e6
                Buf = ResamplingFun(TxSignal, Fs, 10e6);
            else
                Buf = TxSignal;
            end

        IQ2BinInt8(Buf, '.\..\Records\Lab_2_TxSig.bin');
        clear Buf;
    end

%% Канал передачи
% Добавление нулей до и после пакета
    RxSignal = [zeros(size(TxSignal)); TxSignal; zeros(size(TxSignal))];

% Добавление частотной отстройки и случайной фазы
    RxSignal = RxSignal .* ...
        exp(1j*2*pi*fOffset * (0:length(RxSignal)-1).' * Ts);
    RxSignal = RxSignal * exp(1j * phiOffset);

% Добавление АБГШ
    % Генерация комплексного шума
        Noise = randn(length(RxSignal), 2) * [1; 1j];
        Noise = Noise * sqrt(No/2);

    RxSignal = RxSignal + Noise;

%% Приём и обработка пакета
% Согласованная фильтрация
    FSignal = conv(RxSignal, RRC);

% Поиск НОМЕРА ОТСЧЁТА СИГНАЛА, С КОТОРОГО НАЧИНАЕТСЯ ПАКЕТ
    % Сетка частотных отстроек
        fVals1 = [(0:3480:20e3), 20e3];
        fVals1 = [fliplr(-fVals1(2:end)) fVals1];

    % Набор опорных последовательностей с разными частотными сдвигами
        RefSeqs1 = zeros(length(Preamble) * sps, length(fVals1));

        for i = 1:length(fVals1)
            RefSeqs1(:, i) = upsample(Preamble, sps) .* ...
                exp(1j*2*pi*fVals1(i) * (0:length(Preamble)*sps-1)' * Ts);
        end
        
    % Корреляция принятого сигнала с опорными последовательностями
        corrRes1 = ...
            zeros(length(FSignal)-size(RefSeqs1, 1)+1, length(fVals1));

        for i = 1:length(fVals1)
            corrRes1(:, i) = ...
                conv(FSignal, flipud(conj(RefSeqs1(:, i))), "valid");
        end

    [MaxAbs, Inds] = max(abs(corrRes1));
    [~, FreqOffsetInd1] = max(MaxAbs);
    
    PackageBeginSample = Inds(FreqOffsetInd1);

% Грубая частотная подстройка сигнала
    SignalTuned1 = FSignal .* ...
        exp(-1j*2*pi*fVals1(FreqOffsetInd1) * (0:length(FSignal)-1)' * Ts);

% Синхронизация начала пакета по первому отсчёту
    SignalSync = SignalTuned1(PackageBeginSample:end);

% Выбор модуляционных символов 
    RxPackageSymbols= SignalSync(1:sps:sps*(PreLen+BitsPerPackage/2));

% Точная частотная синхронизация
    % Принятая синхропоследовательность после грубой подстройки частоты
        RxPreamble = RxPackageSymbols(1:PreLen);

    % Сетка частотных отстроек
        fVals2 = (0:20:3480/2);
        fVals2 = [fliplr(-fVals2(2:end)) fVals2];
    
    % Набор опорных последовательностей с разными частотными сдвигами
        RefSeqs2 = zeros(PreLen, length(fVals2));

        for i = 1:length(fVals2)
            RefSeqs2(:, i) = Preamble .* ...
               exp(1j*2*pi*fVals2(i) *(0:length(Preamble)-1)'/BaudRate);
        end

    % Корреляция принятой преамбулы с набором опорных последовательностей
        corrRes2 = zeros(1, length(fVals2));

        for i = 1:length(fVals2)
            corrRes2(i) = sum(RxPreamble .* conj(RefSeqs2(:, i)));
        end

    % Определение частотной отстройки
        [~, FreqOffsetInd2] = max(abs(corrRes2));

    % Точная подстройка частоты
        RxPackageSymbolsFreqTuned = MultiplyOnComplexExp( ...
            RxPackageSymbols, -fVals2(FreqOffsetInd2), BaudRate ...
        );

% Синхронизация фазы сигнала
    % Оценка фазы по преамбуле
        PhiEstimate = ...
            angle(sum(RxPackageSymbolsFreqTuned(1:PreLen) .* ...
            conj(Preamble)));

    % Подстройка фазы
        RxPackageSymbolsTuned = RxPackageSymbolsFreqTuned * ...
            exp(-1j * PhiEstimate);

% Демодуляция
    OutputBits = pskdemod(RxPackageSymbolsTuned(PreLen+1:end), ...
        4, pi/4, "gray", "OutputType", "bit");


%% Результаты
% Ошибки бит при приёме
    fprintf('Ошибочно принятых бит: %d/%d;\n', ...
        sum(OutputBits ~= InputData), BitsPerPackage);
