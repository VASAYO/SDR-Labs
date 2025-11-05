clc; clear;
close all;

addpath('..\Lib\');

%% Параметры
% Частота излучения сигнала
    Ftx = 402e6;
% Центральная частота записи
    Frx = 401.516e6;
% Параметры ИХ СФ
    beta = 0.5;
    span = 20;
    sps  = 2;
% Символьная скорость
    Rs = 500e3;

% Частота сигнала в baseband записи
    Fint = Ftx - Frx;
% Частота дискретизации при обработке
    Fs = sps * Rs;
% ИХ СФ
    h = rcosdesign(beta, span, sps, "sqrt");

%% Обработка сигнала
% Чтение файла и формирование IQ сигнала
    [Raw, FsRaw] = audioread('..\Records\Lab3\12-26-44_401516000Hz.wav');
    Signal = Raw(:, 1) + 1j*Raw(:, 2);

% Перенос сигнала на нулевую частоту
    ShiftSignal = Signal .* ...
        exp(-1j*2*pi*Fint * (0:length(Signal)-1)' / FsRaw);

% Понижение частоты дискретизации
    DownConSignal = ResamplingFun(ShiftSignal, FsRaw, Fs);
    
% Согласованная фильтрация
    FSignal = conv(DownConSignal, h);

% Символьная синхронизация
    Packages_Offsets = Package_Synchronization(FSignal, sps);