; Преобразование файла из формата BMP в формат PCX (256-цветов на точку).
; Вариант 3

BufSize       EQU     2000      ; размер буфера                                     
BufOffset  EQU   1000           ; Смещение буфера 
.model small	
.data

; BMP заголовок файла
BitmapFileHeader_size EQU 14  ; размер заголока
bfhType dw ?				; тип файла BMP
bfhSize dd ? 				; размер файла в байтах
bfhReser1 dw ? 				; зарезервированные 1
bfhReser2 dw ? 				; зарезервированные 2
bfhOffBits dd ?             ; смещение изображения от начала файла
; Информационный заголовок
BitmapInfoHeader_size EQU 40  ; размер информ.заголовка
bihSize dd ? 				; Длина заголовка
bihWidth dd ? 				; Ширина изображения в пикселях
bihHeight dd ? 				; Высота изображения в пикселях
bihPlanes dw ? 				; Число плоскостей
bihBitCount dw ? 			; Глубина цвета, бит на пиксель
bihCompression dd ? 		; Тип компрессии (0 - несжатое изображение)
bihSizeImage dd ? 			; Размер изображения, байт
bihXPelsPerMeterL dw ?		; Горизонтальное разрешение, пиксель на метр
bihXPelsPerMeterH dw ?	
bihYPelsPerMeterL dw ?		; Вертикальное разрешение, пиксель на метр
bihYPelsPerMeterH dw ?
bihClrUsed dd ? 			; Число используемых цветов (0 - максимально возможное для данной глубины цвета)
bihClrImportant dd ? 		; Число основных цветов

; Заголовок файла PCX
PCXFileHeader_size EQU 128
pcxManufacturer db 10      	; Постоянный флаг 10
pcxVersion db 5       		; 5 = Версия 3.0
pcxEncoding db 1       		; 1 = PCX кодирование длинными сериями
pcxBitsPerLayer db 8       	; Число бит на пиксель в слое
pcxXmin dw 0       		    ; Минимальная координата x положения изображения
pcxYmin dw 0       		    ; Минимальная координата y положения изображения
pcxXmax dw ?       		    ; Максимальная координата x положения изображения
pcxYmax dw ?       		    ; Максимальная координата x положения изображения
pcxHRes dw ?       		    ; Горизонтальное разрешение создающего устройства
pcxVRes dw ?       		    ; Вертикальное разрешение создающего устройства   
pcxColormap db 48 dup(0) 	; Палитра
pcxReserved db 0       		; зарезервированные
pcxNPlanes db 1       		; Число цветовых слоев
pcxBPL dw ?       			; Число байт на строку в цветовом слое (для PCX-файлов всегда должно быть четным)
pcxPalette dw 1       		; Режим построения палитры 
PCXFiller db 58 dup(0) 		; зарезервированные 

BMP_handle dw ?			    ; хэндл файла BMP
PCX_handle dw ?			    ; хэндл файла PCX
empty_bytes db ?       		; кол-во пустых байт в строке BMP файла
rastr_str_size dw ?		    ; длина строки изображения
BMP_fileName db 200 dup(0) 	; название файла BMP
PCX_fileName db 200 dup(0) 	; название файла PCX

msg_openBMPfile db 'Error open BMP-file$'
msg_readBMPfile db 'Error read BMP-file$'
msg_ok db 'Converting completed successfully$'
msg_notBMPfile db 'File is not BMP', 13, 10, '$'
msg_not8bitBMPfile db 'BMP-file is not 8 bit$'
msg_openPCXfile db 'Error open PCX-file$'
msg_closeBMPfile db 'Error close BMP-file$'
msg_closePCXfile db 'Error close PCX-file$'
msg_writePCXfile db 'Error write PCX-file$'



