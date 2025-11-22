% В данном скрипте выполняется оценка отношения энергии бита к дисперсии
% шума сигнального созвездия пакета, принятого в ЛР №3

clc; clear; 
close all;

% Добавление путей
    addpath("MatFiles\");

% Загрузка принятого созвездия
    load("Constellation.mat", "Constellation");

% Нормировка по уровню
    Preamble = (1+1j)*mlseq(127);
    CorrRes = Constellation(1:127).' * conj(Preamble);
    CorrRef = Preamble(1:127).' * conj(Preamble);
    ScaleFactor = CorrRef / abs(CorrRes);
    ConstellationScaled = Constellation * ScaleFactor;

% Средняя энергия созвездия и бита
    Es = mean(abs(pskmod(0:3, 4, pi/4)).^2);
    Eb = Es/2;

% Дисперсия шума
    Symbols = ConstellationScaled(127+1:end);
    Noise = Symbols - pskmod(pskdemod(Symbols, 4, pi/4), 4, pi/4);
    nvar = var(Noise);

% Eb2nvar
    SNRdB = 10*log10(Eb / nvar);
    
% Рисунки
    plot(Constellation(127+1:end), '.'); hold on;
    plot(ConstellationScaled(127+1:end), '.'); axis equal;
    grid minor;
    xlabel I
    ylabel Q
    legend('До', 'После');

    figure;
    plot(Noise, '.'); axis equal; grid on