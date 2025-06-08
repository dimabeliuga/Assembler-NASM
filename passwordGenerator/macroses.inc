
; Macro for printing to stdout
%macro print 2
    mov rax, 1                ; SYS_WRITE
    mov rdi, 1                ; stdout
    mov rsi, %1               ; String pointer
    mov rdx, %2               ; String length
    syscall
%endmacro

; Macro for printing to stderr
%macro print_error 2
    mov rax, 1                ; SYS_WRITE
    mov rdi, 2                ; stderr
    mov rsi, %1               ; String pointer
    mov rdx, %2               ; String length
    syscall
%endmacro

; Macro for defining string with length calculation (includes newline)
%macro string_with_len 3
    %1: db %2, %3
    %1_len: equ $ - %1
%endmacro

; Macro for defining string with length calculation (no newline)
%macro string_with_len 2
    %1: db %2
    %1_len: equ $ - %1
%endmacro

; Macro for simple string definition (null-terminated)
%macro string_simple 2
    %1: db %2, 0
%endmacro

%macro print 1
    mov rax, 1                ; SYS_WRITE
    mov rdi, 1                ; stdout
    mov rsi, %1
    mov rdx, %1_len
    syscall
%endmacro

%macro print_error 1
    mov rax, 1                ; SYS_WRITE
    mov rdi, 2                ; stderr
    mov rsi, %1
    mov rdx, %1_len
    syscall
%endmacro

%macro string_newline_right 2
%1: db %2, 10, 0
%1_len: equ $ - %1 - 1
%endmacro

%macro string 2
%1: db %2, 0
%1_len: equ $ - %1 - 1
%endmacro

