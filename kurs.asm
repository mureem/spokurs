; �������������� ����� �� ������� BMP � ������ PCX (256-������ �� �����).
; ������� 3

BufSize       EQU     2000      ; ������ ������                                     
BufOffset  EQU   1000           ; �������� ������ 
.model small	
.data

; BMP ��������� �����
BitmapFileHeader_size EQU 14  ; ������ ��������
bfhType dw ?				; ��� ����� BMP
bfhSize dd ? 				; ������ ����� � ������
bfhReser1 dw ? 				; ����������������� 1
bfhReser2 dw ? 				; ����������������� 2
bfhOffBits dd ?             ; �������� ����������� �� ������ �����
; �������������� ���������
BitmapInfoHeader_size EQU 40  ; ������ ������.���������
bihSize dd ? 				; ����� ���������
bihWidth dd ? 				; ������ ����������� � ��������
bihHeight dd ? 				; ������ ����������� � ��������
bihPlanes dw ? 				; ����� ����������
bihBitCount dw ? 			; ������� �����, ��� �� �������
bihCompression dd ? 		; ��� ���������� (0 - �������� �����������)
bihSizeImage dd ? 			; ������ �����������, ����
bihXPelsPerMeterL dw ?		; �������������� ����������, ������� �� ����
bihXPelsPerMeterH dw ?	
bihYPelsPerMeterL dw ?		; ������������ ����������, ������� �� ����
bihYPelsPerMeterH dw ?
bihClrUsed dd ? 			; ����� ������������ ������ (0 - ����������� ��������� ��� ������ ������� �����)
bihClrImportant dd ? 		; ����� �������� ������

; ��������� ����� PCX
PCXFileHeader_size EQU 128
pcxManufacturer db 10      	; ���������� ���� 10
pcxVersion db 5       		; 5 = ������ 3.0
pcxEncoding db 1       		; 1 = PCX ����������� �������� �������
pcxBitsPerLayer db 8       	; ����� ��� �� ������� � ����
pcxXmin dw 0       		    ; ����������� ���������� x ��������� �����������
pcxYmin dw 0       		    ; ����������� ���������� y ��������� �����������
pcxXmax dw ?       		    ; ������������ ���������� x ��������� �����������
pcxYmax dw ?       		    ; ������������ ���������� x ��������� �����������
pcxHRes dw ?       		    ; �������������� ���������� ���������� ����������
pcxVRes dw ?       		    ; ������������ ���������� ���������� ����������   
pcxColormap db 48 dup(0) 	; �������
pcxReserved db 0       		; �����������������
pcxNPlanes db 1       		; ����� �������� �����
pcxBPL dw ?       			; ����� ���� �� ������ � �������� ���� (��� PCX-������ ������ ������ ���� ������)
pcxPalette dw 1       		; ����� ���������� ������� 
PCXFiller db 58 dup(0) 		; ����������������� 

BMP_handle dw ?			    ; ����� ����� BMP
PCX_handle dw ?			    ; ����� ����� PCX
empty_bytes db ?       		; ���-�� ������ ���� � ������ BMP �����
rastr_str_size dw ?		    ; ����� ������ �����������
BMP_fileName db 200 dup(0) 	; �������� ����� BMP
PCX_fileName db 200 dup(0) 	; �������� ����� PCX

msg_openBMPfile db 'Error open BMP-file$'
msg_readBMPfile db 'Error read BMP-file$'
msg_ok db 'Converting completed successfully$'
msg_notBMPfile db 'File is not BMP', 13, 10, '$'
msg_not8bitBMPfile db 'BMP-file is not 8 bit$'
msg_openPCXfile db 'Error open PCX-file$'
msg_closeBMPfile db 'Error close BMP-file$'
msg_closePCXfile db 'Error close PCX-file$'
msg_writePCXfile db 'Error write PCX-file$'



