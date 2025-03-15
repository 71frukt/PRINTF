;:================================================
;: my_printf.asm                        (c)Ya,2025
;:================================================

; nasm -f elf64 -l my_printf.lst my_printf.asm  ;  ld -s -o my_printf my_printf.o

%assign MAX_FORMAT_STR_LEN  100
%assign PRINTF_BUFFER_LEN   128

%assign MAX_INT_ASCII_LEN   20          ; 20 digits in max int (2^64)

section .text

global MyPrintf            ; predefined entry point name for ld


;=================================================================================
; My Printf
;
; Input:    rdi = format str; rsi..r9, stack = other args
; Output:   
; Destroys: rax, rcx, rdx, rsi, rdi
;=================================================================================
MyPrintf:
        pop  rax                        ; return addr -> rax
        push r9                         ; 2..n args in stack, rdi remains eq format str
        push r8
        push rcx
        push rdx
        push rsi
        push rax                        ; return addr -> stack


        push rbp                        ; install the stack frame
        mov  rbp, rsp                   ; [rbp + 0*8 + 16] = 2nd arg

        lea  rsi, [rel PrintfBuffer]    ; rsi = place to print in the buffer
        ; xor  rsi, rsi                   ; rsi = buffer len: the first free cell in buffer = [rel PrintfBuffer + rsi]
        xor  rcx, rcx                   ; rcx = stack offset for addressing the argument for the current specifier. 
                                        ; argument for current specifier = [rbp + rcx * 8 + 16]
read_new_sym:
        mov  al, [rdi]                   ; al = symbol
        inc  rdi

        test al, al                     ; if symbol = '\0'
        jz   end_of_spec_str

        cmp  al, '%'
        je  is_specifier

        ; lea  rbx, [rel PrintfBuffer]
        mov  [rsi], al
        inc  rsi
        jmp  read_new_sym


is_specifier:
        mov  al, [rdi]                   ; al = specifier symbol
        inc  rdi

        cmp  al, 'c'
        je   print_char

        cmp  al, 'd'
        je   print_int



end_of_spec_str:
        ; mov  eax, dword [rbp + 16]
        ; mov  dword [rsi], eax
        ; mov  byte  [rsi + 4], 0

        call ResetPrintfBuffer

        leave
        pop  rax                        ; ret addr is there
        add  rsp, 5 * 8                 ; clean up the stack after yourself
        push rax                        ; ret addr back to where it was
        ret
;----------------------------------------------------------------------------------------


print_char:
        mov  al, [rbp + rcx * 8 + 16]
        inc  rcx

        ; lea  rbx, [rel PrintfBuffer]
        mov  [rsi], al
        inc  rsi
        jmp  read_new_sym

print_int:
        lea  rbx, [rel PrintfBufferEnd]
        cmp  rsi, rbx
        jna  buf_is_ready_print_int
        call ResetPrintfBuffer

    buf_is_ready_print_int:
        mov  rax, [rbp + rcx * 8 + 16]
        inc  rcx

        push rdi
        call ItoA_dec
        pop rdi
        
        jmp  read_new_sym





;=================================================================================
; Counts length of string formated like ".. .."
;
; Input:        rdi = str_pointer
; Output:       rax = length (excluding "")
; Destroys:     rax, rcx, rdi
;=================================================================================
CountStrLen:
        inc  rdi                           ; excluding opening "
        mov  rax, '"'                      ; = "
        mov  rcx, MAX_FORMAT_STR_LEN

        repne scasb

        mov  rax, MAX_FORMAT_STR_LEN - 1    ; excluding closing "
        sub  rax, rcx

        ret
;=================================================================================



;=================================================================================
; Converts the decimal number
; Input:        rax = dec_num, rsi = dest_buffer
; Output:       rsi += printed_number_length
; Destroys:     rax, rbx, rsi, rdi
;=================================================================================
ItoA_dec:
        lea  rdi, [rel ItoABuffer]
        add  rdi, MAX_INT_ASCII_LEN     ; rdi = end of buffer

        mov  rbx, 10                    ; in order to then div by 10 with the residue

    next_dec_digit:
        xor  dl, dl
        div  rbx                        ; rdx = residue
        add  dl, '0'
        mov  [rdi], dl
        dec  rdi
        test rax, rax
        jnz  next_dec_digit

        inc  rdi                        ; rdi to start of res str

        lea  rbx, [rel ItoABuffer]
        add  rbx, MAX_INT_ASCII_LEN     ; rbx = end of buffer

    store_next_dec_digit:
        mov  al, [rdi]
        mov  [rsi], al
        inc  rdi
        inc  rsi
        cmp  rdi, rbx
        jbe  store_next_dec_digit
        
        ret
;=================================================================================



;=================================================================================
; Resets the PrintfBuffer to the console
; Input:        rsi = filled buffer end
; Output:       none
; Destroys:     rdi, rax, rdx
;=================================================================================
ResetPrintfBuffer:
        push rsi

        lea  rdx, [rel PrintfBufferEnd]
        sub  rdx, rsi
        lea  rsi, [rel PrintfBuffer]    ; buffer

        mov  rdi, 1                     ; file descriptor (1 = stdout)
        mov  rax, 1                     ; write syscall
        syscall        

        pop rsi
        ret
;=================================================================================

section     .data
 

Msg:        db "__Hllwrld", 0x0a
MsgLen      equ $ - Msg


; section     .bss
PrintfBuffer db PRINTF_BUFFER_LEN dup (0)
PrintfBufferEnd:

db           'DETSKOE PORNO'
ItoABuffer   db MAX_INT_ASCII_LEN dup (0)

section     .note.GNU-stack noalloc noexec nowrite progbits