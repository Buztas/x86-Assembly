.model small
.stack 100h

;dar reik padaryt, jog veiktu su command line arguments

.data
    src_filename db "src.com"
    src_filehandle dw ?
    out_filename    db "out.asm"
    out_filehandle  dw ?


    src_buffer db 256 dup(0), '$' ;si
    out_buffer db 256 dup(0), '$' ;di

    daliklis db 10h 
    new_line db 10, 13, '$'

    pushf_name db "pushf ", 0 
    popf_name db "popf ", 0 
    cmp_name db "cmp ", 0
    call_name db "call ", 0
    add_name db "add ", 0

    ax_name db "ax", 0
    bx_name db "bx", 0
    cx_name db "cx", 0
    dx_name db "dx", 0
    ah_name db "ah", 0
    al_name db "al", 0
    bh_name db "bh", 0
    bl_name db "bl", 0
    ch_name db "ch", 0
    cl_name db "cl", 0
    dh_name db "dh", 0
    dl_name db "dl", 0
    bx_si_p db "[bx + si + ", 0
    bx_di_p db "[bx + di + ", 0
    bp_si_p db "[bp + si + ", 0
    bp_di_p db "[bp + di + ", 0
    si_p db "[si + ", 0
    di_p db "[di + ", 0
    bp_p db "[bx + ", 0
    bx_p db "[bp + ", 0
    sp_name db "[sp",0
    bp_name db "[bp",0
    si_name db "[si",0
    di_name db "[di",0
    bx_si_name db "[bx + si", 0
    bp_si_name db "[bp + si", 0
    bx_di_name db "[bx + di", 0
    bp_di_name db "[bp + di", 0


    mod_value db 0
    rm_value db 0
    reg_value db 0
    w_value db 0
    d_value db 0
    poslinkis dw 0
    s_value db 0

    cmd_exec db 0 


.code
    mov dx, @data
    mov ds, dx

    mov di, offset out_buffer

    call READ_SRC
    mov si, offset src_buffer
    ;ax kiek nuskaite, jie ax == 255

    label5: ;labelis tam, kad galeciau ivykdyt funkcijas, nes kitaip man nes jos nesivykdo

    ;pagrinde sokam i lebel6 del to, jog pamates tam tikra instrukcija ir apdorojes ja, jis iskart soka is loopo, kad pradetu kita iteracija

    call CHECK_PUSHF
    cmp cmd_exec, 1
    je lebel6
    call CHECK_POPF
    cmp cmd_exec, 1
    je lebel6
    call CHECK_ADD
    cmp cmd_exec, 1
    je lebel6
    call CHECK_CMP
    cmp cmd_exec, 1
    je lebel6
    call CHECK_CALL
    cmp cmd_exec, 1
    je lebel6
    ;call CHECK_CALL_TIESIOG
    ;cmp cmd_exec, 1
    ;je lebel6
    call CHECK_AKUM_CMP_BET
    cmp cmd_exec, 1
    je lebel6
    CALL CHECK_AKUM_ADD
    cmp cmd_exec, 1
    je lebel6

    lebel6:
    mov cmd_exec, 0
    
    ;cia tiesiog idedam musu dissasemblinta masinini koda i out_buffer

    mov byte ptr ds:[di], '$'
    mov ah, 09h
    mov dx, offset out_buffer
    int 21h
    mov di, offset out_buffer

    ;lyginam ar musu src_buffer yra 0 (reiskia bufferio gala), jeigu taip tai baigesi src.asm contentas
    
    cmp byte ptr ds:[si], 0

    jne label5

    mov ah, 4ch
    int 21h

READ_SRC proc;readinam contenta
    mov ah, 3dh
    mov al, 0
    mov dx, offset src_filename
    int 21h
    mov src_filehandle, ax

    mov ah, 3fh
    mov bx, src_filehandle
    mov cx, 255
    mov dx, offset src_buffer
    int 21h

    ret
endp 

