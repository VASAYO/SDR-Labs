clc; clear;
close all;

addpath('..\Lib\');
addpath("MatFiles\");

%% Параметры
% Частота излучения сигнала
    Ftx = 402e6;
% Центральная частота записи
    Frx = 401.516e6;
% Параметры ИХ СФ
    beta = 0.5;
    span = 20;
    sps  = 2;
% Символьная скорость, сим/с
    Rs = 500e3;
% Длина пакета в модуляционных символах
    SymbsPerPackage = 666;
% Число информационных бит в одном пакете
    InfoBitsPerPackage = 1024;

% Частота сигнала в baseband записи
    Fint = Ftx - Frx;
% Частота дискретизации при обработке
    Fs = sps * Rs;
% ИХ СФ
    h = rcosdesign(beta, span, sps, "sqrt");

%% Обработка сигнала
% Чтение файла и формирование IQ сигнала
    [Raw, FsRaw] = audioread('..\Records\Lab3\12-26-44_401516000Hz.wav');
    Signal = Raw(:, 1) + 1j*Raw(:, 2);

% Перенос сигнала на нулевую частоту
    ShiftSignal = Signal .* ...
        exp(-1j*2*pi*Fint * (0:length(Signal)-1)' / FsRaw);

% Понижение частоты дискретизации
    DownConSignal = ResamplingFun(ShiftSignal, FsRaw, Fs);
    
% Согласованная фильтрация
    FSignal = conv(DownConSignal, h);

% Символьная синхронизация
    [Packages_Offsets, Frequency_Offsets] = Package_Synchronization( ...
        FSignal, sps, true);

% Определение числа найденных пакетов
    NumPackages = length(Packages_Offsets);

% Выделение модуляционных символов каждого пакета
    Packages_Symbols = zeros(SymbsPerPackage, NumPackages);

    for PackIdx = 1:NumPackages % Цикл по найденным пакетам
        Packages_Symbols(:, PackIdx) = ...
            FSignal((1:sps:sps*SymbsPerPackage)-1 + Packages_Offsets(PackIdx));
    end

% Грубая частотная подстройка каждого пакета
    for PackIdx = 1:NumPackages
        Packages_Symbols(:, PackIdx) = Packages_Symbols(:, PackIdx) .* ...
            exp(-1j*2*pi*Frequency_Offsets(PackIdx) * (0:SymbsPerPackage-1)'/Rs);
    end

% Точная частотная и фазовая подстройка каждого пакета
    % Сетка частотных отстроек
        fVals2 = (0:20:3480/2);
        fVals2 = [fliplr(-fVals2(2:end)) fVals2];

    % Набор опорных последовательностей с разными частотными сдвигами
        RefSeqs2 = zeros(127, length(fVals2));
        for i = 1:length(fVals2)
            RefSeqs2(:, i) = (1+1j)*mlseq(127) .* ...
               exp(1j*2*pi*fVals2(i) *(0:127-1)'/Rs);
        end

    for PackIdx = 1:NumPackages % Цикл по пакетам
        % Выбор отсчётов преамбулы
            PreambleSamples = Packages_Symbols(1:127, PackIdx);

        % Корреляция принятой преамбулы с набором опорных 
        % последовательностей
            corrRes2 = zeros(1, length(fVals2));
    
            for i = 1:length(fVals2)
                corrRes2(i) = sum(PreambleSamples .* conj(RefSeqs2(:, i)));
            end

        % Определение частотной отстройки
            [~, BufInd] = max(abs(corrRes2));
            dfHz = fVals2(BufInd);

        % Точная подстройка частоты
        Packages_Symbols(:, PackIdx) = Packages_Symbols(:, PackIdx) .* ...
            exp(-1j*2*pi*dfHz * (0:SymbsPerPackage-1)'/Rs);

        % Выбор отсчётов преамбулы после подстройки частоты
            PreambleSamples = Packages_Symbols(1:127, PackIdx);

        % Оценка фазы по преамбуле
            PhiEstimate = angle(sum(PreambleSamples .* conj((1+1j)*mlseq(127))));

        % Подстройка фазы
            Packages_Symbols(:, PackIdx) = Packages_Symbols(:, PackIdx) * ...
                exp(-1j * PhiEstimate);
    end

%% Обработка пакетов
% Массив флагов, указывающий, сошлось ли CRC для соответствующего
% пакета

% Демодуляция бит пакета
    PackageBits = pskdemod(Packages_Symbols(127+1:end, :), 4, pi/4, "gray", ...
        "OutputType", "bit");

% Обнаружение ошибок в пакетах
    [Buf, isErrorInPackage] = crcDetect(PackageBits, crcConfig());

% Дескрэмблирование
    ScrSeq  = (mlseq(2047)+1)/2;
    ScrSeq  = ScrSeq(1:1062);
    ScrSeqs = repmat(ScrSeq, 1, NumPackages);
    BitsPackageDeScr = mod(Buf+ScrSeqs, 2);

% Удаление технических полей
    InfoBits = BitsPackageDeScr(2*14+10+1:end, :);

% Имитация повторной передачи пакетов, в которых обнаружены ошибки
    load("DataDiv.mat");

    % Номера битых пакетов
        IndErrPacks = find(isErrorInPackage == 1);

    % Повторная передача
        for i = 1:length(IndErrPacks)
            InfoBits(:, IndErrPacks(i)) = DataDiv{IndErrPacks(i)};
        end

% Формирование итоговой битовой последовательности и удаление нулей в конце
% последнего пакета
    InfoBits = InfoBits(:);
    InfoBits = InfoBits(1:end-(1024-448));

% Запись результата в файл
    fid = fopen("Res.zip", "w");
    fwrite(fid, InfoBits, "ubit1");
    fclose(fid);