; �����
rastr_str db BufSize dup(1) ; ����� ��� ������ �����������
.stack 100h
.code
start:        
        mov     ax, @data                       ; �������������� ��������
        mov     ds, ax     
        call    read_cmd                        ; ��������� ��������� ���������� cmd
        ; �������� �������� BMP-����
        xor     ax, ax                          ; �������� �������
        push    ax                              ; ����� �������� �����, 0 - ������
        mov     ax, offset BMP_fileName         ; ��� �����
        push    ax                              
        call    open_file                       ; ��������� �������� �����
        pop     ax
        and     ax, ax                          ; ���� 0 
        jz      m_openBMPfile             ; ���� ��������� ������ ��������
                                                ; �����, �������
        jmp     near ptr error_openBMPfile
        m_openBMPfile:
        pop     ax
        ; ���������� ������ ��������� BMP-�����
        mov     BMP_handle, ax                  ; ����� �����
        push    ax
        mov     ax, BitmapFileHeader_size       ; ������ ���������
        push    ax
        mov     ax, offset bfhType              ; ��� �����
        push    ax
        call    read_file                       ; ��������� ������ �� �����
        pop     ax
        and     ax,ax                           ; ���� 0
        jz      m_readBMPfile1            ; ���� ��������� ������ ������ �����,
                                                ; �������
        jmp     near ptr error_readBMPfile
        m_readBMPfile1:

        ; �������� �� �������� ���� ������� BMP
        cmp     word ptr bfhType, 'MB'          ; � ������ ������� ���� �������������
                                                ; ����� �������
        je      m_notBMPfile              ; ���� �����
        jmp     near ptr error_notBMPfile       ; ����� ������
        m_notBMPfile:
        
        ; ������ �������������� �������� BMP �����
        mov     ax, BMP_handle                  ; ����� �����
        push    ax
        mov     ax, BitmapInfoHeader_size       ; ������ ���������
        push    ax
        mov     ax, offset bihSize              ; ����� ���������
        push    ax
        call    read_file                       ; ������ ���������
        pop     ax
        and     ax, ax                          ; ���� 0
        jz      m_readBMPfile2            ; ���� ��������� ������ ������ �����,
                                                ; �������
        jmp     near ptr error_readBMPfile
        
        m_readBMPfile2:                   ; ������ �� ���������
        
        ; ���������� ��� �� ������� ������ ���� 8
        
        cmp     word ptr bihBitCount, 0008h     ; � ����� ������� ������ ���� 8 ���
        je      m_not8bitBMPfile          ; ���� 8 ���
        jmp     near ptr error_not8bitBMPfile   ; ����� ������� �� ������
        
        m_not8bitBMPfile:

        ; ������ ������ �����������
        mov     ax, word ptr bihHeight          ; ������ �����������
        dec     ax                              ; XSIZE = Xmax - Xmin + 1
        mov     pcxYmax, ax                     ; ����. ���������� � ��������� �����������
        mov     ax, word ptr bihWidth           ; ������ �����������
        mov     pcxBPL, ax                      ; ����� ���� �� ������
        dec     ax                              ; ��������� �� �������
        mov     pcxXmax, ax                     ; ������������ ���������� � ��������� �����������
        
        
        ; ��������� ����������� �����������, �� ���� ��������� � ������� �� ����, �� ������� �� ����
        ; � 1 ����� 39 ������ 
        ; ���������� �� �����������
        mov     ax, bihXPelsPerMeterL           ; �������������� ����������
        mov     dx, bihXPelsPerMeterH
        mov     bx, 39                          ; ���������� 1 ����� �� 39 ����
        div     bx                              ; ������� ��� �������
        mov     pcxHRes, ax                     ; �������������� ���������� ����������
        ; ���������� �� ���������
        mov     ax, bihYPelsPerMeterL           ; ������������ ����������
        mov     dx, bihYPelsPerMeterH
        mov     bx, 39                          ; ���������� 1 ����� �� 39 ����
        div     bx                              ; ������� ����� ��� �����
        mov     pcxVRes, ax                     ; ������������ ���������� ����������

        ; ������� � ��������� PCX ����
        mov     ax, 0020h                       ; ������� �����, 5 ��� = 1 (�������� ���, ���� ���� �� ����������)
        push    ax
        mov     ax, offset PCX_fileName         ; ����� ��� �����
        push    ax
        call    openwrite_file                  ; ��������� �������� ����� � ������ � ����
        pop     ax
        test    ax, ax                          ; ���� 0 
        jz      m_openPCXfile             ; ������ �� ���������, �����
        jmp     near ptr error_openPCXfile      ; �������
        m_openPCXfile:
        pop     ax
 
        ; ������ ���������
        mov     PCX_handle, ax                  ; ����� ��� �����
        push    ax
        mov     ax, PCXFileHeader_size          ; ����� ���������
        push    ax
        mov     ax, offset pcxManufacturer      ; ��������� � ������ ����� �������� ������ � �����
        push    ax
        call    write_file                      ; ����� ��������� ������
        pop     ax
        test    ax, ax                          ; ���� 0
        jz      m_writePCXfile            ; ������ ���, �����
        jmp     near ptr error_writePCXfile     ; �������
        m_writePCXfile:
        pop     ax

        ; ���������� ���������� ������ ����� � ������ 
        mov     ax,  word ptr bihWidth
        mov     bx, 3                           ; ����� ������ ���� * 3 /4, ��� ����������� ������� ����
        mul     bx                              ; �������� �� * bx
        mov     bx, 4
        div     bx                              ; ������� ��� �����, ������� � ��
        mov     empty_bytes, dl                 ; ���������� ������ ����, � dl
        mov     ax, word ptr bihWidth
        add     ax, dx                          ; ���������, ��������� � ��
        mov     rastr_str_size, ax              ; ������ ������ ����������� � ������ ������ ���� 
        
        ; ��������� ������ ���� ���������� �� ����� BMP �����
        mov     ax, BMP_handle                  ; ����� �����
        push    ax
        xor     ax, ax
        push    ax                              ; �������� 0 
        push    ax
        mov     ax, 2                           ; 2 = ����� �����
        push    ax
        call    mov_file                        ; ��������� ����������� �������
        pop     ax                              ; ������� ��������
        test    ax, ax                          ; ���� 0, �� ������ ���
        jz      m_readBMPfile5       
        jmp     near ptr error_readBMPfile      ; ����� ������
        m_readBMPfile5:
        pop     dx                              ; ��������� �� �����
        pop     cx

        
        mov     cx, word ptr bihHeight          ; ���������� ����� �����������
        
       ; ������ ������ �� ���������� ������ ���������
     loop_h:         
        mov     ax, BMP_handle                  ; ������ ������
        push    ax
        mov     ax, rastr_str_size              ; ����� ������ �����������
        neg     ax                              ; ������ ����
        push    ax
        cwd                                     ; �������� ����� �����
        push    dx              
        mov     ax, 1                           ; �� ���. ��������� �����
        push    ax
        call    mov_file                        ; ��������� ��������� �� ������
        pop     ax                              ; ����� ��������
        test    ax, ax                          ; ���� 0 
        jz      m_readBMPfile3            ; ������ ���, �����
        jmp     near ptr error_readBMPfile      ; �������
        m_readBMPfile3:
        pop     dx
        pop     ax
        ; ������ ������ �� �����
        mov     ax, BMP_handle                  ; ����� �����
        push    ax
        mov     ax, rastr_str_size              ; ����� ������ �����������  
        push    ax
        mov     ax, offset rastr_str + BufOffset     ; �������� � ������
        push    ax
        call    read_file                       ; ��������� ������
        pop     ax                              ; ������� ���-�� ����������� ����   
        test    ax, ax
        jz      m_readBMPfile4
        jmp     near ptr error_readBMPfile
        m_readBMPfile4:
        pop     ax                              ; ������� ����� ����������� ������             
        ;���������� RLE ������
        push    ax
        call    compress_rle                    ; ��������� ���������������
        pop     dx                              ; ������� ����� ���������� RLE ������
        ; ���������� ������ � PCX
        mov     ax, PCX_handle                  ; ����� ��� �����
        push    ax
        mov     ax, dx                          ; ����� ������ ��� ������
        push    ax
        mov     ax, offset rastr_str            ; ����� ��� ������ �����������
        push    ax
        call    write_file                      ; ��������� ������ � ����
        pop     ax                              ; ����� ���������� ������
        test    ax, ax                          ; ���� 0
        jz      m_writePCXfile3  
        jmp     near ptr error_writePCXfile  
        m_writePCXfile3:
        pop     ax 
          
        ; ��������� ���������� �������
        
        mov     ax, BMP_handle                  ; ����� �����
        push    ax
        mov     ax, rastr_str_size              ; ����� ������    
        neg     ax                              ; ������ ���� �����
        push    ax
        cwd                                     ; �������� ����� ����� � �� �������� ��������� ����� 
        push    dx              
        mov     ax, 1                           ; ��������� � ������� �������        
        push    ax
        call    mov_file                        ; ��������� �� ������
        pop     ax                              ; ��������� ��������
        test    ax, ax
        jz      m_readBMPfile6
        jmp     near ptr error_readBMPfile
        m_readBMPfile6:
        pop     dx
        pop     ax   
        loop    loop_h 

        ; ��������� ������� �� BMP � ��������������� �� � PCX ������
       
        mov     ax, BMP_handle                  ; ������ ������
        push    ax
        mov     ax, 36h                         ; �������� ������ ������� (54)
        push    ax  
        xor     ax, ax                          ; ��������
        push    ax
        mov     ax, 0                           ; ������������ ������ �����
        push    ax
        call    mov_file                        ; ��������� �������
        pop     ax                              ; �������� ������� �� ������ ������� 
        test    ax, ax
        jnz     error_readBMPfile               ; ������ ������ �����
        pop     dx
        pop     ax                
        ; ������ ������� � �����  BMP
        mov     ax, BMP_handle                  ; ����� �����
        push    ax
        mov     ax, 1024                        ; ������ ������� => (256*4)
        push    ax
        mov     ax, offset rastr_str + 4        ; ������� ������� � ������ �� 4 ����� ��� ����, ����� ������������ ���� ����� ���  ��������������� 
        push    ax                     
        call    read_file                       ; ����� ��������� ������ �����
                                       
        pop     ax
        test    ax, ax
        jnz     error_readBMPfile
        pop     ax        
        
        ; ������������ � ������� PCX 

        cld                                     ; ����������� � ������� ���������� ������
        mov     cx, 256                         ; ������� ����������
        mov     si, offset rastr_str + 4        ; ������� ������� � ������ �� 4 �����
                                                
        mov     di, offset rastr_str                   
        mov     byte ptr [di], 12               ; ������ ������� � PCX 
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
        inc     si                              ; ���������� ���� � ����� 0Ch
        loop    palet
        ; ������ ������� � PCX 
        mov     ax, PCX_handle                  ; ����� ������ � PCX ����
        push    ax
        mov     ax, 769                         ; ����� ������ (����-����� + 3*256)
        push    ax
        mov     ax, offset rastr_str            ; ����� ������ ������, ������� ���������� � ����
        push    ax
        call    write_file                      ; ��������� ������ � ����
        pop     ax
        test    ax, ax                          ; ���� �� 0
        jnz     error_writePCXfile              ; ������ ������ � ����
        pop     ax  
        
        ; �������� ����� BMP
        mov     ax, BMP_handle                  ; � �� ������ ����� bmp �����
        push    ax                              
        call    close_file                      ; ����� ��������� �������� �����
        pop     ax                              
        test    ax,ax                           ; ���� ���� ���� �� 0
        jnz     error_closeBMPfile              ; ������� �� ����� ������, �����
        ; �������� ����� PCX
        mov     ax, PCX_handle                  ; � �� ������ ����� pcx �����
        push    ax                    
        call    close_file                      ; ����� ��������� �������� �����
        pop     ax                    
        test    ax,ax                           ; ���� ���� ���� �� 0
        jnz     error_closePCXfile              ; ������� �� ����� ������      

        ; ���������, ���� ��� ������ �������
        mov     ax, offset msg_ok               ; ��������  msg_ok
        push    ax                              ; ������ � ����
        call    print                           ; ����� ��������� ������ �� �����
        xor     al, al                          ; ��� �������� ������������� � 0   
        jmp     gl_exit                         ; �������

        ; ������, ������� ����� ����������
        error_openBMPfile LABEL FAR
        mov     bx, offset msg_openBMPfile
        mov     al, 01                          ; ������������� ���� ������ �������� 1                                    
        jmp     gl_error_print
        error_readBMPfile:
        mov     bx, offset msg_readBMPfile
        mov     al, 02                          ; ������������� ���� ������ �������� 2                                    
        jmp     gl_error_print
        error_notBMPfile:
        mov     bx, offset msg_notBMPfile
        mov     al, 03                          ; ������������� ���� ������ �������� 3                                    
        jmp     gl_error_print
        
        error_not8bitBMPfile:
        mov     bx, offset msg_not8bitBMPfile
        mov     al, 04                          ; ������������� ���� ������ �������� 4                                     
        jmp     gl_error_print
        error_openPCXfile:
        mov     bx, offset msg_openPCXfile
        mov     al, 05                          ; ������������� ���� ������ �������� 5
        jmp     gl_error_print
        error_closeBMPfile:
        mov     bx, offset msg_closeBMPfile
        mov     al, 06                          ; ������������� ���� ������ �������� 6                                      
        jmp     gl_error_print
        error_closePCXfile:
        mov     bx, offset msg_closePCXfile
        mov     al, 07                          ; ������������� ���� ������ �������� 7
        jmp     gl_error_print
        error_writePCXfile:
        mov     bx, offset msg_writePCXfile
        mov     al, 08                          ; ������������� ���� ������ �������� 8
        jmp     gl_error_print
        
        gl_error_print:
        push    bx
        call    print                           ; ����� ��������� ������ �� �����
        
        
        gl_exit:
        mov     ah, 4ch                         ; ���������� ���������
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
mov cx, 1 ; ������������� ��������� �������� �������� ����������

