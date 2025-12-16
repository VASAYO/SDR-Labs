function Symbols = Gen_Frame( Data, Par )
% Функция генерирует кадр по структуре, описанной в Generate_Tx_Signal.m
%
% Data - массив-столбец бит размера не менее 1 и не более 4096;
% Par  - структура параметров, сформированная в Generate_Tx_Signal.m;

% Отсчёты маркера
    Marker = mlseq( Par.Frame.LenMarker ) * ( 1 + 1j ) / sqrt( 2 );

% Число информационных бит в кадре
    NumBits = length( Data );

% Поле длины
    FieldLen = int2bit( NumBits, Par.Frame.LenLength, true );

% Поле данных
    FieldData = [ Data; zeros( Par.Frame.LenData - NumBits, 1 ) ];

% Объединение двух полей
    TwoFields = [ FieldLen; FieldData ];

% Вычисление CRC
    AllFields = crcGenerate( TwoFields, crcConfig() );

% Модуляция
    SymbolsFields = pskmod( AllFields, Par.Mod.Order, ...
        Par.Mod.PhaseOffset, "gray", "InputType", "bit" );

% Добавление в начале маркера
    Symbols = [ Marker; SymbolsFields ];