CHECK_PUSHF proc;paprastsai checkinu pushf, kadangi tai labai paprasta instrukcija

    cmp byte ptr ds:[si], 9Ch
    jne not_pushf

    mov bx, offset pushf_name

    looping_pushf: ;kadangi uztenka vieno compare, cia tiesiog idedu vis po raide i out_bufferi

        mov dl, byte ptr ds:[bx]
        mov byte ptr ds:[di], dl

        inc di
        inc bx

        cmp byte ptr ds:[bx], 0h
        jne looping_pushf

    inc si

    CALL OUTPUT_NEWLINE

    mov cmd_exec, 1 ;sitas yra kiekvienoje porceduroje, ir to reikia, jog galetu normaliai veikti musu funkciju callai

    not_pushf:
        ret
endp
CHECK_POPF proc  ;tas pats kaip su popf

    cmp byte ptr ds:[si], 9Dh
    jne not_popf

    mov bx, offset popf_name

    looping_popf:

        mov dl, byte ptr ds:[bx]
        mov byte ptr ds:[di], dl

        inc di
        inc bx

        cmp byte ptr ds:[bx], 0h 
        jne looping_popf

    
    inc si
    CALL OUTPUT_NEWLINE
    mov cmd_exec, 1

    not_popf:
        ret
endp
CHECK_ADD proc;funkcija apdorotojanti add su reg ~ r/m

        mov al, byte ptr ds:[si]
        ;xor al, 3
        shr al, 2

        cmp al, 0
        jne not_add
        
        mov bx, offset add_name

        CALL TO_OUTPUT ;funkcija kuri i outputa israso musu apdorota masinini koda

        call check_insides ;cia pagrindinis algoritmas
        mov cmd_exec, 1

        not_add:
            ret
endp

CHECK_CMP proc ;compare'as su reg ~ r/m ir atvirksciai

    mov al, byte ptr ds:[si]

    shr al, 2 

    cmp al, 0Eh
    jne not_cmp
    
    mov bx, offset cmp_name

    CALL TO_OUTPUT

    call check_insides ;kadangi tas pats principas kaip su add, tai pavartoju sita procedura vel
    mov cmd_exec, 1

    not_cmp:
         ret

endp

CHECK_CMP_RM_BET   proc

    ;same algorithm kaip su add_bet
    xor ax, ax

    mov al, byte ptr ds:[si]
    call CHECK_W
    shr al, 1

    cmp al, 0Fh 
    je its_cmp

    jmp out_this_bitch

    its_cmp:
    mov bx, offset cmp_name
    call TO_OUTPUT
    pop ax
    inc si

    cmp w_value, 0
    je cmp_is_0

    cmp w_value, 1
    je cmp_is_1

    jmp out_this_bitch

    cmp_is_0:
    ;dirbam su baitais
    mov bx, offset al_name
    call TO_OUTPUT
    call SEP_OP_OUTPUT
    call Print1B

    jmp command_exec

    cmp_is_1:
    ;dirbam su zodziais
    mov bx, offset ax_name
    call TO_OUTPUT
    call SEP_OP_OUTPUT
    call Print

    command_exec:
    mov cmd_exec, 1

    out_this_bitch:
    inc si
    ret

endp

;0011 110w bojb [bovb]

CHECK_AKUM_CMP_BET proc 

    ;same algorithm kaip su add_akum_bet
    xor ah, ah
    mov al, byte ptr ds:[si]

    cmp al, 03Ch
    je cmp_al

    cmp al, 03Dh
    je cmp_ax

    jmp this_aint_it

    cmp_al: ;nera ah
    mov bx, offset cmp_name
    call TO_OUTPUT
    mov bx, offset al_name
    call TO_OUTPUT
    call SEP_OP_OUTPUT
    inc si
    mov al, byte ptr ds:[si]
    call Print1B
    call OUTPUT_NEWLINE

    jmp code_exed_suc

    cmp_ax:
    mov bx, offset cmp_name
    call TO_OUTPUT
    mov bx, offset ax_name
    call TO_OUTPUT
    call SEP_OP_OUTPUT
    inc si
    mov al, byte ptr ds:[si]
    call Print
    call OUTPUT_NEWLINE

    code_exed_suc:
    mov cmd_exec, 1

    this_aint_it:
    inc si
    ret

endp

