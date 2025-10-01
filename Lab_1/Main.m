clc; clear; close all;

addpath('../Lib/');
% comm.FMBroadcastDemodulator()

% Ручная демодуляция записанного FM-сигнала с частотой девиации 75 кГц.
    clc; close all; clear;

% Параметры 
    % Путь к файлу записи
        SourcePath = "C:\Users\VIVADO\Documents\Polytech\Магистратура\SDR course\SDR-Labs\Records\IQ\2025_10_01\12-46-56_101300000Hz.wav";

    % Частота дискретизации
        Fs = [];
    % ЧД после понижения
        Fs1 = 200e3;
    % Центральная частота записи
        F0 = 101.3e6;
    % Частота сигнала
        F_rec = 102e6;

% Считываем запись с файла
    [RawData, Fs] = audioread(SourcePath);

% Формируем IQ
    IQRaw = RawData(:, 1) + 1j * RawData(:, 2);

% Перенос сигнала на нулевую частоту
    IQShift = IQRaw .* exp(-1j * 2*pi*(F_rec-F0) * (0:length(IQRaw)-1)'/Fs);

% Понижаем ЧД
    IQDown = ResamplingFun(IQShift, Fs, Fs1);

% Детектируем аудиосигнал
    ModSignal = diff(unwrap(angle(IQDown)));

% Фильтруем пилотный тон
    fft_tmp = fftshift(fft(ModSignal));
    f = Generete_Freq_Axis_FFT(length(fft_tmp), Fs1);
    fft_tmp(abs(f - 19e3) > 10 & abs(f + 19e3) > 10) = 0;

    Tone_19kHz = ifft(ifftshift(fft_tmp));
    clear f fft_tmp;

% 