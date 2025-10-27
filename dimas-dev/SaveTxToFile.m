function SaveTxToFile(TxSig, Fs, filename)
% Функция сохраняет передаваемые пакеты в файл для дальнейшей передачи
% через SDR
%   
% Входные аргументы:
%   TxSig    - передаваемый сигнал, который необходимо сохранить;
%   Fs       - частота дискретизации сигнала; 
%   filename - путь к файлу для сохранения.

% Повышение частоты дискретизации до рабочей SDR при необходимости 
    if Fs < 10e6
        Buf = resample(TxSig, 10e6, Fs);
    else
        Buf = TxSig;
    end
    
    % Запись в файл
    IQ2BinData = zeros(2 * length(int8(real(Buf))), 1, 'int8');
    IQ2BinData(1:2:end) = int8(real(Buf));
    IQ2BinData(2:2:end) = int8(imag(Buf));

    fid = fopen(filename, 'w');
    
    if fid == -1
        error('Не удалось открыть файл для записи: %s', filename)
    end

    fwrite(fid, IQ2BinData, 'int8');
    fclose(fid);
    clear Buf;

    fprintf('Сигнал сохранен в: %s\n', filename);
end


