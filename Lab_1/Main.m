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


% Считывание запись с файла
    [RawData, Fs] = audioread(SourcePath);

% Формирование IQ
    IQRaw = RawData(:, 1) + 1j * RawData(:, 2);

% Перенос сигнала на нулевую частоту
    IQShift = IQRaw .* exp(-1j * 2*pi*(F_rec-F0) * (0:length(IQRaw)-1)'/Fs);

% Понижение ЧД
    IQDown = ResamplingFun(IQShift, Fs, Fs1);

% Детектирование аудиосигнала
    ModSignal = diff(unwrap(angle(IQDown)));

% Фильтрация пилотного тона
    Tone_19kHz = Bandpass_FFT_Filter(ModSignal, Fs1, 19e3, 10);

% Получение пилотного тона с удвоенной частотой
    Tone_38kHz = Tone_19kHz .^2;
    Tone_38kHz = Bandpass_FFT_Filter(Tone_38kHz, Fs1, 38e3, 10);

% Перенос разностного канала на нулевую частоту с использованием пилотного
% тона с последующей фильтрацией 
    LRDiff = Bandpass_FFT_Filter(ModSignal, Fs1, 38e3, 15e3) .* Tone_38kHz;
    