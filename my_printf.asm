;:================================================
;: my_printf.asm                        (c)Ya,2025
;:================================================

; nasm -f elf64 -l my_printf.lst my_printf.asm  ;  ld -s -o my_printf my_printf.o

%assign MAX_FORMAT_STR_LEN  100
%assign PRINTF_BUFFER_LEN   255

%assign MAX_NUM_ASCII_LEN   10          ; 10 digits in max int (2^64)

%assign FRAC_LENGTH         52
%assign EXP_LENGTH          11
%assign BIAS                1023

%assign CHECK_INF_MASK      0x00000000000007FF      ; first leftward EXP_LENGTH bites = 1, the others = 0
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

        sub rsp, 8
        movsd [rsp], xmm7

        sub rsp, 8
        movsd [rsp], xmm6

        sub rsp, 8
        movsd [rsp], xmm5

        sub rsp, 8
        movsd [rsp], xmm4

        sub rsp, 8
        movsd [rsp], xmm3

        sub rsp, 8
        movsd [rsp], xmm2

        sub rsp, 8
        movsd [rsp], xmm1

        sub rsp, 8
        movsd [rsp], xmm0

        push rax                        ; return addr -> stack


        push rbp                        ; install the stack frame
        mov  rbp, rsp

        mov  rsi, PrintfBuffer          ; rsi = place to print in the buffer

        xor  rcx, rcx
                                        ; cl - number of current usual %_ arg, ch - for current double arg
                                        ; argument for usual %_ = [rbp + cl * 8 + 16 + 8*8]
                                        ; argument for %f       = [rbp + cl * 8 + 16 + 8*8] , ch >= 8
                                        ; argument for %f       = [rbp + ch * 8 + 16]       , ch <  8

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

        mov  [rsi], al
        inc  rsi
        jmp  read_new_sym


is_specifier:
        xor  rax, rax
        mov  al, [rdi]                   ; al = specifier symbol
        inc  rdi

        sub  rax, '%'
        lea  rax, [rax * 4 + rax]       ; rax *= 5  (5 because near jump - 5 bytes on each instruction)

        lea  rax, [PrintfJumpTable + rax]
        jmp  rax

end_of_spec_str:
        call ResetPrintfBuffer

        leave
        pop  rax                        ; ret addr is there
        add  rsp, 13 * 8                ; TODO clean up the stack after yourself
        push rax                        ; ret addr back to where it was
        ret
;----------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------
PrintfJumpTable:

    spec_percent:
        jmp near print_percent

        db ('b' - '%') * 5 - 5 dup(0x90)

    spec_b:
        jmp near print_bin
        
    spec_c:
        jmp near print_char

    spec_d:
        jmp near print_int

        db ('f' - 'd') * 5 - 5 dup(0x90)

    spec_f:
        jmp near print_double

        db ('o' - 'f') * 5 - 5 dup(0x90)
    
    spec_o:
        jmp near print_octal

        db ('s' - 'o') * 5 - 5 dup(0x90)
        
    spec_s:
        jmp near print_str

        db ('x' - 's') * 5 - 5 dup (0x90)

    spec_x:
        jmp near print_hex
        
;----------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------

print_percent:
        mov  byte [rsi], '%'
        inc  rsi
        jmp read_new_sym

print_bin:
        push rcx
        xor  ch, ch
        mov  rax, [rbp + rcx * 8 + 16 + 8*8]
        pop  rcx
        inc  cl
        push rdi
        call BinToASCII
        pop  rdi
        jmp  read_new_sym

print_char:
        push rcx
        xor  ch, ch
        mov  al, [rbp + rcx * 8 + 16 + 8*8]
        pop  rcx
        inc  cl

        ; lea  rbx, [PrintfBuffer]
        mov  [rsi], al
        inc  rsi
        jmp  read_new_sym

print_int:
        cmp  cl, 5
        jae  usual_arg_in_stack_pr_int        ; если количество обычных аргументов уже больше 5, то они изначально были переданы через стек
        
        push rcx
        xor  ch, ch
        mov  rax, [rbp + rcx * 8 + 16 + 8*8]
        pop  rcx
        inc  cl   
        jmp print_res_int

    usual_arg_in_stack_pr_int:
        push rcx
        sub  cl, 5                          ; количество обычных аргументов, переданных через стек

        cmp  ch, 8                          ; количество double  аргументов, переданных через стек
        jae  double_arg_in_stack_pr_int  
        mov  ch, 8
    double_arg_in_stack_pr_int:
        sub  ch, 8

        add  cl, ch                         ; rcx = сколько всего аргументов передали через стек
        xor  ch, ch

        mov  rax, [rbp + rcx * 8 + 16 + (8 + 5) * 8]
        pop  rcx
        inc  cl
        
    print_res_int:
        push rdi
        call IntToASCII
        pop  rdi
        
        jmp  read_new_sym 


