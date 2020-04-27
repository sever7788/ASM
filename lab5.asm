in_sym macro 
    mov ah, 01h
    int 21h
    sub al, '0'
    xor ah, ah
endm
out_sym macro 
    mov ah, 02h
    int 21h
endm

out_str macro 
    mov ah,9
    int 21h
endm
	.model tiny
	.code
	org 80h 
	cmd_length db ? 
	cmd_line db ? 
	org 100h 
start:
	
	cld 
	mov bp, sp
	mov cl, cmd_length
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
	
	mov cx, 2
	cmp cx, wp argc
	je skip1
	lea dx, msg5
	out_str
	jmp exit
skip1:	
	xor si, si
	pop dx
	push dx
	mov ah, 3Dh
	mov al, 00h
	int 21h
	jnc input_number
	lea dx, msg3
	out_str
	jmp exit
	
input_number: 
	mov cx, ax         ;сохраняем идентификатор файла в cx
	pop ax
	pop bx
	push ax
	push cx
	mov bx, word ptr [bx]
	mov al, bl
	sub al, '0'
    mov bp, 10
    mul bp
    mov bp,word ptr ax
    mov al, bh
	sub al, '0'
    add bp, ax
    mov len, bp
	cmp bp, 50
	jnge skip5
	lea dx, msg4
	out_str
	jmp exit
skip5:
	pop bx				;идентификатор файла в bx
    mov bp, 0	
read_data:
	mov cx, 1000
	mov dx,offset buffer 
	mov ah,3Fh 
	int 21h 
	jc close_file 
	mov cx,ax 
	jcxz close_file
	call find_word 
	jmp short read_data 
	
close_file:
	mov ah,3Eh 
	int 21h
	
@:
    cmp bp, 0
    je output_number
	mov dx, word ptr border_size
	inc dx
	cmp dx, len
	jge	output_number
    add si, 1
	adc star, 0
	
output_number:	
	lea dx, msg2
	out_str
	mov ax, star
	call ShowUInt16
	mov ax, si
	call ShowUInt16
	jmp exit
ShowUInt16       proc
        mov     bx,     10              ;делитель (основание системы счисления)
        mov     cx,     5               ;количество выводимых цифр
        @@div:
                xor     dx,     dx      ;делим (dx:ax) на bx
                div     bx
                add     dl,     '0'     ;преобразуем остаток деления в символ цифры
                push    dx              ;и сохраняем его в стеке
        loop     @@div                   ;да - повторить цикл выделения цифры
		mov     cx,     5 
        @@show:
                mov     ah,     02h     ;функция ah=02h int 21h - вывести символ из dl на экран
                pop     dx              ;извлекаем из стека очередную цифру
                int     21h             ;и выводим её на экран
        loop    @@show                  ;и так поступаем столько раз, сколько нашли цифр в числе (cx)        pop     bx
ret
endp
  
exit:
	mov ah,3Eh 
	int 21h
	int 20h

new_line proc 
    mov dl, 0Ah
    out_sym
    mov dl, 0Dh
    out_sym
    xor bp, bp
ret
endp

find_word proc
    push di
    push dx
    push cx
    
    xor di, di
    mov dx, word ptr border_size	;длина слова
	
	cmp bp, 1
	jne loop1
	inc dx
	xor bp, bp
loop1:
    cmp buffer[di], ' '
    je next1
    cmp buffer[di], 0Dh
    je next1 
    cmp buffer[di], 0Ah
	je next1
	
	inc dx
	cmp cx, 2
	jne next2
	mov bp, 1
	jmp next2
next2:
	cmp buffer[di+1], ' '
    je skip2
    cmp buffer[di+1], 0Dh
    je skip2 
    cmp buffer[di+1], 0Ah
	je skip2
	jmp next1
skip2:
	xor bp, bp
	mov ax, dx
	xor dx,dx
	cmp ax, word ptr len
	jge next1
	add si, 1
	adc star, 0
next1:
	inc di
    loop loop1
    
    mov word ptr border_size, dx   
    
    pop cx
    pop dx
    pop di  
ret    
endp
	star dw 0
	argc dw 0 
	wp equ word ptr
	len dw 0
	border_size dw 0
	buffer db 1000 dup('$')
	f_name db 'file.txt',0
	msg1 db 0Dh, 0Ah,"Vvedite dlinu stroki",0Dh, 0Ah,'$'
	msg2 db 0Dh, 0Ah,"Chislo slov = ",'$'
	msg3 db 0Dh, 0Ah,"Fail ne naiden!",0Dh, 0Ah,'$'
	msg4 db 0Dh, 0Ah,"Makcimalnaya dlina stroki < 50 symb!!",0Dh, 0Ah,'$'
	msg5 db 0Dh, 0Ah,"Kol-vo argumentov dolzhno byt 2!!!",0Dh, 0Ah,'$'
end start