check_pixels: 
cmp si, dx ; ���������, �� ����� �� �� �� ����� ������
jge encode_block
inc si
cmp al, [si] ; ���������� ������� ������� � ���������
jne encode_block
inc cx ; ���� ������� �����, ����������� ������� ����������
cmp cx, 255 ; ���������, �� �������� �� �� ������������� �������� ��� �������� ����������
je encode_block

jmp check_pixels

encode_block:
mov ah, cl
mov al, [si]
mov ch, 0 ; ���������� ������� ����������
mov cl, 1 ; ������������� ��������� �������� ��� �������� ����������
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


print   proc    near                            ; ����� ���������
        push    bp                              ; ��������� �������� �������� � �����
        mov     bp, sp                          ; �������� � ���� ���������� �������� sp
        push    ax
        push    dx                              ; ��������� �������� ��������� � �����
        mov     ah, 9                           ; ������� ��� ������ ������ �� �����
        mov     dx, [bp+4]                      ; ����� ������, 1 ��������  
        int     21h
        pop     dx                              ; ���������� �������� ���������
        pop     ax
        pop     bp
        ret    2            
print   endp

 
open_file   proc    near                        ; ������� �������� �����
        push    bp                              ; ���������� ��������
        mov     bp, sp                          ; �������� ���������� � sp
        push    ax                              ; ���������� �������� ��������� � �����
        push    dx
        ;
        mov     ah, 3dh                         ; ������� ��� �������� �����
        mov     al, byte ptr [bp+6]             ; ���� ��� ������, 2 ��������
        mov     dx, [bp+4]                      ; ��� �����, 1 ��������
        int     21h
        jnc     fo_no_error                     ; ������� �� ����������
        mov     word ptr [bp+4], 1              ; CF = 1
        jmp     exit
        fo_no_error:
        mov     word ptr [bp+4], 0              ; CF = 0
        exit:
        mov     [bp+6], ax
        pop     dx                              ; �������������� ���������
        pop     ax
        pop     bp
        ret
