% Реализовать пакетную передачу даннных
%
% Формат данных: текстовая информация 
%
% Параметры системы передачи:
% 1. QPSK модуляция
% 2. Битовая скорость: 1 Мб/с (Символьная: 500 кСимв/c) 
% 3. Формирующий фильтр RRC (beta = 0.35)
% 
% Формат пакета:
%   1. Преамбула  
%   2. Номер пакета
%   3. Количество пакетов
%   4. Данные
%   5. CRC
% 
% Задачи решаемые приемником (требования): 
%   1. Частоная синхронизация по преамбуле
%   2. фазовая синхронизация по преамбуле
%   3. Хорошие корреляционные свойства преамбулы
%
% Допущения: 
% Частотный сдвиг случайный, а фазовый известен заранее 

clc; clear; close all;

%% Параметры моделирования
    % Необходимость сохранения в файл передаваемого сообщения
        SaveTxSig = 0;
    % Число передаемых бит в сообщении
        BitPerMessage = 1024 * 2;
    % Число передаваемых бит в одном пакете
        BitPerPack = 1024;
    % Битовая скорость
        BitRate    = 1e6;
    % Длина преамбулы (синхропоследовательности)
        PreLen     = 2^7 - 1;
    % Начальная фаза 
        IniPhase   = pi/3;
    % Порядок модуляции
        M = 4;

    % Параметры RRC фильтра
        % Коэффициент сглаживания
            beta = 0.5;
        % Символьная скорость (отсчеты на символ)
            sps  = 20;
        % Длительность ИХ фильтра
            span = 10;

    % Параметры для генерации АБГШ
        % Отношение энергии бита к СПМ шума, дБ
            EbNo = 10;

    % Вычисляемые параметры
        % Энергия бита 
            Eb = 1 / log2(M);
        % Символьная скорость QPSK
            BaudRate = BitRate / 2;
        % Частота дискретизации
            Fs = BaudRate * sps;
        % Период дискретизации
            Ts = 1/Fs;
        % Импульс RRC 
            PulseRRC = rcosdesign(beta, span, sps);
        % Дисперсия шума
            No = Eb / 10^(EbNo/10);
        % Частотный сдвиг
            freqOffset = 1 * (40e3 * rand() - 20e3);
        % Фазовый сдвиг 
            phiOffset  = 2*pi*rand() - pi;
        % Количество пакетов необходимых для передачи сообщения
            NumberOfPackages = ceil(BitPerMessage/BitPerPack);

%% Формирование передаваемого сообщения (несколько пакетов в общем случае)
    % Генерация входного потока данных
        InputBits  = randi([0 1], BitPerMessage, 1);
    % Инициализация cell-массива для хранения внутри него пакетов
        TxPackages = cell(NumberOfPackages, 1);
    
    % Цикл формирования пакетов
        for packIdx = 1 : NumberOfPackages
            % Определение индексов бит текущего пакета
            startIdx = (packIdx - 1) * BitPerPack + 1;
            endIdx   = min(packIdx*BitPerPack, BitPerMessage);

            % Выбор бит для текущего пакета
            CurrentBits = InputBits(startIdx:endIdx);

            % Формирование пакета
            TxPackages{packIdx} = FormPackage(CurrentBits, BitPerPack, ...
                M, IniPhase, PreLen, sps, PulseRRC, packIdx);
        end

    % Объединение пакетов в один сигнал
        TxSig = [];

        for i = 1 : length(TxPackages)
            TxSig = [TxSig; TxPackages{i}];
        end

    % Сохранение сигнала в файл
        if isequal(SaveTxSig, 1)
            SaveSignalToFile(TxSig, Fs, ...
                'C:\Users\dmitk\OneDrive\Рабочий стол\Учеба\Семестр 9\SDR\Модели MATLAB\ЛР2\TxSig4Vasyao');
        end

%% Канал передачи 
    % Расчет длины одного пакета в отсчетах  
        PackLen = length(TxPackages{1});

    % Прохождение сигнала через канал 
        RxSig = TransmitionChannel(TxSig, PackLen, NumberOfPackages, ...
            Ts, freqOffset, phiOffset, No);

