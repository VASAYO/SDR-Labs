function TxSig = FormPackage(InputBits, BitPerPack, ...
    M, IniPhase, PreLen, sps, PulseRRC, packIdx)
% Функция формирует передаваемый пакет из входхны битов, добавляя 16 CRC
% бит
%   
% Входные аргументы:
%   InputBits  - вектор-строка входного потока данных (биты);
%   BitPerPack - количество бит на один пакет;
%   M          - порядок модуляции;
%   IniPhase   - начальная фаза;
%   Prelen     - длина синхропоследовательности;
%   sps        - количество отсчетов на символ;
%   PulseRRC   - ИХ RRC-фильтра;
%   packIdx    - номер пакета.
%
% Выходные аргументы:
%   TxSig      - сформированный передаваемый пакет

% Проверка количества входных битов
    numInputBits = length(InputBits);

    if numInputBits > BitPerPack
        error('Количество входных бит превышает размер пакета');
    end

% Дополнение m-последовательностью, если пакет неполный (исправить на нули)
    if numInputBits < BitPerPack
        % Количество битов, недостающих до заполнения пакета
        bitsToAdd = BitPerPack - numInputBits;
        % Расчет нужной длины m-последовательности
        mlseqLength = 2^ceil(log2(bitsToAdd + 1)) - 1;
        % Генерация m-последовательности
        mlseqBits = mlseq(mlseqLength);
        % Изъятие нужного количества бит из m-последователньости
        RemBits = mlseqBits(1:bitsToAdd);
        % Объединение входных битов с дополненными
        InputBits = [InputBits; RemBits];
    end
    
% Инициализация генератора CRC-16
    crcGen = comm.CRCGenerator('Polynomial','z^16 + z^14 + z + 1');

% Добавление бит CRC к входному потоку бит
    InputBitsWithCRC = crcGen(InputBits);

% Модуляция PSK входного потока бит
    Symbols = ...
        pskmod(InputBitsWithCRC, M, IniPhase, "gray", "InputType","bit");

% Формирование преамбулы 
    Preamble = GeneratePreambule(PreLen);

% Формирование номера пакета (16 бит)
    PackNumberBits    = de2bi(packIdx, 16, 'left-msb')';
    PackNumberSymbols = ...
        pskmod(PackNumberBits, M, IniPhase, "gray", "InputType","bit"); 
        
% Формирование размера пакета (16 бит)
    PackSize        = numInputBits;
    PackSizeBits    = de2bi(PackSize, 16, 'left-msb')'; 
    PackSizeSymbols = ...
        pskmod(PackSizeBits, M, IniPhase, "gray", "InputType","bit"); 

% Объединение символов и преамбулы в один пакет
    SymbPack = [Preamble; PackNumberSymbols; PackSizeSymbols; Symbols];

% Формирование сигнала
    SymbPackUpsampled = upsample(SymbPack, sps);
    TxSig = conv(SymbPackUpsampled(1:end - (sps - 1)), PulseRRC);