open_file   endp


openwrite_file  proc    near                    ; �������� � �������� �����
        push    bp
        mov     bp, sp
        push    ax                              ; ���������� �������� � �����
        push    dx    
        mov     ah, 3ch                         ; ������� �������� � �������� �����
        mov     cx, [bp+6]                      ; ������� �����, 2 ��������
        mov     dx, [bp+4]                      ; ��� �����, 1 ��������
        int     21h
        jnc     fow_no_error                    ; ������� ���� ���� �������� �� ����������
        mov     word ptr [bp+4], 1              ; CF = 1
        jmp     fow_exit
        fow_no_error:
        mov     word ptr [bp+4], 0              ; CF = 0
        fow_exit:
        mov     [bp+6], ax
        pop     dx                              ; �������������� ���������
        pop     ax
        pop     bp
        ret
openwrite_file  endp


close_file  proc    near                        ; �������� ������
        push    bp
        mov     bp, sp
        push    ax                              ; ��������� �������� � �����
        push    bx
        mov     ah, 3eh                         ; ������� �������� �����
        mov     bx, [bp+4]                      ; ����� �����
        int     21h
        jnc     fcl_no_error                    ; ������� �� ���������
        mov     word ptr [bp+4], 1              ; CF = 1
        jmp     fcl_exit
        fcl_no_error:
        mov     word ptr [bp+4], 0              ; CF = 0
        fcl_exit:
        pop     bx                              ; �������������� ���������
        pop     ax
        pop     bp
        ret