;also fix
CHECK_ADD_BET proc ;kol kas nebaigta procedura, bet cia turetu veikt su rm ~ bet operand

    mov al, byte ptr ds:[si]
    shr al, 2

    cmp al, 2
    je possible_add

    possible_add:
    mov al, byte ptr ds:[si]
    call CHECK_D ;assuming this is s_value
    call CHECK_W

    inc si
    call CHECK_MOD
    call CHECK_REG
    cmp reg_value, 0
    je is_add_bet  

is_add_bet:

    mov bx, offset add_name
    CALL TO_OUTPUT

    cmp d_value, 0
    je d_val_0

    cmp d_value, 1
    je d_val_1

    d_val_0:
        inc si
        call CHECK_MOD
        call CHECK_REG
        call CHECK_RM
        cmp w_value, 0
        je w_val_0

        cmp w_value, 1
        je w_val_1

        w_val_0:
        call PRINT_OPERAND_1
        jmp out_of_this_code
        w_val_1:
        call PRINT_OPERAND_2

        jmp out_of_this_code

    d_val_1:
        inc si
        call CHECK_MOD
        call CHECK_REG
        call CHECK_RM
        cmp w_value, 0
        je w_val_0_t ;cant be 0

        cmp w_value, 1
        je w_val_1_t


        w_val_0_t:


        jmp out_of_this_code

        w_val_1_t:
        


        jmp out_of_this_code

    out_of_this_code:
    mov cmd_exec, 1
    inc si

    ret
endp

;0000 010w bojb [bovb] – ADD akumuliatorius += betarpiškas operandas
CHECK_AKUM_ADD proc  ;akumuliatorius ir betarpiskas operandas, neisivaizduoju kodel neveikia nors pagal viska turetu veikt
    xor ax, ax
    mov al, byte ptr ds:[si]
    

    cmp al, 5
    je is_2_baitai

    cmp al, 4
    je is_1_baitas

    jmp not_akum_add

    is_1_baitas:
    mov bx, offset add_name
    call TO_OUTPUT
    mov bx, offset al_name
    call TO_OUTPUT
    call SEP_OP_OUTPUT
    inc si
    mov al, byte ptr ds:[si]
    call Print1B
    call OUTPUT_NEWLINE

    jmp out_of_this

    is_2_baitai:
    mov bx, offset add_name
    call TO_OUTPUT
    mov bx, offset ax_name
    call TO_OUTPUT
    call SEP_OP_OUTPUT
    inc si
    mov al, byte ptr ds:[si]
    call Print
    call OUTPUT_NEWLINE

    out_of_this:
    mov cmd_exec, 1
    inc si

    not_akum_add:
    ret
endp

;1110 1000 pjb pvb - CALL zyme (vidinis tiesioginis)
;tiesiog su poslinkiu, arba 1 baito arba 2 baitu
CHECK_CALL_TIESIOG proc                        ;50% works lol, fix this

    mov al, byte ptr ds:[si]
    CALL CHECK_W
    CALL CHECK_D
    cmp al, 0016h
    je its_call

    its_call:
    inc si

    CALL CHECK_MOD
    CALL CHECK_REG
    CALL CHECK_RM

    cmp mod_value, 0
    je call_su_baitu

    cmp mod_value, 1
    je call_su_zodziu

    cmp mod_value, 2
    je call_su_zodziu

    jmp bad_call

    call_su_baitu:
    call check_call_insides
    CALL OUTPUT_NEWLINE

    jmp code_exec_succ

    call_su_zodziu:
    CALL PRINT_OPERAND_2
    CALL OUTPUT_NEWLINE

    code_exec_succ:
    mov cmd_exec, 1
    inc si

    bad_call:
    ret

endp

;1111 1111 mod 010 r/m [poslinkis] – CALL adresas (vidinis netiesioginis)
;1111 1111 mod 011 r/m [poslinkis] – CALL adresas (išorinis netiesioginis)