print_str:
        cmp  cl, 5
        jae  usual_arg_in_stack_pr_str        ; если количество обычных аргументов уже больше 5, то они изначально были переданы через стек
        
        push rcx
        xor  ch, ch
        mov  rax, [rbp + rcx * 8 + 16 + 8*8]
        pop  rcx
        inc  cl   
        jmp print_res_str

    usual_arg_in_stack_pr_str:
        push rcx
        sub  cl, 5                          ; количество обычных аргументов, переданных через стек

        cmp  ch, 8                          ; количество double  аргументов, переданных через стек
        jae  double_arg_in_stack_pr_str  
        mov  ch, 8
    double_arg_in_stack_pr_str:
        sub  ch, 8

        add  cl, ch                         ; rcx = сколько всего аргументов передали через стек
        xor  ch, ch

        mov  rax, [rbp + rcx * 8 + 16 + (8 + 5) * 8]
        pop  rcx
        inc  cl
        
    ; print_res_oct:
    ;     push rdi
    ;     call OctToASCII
    ;     pop  rdi
        
    ;     jmp  read_new_sym 


    ;     push rcx
    ;     xor  ch, ch
    ;     mov  rax, [rbp + rcx * 8 + 16 + 8*8]
    ;     pop  rcx
    ;     inc  cl
    print_res_str:
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
        cmp  cl, 5
        jae  usual_arg_in_stack_pr_oct        ; если количество обычных аргументов уже больше 5, то они изначально были переданы через стек
        
        push rcx
        xor  ch, ch
        mov  rax, [rbp + rcx * 8 + 16 + 8*8]
        pop  rcx
        inc  cl   
        jmp print_res_oct

    usual_arg_in_stack_pr_oct:
        push rcx
        sub  cl, 5                          ; количество обычных аргументов, переданных через стек

        cmp  ch, 8                          ; количество double  аргументов, переданных через стек
        jae  double_arg_in_stack_pr_oct  
        mov  ch, 8
    double_arg_in_stack_pr_oct:
        sub  ch, 8

        add  cl, ch                         ; rcx = сколько всего аргументов передали через стек
        xor  ch, ch

        mov  rax, [rbp + rcx * 8 + 16 + (8 + 5) * 8]
        pop  rcx
        inc  cl
        
    print_res_oct:
        push rdi
        call OctToASCII
        pop  rdi
        
        jmp  read_new_sym 


print_hex:
        cmp  cl, 5
        jae  usual_arg_in_stack_pr_hex        ; если количество обычных аргументов уже больше 5, то они изначально были переданы через стек
        
        push rcx
        xor  ch, ch
        mov  rax, [rbp + rcx * 8 + 16 + 8*8]
        pop  rcx
        inc  cl   
        jmp print_res_hex

    usual_arg_in_stack_pr_hex:
        push rcx
        sub  cl, 5                          ; количество обычных аргументов, переданных через стек

        cmp  ch, 8                          ; количество double  аргументов, переданных через стек
        jae  double_arg_in_stack_pr_hex  
        mov  ch, 8
    double_arg_in_stack_pr_hex:
        sub  ch, 8

        add  cl, ch                         ; rcx = сколько всего аргументов передали через стек
        xor  ch, ch

        mov  rax, [rbp + rcx * 8 + 16 + (8 + 5) * 8]
        pop  rcx
        inc  cl
        
    print_res_hex:
        push rdi
        call HexToASCII
        pop  rdi
        
        jmp  read_new_sym 


print_double:
        cmp  ch, 8
        jae  double_arg_in_stack_pr_double

        push rcx
        xor  cl, cl
        sar  rcx, 8     ; rcx = ch = cur num of xmm arg
        ; rbp + ch * 8 + 16
        movsd xmm0, [rbp + rcx * 8 + 16]
        pop  rcx
        inc  ch
        jmp  print_res_double

    double_arg_in_stack_pr_double:
        push rcx
        sub  ch, 8

        cmp  cl, 5                         ; количество обычных аргументов, переданных через стек
        jae  usual_arg_in_stack_pr_double
        mov  cl, 5
    usual_arg_in_stack_pr_double:
        sub  cl, 5

        add  cl, ch                         ; rcx = сколько всего аргументов передали через стек
        xor  ch, ch

        movsd xmm0, [rbp + rcx * 8 + 16 + (8 + 5)*8]
        pop  rcx
        inc  ch

    print_res_double:
        push rdi
        call DoubleToASCII
        pop  rdi
        
        jmp  read_new_sym
;=================================================================================


