.model small
.stack 100h
.data

in_handle dw 0
out_handle dw 0

input_name db 40 dup(0)
output_name db 40 dup(0)

buffer db 255 dup(0)

param_size db 0

rasymas_in_out db 0

simboliai dw 0

mazosios dw 0
didziosios dw 0
zodziai dw 0
visi_simboliai dw 0
if_space dw 0

blogi_parametrai db "Iveskite {input.txt} ir {output.txt}", '$'

msg_did db "Didziosios: ", '$'
msg_maz db "Mazosios: ", '$'
msg_simbol db "Visi simboliai: ", '$'
msg_zodziai db "Zodziai: ", '$'

new_line db 10, 13

daliklis db 10
;skaiciai_output db 10 dup(0)
skaiciai_output dw ?

tmp1 db 0

.code

start:
    mov ax, @data
    mov ds, ax

    xor cx, cx
    mov cl, es:[0080h] ;0080h command line'o dydis

    mov param_size, cl ;issaugom command line'o dydi kintamajame

    mov bx, 0082h ;0082h pradzia command line'o

    mov si, offset input_name ;pointina i input_name
    mov di, offset output_name ;pointina i output_name

    read_params:
 
        mov dx, es:[bx]                     ;i dx patalpinam command line'o contenta, dl bus musu simboliai
        cmp dx, "?/"                        ;checkinam su '/?' , nes dl bus / o dh ?
        jne next1
		jmp blogi_params                     ;jei blogai ismetam help msg
		next1:
		
        cmp rasymas_in_out, 0               ;checkinam ar 0, nes jei 0 ivedinejame input.txt name
        je write_to_input 
 
        jmp write_to_output                 ;jei rasymas_in_out yra 1, tai sokam i outputo ivedima

        write_to_input:

        cmp dl, 20h                         ;comparinam su space'u
        je change_to_out                    ;jei yra space'as pakeicia reiksme rasymo_in_out

        mov [si], dl                        ;si registre saugom command line ivesties reiksmes
        inc si
        inc bx                              ;incrementinam bx, kad programa perskaitytu kita command line ivesties simboli

        jmp read_params

        write_to_output: 
        cmp dl, 0Dh                         ;comparinam su enteriu jei equal tai sokam i kodo starta
        je start_code

        mov [di], dl                        ;movinam i di registra, dl contenta (command line contenta)
        inc di
        inc bx

        jmp read_params

        change_to_out:                      ;pakecia rasymas_in_out is 0 i 1 , jeigu programa pastebi space'a
        mov rasymas_in_out, 1

        inc bx

        jmp read_params

    start_code:

        mov dx, offset input_name
        mov ax, 3d00h
        int 21h

		jnc next2
        jmp blogi_params
		next2:
		
        mov in_handle, ax                 ;issaugom ax instrukcija i in_handle

        mov dx, offset output_name

        mov cx, 0
        mov ah, 3ch
        int 21h

        jnc next3
        jmp blogi_params
		next3:

        mov out_handle, ax               ;tas pats tik su out_handle

        skaitymas:                       ;dirbam su vienu 255 bloku simboliais

            mov bx, in_handle            ;i bx patalpinam in_handle kuriame sedi musu failo instrukcija
            mov ah, 3fh
            mov cx, 255                  ;i cx patalpinam kiek norim nuskaityt is bloko 
            mov dx, offset buffer
            int 21h
			
			jnc next4
            jmp blogi_params             ; in case error happens
			next4:
			
            or ax, ax                   ;checkinam del zero flago, jeigu inpute nieko nera
            jz proofing

            mov simboliai, ax       ; issaugom visus simbolius, nes ivykstant programai ax patalpinama musu nuskaitytu simboliu reiksmes
            add visi_simboliai, ax ;issaugom visus_simbolius su add, jeigu ax > 255 tada ax tampa 0
            mov cx, ax                    ; del loopo i cx patalpinama visa ax 
            mov si, offset buffer 

            jmp tikrinti

    tikrinti: ;algorithm for checking values and later on jumping

        cmp byte ptr[si], 20h
		ja next6
        jmp check_garbage
		next6:

        mov if_space, 1                    ;pakeiciame if_space i 1 kai randame imboli o ne garbage value

        cmp byte ptr[si], 7Ah              ;checkinam reiksme si su mazaja z raide
		ja next5                           ;sukurtas naujas labelis tam, nes relative jump nepasiekia kito labelio per 127 eilutes
        jmp check_mazos
		next5:
		
        dec_cx:

        loop tikrinti 

    ;jei if_space = 1 ir baiges failas, zodziai++ 
      
    cmp simboliai, 255
    je skaitymas 
    
    cmp if_space, 1
    je inc_zodziai

    jmp skaiciuoti                     ; jump i output 
    
    proofing:
        cmp visi_simboliai, 0          ;jei nieko nera, baigiam faila
        je exit                        
        
        cmp if_space, 1                ;jeigu if_space 1 tai reiskia bus kitas zodis
        je inc_zodziai
    
    inc_zodziai:                       ;incrementinam zodzius ir tadda sokam i outputo labeli
        inc zodziai
        jmp skaiciuoti

    check_did:                         ;checkinam didziasias raides
        cmp byte ptr[si], 41h
        jae inc_did

        inc si

        jmp dec_cx

    inc_did:                           ;incrementinam didziasias raides
        inc didziosios
        inc si

        jmp dec_cx

    check_mazos:                       ;checkinam mazasias
        cmp byte ptr[si], 61h          ;byte ptr su si naudojam, tam kad byte su byte comparintume
        jae inc_mazos

        cmp byte ptr[si], 5Ah          ;tas pats
        jbe check_did

        inc si
        jmp dec_cx

    inc_mazos:                      ;incrementinam mazasiasias
        inc mazosios 
        inc si
        jmp dec_cx
    
    check_garbage:                 ;labelis, kuriame checkina del garbage values ASCII table nuo 0 iki 20 ( space'o )
        cmp if_space, 1
        je change_if_space

        inc si
        jmp dec_cx 

    change_if_space:              ;jeigu pastebi space'a, incrementina zodzius
        mov if_space, 0
        inc zodziai

        inc si
        jmp dec_cx

    blogi_params:                 ;netaisiklingai ivesti parametrai su cmd line args
        ;help zinute ismeta ir uzdaro faila bet baigia prog
        mov dx, offset blogi_parametrai
        mov ah, 09h
        int 21h

        mov ax, 4c00h
        int 21h
    exit:                         ;baigia kodo darba
        mov bx, in_handle

        mov ah, 3eh
        int 21h

        mov ax, 4c00h
        int 21h
        ;uzdarys faila ir baigs prog

    skaiciuoti:                 ;outputo labelis
        
        mov dx, offset msg_did  ;taip pat su visais zemiau, i dx patalpinama msg zinute, cx jos ilgis, new_lines labeli yra musu bx out_handle
                                ;ax bus musu algoritme suskaiciuotos reiksmes
        mov cx, 12
        call new_lines
        mov ax, didziosios 

        call convert

        mov dx, offset msg_maz
        mov cx, 10
        call new_lines
        mov ax, mazosios
        
        call convert

        mov dx, offset msg_simbol
        mov cx, 16
        call new_lines
        mov ax, visi_simboliai

        call convert

        mov dx, offset msg_zodziai
        mov cx, 9
        call new_lines
        mov ax, zodziai

        call convert

    jmp exit            ;sokam i pabaiga
    
    convert proc        ;procedura, kurioje convertina skaiciu i ascii ir isprintina ji
		mov si, offset skaiciai_output  ;sukurtas naujas bufferis, kad jame talpintume reiksmes
		xor cx, cx
		cmp ax, 0
		jne kartoti  
				
		mov dx, '0'     ;jei nera simboliu, dx gauna 0 ir ismetam 0 
		mov ah, 40h
		mov bx, out_handle
		mov cx, 1
		int 21h 
       
       jmp isvesti_new_line
       
        kartoti:      ;labelis, kuriame vyks pagrindinis convertinimas  

        xor cx, cx
        mov bx, 10

        cycle1:
        mov dx, 0
        div bx
        push dx
        inc cx

        cmp ax, 0
        jne cycle1

            ;mov si, offset skaiciai_output  
            cycle2:        ;40h isvedimo kodo dalis, lea dx tam, jog dx gautu bufferio adresa
                     ;std
            pop dx
            add dl, 48
            mov [si], dl
            inc si

            loop cycle2    ;loopinam tam, jog isvestu po viena skaiciu i faila

            mov dx, offset skaiciai_output
            mov ax, 4000h
            mov bx, out_handle
            mov cx, 5
            int 21h

            isvesti_new_line:   ;kodo dalis, kuri isveda messages

                 mov ax, 4000h 
                 mov bx, out_handle
                 mov cx, 1
                 mov dx, offset new_line
                 int 21h

        ret
    endp convert

        kartoti2:          ;jeigu skaicius trizenklis, uznulinam liekana, nes jau ji bus irasyta, ir mums nebereikia jos
            xor ah, ah
            jmp kartoti

new_lines proc             ;prints new  lines
    mov ax, 4000h 
    mov bx, out_handle
    int 21h

    ret
    endp new_lines

end start

