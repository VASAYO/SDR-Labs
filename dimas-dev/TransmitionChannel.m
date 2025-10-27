function RxSig = TransmitionChannel(TxSig, PackLen, ...
    numPackages, Ts, freqOffset, phiOffset, No)
% Функция имитирует канал передачи с разделением пакетов и добавления шума
% к передаваемому сигналу, а также отсроек по частоте и фазе
%
% Входные аргументы:
%   TxSig       - сигнал из объединения всех передаваемых пакетов;
%   PackLen     - длина одного пакета;
%   numPackages - количество передаваемых пакетов;
%   Ts          - период дискретизации;
%   freqOffset  - отстройка по частоте;
%   phiOffset   - отстройка по фазе;
%   No          - дисперсия шума.
%
% Выходные аргументы:
%   RxSig - сигнал с добавлением шума и разделением пакетов, сдвинутых по
%           времени и частоте.

% Паузы в начале передаваемого сигнала, конце и между пакетами
    PauseLen = 1.0 * PackLen;
    Prefix   = 1.0 * PackLen;
    Suffix   = 1.0 * PackLen;
% Добавление нулей в начало
    RxSig = [zeros(Prefix, 1)];

% Добавление пакетов и пауз между ними
    for i = 1 : numPackages
        % Извлечение i-того пакета из входного сигнала
        startIdx    = (i - 1) * PackLen + 1;
        endIdx      = i * PackLen;
        CurrentPack = TxSig(startIdx : endIdx);
        
        % Переопределение выходного аргумента 
        RxSig = [RxSig; CurrentPack];

        % Добавление паузы после пакета, если он не крайний
        if i < numPackages
            RxSig = [RxSig; zeros(PauseLen, 1)];
        end
    end

% Добавление нулей в конец 
    RxSig = [RxSig; zeros(Suffix, 1)];

% Добавление отстройки по частоте 
    RxSig = RxSig .* ...
        exp(1j * 2*pi* freqOffset * (0 : length(RxSig) - 1).' * Ts);

% Добавление отстройки по фазе 
    RxSig = RxSig * exp(1j * phiOffset);

% Добавление АБГШ
    Noise = randn(length(RxSig), 2) * [1; 1j];
    Noise = Noise * sqrt(No/2);
    RxSig = RxSig + Noise;