;=================================================================================
; Converts the decimal number to ASCII
; Input:        rax = dec_num, rsi = dest_buffer
; Output:       rsi += printed_number_length
; Destroys:     rax, rbx, rdx, rsi, rdi
;=================================================================================
IntToASCII:
        mov  rdi, ConverterBuffer + MAX_NUM_ASCII_LEN      ; rdi = end of buffer

        mov  rbx, 10                    ; in order to then div by 10 with the remainder

        cdqe                            ; extend eax to rax in additional code 

        push rax
        test rax, rax
        jns  next_dec_digit             ; if is negative
        not  rax                        ; take positive part of num
        inc  rax

    next_dec_digit:
        xor  rdx, rdx
        div  rbx                        ; rdx = remainder
        add  dl, '0'
        mov  [rdi], dl
        dec  rdi
        test rax, rax
        jnz  next_dec_digit

        lea  rbx, [ConverterBuffer + MAX_NUM_ASCII_LEN]     ; rbx = end of buffer

        pop  rax
        test rax, rax
        jns  store_dec_num   ; if is negative
        mov  dl, '-'                ; print minus
        mov  [rdi], dl
        dec  rdi


        push rsi
        add  rsi, MAX_NUM_ASCII_LEN
        cmp  rsi, PrintfBufferEnd
        pop  rsi
        jb   store_dec_num

        push rdi
        call ResetPrintfBuffer
        pop  rdi

    store_dec_num:
        inc  rdi

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
        mov  rdi, ConverterBuffer + MAX_NUM_ASCII_LEN      ; rdi = end of buffer

    next_oct_digit:
        mov  dl, al
        and  dl, 7
        sar  rax, 3

        add  dl, '0'
        mov  [rdi], dl
        dec  rdi
        test rax, rax
        jnz  next_oct_digit

        inc  rdi                        ; rdi to start of res str

        lea  rbx, [ConverterBuffer + MAX_NUM_ASCII_LEN]      ; rbx = end of buffer

        push rsi
        add  rsi, MAX_NUM_ASCII_LEN
        cmp  rsi, PrintfBufferEnd
        pop  rsi
        jb   store_next_oct_digit

        push rdi
        call ResetPrintfBuffer
        pop  rdi

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
; Destroys:     rax, rbx, rsi, rdi
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
; Converts double number to ascii
; Input:    xmm0 = the bit sequence of double number; rsi = dest_buffer
; Output:   rsi += printed_number_length
; Destroys: xmm0, xmm1, xmm2, rax, rbx, rdx, rsi, rdi
;=================================================================================
DoubleToASCII:
        movq rax, xmm0
        push rax
        shl  rax, 1
        shr  rax, FRAC_LENGTH + 1          ; rax = exp  и отбросить бит знака
        xor  rax, CHECK_INF_MASK
        pop  rax
        jnz  normal_number

        ; это бесконечность или NAN
        push rax
        sal  rax, EXP_LENGTH + 1
        test rax, rax
        pop  rax
        jnz  is_nan

        ; это бесконечность
        rol  rax, 1                         ; проверка на бит знака
        test rax, 1
        ror  rax, 1
        jz    positive_inf
        mov  byte [rsi],     '-'
        inc  rsi

    positive_inf:
        mov  byte [rsi],     'i'
        mov  byte [rsi + 1], 'n'
        mov  byte [rsi + 2], 'f'
        add  rsi, 3
        ret

    is_nan:
        mov  byte [rsi],     'n'
        mov  byte [rsi + 1], 'a'
        mov  byte [rsi + 2], 'n'
        add  rsi, 3
        ret

    normal_number:
        roundsd xmm1, xmm0, 3           ; округление в сторону нуля  
        cvttsd2si rax, xmm1             ; rax = целая часть

        movsd xmm2, [taking_modulo_mask]    ; обнуление старшего (знакового) бита
        andpd xmm0, xmm2
        andpd xmm1, xmm2
        subsd xmm0, xmm1                ; xmm0 = дробная часть
        
        call IntToASCII
        mov  dl, '.'                    ; print '.'
        mov  [rsi], dl
        inc  rsi

        movsd xmm1, [FracMultiplier]    ; xmm1 = 10^8
        mulsd xmm0, xmm1                ; дробная часть с точностью до 8 знака после запятой
        cvttsd2si rax, xmm0             ; rax = дробная часть

        push rax
        push rcx
        mov  rbx, 10
        mov  rcx, 8                     ; rcx = сколько нулей нужно напечатать

    ; посчитать нули
        jmp test_frac_digit
    count_first_frac_nulls:             ; всего 8 цифр, IntToASCII печатает существенную часть, недостающие нули нужно напечатать самим
        dec  rcx
        test rcx, rcx
        jz   print_frac_nulls           ; если цифр больше 8 напечатать 8

    test_frac_digit:
        xor  rdx, rdx
        div  rbx                        ; rdx = остаток от деления на 10  =  цифра числа
        or   rdx, rax
        test rdx, rdx                   ; если цифра ноль и оставшееся число = 0, то все цифры подсчитаны
        jnz  count_first_frac_nulls


    ; напечатать недостающие нули
        jmp print_frac_nulls
    print_next_frac_null:

        cmp  rsi, PrintfBufferEnd       ; сбросить буфер если полон
        jb   free_buffer_dtoa
        call ResetPrintfBuffer
        free_buffer_dtoa:

        mov  byte [rsi], '0'
        inc  rsi
        dec  rcx
    print_frac_nulls:
        test rcx, rcx
        jnz  print_next_frac_null


        pop  rcx
        pop  rax

        call IntToASCII                 ; напечатать rax = дробная часть

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

ConverterBuffer db MAX_NUM_ASCII_LEN dup (0)

align 16
FracMultiplier      dq 100000000.0  ; 10^8 в формате double
taking_modulo_mask  dq 0x7FFFFFFFFFFFFFFF