close_file  endp


mov_file    proc    near                        ; ��������� ��������� � �����
        push    bp
        mov     bp, sp
        push    ax                              ; ���������� ��������� � ����
        push    bx
        push    cx
        push    dx
        mov     ax, [bp+4]                      ; ����� �������
        mov     ah, 42h                         ; ������� ����������� � �����
        mov     bx, [bp+10]                     ; ����� �����
        mov     cx, [bp+6]                      ; �������� 32 ���������, ��� ������� �����
        mov     dx, [bp+8]                      ; �������� ������� �����
        int     21h

        jnc     fm_no_error                     ; ������� �� ����������
        mov     word ptr [bp+6], 1              ; CF = 1 
        jmp     fm_exit
        fm_no_error:                
        mov     word ptr [bp+6], 0              ; CF = 0
        mov     [bp+8], dx                      ; ����� ��������, ������� �����
        mov     [bp+10], ax                     ; ������� �����
        fm_exit:                                ; ���������� ���������
        pop     dx                              ; �������������� ���������
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        ;
        ret     2
mov_file   endp


read_file   proc    near                        ; ������ �����
        push    bp
        mov     bp, sp
        push    ax                              ; ��������� �������� � �����
        push    bx
        push    cx
        push    dx
        xor     ax, ax
        mov     ah, 3fh                         ; ������� ������ �����
        mov     bx, [bp+8]                      ; ������������� �����
        mov     cx, [bp+6]                      ; ����� ������
        mov     dx, [bp+4]                      ; ����� ������ ��� ������ ������
        int     21h                             ; ����� ����������
        jnc     fr_no_error                     ; ������� �� ���������
        mov     word ptr [bp+6], 1              ; CF = 1
        jmp     fr_exit
        fr_no_error:
        mov     word ptr [bp+6], 0              ; CF = 0
        fr_exit:
        mov     [bp+8], ax                      ; ���-�� ����������� ����
        pop     dx                              ; �������������� ���������
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        ret 2
read_file   endp