; Буфер
rastr_str db BufSize dup(1) ; буфер для строки изображения
.stack 100h
.code
start:        
        mov     ax, @data                       ; инициализируем регистры
        mov     ds, ax     
        call    read_cmd                        ; процедура обработки параметров cmd
        ; Проедура открытия BMP-файл
        xor     ax, ax                          ; обнуляем регистр
        push    ax                              ; Режим открытия файла, 0 - чтение
        mov     ax, offset BMP_fileName         ; Имя файла
        push    ax                              
        call    open_file                       ; процедура открытия файла
        pop     ax
        and     ax, ax                          ; если 0 
        jz      m_openBMPfile             ; Если произошла ошибка открытия
                                                ; файла, выходим
        jmp     near ptr error_openBMPfile
        m_openBMPfile:
        pop     ax
        ; Производим чтение заголовка BMP-файла
        mov     BMP_handle, ax                  ; хендл файла
        push    ax
        mov     ax, BitmapFileHeader_size       ; размер заголовка
        push    ax
        mov     ax, offset bfhType              ; тип файла
        push    ax
        call    read_file                       ; процедура чтения из файла
        pop     ax
        and     ax,ax                           ; если 0
        jz      m_readBMPfile1            ; Если произошла ошибка чтения файла,
                                                ; выходим
        jmp     near ptr error_readBMPfile
        m_readBMPfile1:

        ; Является ли введнный файл формата BMP
        cmp     word ptr bfhType, 'MB'          ; В памяти младший байт располагается
                                                ; перед старшим
        je      m_notBMPfile              ; если равно
        jmp     near ptr error_notBMPfile       ; иначе ошибка
        m_notBMPfile:
        
        ; Читаем информационный заголовк BMP файла
        mov     ax, BMP_handle                  ; хендл файла
        push    ax
        mov     ax, BitmapInfoHeader_size       ; размер заголовка
        push    ax
        mov     ax, offset bihSize              ; длина заголовка
        push    ax
        call    read_file                       ; чтение заголовка
        pop     ax
        and     ax, ax                          ; если 0
        jz      m_readBMPfile2            ; Если произошла ошибка чтения файла,
                                                ; выходим
        jmp     near ptr error_readBMPfile
        
        m_readBMPfile2:                   ; ошибки не произошло
        
        ; количество бит на пиксель должно быть 8
        
        cmp     word ptr bihBitCount, 0008h     ; в одном пикселе должно быть 8 бит
        je      m_not8bitBMPfile          ; если 8 бит
        jmp     near ptr error_not8bitBMPfile   ; иначе переход на ошибку
        
        m_not8bitBMPfile:

        ; Задаем размер изображения
        mov     ax, word ptr bihHeight          ; высота изображения
        dec     ax                              ; XSIZE = Xmax - Xmin + 1
        mov     pcxYmax, ax                     ; макс. координата у положения изображения
        mov     ax, word ptr bihWidth           ; ширина изображения
        mov     pcxBPL, ax                      ; число байт на строку
        dec     ax                              ; уменьшаем на единицу
        mov     pcxXmax, ax                     ; максимальная координата х положения изображения
        
        
        ; Формируем разрешающую способность, то есть переводим в пиксель на дюйм, из пиксель на метр
        ; В 1 метре 39 дюймов 
        ; Разрешение по горизонтали
        mov     ax, bihXPelsPerMeterL           ; горизонтальное разрешение
        mov     dx, bihXPelsPerMeterH
        mov     bx, 39                          ; округление 1 метра до 39 дюйм
        div     bx                              ; деление без остатка
        mov     pcxHRes, ax                     ; горизонтальное разрешение устройства
        ; Разрешение по вертикали
        mov     ax, bihYPelsPerMeterL           ; вертикальное разрешение
        mov     dx, bihYPelsPerMeterH
        mov     bx, 39                          ; округление 1 метра до 39 дюйм
        div     bx                              ; деление чисел без знака
        mov     pcxVRes, ax                     ; вертикальное разрешение устройства

        ; Создаем и открываем PCX файл
        mov     ax, 0020h                       ; атрибут файла, 5 бит = 1 (архивный бит, если файл не сохранялся)
        push    ax
        mov     ax, offset PCX_fileName         ; адрес имя файла
        push    ax
        call    openwrite_file                  ; процедура открытия файла и запись в него
        pop     ax
        test    ax, ax                          ; если 0 
        jz      m_openPCXfile             ; ошибки не произошло, иначе
        jmp     near ptr error_openPCXfile      ; переход
        m_openPCXfile:
        pop     ax
 
        ; Запись заголовка
        mov     PCX_handle, ax                  ; хендл рсх файла
        push    ax
        mov     ax, PCXFileHeader_size          ; рамер загловока
        push    ax
        mov     ax, offset pcxManufacturer      ; указатель с какого места начнется запись в буфер
        push    ax
        call    write_file                      ; вызов процедуры записи
        pop     ax
        test    ax, ax                          ; если 0
        jz      m_writePCXfile            ; ошибки нет, иначе
        jmp     near ptr error_writePCXfile     ; переход
        m_writePCXfile:
        pop     ax

        ; определяем количество пустых точек в строке 
        mov     ax,  word ptr bihWidth
        mov     bx, 3                           ; длину строки байт * 3 /4, для определения нулевых байт
        mul     bx                              ; умножаем ах * bx
        mov     bx, 4
        div     bx                              ; деление без знака, частное в ах
        mov     empty_bytes, dl                 ; количество пустых байт, в dl
        mov     ax, word ptr bihWidth
        add     ax, dx                          ; суммируем, результат в ах
        mov     rastr_str_size, ax              ; размер строки изображения с учетом пустых байт 
        
        ; указатель должен быть установлен на конец BMP файла
        mov     ax, BMP_handle                  ; хендл файла
        push    ax
        xor     ax, ax
        push    ax                              ; смещение 0 
        push    ax
        mov     ax, 2                           ; 2 = конец файла
        push    ax
        call    mov_file                        ; процедура перемещения курсора
        pop     ax                              ; текущее смещение
        test    ax, ax                          ; если 0, то ошибки нет
        jz      m_readBMPfile5       
        jmp     near ptr error_readBMPfile      ; иначе ошибка
        m_readBMPfile5:
        pop     dx                              ; извлекаем из стека
        pop     cx

        
        mov     cx, word ptr bihHeight          ; количество строк изображения
        
       ; Теперь ставим на предыдущую строку указатель
     loop_h:         
        mov     ax, BMP_handle                  ; запись хендла
        push    ax
        mov     ax, rastr_str_size              ; длина строки изображения
        neg     ax                              ; меняем знак
        push    ax
        cwd                                     ; Получаем отриц число
        push    dx              
        mov     ax, 1                           ; От тек. указателя файла
        push    ax
        call    mov_file                        ; процедура указателя на курсор
        pop     ax                              ; новое смещение
        test    ax, ax                          ; если 0 
        jz      m_readBMPfile3            ; ошибки нет, иначе
        jmp     near ptr error_readBMPfile      ; переход
        m_readBMPfile3:
        pop     dx
        pop     ax
        ; Читаем строку из файла
        mov     ax, BMP_handle                  ; хендл файла
        push    ax
        mov     ax, rastr_str_size              ; длина строки изображения  
        push    ax
        mov     ax, offset rastr_str + BufOffset     ; смещение в буфере
        push    ax
        call    read_file                       ; процедура чтения
        pop     ax                              ; достаем кол-во прочитанных байт   
        test    ax, ax
        jz      m_readBMPfile4
        jmp     near ptr error_readBMPfile
        m_readBMPfile4:
        pop     ax                              ; вернули длину прочитанной строки             
        ;Используем RLE сжатие
        push    ax
        call    compress_rle                    ; процедура конвертирования
        pop     dx                              ; Вернули длину полученной RLE строки
        ; Записываем строку в PCX
        mov     ax, PCX_handle                  ; хендл рсх файла
        push    ax
        mov     ax, dx                          ; длина строки для записи
        push    ax
        mov     ax, offset rastr_str            ; буфер для строки изображения
        push    ax
        call    write_file                      ; процедура записи в файл
        pop     ax                              ; длина записанной строки
        test    ax, ax                          ; если 0
        jz      m_writePCXfile3  
        jmp     near ptr error_writePCXfile  
        m_writePCXfile3:
        pop     ax 
          
        ; Указатель возвращаем обратно
        
        mov     ax, BMP_handle                  ; хендл файла
        push    ax
        mov     ax, rastr_str_size              ; длина строки    
        neg     ax                              ; меняем знак числа
        push    ax
        cwd                                     ; Получаем отриц число и от текущего указателя файла 
        push    dx              
        mov     ax, 1                           ; указатель с текущей позиции        
        push    ax
        call    mov_file                        ; указатель на курсор
        pop     ax                              ; установка смещения
        test    ax, ax
        jz      m_readBMPfile6
        jmp     near ptr error_readBMPfile
        m_readBMPfile6:
        pop     dx
        pop     ax   
        loop    loop_h 

        ; Считываем палитру из BMP и преобразовываем ее в PCX формат
       
        mov     ax, BMP_handle                  ; запись хендла
        push    ax
        mov     ax, 36h                         ; Смещение начала палитры (54)
        push    ax  
        xor     ax, ax                          ; обнуляем
        push    ax
        mov     ax, 0                           ; Относительно начала файла
        push    ax
        call    mov_file                        ; установка курсора
        pop     ax                              ; смещение курсора на начало палитры 
        test    ax, ax
        jnz     error_readBMPfile               ; ошибка чтения файла
        pop     dx
        pop     ax                
        ; Читаем палитру в буфер  BMP
        mov     ax, BMP_handle                  ; хендл файла
        push    ax
        mov     ax, 1024                        ; размер палитры => (256*4)
        push    ax
        mov     ax, offset rastr_str + 4        ; Смещаем палитру в буфере на 4 байта для того, чтобы использовать один буфер для  конвертирования 
        push    ax                     
        call    read_file                       ; вызов процедуры чтения файла
                                       
        pop     ax
        test    ax, ax
        jnz     error_readBMPfile
        pop     ax        
        
        ; Конвертируем в палитру PCX 

        cld                                     ; направление в сторону увеличения адреса
        mov     cx, 256                         ; счетчик повторений
        mov     si, offset rastr_str + 4        ; Палитра смещена в буфере на 4 байта
                                                
        mov     di, offset rastr_str                   
        mov     byte ptr [di], 12               ; начало палитры в PCX 
        inc     di
        palet:
        mov     al, [si]
        inc     si
        mov     ah, [si]
        inc     si
        mov     dl, [si]
        inc     si
        mov     [di], dl
        inc     di
        mov     [di], ah
        inc     di
        mov     [di], al
        inc     di 
        inc     si                              ; Пропускаем байт с кодом 0Ch
        loop    palet
        ; Запись палитры в PCX 
        mov     ax, PCX_handle                  ; вывод данных в PCX файл
        push    ax
        mov     ax, 769                         ; длина строки (байт-метка + 3*256)
        push    ax
        mov     ax, offset rastr_str            ; адрес начала данных, которые записываем в файл
        push    ax
        call    write_file                      ; процедура записи в файл
        pop     ax
        test    ax, ax                          ; если не 0
        jnz     error_writePCXfile              ; ошибка записи в файл
        pop     ax  
        
        ; Закртыие файла BMP
        mov     ax, BMP_handle                  ; в ах кладем хендл bmp файла
        push    ax                              
        call    close_file                      ; вызов процедуры закрытия файла
        pop     ax                              
        test    ax,ax                           ; если флаг нуля не 0
        jnz     error_closeBMPfile              ; перейти на метку ошибки, иначе
        ; Закрытие файла PCX
        mov     ax, PCX_handle                  ; в ах кладем хендл pcx файла
        push    ax                    
        call    close_file                      ; вызов процедуры закрытия файла
        pop     ax                    
        test    ax,ax                           ; если флаг нуля не 0
        jnz     error_closePCXfile              ; перейти на метку ошибку      

        ; Сообщение, если все прошло успешно
        mov     ax, offset msg_ok               ; смещение  msg_ok
        push    ax                              ; запись в стек
        call    print                           ; вызов процедуры вывода на экран
        xor     al, al                          ; Код возврата устанавливаем в 0   
        jmp     gl_exit                         ; переход

        ; Ошибки, которые могут возникнуть
        error_openBMPfile LABEL FAR
        mov     bx, offset msg_openBMPfile
        mov     al, 01                          ; Устанавливаем кода ошибки возврата 1                                    
        jmp     gl_error_print
        error_readBMPfile:
        mov     bx, offset msg_readBMPfile
        mov     al, 02                          ; Устанавливаем кода ошибки возврата 2                                    
        jmp     gl_error_print
        error_notBMPfile:
        mov     bx, offset msg_notBMPfile
        mov     al, 03                          ; Устанавливаем кода ошибки возврата 3                                    
        jmp     gl_error_print
        
        error_not8bitBMPfile:
        mov     bx, offset msg_not8bitBMPfile
        mov     al, 04                          ; Устанавливаем кода ошибки возврата 4                                     
        jmp     gl_error_print
        error_openPCXfile:
        mov     bx, offset msg_openPCXfile
        mov     al, 05                          ; Устанавливаем кода ошибки возврата 5
        jmp     gl_error_print
        error_closeBMPfile:
        mov     bx, offset msg_closeBMPfile
        mov     al, 06                          ; Устанавливаем кода ошибки возврата 6                                      
        jmp     gl_error_print
        error_closePCXfile:
        mov     bx, offset msg_closePCXfile
        mov     al, 07                          ; Устанавливаем кода ошибки возврата 7
        jmp     gl_error_print
        error_writePCXfile:
        mov     bx, offset msg_writePCXfile
        mov     al, 08                          ; Устанавливаем кода ошибки возврата 8
        jmp     gl_error_print
        
        gl_error_print:
        push    bx
        call    print                           ; вызов процедуры вывода на экран
        
        
        gl_exit:
        mov     ah, 4ch                         ; завершение программы
        int     21h 

