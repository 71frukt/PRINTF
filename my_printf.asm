;:================================================
;: my_printf.asm                        (c)Ya,2025
;:================================================

; nasm -f elf64 -l my_printf.lst my_printf.asm  ;  ld -s -o my_printf my_printf.o

%assign MAX_FORMAT_STR_LEN  100
%assign PRINTF_BUFFER_LEN   64

%assign MAX_INT_ASCII_LEN   18          ; 20 digits in max int (2^64)

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

        mov  rsi, PrintfBuffer          ; rsi = place to print in the buffer
        xor  rcx, rcx                   ; rcx = stack offset for addressing the argument for the current specifier. 
                                        ; argument for current specifier = [rbp + rcx * 8 + 16]
read_new_sym:
        cmp  rsi, PrintfBufferEnd
        jb   free_buffer
        push rdi
        call ResetPrintfBuffer
        pop  rdi

    free_buffer:
        mov  al, [rdi]                   ; al = symbol (rdi = spec str)
        inc  rdi

        test al, al                     ; if symbol = '\0'
        jz   end_of_spec_str

        cmp  al, '%'
        je  is_specifier

        ; lea  rbx, [ PrintfBuffer]
        mov  [rsi], al
        inc  rsi
        jmp  read_new_sym


is_specifier:
        xor  rax, rax
        mov  al, [rdi]                   ; al = specifier symbol
        inc  rdi

        sub  rax, '%'
        sal  rax, 1

        lea  rax, [PrintfJumpTable + rax]

        jmp  rax

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


;----------------------------------------------------------------------------------------
PrintfJumpTable:
    spec_percent:
        jmp print_percent

        db ('b' - '%') * 2 - 2 dup(0x90)

    spec_b:
        jmp print_bin
        
    spec_c:
        jmp print_char

    spec_d:
        jmp print_int

        db ('h' - 'd') * 2 - 2 dup(0x90)

    spec_h:
        jmp print_hex

        db ('o' - 'h') * 2 - 2 dup (0x90)
    
    spec_o:
        jmp print_octal

        db ('s' - 'o') * 2 - 2 dup(0x90)
        
    spec_s:
        jmp print_str


        
;----------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------

print_percent:
        mov  byte [rsi], '%'
        inc  rsi
        jmp read_new_sym

print_bin:
        mov  rax, [rbp + rcx * 8 + 16]
        inc  rcx
        push rdi
        call BinToASCII
        pop  rdi
        jmp  read_new_sym

print_char:
        mov  al, [rbp + rcx * 8 + 16]
        inc  rcx

        ; lea  rbx, [PrintfBuffer]
        mov  [rsi], al
        inc  rsi
        jmp  read_new_sym

print_int:
        mov  rax, [rbp + rcx * 8 + 16]
        inc  rcx

        push rdi
        call IntToASCII
        pop  rdi
        
        jmp  read_new_sym

print_str:
        mov  rax, [rbp + rcx * 8 + 16]
        inc  rcx
        push rdi

        next_char_print_str:
        cmp  rsi, PrintfBufferEnd
        jb   free_buffer_print_str
        call ResetPrintfBuffer

    free_buffer_print_str:
        mov  dil, [rax]
        mov  [rsi], dil
        inc  rax
        inc  rsi

        test dil, dil                   ; while != '\0'
        jnz  next_char_print_str

        dec  rsi                        ; remove '\0'

        pop  rdi
        jmp  read_new_sym

print_octal:
        mov  rax, [rbp + rcx * 8 + 16]
        inc  rcx

        push rdi
        call OctToASCII
        pop  rdi
        
        jmp  read_new_sym

print_hex:
        mov  rax, [rbp + rcx * 8 + 16]
        inc  rcx

        push rdi
        call HexToASCII
        pop  rdi
        
        jmp  read_new_sym

;=================================================================================



