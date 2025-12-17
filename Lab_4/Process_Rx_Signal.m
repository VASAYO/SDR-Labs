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
        Par.Channel.Enable = 0;
    % ОСШ на бит, дБ
        Par.Channel.EbNo = 20;

% Вычисляемые параметры
    % Энергия бита
        Par.Channel.Eb = 1 / log2( Par.Mod.Order );
    % Дисперсия шума
        Par.Channel.No = Par.Channel.Eb / 10^( Par.Channel.EbNo / 10 );

    % Объект системы символьной синхронизации
        SymbolSyncronizer = comm.SymbolSynchronizer( ...
            "Modulation", "PAM/PSK/QAM", ...
            "TimingErrorDetector", "Early-Late (non-data-aided)", ...
            "SamplesPerSymbol", Par.RRC.SPS);
    % Объект системы подстройки частоты
        PLL = comm.CarrierSynchronizer( ...
            "SamplesPerSymbol", 1, ...
            "Modulation", "QPSK");

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
    % Выгрузка принятого при помощи SDR сигнала
        [ Rx_Waveform, Par.Fs ] = audioread( ...
            '..\Records\Lab4\14-23-21_402000000Hz.wav' );
        Rx_Waveform = Rx_Waveform( :, 1 ) + 1j * Rx_Waveform( :, 2 );
end

%% Обработка сигнала
% Согласованная фильтрация
    FSignal = conv( Rx_Waveform, Par.RRC.Impulse );
    FSignalShort = FSignal( 1 : 2.5e6 );

% Синхронизация с началом сигнала и грубая оценка частотной отстройки
    % Сетка частотных отстроек
        fVals1 = ( 100:20:300 );
        % fVals1 = [fliplr(-fVals1(2:end)) fVals1];

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

        % Определение сдвига до начала сигнала и грубой частотной отстройки
            [ Buf, IndsMaxByCols] = max( abs( corrRes1 ) );
            [ ~, NumColOfMaxVal] = max( Buf );

            Signal_Offset = IndsMaxByCols( NumColOfMaxVal );
            dfCoarse = fVals1( NumColOfMaxVal );

        % Синхронизация с началом сигнала
            SyncSignal = FSignal( Signal_Offset : end );

        % Грубая подстройка частоты
            SyncSignal = SyncSignal .* ...
                exp( -1j*2*pi*dfCoarse * ...
                    ( 0:length(SyncSignal)-1 )' / Par.Fs ...
                );

% Символьная синхронизация
    Rx_Symbols = SymbolSyncronizer( SyncSignal );

% Частотная синхронизация при помощи ФАПЧ
    Constellation = PLL.step( Rx_Symbols );

% Cинхронизация с началом каждого кадра
    MarkerCorrTreshold = 4;
    MarkerCorrRes = conv( Constellation, flipud( conj( Par.Marker ) ), ...
        "valid" );
    Frame_Offsets = find( abs( MarkerCorrRes ) > MarkerCorrTreshold );

% Определение фазовой неоднозначености каждого кадра
    Phase_Offsets = zeros( size( Frame_Offsets ) );

    for frIdx = 1 : length( Frame_Offsets )
        RxMarker = Constellation( (0 : 15-1) + Frame_Offsets( frIdx ) );

        Buf = RxMarker.' * conj( Par.Marker );

        Phase_Offsets( frIdx ) = pi / 2 * round( angle(Buf) / (pi/2) );
    end

% Покадровая обработка сигнала
    RxFramesPayloads = cell(1);
    RxFramesPayloads{1} = zeros( 4096, 1 );
    RxFramesPayloads = repmat( RxFramesPayloads, length( Frame_Offsets  ), 1 );
    isCRCError = zeros( size( Frame_Offsets ) );

    for frIdx = 1 : length( Frame_Offsets )
        FrameSymbols = Constellation( (0:2077-1) + Frame_Offsets( frIdx ) );
        FrameSymbols = FrameSymbols * exp( -1j * Phase_Offsets( frIdx) );

        PayloadSymbols = FrameSymbols( 15+1 : end );

        PayloadBits = pskdemod( PayloadSymbols, 4, pi/4, "gray", ...
            "OutputType", "bit" );

        [TwoFieldsBits, isCRCError(frIdx)] = ...
            crcDetect( PayloadBits, crcConfig() );

        FieldLen = bit2int( TwoFieldsBits( 1:12 ), 12, true );

        if FieldLen == 0
            RxFramesPayloads{ frIdx } = TwoFieldsBits( 13:end );
        else
            RxFramesPayloads{ frIdx } = TwoFieldsBits( 13:13+FieldLen-1 );
        end
    end

% Формирование итогового переданного файла
    L = 0;
    for i = 1:length( RxFramesPayloads )
        L = L + length( RxFramesPayloads{ i } );
    end

    RxData = [];

    for i = 1:length( RxFramesPayloads )
        RxData = [ RxData; RxFramesPayloads{ i } ];
        i
    end

% Запись в файл
    fid = fopen( "Rx_File.fb2", "w" );
    fwrite( fid, RxData, "ubit1" );
    fclose( fid );