CHECK_CALL proc ;checkinam calla kur virsuj parodytos instrukcijos

    ;code easiest call su adress
    ;rast moda, modas arba 00 arba 01 arba 10

    ;rast reg ir cmp su tais 3 sk kur turetu but reg

    ;callint operand 2 nes ten adresai

    ;poslinkis? pagal moda

    ;negali but mod 3
    ;nerek kviest operan 1

    mov al, byte ptr ds:[si]

    cmp al, 0FFh
    je is_check_call

    jmp not_call

    is_check_call:
    inc si
    CALL CHECK_REG
    cmp reg_value, 2
    je is_call
    cmp reg_value, 3
    je is_call

    ;reik breako cia
    jmp not_call

    is_call:
        ;mov byte ptr ds:[di], call_name
        mov bx, offset call_name
        call TO_OUTPUT

    CALL CHECK_MOD
    CALL CHECK_RM

    cmp reg_value, 2
    je reg_is_2

    cmp reg_value, 3
    je reg_is_3

    reg_is_2:

        cmp mod_value, 2h
        je mod_is_2

        cmp mod_value, 1h 
        je mod_is_1

        mod_is_0:

        CALL check_call_insides
        jmp exec_succ

        mod_is_1:

        call PRINT_OPERAND_2
        jmp exec_succ

        mod_is_2:

        call PRINT_OPERAND_2
        jmp exec_succ
    
    reg_is_3:

        cmp mod_value, 2h
        je mod_is_2_c

        cmp mod_value, 1h 
        je mod_is_1_c

        mod_is_0_c:

        CALL check_call_insides
        jmp exec_succ
        
        mod_is_1_c:

        CALL PRINT_OPERAND_2
        jmp exec_succ

        mod_is_2_c:

        CALL PRINT_OPERAND_2
        jmp exec_succ

    exec_succ:
    mov byte ptr ds:[di], "]"
    inc di
    mov cmd_exec, 1
    call OUTPUT_NEWLINE
    inc si

    not_call:
        ret
endp

check_call_insides proc;procedura giliau isanalizuot callo masinini koda, pagrinde rm values, 

    cmp rm_value, 0
    je is_0 

    cmp rm_value, 1
    je is_1 

    cmp rm_value, 2
    je is_2 

    cmp rm_value, 3
    je is_3

    cmp rm_value, 4
    je is_4 

    cmp rm_value, 5
    je is_5 

    cmp rm_value, 5
    je is_5 

    cmp rm_value, 7
    je is_7 

    jmp out_check

    is_0:
        mov bx, offset bx_si_name
        CALL TO_OUTPUT
    jmp out_check

    is_1:
        mov bx, offset bx_di_name
        CALL TO_OUTPUT

    jmp out_check
    
    is_2:
        mov bx, offset bp_si_name
        CALL TO_OUTPUT

    jmp out_check
 
    is_3:
        mov bx, offset bp_di_name
        CALL TO_OUTPUT 

    jmp out_check

    is_4:
        mov bx, offset si_name
        CALL TO_OUTPUT

    jmp out_check

    is_5:
        mov bx, offset di_name
        CALL TO_OUTPUT

    jmp out_check

    is_6:
        mov bx, offset poslinkis
        CALL TO_OUTPUT

    jmp out_check

    is_7:
        mov bx, offset bx_name
        CALL TO_OUTPUT

    jmp out_check

    out_check:
        ret
endp

check_insides Proc;procedura kuri veikia su cmp bei add

        CALL CHECK_D
        CALL CHECK_W
        inc si
        CALL CHECK_REG
        CALL CHECK_MOD
        CALL CHECK_RM
        inc si

        ;checkinam poslinki

        cmp mod_value, 1
        je poslinkis_baitas

        cmp mod_value, 2
        je poslinkis_2_baitas

        jmp find_reg

        poslinkis_baitas:
        
        mov al, byte ptr ds:[si] 
        xor ah, ah
        mov poslinkis, ax
        inc si 

        jmp find_reg

        poslinkis_2_baitas:
        mov al, byte ptr ds:[si]
        inc si
        mov ah, byte ptr ds:[si]
        inc si
        mov poslinkis, ax

        find_reg: ;looking for reg

        cmp mod_value, 03h 
        je if_dest_0

        CALL PRINT_OPERAND_1
        CALL SEP_OP_OUTPUT
        jmp continue_code

        if_dest_0:
        cmp d_value, 0
        je reg_to_rm

        CALL PRINT_OPERAND_1
        CALL SEP_OP_OUTPUT

        jmp change_reg

        reg_to_rm:
        CALL CHANGE_REG_RM
        CALL PRINT_OPERAND_1

        CALL SEP_OP_OUTPUT

        cmp mod_value, 3
        je change_reg 

        jmp continue_code

        change_reg:
        CALL CHANGE_REG_RM
        CALL PRINT_OPERAND_1
        CALL OUTPUT_NEWLINE

        jmp to_return

        continue_code:

        call PRINT_OPERAND_2
        call OUTPUT_NEWLINE

        to_return:

        ret
