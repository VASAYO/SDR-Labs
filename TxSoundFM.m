% Скрипт FM-модуляции аудиосигнала, формирования IQ-сигнала и создания .bin
% файла с отсчетами сигнала для дальнейшей передачи через SDR-платформу
    clc; clear; close all;

% Считываем аудиофайл
    [RawData, Fs] = audioread("C:\Users\user\Documents\SDR-Labs\" + ...
        "Source_sound.mp3");

% Преобразуем в моно
    DataMono = sum(RawData, 2)/2;
    clear RawData;

% Обрезаем по времени 
    t = (0:length(DataMono)-1)/Fs;
    DataCut = DataMono(t >= 15 & t < 25);
    clear t DataMono;

% Модулируем звуковой сигнал
    FMModObj = comm.FMBroadcastModulator( ...
        "AudioSampleRate", Fs, ...
        "SampleRate", 200e3, ...
        "FrequencyDeviation", 75e3);
    IQRaw = FMModObj(DataCut);
    clear DataCut

% Повышаем частоту дискретизации
    ResampFactor = 10e6/200e3;
    IQResamp = ResamplingFun(IQRaw, 200e3, 10e6);
    clear IQRaw

% Масштабируем по уровню 
    RefLevel = 127;
    ScaleFactor = RefLevel / ...
        max([max(abs(real(IQResamp))) max(abs(imag(IQResamp)))]);
    
    IQScaled = IQResamp * ScaleFactor;
    clear IQResamp

% Формируем .bin файл с отсчётами сигнала
    IQPrepared4Tx = [real(IQScaled), imag(IQScaled)].';

    fid = fopen("C:\Users\user\Documents\SDR-Labs\TxData.bin", "w");
    fwrite(fid, IQPrepared4Tx(:), "int8");
    fclose(fid);

    clear IQScaled
