% Модуляция информационных бит, формирование сигнала для передачи по каналу
% связи

clc;
clear;
close all;
addpath('..\Lib\');

%% Параметры
% Битовая скорость, бит/с
    Rb = 1e6;
% Символьная скорость (ФМ-4), Бод
    Rs = 500e3;
% Число информационных бит в одном пакете
    BitsPerPackage = 1024;
% Параметры импульсной характеристики RRC-фильтра
    beta = 0.5;
    span = 20;
    sps  = 20;

% Частота дискретизации
    Fs = sps * Rs;
% Исходная информационная последовательность
    SourceData = randi([0 1], 10*1024 + randi([0 1023]), 1);
% Число пакетов
    NumPackages = ceil(length(SourceData) / BitsPerPackage);

%% Формирование
% Разбиение бит по пакетам
    BitsDivided = cell(NumPackages, 1); % cell-столбец, где каждая ячейка 
                                        % содержит массив-столбец
                                        % информационных бит, передаваемых
                                        % в очередном пакете

    if mod(length(SourceData), BitsPerPackage) == 0 
    % Общее число информационных бит кратно числу информационных бит,
    % передаваемых в одном пакете
        for idx = 1:NumPackages
            BitsDivided{idx} = ...
                SourceData((1:BitsPerPackage) + (idx-1)*BitsPerPackage);
        end

    else
    % Общее число информационных бит НЕ кратно числу информационных бит,
    % передаваемых в одном пакете
        for idx = 1:NumPackages-1
            BitsDivided{idx} = ...
                SourceData((1:BitsPerPackage) + (idx-1)*BitsPerPackage);
        end

        BitsDivided{NumPackages} = ...
            SourceData(end-mod(length(SourceData), BitsPerPackage)+1:end);
    end

% Для каждой группы бит выполняем формирование пакета
    PacksIQ = cell(NumPackages, 1); % cell-столбец, где каждая ячейка 
                                    % содержит массив-столбец
                                    % комплексных отсчётов соответствующего
                                    % по номеру пакета
    for idx = 1:NumPackages
        PacksIQ{idx} = Generate_Package_IQ(BitsDivided{idx}, idx, ...
            NumPackages, beta, span, sps);
    end

% Объединение пакетов в единую запись
    TxIQ = [];

    for idx = 1:length(PacksIQ)
        TxIQ = [TxIQ; PacksIQ{idx}];
    end

% Смещение сигнала на промежуточную частоту чтобы избежать dc offset
    TxIQ = TxIQ .* exp(1j*2*pi* Rs/2*(1+beta) * (0:length(TxIQ)-1)'/Fs);

% Запись сигнала в файл для передачи
    IQ2BinInt8(TxIQ, '.\..\Records\Lab2_TxSig.bin');
