    .model tiny
    .code
    org 100h
     
    jmp start

out_str macro 
    mov ah,9
    int 21h
endm
in_str macro 
    mov ah, 0Ah
    int 21h
endm
out_sym macro 
    mov ah, 02h
    int 21h
endm

in_sym macro 
    mov ah, 01h
    int 21h
endm

err1:
    lea dx, msg_err1
    out_str
    int 20h
ret

input_number proc
m1:
    mul     si                      
    mov     bl,[di]                 
    cmp     bl, 30h                
    jl      err1                     
    cmp     bl, 39h                
    jg      err1                    
    sub     bl,30h                  
    add     ax,bx                   
    inc     di                      
    loop    m1                      
    ret    
endp

new_line proc 
    mov dl, 0Ah
    out_sym
    mov dl, 0Dh
    out_sym
    xor bp, bp
ret
endp

space proc
mov dl, ' '                                   
    out_sym
ret 
endp
clear2:
    lea dx, clears
    inc cx
    cmp si, 1
    jne clear
    lea dx, clears2
    neg wp [di]
    cmp wp [di], -32768
    jne clear
    call space
    je @ 
clear:
     cmp cx, 1
     je clear2 
     mov [di], wp 0
     out_str    
jmp loop1
   
minus:
    inc si   
jmp loop2

minus2:
    neg wp [di]
    mov ax, wp [di]
jmp @@
   
;------------НАЧАЛО------------|                                                  
start:
    
    lea dx, msg1
    out_str
    lea dx, params 
    in_str
;------------Перевод строки длины матрицы в число------------| 
    xor     ax,ax                   
    lea     di,params[2]               
    xor     ch,ch                   
    mov     cl, params[1]           
    mov     si,10                   
    xor     bh,bh
    call input_number                   
    
    mov     x, ax 
    
    lea dx, msg2
    out_str
    lea dx, params 
    in_str
;------------Перевод строки ширины матрицы в число------------|     
    xor     ax,ax                   
    lea     di,params[2]               
    xor     ch,ch                  
    mov     cl, params[1]                  
    mov     si,10                   
    xor     bh,bh
    call input_number                   
    
    mov     y, ax
;------------------------------|   
    mov ax, 2				  ;|Вычисление длины массива matrix в байтах
    mul x					  ;|
    mul y					  ;|
    add ax, offset matrix	  ;|
    mov length, ax			  ;|Ширина в байтах
    mov ax, 2				  ;|
    mul x					  ;|
    add ax, offset matrix	  ;|
    mov x_length, ax          ;|
;-------------------------------
;------------Ввод эл-тов матрицы------------|
    lea dx, msg3
    out_str
    lea di, matrix
loop1:
    mov cx, 5
    xor ax, ax
    xor dx, dx
    xor si, si
    loop2:
        in_sym
        mov bl, al
        cmp bl, ' '
        je @
        cmp bl, '-'
        je minus
        sub bl, '0'
        xor ah, ah
        mov ax, 10
        imul wp [di]
        mov [di+1], dx
        jo clear
        add ax, bx
        mov [di], ax
        jo clear                                                              
    loop loop2                                    
    call space                                        
@:                                                 
    cmp si, 1                                      
    je minus2                                      
@@:                                                       
    add di, 2
    inc bp				;??????? enter-??
    cmp bp, x		
    jl continue
    call new_line		;??????? ?? ????? ?????? ??? ?????
    continue:
    cmp di, length    
jl loop1

;|----------------Вычисление суммы эл-тов в столбцах-------------------|
    lea dx, msg4
    out_str

    xor cx, cx
    lea di, matrix
    lea si, summs
loop3:
    xor bp, bp
    push di
    loop4:       
        mov dx, [di]
        add [si+2],dx
        jno no_overflow 
        cmp wp [di],0
        jns no_minus
        add wp [si], -1
        jmp no_overflow
        no_minus:
        add wp [si], 1
        no_overflow:
        add di, x
        add di, x
        inc bp
        cmp bp, y
    jne loop4
    pop di
    add si, 4 
    inc cx
    add di, 2
    cmp cx, x
jne loop3
;------------Поиск минимальной суммы------------|
mov cx, x
lea di, summs
mov ax, wp [di]
mov dx, wp [di+2]
findMin:
    cmp wp [di+2], dx
    jg next         
    cmp wp [di], ax
    jg next
    mov dx, wp [di+2]
    mov ax, wp [di]            
next:
    add di, 4
loop findMin

xor cx, cx
lea di, summs
mov bp, ax 
mov bx, dx
;------------Вывод номеров столбцов------------|
output:
    cmp wp [di+2], bx
    jne next2
    cmp wp [di], bp    
    jne next2
    mov dl, '0'+1         
    add dl, cl
    out_sym
	mov dl, ' '
	out_sym
next2:
    add di, 4 
    inc cx
    cmp cx, x
jl output

ret

params db 20 dup('$')
matrix dw 30 dup(0) 
wp equ word ptr
byp equ byte ptr 
msg1 db "Vvedite kol-vo stolbcov: $"
msg2 db 0Ah,0Dh,"Vvedite kol-vo strok: $"   
msg3 db 0Dh, 0Ah,"Vvedite matrizu",0Dh, 0Ah,'$'
msg4 db 0Dh, 0Ah,"Minimalnaya summa el-tov v stolbcah No:",0Dh, 0Ah,'$'
msg_err1 db 0Dh,0Ah,"Invalid value!$"
clears db 5 dup(8),5 dup(32),5 dup(8),'$'
clears2 db 6 dup(8),6 dup(32),6 dup(8),'$'
x dw 0
y dw 0
length dw 0
x_length dw 0
summs dw 60 dup(00h)

end start