;=================================================================================
; Counts length of string formatted like ".. .."
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
; Converts the decimal number to ASCII
; Input:        rax = dec_num, rsi = dest_buffer
; Output:       rsi += printed_number_length
; Destroys:     rax, rbx, rdx, rsi, rdi
;=================================================================================
IntToASCII:
        mov  rdi, ConverterBuffer + MAX_INT_ASCII_LEN      ; rdi = end of buffer

        mov  rbx, 10                    ; in order to then div by 10 with the residue

        cdqe                            ; extend eax to rax in additional code 

        push rax
        test rax, rax
        jns  next_dec_digit             ; if is negative
        not  rax                        ; take positive part of num
        inc  rax

    next_dec_digit:
        cmp  rsi, PrintfBufferEnd
        jb   free_buffer_itoa
        call ResetPrintfBuffer

    free_buffer_itoa:
        xor  rdx, rdx
        div  rbx                        ; rdx = residue
        add  dl, '0'
        mov  [rdi], dl
        dec  rdi
        test rax, rax
        jnz  next_dec_digit

        lea  rbx, [ConverterBuffer + MAX_INT_ASCII_LEN]     ; rbx = end of buffer

        pop  rax
        test rax, rax
        jns  store_next_dec_digit   ; if is negative
        mov  dl, '-'                ; print minus
        mov  [rdi], dl
        dec  rdi

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
; Converts the binary number to ASCII
; Input:        rax = bin_num, rsi = dest_buffer
; Output:       rsi += printed_number_length
; Destroys:     rax, rbx, rdx, rsi, rdi
;=================================================================================
BinToASCII:
    ; rax = 00..01..
        xor  bh, bh                 ; bh = digit of rax (0 -> 64)

    skip_nulls_btoa:
        test rax, rax
        js   nulls_are_skipped_btoa ; if the highest bit == 1 --> nulls_are_skipped
        sal  rax, 1                 ; else shift left
        inc  bh                     ; counter++
        jmp  skip_nulls_btoa
    nulls_are_skipped_btoa:

    next_bin_digit:
        cmp  rsi, PrintfBufferEnd
        jb   free_buffer_btoa
        call ResetPrintfBuffer

    free_buffer_btoa:
        test rax, rax
        js   bit_1_btoa
        mov  bl, '0'
        jmp  print_bit_btoa

    bit_1_btoa:
        mov  bl, '1'

    print_bit_btoa:
        mov  [rsi], bl
        inc  rsi
        sal  rax, 1

        inc  bh
        cmp  bh, 64
        jb   next_bin_digit

        ret
;=================================================================================


;=================================================================================
; Converts the octal number to ASCII
; Input:        rax = dec_num, rsi = dest_buffer
; Output:       rsi += printed_number_length
; Destroys:     rax, rbx, rdx, rsi, rdi
;=================================================================================
OctToASCII:
        mov  rdi, ConverterBuffer + MAX_INT_ASCII_LEN      ; rdi = end of buffer

    next_oct_digit:
        cmp  rsi, PrintfBufferEnd
        jb   free_buffer_otoa
        call ResetPrintfBuffer

    free_buffer_otoa:
        mov  dl, al
        and  dl, 7
        sar  rax, 3

        add  dl, '0'
        mov  [rdi], dl
        dec  rdi
        test rax, rax
        jnz  next_oct_digit

        inc  rdi                        ; rdi to start of res str

        lea  rbx, [ConverterBuffer + MAX_INT_ASCII_LEN]      ; rbx = end of buffer

    store_next_oct_digit:
        mov  al, [rdi]
        mov  [rsi], al
        inc  rdi
        inc  rsi
        cmp  rdi, rbx
        jbe  store_next_oct_digit
        
        ret
;=================================================================================



;=================================================================================
; Converts a string ending with a space to a hexadecimal number
; after work of the func si indicates on the next arg
;
; Input:        rax = dec_num, rsi = dest_buffer
; Output:       rsi += printed_number_length
; Destroys:     rax, rbx, rdx, rsi, rdi
;=================================================================================
HexToASCII:
        xor  bh, bh                 ; bh = digit of rax (0 -> 16)

    skip_nulls_htoa:
        rol  rax, 4
        mov  bl, al                 ; 2nd half of bl = cur_digit
        and  bl, 0x0F
        
        test bl, bl

        jnz  nulls_are_skipped_htoa

        inc  bh                     ; counter++
        jmp  skip_nulls_htoa
    nulls_are_skipped_htoa:

    next_hex_digit:
        mov  bl,  al                ; bl = cur_digit
        and  bl, 0x0F

        rol  rax, 4

        cmp  bl, 9h
        ja   is_letter_htoa
        add  bl, '0'    
        jmp  is_parsed_htoa

    is_letter_htoa:
        add  bl, 'A' - 0Ah

    is_parsed_htoa:
        mov  [rsi], bl
        inc  rsi

        inc  bh
        cmp  bh, 16
        jb   next_hex_digit

        ret
;=================================================================================




;=================================================================================
; Resets the PrintfBuffer to the console
; Input:        rsi = filled buffer end
; Output:       rsi = buffer start
; Destroys:     rdi, rsi, rax, rdx
;=================================================================================
ResetPrintfBuffer:
        mov  rdx, rsi
        sub  rdx, PrintfBuffer
        mov  rsi, PrintfBuffer

        mov  rdi, 1                     ; file descriptor (1 = stdout)
        mov  rax, 1                     ; write syscall
        
        push rcx
        syscall 
        pop  rcx       

        ret
;=================================================================================

section     .data
 

PrintfBuffer db PRINTF_BUFFER_LEN dup (0)
PrintfBufferEnd:

db           'DETSKOE PORNO'
ConverterBuffer   db MAX_INT_ASCII_LEN dup (0)

section     .note.GNU-stack noalloc noexec nowrite progbits