% Скрипт выполняет генерацию сигнала для его передачи через SDR
%
% Параметры сигнала:
%   - Битовая скорость: 10^6 бит/с;
%   - Модуляция: QPSK-pi/4;
%   - Форма спектра: RRC, Roll-Off = 0.5;
%
% Структура сигнала:
%   1. Преамбула, 127-элементная m-последовательность, отображаемая во
%      множество значений {0.707 + 0.707i, -0.707 - 0.707i};
%   2. 1000 случайных модуляционных символов;
%   3. Последовательность кадров;
%
% Структура кадра:
%   1. Маркер, 15-элементная m-последовательность значений 
%      {0.707 + 0.707i, -0.707 - 0.707i};
%   2. Нагрузка;
%
% Нагрузка представляет из себя последовательность модуляционных символов,
% сформированную на основе битовой последовательности, имеющей следующие
% поля:
%   1. Поле длины (12 бит). MSB - бит, передающийся первый во времени;
%   2. Поле данных (4096 бит). Если десятичное значение поля длины равно 
%      0, то все биты поля заняты под передачу информации. Если десятичное
%      значение поля длины равно 0 < A < 4096, то для передачи информации
%      задействованы только первые А бит поля;
%   3. CRC16 (16 бит). Контроль целостности первых двух полей.

clc; clear; 
close all;

addpath('..\Lib\');

%% Параметры
% Битовая скорость, бит/с
    Par.Rb = 1e6;
% Параметры формирующего импульса
    Par.RRC.Beta = 0.5;
    Par.RRC.Span = 15;
    Par.RRC.SPS = 20;
% Параметры модуляции
    Par.Mod.Order = 4;
    Par.Mod.PhaseOffset = pi / 4;
% Длина преамбулы, маркеров и последовательности филлерных символов
    Par.LenPreamble = 127;
    Par.LenFillers  = 1000;
% Длины полей кадра
    Par.Frame.LenMarker = 15;
    Par.Frame.LenLength = 12;
    Par.Frame.LenData   = 4096;
    Par.Frame.LenCRC    = 16;

% Вычисляемые параметры
    % Символьная скорость, сим/с
        Par.Rs = Par.Rb / log2( Par.Mod.Order );
    % Частота дискретизации, Гц
        Par.Fs = Par.Rs * Par.RRC.SPS;
    % Формирующий импульс
        RRC = rcosdesign( Par.RRC.Beta, Par.RRC.Span, Par.RRC.SPS );
    % Преамбула и филлерные символы
        Preamble = mlseq( Par.LenPreamble ) * ( 1+1j ) / sqrt( 2 );
        Fillers  = pskmod( ...
            randi( [0 3], Par.LenFillers, 1 ), Par.Mod.Order, ...
            Par.Mod.PhaseOffset, "gray", "InputType", "integer" ...
        );


%% Формирование сигнала
% Передаваемая информационная последовательность
    TxData = randi( [0 1], Par.Rb * 4 + randi([1 4095]), 1 );

% Разбиение битовой последовательности на кадры
    % Число кадров
        NumFrames = ceil( length(TxData) / Par.Frame.LenData );

    Buf = cell(1);
    Buf{1} = zeros( Par.Frame.LenData, 1 );
    TxDataDiv = repmat( Buf, NumFrames, 1 );
    clear Buf;

    for i = 1:NumFrames
        if i ~= NumFrames
            TxDataDiv{ i } = TxData( ...
                ( 1:Par.Frame.LenData ) + ( i - 1) * Par.Frame.LenData ...
            );

        else
            TxDataDiv{ i } = TxData( ...
                1 + ( i - 1) * Par.Frame.LenData : end ...
            );
        end
    end

% Формирование кадров
    % Память под кадры
        Frames = zeros( ...
            Par.Frame.LenMarker + (Par.Frame.LenLength + ...
            Par.Frame.LenData + Par.Frame.LenCRC) / 2, ...
            NumFrames ...
        );

    % Цикл по кадрам
    for i = 1:NumFrames
        Frames( :, i ) = Gen_Frame( TxDataDiv{ i }, Par );
    end

% Добавление преамбулы и филлеров
    Tx_Symbols = [ Preamble; Fillers; Frames(:) ];

% Формирующая фильтрация
    Buf = upsample( Tx_Symbols, Par.RRC.SPS );
    Tx_Waveform = conv( Buf, RRC );

% Сохранение сигнала и набора параметров в файл
    IQ2BinInt8( Tx_Waveform, '..\Records\Lab_4_TxWaveform.bin' );
    save( '..\Records\Lab_4_Params.mat', "Par" );