endp


CHECK_MOD proc  ;gaunam moda
    ;1100 0000 C
    mov al, byte ptr ds:[si]
    shr al, 6
    ;and al, 0C0h
    mov mod_value, al

    ret
endp

CHECK_REG proc ;gaunam rega

    mov al, byte ptr ds:[si]

    and al, 038h
    shr al, 3
    mov reg_value, al

    ret
endp

CHECK_RM proc ;gaunam rm'a

    mov al, byte ptr ds:[si]
    and al, 7

    mov rm_value, al

    ret
endp

CHECK_D proc ;gaunam d

    mov al, byte ptr ds:[si]
    ;0000 0010 2
    and al, 2
    shr al, 1
    mov d_value, al
    
    ret
endp

;ADD AX, BX
;03     C3
;0011 1100 0011

;d = 1, w = 1

CHECK_W PROC ;sita reiks naudot pacheckint ar akumuliatorius yra 2 baitu ar 1 baito
;0000 0011 d w
;jeigu d 0 tai source: reg, destination: r/m
;jeigu d 1 tai source: r/m, destination: reg
    mov al, byte ptr ds:[si]

    and al, 1
    mov w_value, al

    ret
endp

PRINT_OPERAND_1 proc ;sitas naudojamas tada jeigu musu w yra 0 ir mod 11

    cmp reg_value, 0 ;0
    jne test_1

    cmp w_value, 0
    je ismesti_al

    mov bx, offset ax_name
    call TO_OUTPUT
    ret
    ismesti_al:

    mov bx, offset al_name
    call TO_OUTPUT
    ret
    test_1:

    cmp reg_value, 1 ;2
    jne test_2

    cmp w_value, 0
    je ismesti_cl

    mov bx, offset cx_name
    call TO_OUTPUT
    ret
    ismesti_cl:

    mov bx, offset cl_name
    call TO_OUTPUT
    ret

    test_2:

    cmp reg_value, 2 ;3
    jne test_3

    cmp w_value, 0
    je ismesti_dl

    mov bx, offset dx_name
    call TO_OUTPUT
    ret
    ismesti_dl:

    mov bx, offset dl_name
    call TO_OUTPUT
    ret
    test_3:

    cmp reg_value, 3 ;4
    jne test_4

    cmp w_value, 0
    je ismesti_bl

    mov bx, offset bx_name
    call TO_OUTPUT
    ret
    ismesti_bl:

    mov bx, offset bl_name
    call TO_OUTPUT
    ret
    test_4:

    cmp reg_value, 4 ;5
    jne test_5

    cmp w_value, 0
    je ismesti_ah

    mov bx, offset sp_name
    call TO_OUTPUT
    ret
    ismesti_ah:

    mov bx, offset ah_name
    call TO_OUTPUT
    ret
    test_5:

    cmp reg_value, 5 ;6
    jne test_6

    cmp w_value, 0
    je ismesti_ch

    mov bx, offset bp_name
    call TO_OUTPUT
    ret
    ismesti_ch:

    mov bx, offset ch_name
    call TO_OUTPUT
    ret
    test_6:

    cmp reg_value, 6 ;7
    jne test_7

    cmp w_value, 0
    je ismesti_dh

    mov bx, offset si_name
    call TO_OUTPUT
    ret
    ismesti_dh:

    mov bx, offset dh_name
    call TO_OUTPUT
    ret
    test_7:

    cmp reg_value, 7 ;8
    jne test_8

    cmp w_value, 0
    je ismesti_bh

    mov bx, offset di_name
    call TO_OUTPUT
    ret
    ismesti_bh:

    mov bx, offset bh_name
    call TO_OUTPUT
    ret

    test_8:


    ret
endp