compress_rle proc near
push bp
mov bp, sp

push si
push di
push dx
push ax
push cx

cld     
mov si, offset rastr_str + BufOffset
mov di, offset ComprData
mov dx, si
add dx, word ptr bihWidth

next_byte:
cmp si, dx
jge rle_exit
mov al, [si]

push cx
mov cx, 1 ; устанавливаем начальное значение счетчика повторений

check_pixels: 
cmp si, dx ; проверяем, не дошли ли мы до конца строки
jge encode_block
inc si
cmp al, [si] ; сравниваем текущий пиксель с следующим
jne encode_block
inc cx ; если пиксели равны, увеличиваем счетчик повторений
cmp cx, 255 ; проверяем, не достигли ли мы максимального значения для счетчика повторений
je encode_block

jmp check_pixels

encode_block:
mov ah, cl
mov al, [si]
mov ch, 0 ; сбрасываем счетчик повторений
mov cl, 1 ; устанавливаем начальное значение для счетчика повторений
mov [di], ah
inc di
mov [di], al
inc di

jmp next_byte

rle_exit:
sub di, offset ComprData
mov [bp+4], di

pop cx
pop cx
pop ax
pop dx
pop di
pop si
pop bp
ret

compress_rle endp


print   proc    near                            ; вывод сообщения
        push    bp                              ; сохраняем значение регистра в стеке
        mov     bp, sp                          ; копируем в него содержимое регистра sp
        push    ax
        push    dx                              ; сохраняем значение регистров в стеке
        mov     ah, 9                           ; функция для вывода строки на экран
        mov     dx, [bp+4]                      ; адрес строки, 1 параметр  
        int     21h
        pop     dx                              ; возвращаем значения регистров
        pop     ax
        pop     bp
        ret    2            
