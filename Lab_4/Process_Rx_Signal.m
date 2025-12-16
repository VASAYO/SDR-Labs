% Функция выполняет обработку принятого сигнала, имеющего структуру, 
% описанную в Generate_Tx_Signal.m

clc; clear;
close all;

addpath('..\Lib\');

%% Параметры
% Загрузка структуры параметров, созданной в Generate_Tx_Signal.m
    load( "..\Records\Lab_4_Params.mat", "Par" );

% Параметры канала 
    % Нужно ли выполнять имитацию канала
        Par.Channel.Enable = true;
    % ОСШ на бит, дБ
        Par.Channel.EbNo = 10;

% Вычисляемые параметры
    % Энергия бита
        Par.Channel.Eb = 1 / log2( Par.Mod.Order );
    % Дисперсия шума
        Par.Channel.No = Par.Channel.Eb / 10^( Par.Channel.EbNo / 10 );

%% Выгрузка сигнала из файла, имитация канала при необходимости
if Par.Channel.Enable
    % Выгружаем сигнал из файла
        load( '..\Records\Lab_4_TxWaveform.mat', 'Tx_Waveform' )

    % Добавляем нули перед и после сигнала
        Rx_Waveform = [zeros( 12432, 1 ); Tx_Waveform; zeros( 32121, 1 )];

    % Добавляем частотную и фазовую отстройку
        df = rand() * 40e3 - 20e3;
        dphi = rand() * 2*pi;

        Rx_Waveform = Rx_Waveform .* ...
            exp( 1j*2*pi*df*( 0:length(Rx_Waveform)-1 )' / Par.Fs ) .* ...
            exp( 1j * dphi );

    % Добавляем АБГШ
        Noise = randn( length( Rx_Waveform ), 2 ) * [ 1; 1j ];
        Noise = Noise * sqrt( Par.Channel.No / 2 );

        Rx_Waveform = Rx_Waveform + Noise;

else
    % Тут должна находиться выгрузка принятого при помощи SDR сигнала
end

%% Обработка сигнала
% Согласованная фильтрация
    FSignal = conv( Rx_Waveform, Par.RRC.Impulse );
    FSignalShort = FSignal( 1 : 1e6 );

% Синхронизация с началом сигнала
    % Сетка частотных отстроек
        fVals1 = [(0:3480:20e3), 20e3];
        fVals1 = [fliplr(-fVals1(2:end)) fVals1];

    % Набор опорных последовательностей с разными частотными сдвигами
        RefSeqs1 = zeros( Par.LenPreamble * Par.RRC.SPS, length(fVals1));

        for i = 1:length(fVals1)
            RefSeqs1(:, i) = upsample( Par.Preamble , Par.RRC.SPS) .* ...
                exp(1j*2*pi*fVals1(i) * (0:length(Par.Preamble)*Par.RRC.SPS-1)' / Par.Fs );
        end

    % Корреляция принятого сигнала с опорными последовательностями
        corrRes1 = ...
            zeros(length(FSignalShort)-size(RefSeqs1, 1)+1, length(fVals1));

        for i = 1:length(fVals1)
            corrRes1(:, i) = ...
                conv(FSignalShort, flipud(conj(RefSeqs1(:, i))), "valid");
        end
