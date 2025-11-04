function Symbols = Generate_Package_Symbols( ...
    Data, TotalPacks, PackNumber)
% Функция выполняет формирование модуляционных символов пакета
%
% Входные параметры:
%   Data            - массив, содержащий не более 1024 информационных бит;
%   TotalPacks      - суммарное число пакетов от 1 до 16384;
%   PackNumber      - номер пакета от 1 до 16384.
%
% Выходные параметры:
%   Symbols - массив-столбец, содержащий модуляционные символы пакета.

% Число информационных бит в пакете
    NumBits = length(Data);

% Если NumBits оказывается меньше 1024, в конец массива вставляются нули
    if NumBits > 1024
        error(['Generate_Package_Symbols.m: число информационных бит ' ...
            'пакета не должно превышать 1024']);

    elseif NumBits < 1024
        Data = [Data; zeros(1024 - NumBits, 1)];
    end

% Перевод PackNumber, TotalPacks, NumBits в двоичный вид
    PackNumberBin = int2bit(PackNumber-1, 14, true);
    TotalPacksBin = int2bit(TotalPacks-1, 14, true);
    NumBitsBin    = int2bit(NumBits-1,    10, true);

% Объединение всех полей в единую битовую последовательность
    PackSeq = [TotalPacksBin; PackNumberBin; NumBitsBin; Data];

% Скрэмблирование содержимого пакета
    ScrSeq = (mlseq(2047)+1)/2;
    ScrSeq = ScrSeq(1:length(PackSeq));
    PackSeqScr = mod(PackSeq+ScrSeq, 2);

% Вычисление CRC16 и добавление контрольной суммы в конец
% последовательности
    crcConf = crcConfig();
    PackSeqScrCRC = crcGenerate(PackSeqScr, crcConf);

% Маппинг последовательности
    FieldsSymbols = pskmod(PackSeqScrCRC, 4, pi/4, "gray", ...
        "InputType", "bit");

% Преамбула
    Preamble = (1+1j) * mlseq(127);

% Объединение символов тела пакета и преамбулы
    Symbols = [Preamble; FieldsSymbols];
