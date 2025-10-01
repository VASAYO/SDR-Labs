% Ручная демодуляция записанного FM-сигнала с частотой девиации 75 кГц.
    clc; close all; clear;

% Параметры 
    % Путь к файлу записи
        SourcePath = "C:\Users\VIVADO\Documents\Polytech\" + ...
            "Магистратура\SDR course\SDR-Labs\Records\IQ\" + ...
            "2025_09_24\12-52-52_450000000Hz.wav";

    % Частота дискретизации
        Fs = 8e6;
    % ЧД после понижения
        Fs1 = 100e3;
    % Центральная частота записи
        F0 = 450e6;
    % Частота сигнала
        F_rec = 452e6;

% Считываем запись с файла
    RawData = audioread(SourcePath);

% Формируем IQ
    IQRaw = RawData(:, 1) + 1j * RawData(:, 2);

% Перенос сигнала на нулевую частоту
    IQShift = IQRaw .* exp(-1j * 2*pi*(F_rec-F0) * (0:length(IQRaw)-1)'/Fs);

% Понижаем ЧД
    IQDown = ResamplingFun(IQShift, Fs, Fs1);

% Детектируем аудиосигнал
    Audio = diff(unwrap(angle(IQDown)));
    AudioDown = ResamplingFun(Audio, Fs1, 44100);

    sound(AudioDown, 44100);
