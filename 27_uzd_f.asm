.model small
.stack 100h
.data

msg db "Iveskite simbolius: ", '$'
new_line db 13, 10, 24h
buffer db 255, ? , 255 dup(?)
another db 5 dup(0)
index db 1

.code
    mov ax, @data
    mov ds, ax

    mov ah, 9
    lea dx, msg
    int 21h

    mov ah, 0ah
    lea dx, buffer
    int 21h

    mov ah, 9
    lea dx, new_line
    int 21h

    mov si, offset buffer+2
    xor cx, cx
    mov dl, [buffer + 1]
    mov bl, 0
    check:
        lodsb ;- automatiskai incrementina si, plius nereik mov al
        inc cl
        cmp al, 96
        ja below
   
        cmp cl, dl 
        je convert
        
        jle check
    below:
        cmp al, 124
        jb count 
        
        cmp cl, dl 
        je convert 
        
        jmp check
    count:
        inc bl 
        cmp cl, dl 
        je convert
        
        jmp check

    convert:
        xor ax, ax
        mov bh, 0
        mov ax, bx
        xor bx, bx


        mov di, offset another + 4
        mov bl, 10
                  
        mov si, 1
        jmp ender
    ender:

       xor dx, dx
       div bl
       add ah, '0'

       mov [di], ah

       cmp al, 0
       je printing

       dec di
       inc si 
       mov ah,0
    
    jmp ender

    printing:

        mov ah, 40h 
        mov bx, 1
        mov dx, di 
        mov cx, si 
        int 21h 

        mov ax, 4c00h
        int 21h
end