global _start


; Macro to print a string with its length
%macro print 1
    mov rdx, %1_len      ; Set length of string
    mov rsi, %1          ; Set pointer to string
    mov rax, SYS_WRITE   ; Set syscall to write
    mov rdi, STDOUT      ; Set output to stdout
    syscall              ; Call kernel
%endmacro

; Macro to print error message and exit
%macro print_error 1
    mov rdx, %1_len      ; Set length of error message
    mov rsi, %1          ; Set pointer to error message
    mov rax, SYS_WRITE   ; Set syscall to write
    mov rdi, STDERR      ; Set output to stderr
    syscall              ; Call kernel
    mov rdi, 1           ; Set exit code to 1 (error)
    jmp exit             ; Jump to exit
%endmacro

section .text

_start:
    ; Check number of arguments
    mov rax, [rsp]       ; Load argc from stack
    cmp rax, 3           ; Check if at least 3 arguments (program + 2 args)
    jl _error_too_few_arguments ; Jump to error if too few arguments

    ; Convert first argument to floating-point number
    mov rbx, [rsp + 16]  ; Load address of first argument
    call _atof           ; Convert string to float (result in xmm0)
    movsd [num1], xmm0   ; Store result in num1

    ; Convert second argument to floating-point number
    mov rbx, [rsp + 24]  ; Load address of second argument
    call _atof           ; Convert string to float (result in xmm0)
    movsd [num2], xmm0   ; Store result in num2

    ; Print results of arithmetic operations
    call _print_addition_result      ; Print addition result
    call _print_subtraction_result   ; Print subtraction result
    call _print_multiplication_result ; Print multiplication result
    call _print_division_result      ; Print division result

    xor rdi, rdi         ; Set exit code to 0 (success)
exit:
    mov rax, SYS_EXIT    ; Set syscall to exit
    syscall              ; Call kernel to exit

; Error handlers
_error_too_few_arguments:
    print_error error_too_few_args ; Print error for too few arguments

_error_division_by_zero:
    print_error error_division_by_zero ; Print error for division by zero

_error_invalid_number:
    print_error error_invalid_number ; Print error for invalid number format

; Function: Convert string to floating-point number
; Input: rbx - pointer to string
; Output: xmm0 - floating-point number
_atof:
    xor rcx, rcx         ; Clear character counter
    xor rax, rax         ; Clear integer part
    xor r8, r8           ; Clear fractional part
    xor r9, r9           ; Clear fractional digit counter
    mov r10, 1           ; Set sign to positive (+1)
    pxor xmm0, xmm0      ; Clear result register

    ; Check for sign
    movzx rsi, byte [rbx] ; Load first character
    cmp rsi, '-'         ; Check for negative sign
    jne .check_plus      ; If not '-', check for '+'
    mov r10, -1          ; Set sign to negative
    inc rcx              ; Skip sign character
    jmp .parse_integer   ; Start parsing integer part
.check_plus:
    cmp rsi, '+'         ; Check for positive sign
    jne .parse_integer   ; If not '+', start parsing
    inc rcx              ; Skip sign character

.parse_integer:
    movzx rsi, byte [rbx + rcx] ; Load next character
    cmp rsi, '.'         ; Check for decimal point
    je .parse_fraction   ; If found, parse fractional part
    cmp rsi, 0           ; Check for end of string
    je .convert          ; If end, convert to number
    cmp rsi, '0'         ; Check if less than '0'
    jl _error_invalid_number ; Invalid if less than '0'
    cmp rsi, '9'         ; Check if greater than '9'
    jg _error_invalid_number ; Invalid if greater than '9'
    sub rsi, '0'         ; Convert character to digit
    imul rax, 10         ; Multiply integer part by 10
    add rax, rsi         ; Add new digit
    inc rcx              ; Move to next character
    jmp .parse_integer   ; Continue parsing integer

.parse_fraction:
    inc rcx              ; Skip decimal point
.parse_fraction_loop:
    movzx rsi, byte [rbx + rcx] ; Load next character
    cmp rsi, 0           ; Check for end of string
    je .convert          ; If end, convert to number
    cmp rsi, '0'         ; Check if less than '0'
    jl _error_invalid_number ; Invalid if less than '0'
    cmp rsi, '9'         ; Check if greater than '9'
    jg _error_invalid_number ; Invalid if greater than '9'
    sub rsi, '0'         ; Convert character to digit
    imul r8, 10          ; Multiply fractional part by 10
    add r8, rsi          ; Add new digit
    inc r9               ; Increment fractional digit counter
    inc rcx              ; Move to next character
    jmp .parse_fraction_loop ; Continue parsing fractional part