TO_OUTPUT proc ;algoritmas kuris buvo panaudotas pirma karta su pushf, tai supratau, jog poto sita galiu daug kart panaudot

looping_add:
            
    mov dl, byte ptr ds:[bx]
    mov byte ptr ds:[di], dl

    inc di
    inc bx

    cmp byte ptr ds:[bx], 0h 
    jne looping_add

    ret
endp

CHANGE_REG_RM proc ;tiesiog apkeiciu reg ir rm reiksmes, pagal salyga

    mov ah, reg_value
    mov al, rm_value

    mov reg_value, al
    mov rm_value, ah

    ret
endp

PRINT_OPERAND_2 proc ;jeigu mod 01, 10

    cmp rm_value, 0 ;0
    jne test_0_2

    mov bx, offset bx_si_p
    call TO_OUTPUT

    jmp test_8_2

    test_0_2:

    cmp rm_value, 1 ;2

    jne test_2_2

    mov bx, offset bx_di_p
    call TO_OUTPUT
    jmp test_8_2

    test_2_2:

    cmp rm_value, 2 ;3

    jne test_3_2

    mov bx, offset bp_si_p
    call TO_OUTPUT
    jmp test_8_2

    test_3_2:

    cmp rm_value, 3 ;4

    jne test_4_2

    mov bx, offset bp_di_p
    call TO_OUTPUT
    jmp test_8_2

    test_4_2:

    cmp rm_value, 4 ;5

    jne test_5_2

    mov bx, offset si_p
    call TO_OUTPUT
    jmp test_8_2
 
    test_5_2:

    cmp rm_value, 5 ;6

    jne test_6_2

    mov bx, offset di_p
    call TO_OUTPUT
    jmp test_8_2

    test_6_2:

    cmp rm_value, 6 ;7

    jne test_7_2

    mov bx, offset bp_p
    call TO_OUTPUT
    jmp test_8_2

    test_7_2:

    cmp rm_value, 7 ;8

    mov bx, offset bx_p
    call TO_OUTPUT

    test_8_2:

    mov ax, poslinkis

    cmp mod_value, 1
    je mod_value_1


    cmp mod_value, 2
    je mod_value_2

    ret

    mod_value_1: ;sitie labeliai tam skirti, jog galeciau tiesiog iterp [] bei h
    CALL Print1B
    mov byte ptr ds:[di], "h"
    inc di
    mov byte ptr ds:[di], "]"
    inc di
    ret

    mod_value_2:
    CALL Print
    mov byte ptr ds:[di], "h"
    inc di
    mov byte ptr ds:[di], "]"
    inc di
    ret


endp   

        Print proc ;procedura skirta printinti pacius skaicius, bei poslinki
            push ax  ;print ah tada al
            mov al, ah
            call Print1B
            pop ax
            call Print1B
            ret
        endp Print

        Print1B proc  ;print j.b.
            xor ah, ah
            div daliklis ;shr galima 
            push ax
            call PrintHexNumber
            pop ax
            mov al, ah
            call PrintHexNumber
            ret 
        endp Print1B

        PrintHexNumber proc
            cmp al, 9
            jbe decimal

            mov dl, al
            add dl, 37h ;A-F 
            mov byte ptr ds:[di], dl
            inc di
            jmp return

            decimal:
                mov dl, al
                add dl, 30h
                mov byte ptr ds:[di], dl
                inc di
                jmp return
            return:
            ret 
        endp PrintHexNumber

SEP_OP_OUTPUT proc ;precudra kuri seperatina argumentus

    mov byte ptr ds:[di], ","   
    inc di
    mov byte ptr ds:[di], " "
    inc di

    ret
endp
OUTPUT_NEWLINE proc ;tiesiog outputina new line'a

    mov dx, offset new_line
    mov ah, 09h
    int 21h

    ret

endp
end
;ADD registras ~ registras 0000 00dw mod reg r/m [poslinkis] 1100 0011 ADD AX,BX 0011 - ADD, 1100 0011 AX,BX 11 - MOD 000 - AX reg 011 - BX r/m
;ADD registras ~ atmintis
;ADD akumuliatorius, betarpiskas operandas 0000 010w bojb [bovb]
;d - 0 arba 1, w - 0 arba 1