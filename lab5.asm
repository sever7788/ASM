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
	xor bx, bx
	cld 
	mov bp,sp 
	mov cl,cmd_length
	cmp cl,1
	jg skip1
	lea dx, msg1
	out_str
	jmp exit 
skip1:
	mov cx,-1 
	mov di,offset cmd_line 
find_param:
	mov al,' ' 
	repz scasb 
	dec di 
	push di 
	mov si,di 
scan_params:
	inc bx
	cmp bx, 3
	je params_ended 
	lodsb
	cmp al,0Dh 
	je params_ended 
	cmp al,20h
	je params_ended
	sub al, '0'
	mov byte ptr len[bx-1], al 
	jmp scan_params
params_ended:
	cmp bx, 2
	jne skip3
	mov al, byte ptr len[0]
	mov byte ptr len[1], al
	mov byte ptr len[0], 0
skip3:
	xor si, si
	mov dx, offset f_name
	mov ah, 3Dh
	mov al, 00h
	int 21h
	jnc skip4
	lea dx, msg3
	out_str
	jmp exit
	skip4:
	mov bx, ax
	mov di, 01
input_number: 
    mov al, byte ptr len[0]
    mov bp, 10
    mul bp
    mov bp,word ptr ax
    mov al, byte ptr len[1]
    add bp, ax
    mov len, bp
	cmp bp, 50
	jnge skip5
	lea dx, msg4
	out_str
	jmp exit
skip5:
    mov bp, 1	
read_data:
	mov cx,1000
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
    cmp bp, 1
    je output_number
    inc si
	
output_number:	
	mov ax, si
	call ShowUInt16
	jmp exit
ShowUInt16       proc
        mov     bx,     10              ;делитель (основание системы счисления)
        mov     cx,     0               ;количество выводимых цифр
        @@div:
                xor     dx,     dx      ;делим (dx:ax) на bx
                div     bx
                add     dl,     '0'     ;преобразуем остаток деления в символ цифры
                push    dx              ;и сохраняем его в стеке
                inc     cx              ;увеличиваем счётчик цифр
                test    ax,     ax      ;в числе ещё есть цифры?
        jnz     @@div                   ;да - повторить цикл выделения цифры
		lea dx, msg2
		out_str
        @@show:
                mov     ah,     02h     ;функция ah=02h int 21h - вывести символ из dl на экран
                pop     dx              ;извлекаем из стека очередную цифру
                int     21h             ;и выводим её на экран
        loop    @@show                  ;и так поступаем столько раз, сколько нашли цифр в числе (cx)        pop     bx
	call new_line 
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
    mov dx, word ptr border_size
loop1:
    cmp buffer[di], ' '
    je next1
    cmp buffer[di], 0Dh
    je next1 
    cmp buffer[di], 0Ah
    je next1
    inc dx
    xor bp, bp
    jmp next2
next1:
    cmp bp, 1
    je next_word
    mov bp, 1
    cmp dx, word ptr len
    jge next_word
    inc si
next_word:
    xor dx, dx      
next2:
    inc di    
loop loop1
    
    mov word ptr border_size, dx   
    
    pop cx
    pop dx
    pop di  
ret    
endp
	wp equ word ptr
	len dw 0
	border_size db 2 dup(0)
	buffer db 1024 dup('$')
	f_name db 'file.txt',0	
	msg1 db 0Dh, 0Ah,"Vvedite dlinu stroki",0Dh, 0Ah,'$'
	msg2 db 0Dh, 0Ah,"Chislo slov = ",'$'
	msg3 db 0Dh, 0Ah,"Fail ne naiden",0Dh, 0Ah,'$'
	msg4 db 0Dh, 0Ah,"Makcimalnaya dlina stroki < 49 byte",0Dh, 0Ah,'$'
end start