.convert:
    cvtsi2sd xmm0, rax   ; Convert integer part to double
    test r9, r9          ; Check if fractional part exists
    jz .apply_sign       ; If no fractional part, apply sign
    cvtsi2sd xmm1, r8    ; Convert fractional part to double
    mov rax, 10          ; Set divisor to 10
    cvtsi2sd xmm2, rax   ; Convert 10 to double
    mov rcx, r9          ; Load number of fractional digits
.power_loop:
    test rcx, rcx        ; Check if more digits to process
    jz .add_fraction     ; If done, add fractional part
    divsd xmm1, xmm2     ; Divide fractional part by 10
    dec rcx              ; Decrease digit counter
    jmp .power_loop      ; Continue dividing
.add_fraction:
    addsd xmm0, xmm1     ; Add fractional part to integer part
.apply_sign:
    cmp r10, -1          ; Check if negative sign
    jne .done            ; If positive, finish
    movsd xmm1, [minus_one] ; Load -1.0
    mulsd xmm0, xmm1     ; Apply negative sign
.done:
    ret                  ; Return from function

; Function: Print integer to stdout
; Input: rdi - integer to print
_print_digit:
    mov rax, rdi         ; Load number to print
    mov rbx, 10          ; Set divisor to 10
    lea rsi, [buffer + 20] ; Point to end of buffer
    mov rcx, rsi         ; Save end of buffer
    mov r11, 1           ; Set sign to positive
    test rax, rax        ; Check if number is negative
    jge .convert_digits  ; If positive, convert digits
    neg rax              ; Make number positive
    mov r11, -1          ; Set sign to negative

.convert_digits:
    xor rdx, rdx         ; Clear remainder
    div rbx              ; Divide by 10: rax = quotient, rdx = remainder
    dec rsi              ; Move buffer pointer left
    add dl, '0'          ; Convert remainder to ASCII
    mov [rsi], dl        ; Store digit in buffer
    test rax, rax        ; Check if more digits remain
    jnz .convert_digits  ; If yes, continue
    cmp r11, 1           ; Check if number was positive
    je .print_number     ; If positive, print
    dec rsi              ; Move buffer pointer left
    mov byte [rsi], '-'  ; Add negative sign

.print_number:
    mov rdx, rcx         ; Calculate string length
    sub rdx, rsi         ; Length = end - start
    mov rax, SYS_WRITE   ; Set syscall to write
    mov rdi, STDOUT      ; Set output to stdout
    syscall              ; Call kernel to print
    ret                  ; Return from function

; Function: Print floating-point number to stdout
; Input: xmm0 - number to print
_print_float:
    movsd xmm1, [zero]   ; Load 0.0 for comparison
    comisd xmm0, xmm1    ; Compare number with 0
    jae .positive        ; If positive or zero, skip sign
    print minus_sign_num_indicator ; Print negative sign
    movsd xmm1, [minus_one] ; Load -1.0
    mulsd xmm0, xmm1     ; Make number positive

.positive:
    cvttsd2si rdi, xmm0  ; Convert integer part to integer
    call _print_digit    ; Print integer part
    print dot_sign       ; Print decimal point
    cvttsd2si rax, xmm0  ; Convert integer part to integer
    cvtsi2sd xmm1, rax   ; Convert back to double
    subsd xmm0, xmm1     ; Get fractional part
    movsd xmm1, [fraction_multiplier] ; Load 1000000.0
    mulsd xmm0, xmm1     ; Multiply to get 6 decimal places
    cvttsd2si rdi, xmm0  ; Convert fractional part to integer
    test rdi, rdi        ; Check if negative
    jge .print_fraction  ; If positive, print
    neg rdi              ; Make positive

.print_fraction:
    mov rax, rdi         ; Load fractional part
    mov rcx, 6           ; Set number of digits to print
    lea rsi, [buffer + 20] ; Point to end of buffer
    mov r8, rsi          ; Save end of buffer

.fraction_loop:
    xor rdx, rdx         ; Clear remainder
    mov rbx, 10          ; Set divisor to 10
    div rbx              ; Divide by 10: rax = quotient, rdx = remainder
    dec rsi              ; Move buffer pointer left
    add dl, '0'          ; Convert remainder to ASCII
    mov [rsi], dl        ; Store digit in buffer
    dec rcx              ; Decrease digit counter
    test rcx, rcx        ; Check if more digits needed
    jnz .fraction_loop   ; If yes, continue

.remove_trailing_zeros:
    cmp rsi, rcx         ; Check if at end of buffer
    jae .print_fraction_result ; If yes, print result
    cmp byte [rcx], '0'  ; Check for trailing zero
    jne .print_fraction_result ; If not zero, print result
    dec rcx              ; Move to previous digit
    jmp .remove_trailing_zeros ; Continue checking