print   endp

 
open_file   proc    near                        ; функция открытия файла
        push    bp                              ; сохраняаем значение
        mov     bp, sp                          ; копируем содержимое в sp
        push    ax                              ; сохранение значений регистров в стеке
        push    dx
        ;
        mov     ah, 3dh                         ; функция для открытия файла
        mov     al, byte ptr [bp+6]             ; файл для чтения, 2 параметр
        mov     dx, [bp+4]                      ; имя файла, 1 параметр
        int     21h
        jnc     fo_no_error                     ; перенос не установлен
        mov     word ptr [bp+4], 1              ; CF = 1
        jmp     exit
        fo_no_error:
        mov     word ptr [bp+4], 0              ; CF = 0
        exit:
        mov     [bp+6], ax
        pop     dx                              ; восстановление регистров
        pop     ax
        pop     bp
        ret
open_file   endp


openwrite_file  proc    near                    ; создание и открытие файла
        push    bp
        mov     bp, sp
        push    ax                              ; сохранение регистро в стеке
        push    dx    
        mov     ah, 3ch                         ; функция создания и открытия файла
        mov     cx, [bp+6]                      ; атрибут файла, 2 параметр
        mov     dx, [bp+4]                      ; имя файла, 1 параметр
        int     21h
        jnc     fow_no_error                    ; переход если флаг переноса не установлен
        mov     word ptr [bp+4], 1              ; CF = 1
        jmp     fow_exit
        fow_no_error:
        mov     word ptr [bp+4], 0              ; CF = 0
        fow_exit:
        mov     [bp+6], ax
        pop     dx                              ; восстановление регистров
        pop     ax
        pop     bp
        ret
