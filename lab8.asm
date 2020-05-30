out_str macro 
    mov ah,9
    int 21h
endm
Seg1 SEGMENT
ASSUME SS:Seg1,DS:Seg1,CS:Seg1,ES:Seg1
.386
	org 80h 
	cmd_length db ? 
	cmd_line db ? 
	org 100h 

Pr: 
	JMP M1 ;Пропускаем резидентную часть

;--------------------- Резидентная часть
old_09 dd 0 ;Старый адрес Int 09h
buffer db 4000 dup(0)
f_id dw 0
f_name db 15 dup (0)
error1 db 0Dh, 0Ah,"Fail ne naiden!",0Dh, 0Ah,'$'
error2 db 0Dh, 0Ah,"Error open file!",0Dh, 0Ah,'$'
M2: 
	pushF ;Регистр флагов - в стек
	call CS:old_09 ;Вызов системного обр. прер. 09h
	cli
	pusha
	
	mov AX,40h ;Занесение сегментного адреса
	mov ES,AX ;буфера клавиатуры в рег.ES
	mov BX,ES:[1Ah] ;Адрес головы буфера клавиатуры
	mov AX,ES:[BX] ;Чтение кода нажатой клавиши
	cmp AX,2C1Ah ;Сравнение его с Ctrl+Z
	jnz M3 ;Переход на выход, если не Ctrl+Z
	
	mov ax,0B800h ;В рег.ES засылаем сегментный
	mov ds,ax ;адрес буфера экрана B800
	mov ax, cs
	mov es, ax
	;----------------------Запись данных изконсоли в буфер
	mov di, offset buffer   ; В si загружаем 
	xor si, si
	mov cx, 2000
	rep movsw
	;----------------------Форматирование данных в буфере
	mov ax, cs
	mov ds, ax
	mov cx, 2000
	mov di, offset buffer
	xor si, si
	xor bl, bl
loop1:
	mov ah, [di]
	mov buffer[si], ah
	cmp bl, 79
	jne next2
	mov byte ptr buffer[si+1], 0Dh
	inc si
	mov bl, -1
next2:
	inc bl
	inc si
	add di, 2
skip1:
loop loop1
	;---------------------- Открытие файла
	xor cx, cx
	lea dx, f_name
	mov ah, 3Ch
	mov al, 00h
	int 21h
	jnc next
	lea dx, error1
	out_str
	jmp M3
	;---------------------- Чтение в файл
next:
	mov f_id, ax
	mov bx, ax
	mov cx, 2025
	lea dx, buffer
	mov ah, 40h
	int 21h
	
	mov ah,3Eh ;закрытие файла 
	int 21h

M3: 
	popa
	sti
	iret ;Выход в DOS
;---------------------- ;Инициирующая часть
M1: 
	
	cld 
	mov bp, sp
	mov cl, cmd_length
	cmp cl, 1
	jnle next3
	lea dx, error3
	out_str
	jmp exit
next3:
	mov cx, -1
	mov di, offset cmd_line
find_param:
	mov al, ' '
	repz scasb
	dec di
	push di
	inc word ptr argc
	mov si, di
	
scan_params:
	lodsb
	cmp al, 0Dh
	je params_ended
	cmp al, 20h
	jne scan_params
	
	dec si
	mov byte ptr [si], 0
	mov di, si
	inc di
	jmp short find_param
	
params_ended:
	dec si
	mov byte ptr [si], 0
	
	mov cx, 1
	cmp cx, wp argc
	je skip2
	lea dx, error3
	out_str
	jmp exit
skip2:
	mov cx, 15
	pop si
	lea di, f_name
	repne movsb
	
	cli
	mov AX,3509h ;Получить в ES:BX старый адрес
	INT 21h ;обработчика прерывания int 09h
	mov word ptr CS:old_09,BX ;и запомнить его
	mov word ptr CS:old_09+2,ES ;в ячейке old_09
	mov AX,2509h ;Установка нового адреса <адр.M2>
	lea DX,M2 ;обработчика прерывания int 09h
	INT 21h 
	sti
; -------
	mov AH,09h ;Вывод строки:
	lea DX,x ;'Резидентный обработчик загружен$'
	INT 21h 
; -------
	mov AX,3100h ;Завершить и оставить резидентной
	mov DX,(M1-Pr+10Fh)/16 ;часть размером (M1-Pr+10Fh)/16
exit:	
	INT 21h
	int 20h	
; -------
wp equ word ptr
argc dw 0
error3 db 0Dh, 0Ah,"Kol-vo argumentov dolzhno byt 1!!!",0Dh, 0Ah,'$'
x db 'Resident upload$'
Seg1 ENDS ;Конец сегмента
END Pr ;Полный конец программы Pr