function IQ2BinInt8(IQ, Path)
%IQ2BIN Summary of this function goes here
%   Detailed explanation goes here

if ~isrow(IQ)
    IQ = IQ(:);
end

% Масштабирование по уровню
    RefLevel = 127;
    ScaleFactor = RefLevel / ...
        max([abs(real(IQ)) abs(imag(IQ))], [], 'all');
    
    Buf = IQ * ScaleFactor;

% Форматирование отсчётов для записи в файл
    Buf = [real(Buf), imag(Buf)].';
    Buf = Buf(:);

% Запись в файл
    fid = fopen(Path, 'w');
    
    if fid == -1
        error('%s IQ2BinInt8: Не удалось открыть файл в режиме записи', ...
            datestr(now));
    end
    
    fwrite(fid, Buf, "int8");
    fclose(fid);
