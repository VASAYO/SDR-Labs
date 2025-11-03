% Скрипт выполняет разбиение исходной информационной последовательности бит
% на группы, формирование последовательности пакетов для передачи данных
% через канал связи при помощи SDR
%
% Поля пакета:
%   - Преамбула - 127 комплексных символов;
%   - Общее число пакетов - 14 бит;
%   - Номер текущего передаваемого пакета - 14 бит;
%   - Число передаваемых информационных бит в пакете - 10 бит;
%   - Поле данных - 1024 бит;
%   - CRC - 16 бит.

clc; clear;
close all;

addpath('..\Lib\');

%% Параметры
% Битовая скорость, бит/с
    Rb = 1e6;
% Символьная скорость (QPSK), Бод
    Rs = 500e3;
% Параметры импульсной характеристики формирующего RRC-фильтра
    beta = 0.5;
    span = 20;
    sps  = 20;
% Число информационных бит, передаваемых в одном пакете
    BitsPerPack = 1024;
% Длина поля общего числа пакетов, бит
    TotPacFieldLen = 14;
% Длина поля номера текущего пакета, бит
    PacNumFieldLen = 14;
% Длина поля числа информационных бит, передаваемых в пакете, бит
    NumBitsInPack = 10;
% Длина поля CRC, бит
    crcFieldLen = 16;
% Длина преамбулы, символов
    PreLenSymbs = 2^7-1;
% Нужно ли сохранять сигнал в файл
    Flag_SaveTx2File = 1;

% Информационная последовательность бит
    fid = fopen('..\Records\2. Цена алчности.fb2.zip', 'r');
    SourceData = fread(fid, +inf, 'ubit1');
    fclose(fid);
% Число передаваемых бит
    NumTxBits = length(SourceData);
% Число пакетов
    NumTxPacks = ceil(NumTxBits / BitsPerPack);
% Длина пакета в модуляционных символах
    PackLenSymbs = PreLenSymbs + ...
        (TotPacFieldLen + PacNumFieldLen + NumBitsInPack + BitsPerPack + ...
        crcFieldLen)/2;
% ИХ формирующего фильтра
    RRC = rcosdesign(beta, span, sps, "sqrt");

%% Формирование последовательности пакетов
% Разбиение бит по пакетам
    DataDiv = cell(NumTxPacks, 1);

    if mod(NumTxBits, BitsPerPack) == 0 % Число передаваемых информационных 
                                        % бит кратно числу бит в одном
                                        % пакете
        for PacIdx = 1:NumTxPacks
            DataDiv{PacIdx} = ...
                SourceData((1:BitsPerPack) + (PacIdx-1)*BitsPerPack);
        end
    else % Число передаваемых информационных бит НЕ кратно числу бит в 
         % одном пакете
        for PacIdx = 1:NumTxPacks-1
            DataDiv{PacIdx} = ...
                SourceData((1:BitsPerPack) + (PacIdx-1)*BitsPerPack);
        end
        DataDiv{NumTxPacks} = ...
            SourceData(end-mod(NumTxBits, BitsPerPack)+1:end);
    end

% Формирование последовательности модуляционных символов для каждого пакета
    PacksSymbs = zeros(PackLenSymbs, NumTxPacks);

    for PacIdx = 1:NumTxPacks
        PacksSymbs(:, PacIdx) = ...
            Generate_Package_Symbols(DataDiv{PacIdx}, NumTxPacks, PacIdx);
    end
    PacksSymbs = PacksSymbs(:);

% Формирующая фильтрация
    TxSignal = upsample(PacksSymbs, sps);
    TxSignal = TxSignal(1:end-(sps-1));

    TxSignal = conv(TxSignal, RRC);

% Сохранение сигнала в файл
    if Flag_SaveTx2File
        IQ2BinInt8(TxSignal, '..\Records\Lab2_Tx.bin');
    end