%% Приемная часть 
    % Преамбула
        Preamble = GeneratePreambule(PreLen);
    % Согласованная фильтрация
        FiltSig = conv(RxSig, PulseRRC);
        FiltSigLen = length(FiltSig);

    % Параметры для многопакетной обработки
        % Выделение памяти под принятые биты
            AllOutputBits  = [];
        % Текущая позиция в сигнале
            CurrentSample  = 1;
        % Счетчик найденных пакетов
            DetectPackages = 0;

    while DetectPackages < NumberOfPackages && CurrentSample < FiltSigLen
        % Обнаружение отсчета сигнала, с которого начинается пакет
        % Формирование частотной сетки
            fVals1 = [(0:3480:20e3), 20e3];
            fVals1 = [fliplr(-fVals1(2:end)) fVals1];
        % Количество отсчетов внутри частотной сетки
            fVLen1 = length(fVals1);

        % Формирование опорных последовательностей для разных сдвигов по 
        % частоте
            RefSeqs1    = zeros(PreLen * sps, fVLen1);
        % Сэмплирование преамбулы
            PreUpsample = upsample(Preamble, sps);

        % Цикл по частотным отсчетам
            for i = 1 : fVLen1
                RefSeqs1(:, i) = PreUpsample .* ...
                    exp(1j*2*pi*fVals1(i) * (0:PreLen * sps - 1)' * Ts);
            end

        % Корреляция принятого сигнала с опорными последовательностями с
        % текущего отсчета
            CurrentSignal = FiltSig(CurrentSample:end);
            corrRes1 = ...
                zeros(length(CurrentSignal) - size(RefSeqs1, 1)+1, fVLen1);

            for i = 1 : fVLen1
                corrRes1(:,i) = conv(CurrentSignal, ...
                    flipud(conj(RefSeqs1(:, i))), "valid");
            end            

        % Определение индекса глобального максимума среди корреляций 
            [MaxAbs, Inds]      = max(abs(corrRes1));
            [~, freqOffsetInd1] = max(MaxAbs);
            PackageBeginSample  = Inds(freqOffsetInd1) + CurrentSample - 1;

        % Грубая частотная подстройка
            timeVector = (0:FiltSigLen-1)' * Ts;
            freqShift = -1j*2*pi*fVals1(freqOffsetInd1) * timeVector;
            SignalTuned1 = FiltSig .* exp(freqShift);

        % Частотная синхронизация пакета 
            SyncSig = SignalTuned1(PackageBeginSample:end);

        % Расчет длины пакета с учетом полей 
            ExpectedSymbols = PreLen + 16/2 + 16/2 + (BitPerPack+16)/2;
            
        % Условие на то, что следующий пакет не окажется обрезан 
            if length(SyncSig) >= ExpectedSymbols * sps
                % Выбор модуляционных символов
                    RxPackageSymbols = SyncSig(1:sps:sps*ExpectedSymbols);
 
                % Точная частотная подстройка
                    % Принятая преамбула с грубой частотной подстрой
                        RxPreamble = RxPackageSymbols(1:PreLen);

                    % Формирование частотной сетки 
                        fVals2 = (0:20:3480/2);
                        fVals2 = [fliplr(-fVals2(2:end)) fVals2];
                        fVLen2 = length(fVals2);
                    
                    % Формирование оп. пос-ей для разных сдвигов по частоте
                        RefSeqs2 = zeros(PreLen, fVLen2);
            
                        for i = 1:fVLen2
                            RefSeqs2(:, i) = Preamble .* ...
                                exp(1j*2*pi*fVals2(i) * (0:PreLen-1)' / ...
                                BaudRate);
                        end

                    % Корреляция принятой преамбулы с опорными сигналами
                        corrRes2 = zeros(1, fVLen2);
            
                        for i = 1:fVLen2
                            corrRes2(i) = ...
                                sum(RxPreamble .* conj(RefSeqs2(:,i)));
                        end
                    % Определение частотной остройки
                        [~, freqOffsetInd2] = max(abs(corrRes2));   

                    % Подстройка частоты
                        RxPackageSymbolsFreqTuned = RxPackageSymbols .* ...
                            exp(-1j*2*pi*fVals2(freqOffsetInd2) * ...
                            (0:length(RxPackageSymbols)-1)' / BaudRate);
                    % Синхронизация фазы 
                        PhiEstimate = ...
                            angle(sum(RxPackageSymbolsFreqTuned(1:PreLen) ...
                            .* conj(Preamble)));
                    % Подстройка фазы
                        RxPackageSymbolsFreqTuned = ...
                            RxPackageSymbolsFreqTuned * ...
                            exp(-1j * PhiEstimate);

                % Извлечение полей номера и размера пакета
                    PackageNumbSymb = ...
                        RxPackageSymbolsFreqTuned(PreLen+1:PreLen+8);
                    PackageSizeSymb = ...
                        RxPackageSymbolsFreqTuned(PreLen+9:PreLen+16);
                % Демодуляция полей номера и размера пакета
                    PackageNumbBits = ...
                        pskdemod(PackageNumbSymb, M, IniPhase, ...
                        "gray","OutputType","bit");
                    PackageSizeBits = ...
                         pskdemod(PackageSizeSymb, M, IniPhase, ...
                        "gray","OutputType","bit");                       
                % Перевод в десятичную СС
                    PackageNumb = bi2de(PackageNumbBits', 'left-msb');
                    PackageSize = bi2de(PackageSizeBits', 'left-msb');

                % Демодуляция данных
                    DataSymb = RxPackageSymbolsFreqTuned(PreLen + 17:end);
                    OutputBits = pskdemod(DataSymb, M, IniPhase, ...
                        "gray","OutputType","bit");

                % Обрезка пакета до фактического размера (если он был
                % дополен при передаче)
                    if PackageSize < length(OutputBits)
                        OutputBits = OutputBits(1:PackageSize);
                    end
                
                % Формирование переданного сообщения
                    AllOutputBits = [AllOutputBits; OutputBits];
                    DetectPackages = DetectPackages + 1;

                % Переход к следующему пакету
                    CurrentSample = ...
                        PackageBeginSample + ExpectedSymbols * sps + PackLen;
            else
                fprintf('Пакет %d слишком короткий, поиск прекращен\n', DetectPackages+1);
                break;
            end
    end

    fprintf('Обработано пакетов: %d из %d\n', DetectPackages, NumberOfPackages);
    disp(sum(InputBits == AllOutputBits));

    % Выбор модуляционных символов 
        %RxPackageSymbols = SyncSig(1:sps:sps*(PreLen + (BitPerPack+16)/2)); % +16 бит CRC

    % Точная частотная подстройка
        % Принятая преамбула с грубой частотной подстройкой
            % RxPreamble = RxPackageSymbols(1:PreLen);

        % % Формирование частотной сетки 
        %     fVals2 = (0:20:3480/2);
        %     fVals2 = [fliplr(-fVals2(2:end)) fVals2];
        %     fVLen2 = length(fVals2);




    % % Демодуляция 
    %     OutputBits = pskdemod(RxPackageSymbolsFreqTuned(PreLen+1:end), ...
    %         M, IniPhase, "gray", "OutputType", "bit");


            

    % % Формирование преамбулы 
    %     Preamble = (1 + 1j) * mlseq(PreLen);
    % % Добавление бит CRC ко входному потоку данных
    %     InputBitsWithCRC = crcGen(InputBits);
    % % Модуляция PSK входного потока бит
    %     Symbols  = ...
    %         pskmod(InputBitsWithCRC, M, IniPhase, "gray", "InputType","bit");
    % % Объединение символов и преамбулы в один пакет
    %     SymbPack = [Preamble; Symbols];
    % 
    % % Формирование сигнала 
    %     SymbPackUpsampled = upsample(SymbPack, sps);
    %     TxSig = conv(SymbPackUpsampled(1:end - (sps - 1)), PulseRRC);


    % % Разделение пакетов - добавление нулей 
    %     RxSig = [zeros(size(TxSig)); TxSig; zeros(size(TxSig))];
    % % Отсройка по частоте
    %     RxSig = RxSig .* ...
    %         exp(1j * 2*pi * freqOffset * (0 : length(RxSig) - 1).' * Ts);
    % % Отстройка по фазе
    %     RxSig = RxSig * exp(1j * phiOffset);
    % 
    % % АБГШ
    %     % Генерация шума
    %         Noise = randn(length(RxSig), 2) * [1; 1j];
    %         Noise = Noise * sqrt(No/2);
    %     % Добавление шума к сигналу 
    %         RxSig = RxSig + Noise;

    %     % Повышение частоты дискретизации до рабочей при необходимости
    % if Fs < 10e6
    %     Buf = resample(TxSig, 10e6, Fs);
    % else
    %     Buf = TxSig;
    % end
    % 
    % % Запись в файл
    % IQ2BinData = zeros(2 * length(int8(real(Buf))), 1, 'int8');
    % IQ2BinData(1:2:end) = int8(real(Buf));
    % IQ2BinData(2:2:end) = int8(imag(Buf));
    % 
    % fid = fopen('C:\Users\dmitk\OneDrive\Рабочий стол\Учеба\Семестр 9\SDR\Модели MATLAB\ЛР2\TxSig4Vasyao', 'w');
    % 
    % if fid == -1
    %     error('Не удалось открыть файл для записи')
    % end
    % 
    % fwrite(fid, IQ2BinData, 'int8');
    % fclose(fid);
    % clear Buf;