.print_fraction_result:
    inc rcx              ; Include last non-zero digit
    mov rdx, rcx         ; Calculate string length
    sub rdx, rsi         ; Length = end - start
    mov rax, SYS_WRITE   ; Set syscall to write
    mov rdi, STDOUT      ; Set output to stdout
    syscall              ; Call kernel to print
    ret                  ; Return from function

; Function: Print addition result
_print_addition_result:
    movsd xmm0, [num1]   ; Load first number
    call _print_float     ; Print first number
    print plus_sign      ; Print "+" sign
    movsd xmm0, [num2]   ; Load second number
    call _print_float     ; Print second number
    print equal_sign     ; Print "=" sign
    movsd xmm0, [num1]   ; Load first number
    addsd xmm0, [num2]   ; Add second number
    call _print_float     ; Print result
    print newline        ; Print newline
    ret                  ; Return from function

; Function: Print subtraction result
_print_subtraction_result:
    movsd xmm0, [num1]   ; Load first number
    call _print_float     ; Print first number
    print minus_sign_operation ; Print "-" sign
    movsd xmm0, [num2]   ; Load second number
    call _print_float     ; Print second number
    print equal_sign     ; Print "=" sign
    movsd xmm0, [num1]   ; Load first number
    subsd xmm0, [num2]   ; Subtract second number
    call _print_float     ; Print result
    print newline        ; Print newline
    ret                  ; Return from function

; Function: Print multiplication result
_print_multiplication_result:
    movsd xmm0, [num1]   ; Load first number
    call _print_float     ; Print first number
    print multiplication_sign ; Print "*" sign
    movsd xmm0, [num2]   ; Load second number
    call _print_float     ; Print second number
    print equal_sign     ; Print "=" sign
    movsd xmm0, [num1]   ; Load first number
    mulsd xmm0, [num2]   ; Multiply by second number
    call _print_float     ; Print result
    print newline        ; Print newline
    ret                  ; Return from function

; Function: Print division result
_print_division_result:
    movsd xmm0, [num2]   ; Load second number
    movsd xmm1, [zero]   ; Load 0.0
    comisd xmm0, xmm1    ; Compare with zero
    je _error_division_by_zero ; If zero, handle error
    movsd xmm0, [num1]   ; Load first number
    call _print_float     ; Print first number
    print division_sign  ; Print "/" sign
    movsd xmm0, [num2]   ; Load second number
    call _print_float     ; Print second number
    print equal_sign     ; Print "=" sign
    movsd xmm0, [num1]   ; Load first number
    divsd xmm0, [num2]   ; Divide by second number
    call _print_float     ; Print result
    print newline        ; Print newline
    ret                  ; Return from function

section .data
    ; Error messages
    error_too_few_args db "[Error]: too few arguments. Two arguments at least ...", 10
    error_too_few_args_len equ $ - error_too_few_args ; Length of error message
    error_division_by_zero db "[Error]: Incorrect operation: division by zero", 10
    error_division_by_zero_len equ $ - error_division_by_zero ; Length of error message
    error_invalid_number db "[Error]: Invalid number format", 10
    error_invalid_number_len equ $ - error_invalid_number ; Length of error message

    ; Mathematical symbols
    plus_sign db " + "   ; Addition sign
    plus_sign_len equ $ - plus_sign ; Length of addition sign
    minus_sign_operation db " - " ; Subtraction sign
    minus_sign_operation_len equ $ - minus_sign_operation ; Length of subtraction sign
    minus_sign_num_indicator db "-" ; Negative sign for numbers
    minus_sign_num_indicator_len equ $ - minus_sign_num_indicator ; Length of negative sign
    multiplication_sign db " * " ; Multiplication sign
    multiplication_sign_len equ $ - multiplication_sign ; Length of multiplication sign
    division_sign db " / " ; Division sign
    division_sign_len equ $ - division_sign ; Length of division sign
    equal_sign db " = "  ; Equal sign
    equal_sign_len equ $ - equal_sign ; Length of equal sign
    dot_sign db "."      ; Decimal point
    dot_sign_len equ $ - dot_sign ; Length of decimal point
    newline db 10        ; Newline character
    newline_len equ $ - newline ; Length of newline

    ; Constants for calculations
    zero dq 0.0          ; Constant 0.0
    minus_one dq -1.0    ; Constant -1.0
    fraction_multiplier dq 1000000.0 ; Multiplier for 6 decimal places

section .rodata:
; System call constants
SYS_WRITE equ 1          ; Syscall number for write
SYS_EXIT equ 60          ; Syscall number for exit
STDOUT equ 1             ; File descriptor for stdout
STDERR equ 2             ; File descriptor for stderr

section .bss
    num1 resq 1          ; Storage for first number (double)
    num2 resq 1          ; Storage for second number (double)
    buffer resb 21       ; Buffer for printing numbers