write_file  proc    near                        ; ������ � ����
        push    bp
        mov     bp, sp
        push    ax                              ; ��������� �������� � �����
        push    bx
        push    cx
        push    dx
        ;
        xor     ax, ax
        mov     ah, 40h                         ; ������� ������ � ����
        mov     bx, [bp+8]                      ; ����� ����� 
        mov     cx, [bp+6]                      ; ���-�� ���� ��� ������
        mov     dx, [bp+4]                      ; ��������� �� �����
        int     21h                          
        jnc     fw_no_error                     ; ������� �� ���������
        mov     word ptr [bp+6], 1              ; CF = 1
        jmp     fw_exit
        fw_no_error:
        mov     word ptr [bp+6], 0              ; CF = 0
        fw_exit:
        mov     [bp+8], ax                      ; ����� ����������� ����
        pop     dx                              ; ��������������� ��������
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        ret 2
write_file  endp


read_cmd PROC                              ; ������������� ���������� �������� ������
	xor cx,cx                                   ; ������� ��
	mov si, 0                                   ; ���������������� �������� �� 0
        
    mov cl, [es:80h]                            ; ����� ��������� ������
    dec cl
    push cx
       
param_str:
    mov al, [es:82h+si]                         ; ���������� � ������� � ��������� ������ ����� �������
    mov BMP_fileName[si], al                    ; ���������� ������ � ������ �������� ����� BMP
    inc si                                      ; ������� � ���������� �������
    loop param_str                              ; ���� cx �� 0 ���������� ����
        
    pop si                                      ; ��������� �������� �� �����
    push si
    mov cx, si
        
    mov ax, @data 
    mov es, ax
        
    mov si,offset BMP_fileName 
    mov di,offset PCX_fileName
    rep movsb                                   ; �������� ������� ������ ��� BMP-�����
        
    pop si
    
       
    mov PCX_fileName[si-3], 'p'                 ; ������ �������� � ������� �����
    mov PCX_fileName[si-2], 'c'        
    mov PCX_fileName[si-1], 'x'
	ret
read_cmd endp
end start