openwrite_file  endp


close_file  proc    near                        ; закрытие файлов
        push    bp
        mov     bp, sp
        push    ax                              ; сохраняем регистры в стеке
        push    bx
        mov     ah, 3eh                         ; функция закрытия файла
        mov     bx, [bp+4]                      ; хендл файла
        int     21h
        jnc     fcl_no_error                    ; перенос не произошел
        mov     word ptr [bp+4], 1              ; CF = 1
        jmp     fcl_exit
        fcl_no_error:
        mov     word ptr [bp+4], 0              ; CF = 0
        fcl_exit:
        pop     bx                              ; восстановление регистров
        pop     ax
        pop     bp
        ret
close_file  endp


mov_file    proc    near                        ; установка указателя в файле
        push    bp
        mov     bp, sp
        push    ax                              ; сохранение регистров в стек
        push    bx
        push    cx
        push    dx
        mov     ax, [bp+4]                      ; метод курсора
        mov     ah, 42h                         ; функция перемещения в файле
        mov     bx, [bp+10]                     ; хендл файла
        mov     cx, [bp+6]                      ; смещение 32 разрядное, это старшая часть
        mov     dx, [bp+8]                      ; смещение младшая часть
        int     21h

        jnc     fm_no_error                     ; перенос не установлен
        mov     word ptr [bp+6], 1              ; CF = 1 
        jmp     fm_exit
        fm_no_error:                
        mov     word ptr [bp+6], 0              ; CF = 0
        mov     [bp+8], dx                      ; новое смещение, старшая часть
        mov     [bp+10], ax                     ; младшая часть
        fm_exit:                                ; завершение процедуры
        pop     dx                              ; восстановление регистров
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        ;
        ret     2
