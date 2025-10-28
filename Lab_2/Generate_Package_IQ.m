function PackIQ = Generate_Package_IQ(Bits, PackNumber, TotalPacks, ...
    beta, span, sps)
% Функция выполняет формирование пакета на основе входных параметров
%
% Входные параметры:
%   Bits            - массив-столбец не более 1024 информационных бит;
%   PackNumber      - номер пакета от 1 до 16384;
%   TotalPacks      - суммарное число пакетов от 1 до 16384;
%   beta, span, sps - параметры ИХ формирующего фильтра.
%
% Выходные параметры:
%   PackIQ - массив-столбец, содержащий комплексные отсчёты пакета.

% ИХ формирующего фильтра
    RRC = rcosdesign(beta, span, sps, "sqrt");

% Синхропоследовательность
    PreSymbols = (1+1j) * mlseq(127);

% Число информационных бит в пакете
    NumBits = length(Bits);

% Если NumBits оказывается меньше 1024, в конец массива вставляются нули
    if NumBits > 1024
        error(['Generate_Package_IQ.m: число информационных бит ' ...
            'пакета не должно превышать 1024']);

    elseif NumBits < 1024
        Bits = [Bits; zeros(1024 - NumBits, 1)];
    end

% Перевод PackNumber, TotalPacks, NumBits в двоичный вид
    PackNumberBin = int2bit(PackNumber, 14, true);
    TotalPacksBin = int2bit(TotalPacks, 14, true);
    NumBitsBin    = int2bit(NumBits, 10, true);

% Объединение всех полей в единую битовую последовательность
    PackSeq = [TotalPacksBin; PackNumberBin; NumBitsBin; Bits];

% Скрэмблирование при помощи m-последовательности
    ScrSeq = (mlseq(2047)+1)/2;
    ScrSeq = ScrSeq(1:length(PackSeq));

    PackSeqScr = mod(PackSeq + ScrSeq, 2);

% Вычисление CRC16 и добавление проверочных бит в конец последовательности
    crcConf = crcConfig();
    PackSeqScrCRC = crcGenerate(PackSeqScr, crcConf);

% Маппинг последовательности
    BodySymbols = pskmod(PackSeqScrCRC, 4, pi/4, "gray", "InputType", ...
        "bit", "OutputDataType", "double");

% Объединение символов преамбулы и тела пакета
    Symbols = [PreSymbols; BodySymbols];

% Формирующий фильтр
    PackIQ = upsample(Symbols, sps);
    PackIQ = conv(PackIQ(1:end-(sps-1)), RRC);
