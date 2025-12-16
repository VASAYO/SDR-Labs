function IQ = IQFromBinInt8( Path )

% Открываем файл
    fid = fopen( Path, "r" );

if fid < 1
    error('%s IQFromBinInt8: Не удалось открыть файл в режиме записи', ...
                datestr(now));
end

% Считываем содержимое и закрываем файл
    Buf = fread( fid, +inf, "int8" );
    fclose( fid );

% Форматируем сигнал
    Buf = reshape( Buf, 2, [] );
    IQ = Buf( 1, : )' + 1j * Buf( 2, : )';