mov_file   endp


read_file   proc    near                        ; чтение файла
        push    bp
        mov     bp, sp
        push    ax                              ; сохраняем регистры в стеке
        push    bx
        push    cx
        push    dx
        xor     ax, ax
        mov     ah, 3fh                         ; функция чтения файла
        mov     bx, [bp+8]                      ; идентификатор файла
        mov     cx, [bp+6]                      ; число байтов
        mov     dx, [bp+4]                      ; адрес буфера для приема данных
        int     21h                             ; вызов прерывания
        jnc     fr_no_error                     ; перенос не произошел
        mov     word ptr [bp+6], 1              ; CF = 1
        jmp     fr_exit
        fr_no_error:
        mov     word ptr [bp+6], 0              ; CF = 0
        fr_exit:
        mov     [bp+8], ax                      ; кол-во прочитанных байт
        pop     dx                              ; восстановление регистров
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        ret 2
read_file   endp


write_file  proc    near                        ; запись в файл
        push    bp
        mov     bp, sp
        push    ax                              ; сохраняем регистры в стеке
        push    bx
        push    cx
        push    dx
        ;
        xor     ax, ax
        mov     ah, 40h                         ; функция записи в файл
        mov     bx, [bp+8]                      ; хендл файла 
        mov     cx, [bp+6]                      ; кол-во байт для записи
        mov     dx, [bp+4]                      ; указатель на буфер
        int     21h                          
        jnc     fw_no_error                     ; перенос не произошел
        mov     word ptr [bp+6], 1              ; CF = 1
        jmp     fw_exit
        fw_no_error:
        mov     word ptr [bp+6], 0              ; CF = 0
        fw_exit:
        mov     [bp+8], ax                      ; число прочитанных байт
        pop     dx                              ; восстанавливаем регистры
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        ret 2
write_file  endp


read_cmd PROC                              ; использование параметров командой строки
	xor cx,cx                                   ; очищаем сх
	mov si, 0                                   ; инициализировать смещения на 0
        
    mov cl, [es:80h]                            ; длина командной строки
    dec cl
    push cx
       
param_str:
    mov al, [es:82h+si]                         ; обращаемся к символу в командной строке после пробела
    mov BMP_fileName[si], al                    ; записываем символ в строку названия файла BMP
    inc si                                      ; переход к следующему символу
    loop param_str                              ; пока cx не 0 продолжать цикл
        
    pop si                                      ; извлекаем регистры из стека
    push si
    mov cx, si
        
    mov ax, @data 
    mov es, ax
        
    mov si,offset BMP_fileName 
    mov di,offset PCX_fileName
    rep movsb                                   ; копируем символы строки имя BMP-файла
        
    pop si
    
       
    mov PCX_fileName[si-3], 'p'                 ; замена символов в формате файла
    mov PCX_fileName[si-2], 'c'        
    mov PCX_fileName[si-1], 'x'
	ret
read_cmd endp
end start
