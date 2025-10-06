% Ручная демодуляция записанного FM-сигнала с частотой девиации 75 кГц.
% comm.FMBroadcastDemodulator()
    clc; close all; clear;

addpath('../Lib/');

% Параметры (все параметры указаны в системе СИ)
    % Путь к файлу записи
        SourcePath = ".\..\Records\IQ\" + ...
            "2025_09_17\13-08-04_100000000Hz.wav";
    % Частота дискретизации
        Fs = [];
    % ЧД после понижения
        Fs1 = 200e3;
    % Центральная частота записи
        F0 = 100e6;
    % Частота сигнала
        F_rec = 97e6;
    % Девиация частоты
        fd = 75e3;
    % Постоянная времени фильтра предыскажения
        tau = 50e-6;


% Считывание запись с файла
    [RawData, Fs] = audioread(SourcePath);

% Формирование IQ
    IQRaw = RawData(:, 1) + 1j * RawData(:, 2);

% Перенос сигнала на нулевую частоту
    IQShift = IQRaw .* exp(-1j * 2*pi*(F_rec-F0) * (0:length(IQRaw)-1)'/Fs);

% Понижение ЧД
    IQDown = ResamplingFun(IQShift, Fs, Fs1);

% Детектирование аудиосигнала
    ModSignal = 1/(2*pi*fd) * ...
        angle(IQDown(2:end) .* conj(IQDown(1:end-1))) * Fs1;

% Устранение предыскажения
    % Коррекция постоянной времени фильтра для устранения преобразования
    % частотной оси при билинейном преобразовании
        tauCorr = (2*Fs1 * tan(tau^-1/Fs1 / 2))^-1;

    % Синтез ЦФ на основе билинейного преобразования от аналоговой
    % интегрирующей RC-цепочки
        DeEmphasis_B = [1/(1+2*Fs1*tauCorr), 1/(1+2*Fs1*tauCorr)];
        DeEmphasis_A = [1, (1-2*Fs1*tauCorr)/(1+2*Fs1*tauCorr)];

    % Фильтрация
        DeEmphasis = filter(DeEmphasis_B, DeEmphasis_A, ModSignal);

% Фильтрация компоненты L+R
    load("Filt1.mat");
    LRSum = filter(Filt1, 1, DeEmphasis);

% Фильтрация компоненты L-R
    load("Filt3.mat");
    LRDiffRaw = filter(Filt3, 1, DeEmphasis);

% Фильтрация пилотного тона
    load("Filt2.mat")
    Tone_19kHz = filter(Filt2, 1, DeEmphasis);

% Получение пилотного тона с удвоенной частотой
    Tone_38kHz = Tone_19kHz .^2;
    load("Filt4.mat")
    Tone_38kHz = filter(Filt4, 1, Tone_38kHz);

% Нормировка пилотного тона по величине
    RefLevel = 1;
    Level = max(abs(fft(Tone_38kHz)/length(Tone_38kHz)));
    ScaleFactor = RefLevel / Level;

    Tone_38kHz = Tone_38kHz * ScaleFactor;

% Перенос разностного канала на нулевую частоту с использованием пилотного
% тона с последующей фильтрацией 
    LRDiffShift = LRDiffRaw .* Tone_38kHz;
    LRDiff = filter(Filt1, 1, LRDiffShift);

% Выделение левого и правого каналов
    Left = LRDiff + LRSum;
    Right = LRDiff - LRSum;

    Stereo = [Left, Right];

% Проигрывание звука
    sound(Stereo, Fs1);
    