; === Helper Functions ===
global _parse_and_validate_year
global _parse_and_validate_rate
global _strcmp
global _find_book
global _lend_book
global _return_book
global _remove_book
extern _input_title_for_search
extern book

%include "str_book.inc" ; Include book structure definition (assumed to define Book_size, Book.title, etc.)

; === Macros for printing ===
%macro print 1
    mov rax, 1          ; syscall number for write
    mov rdi, 1          ; file descriptor: stdout
    mov rsi, %1         ; pointer to message
    mov rdx, %1_len     ; length of message
    syscall
%endmacro

%macro print_error 1
    mov rax, 1          ; syscall number for write
    mov rdi, 2          ; file descriptor: stderr
    mov rsi, %1
    mov rdx, %1_len
    syscall
%endmacro

%macro string_newline_right 2
%1: db %2, 10, 0
%1_len: equ $ - %1
%endmacro

section .rodata
    MIN_YEAR equ 1900
    MAX_YEAR equ 2025
    MIN_RATE equ 0
    MAX_RATE equ 100

    ; Error messages
    string_newline_right error_invalid_input, "Error: Invalid input, only digits allowed"
    string_newline_right error_year_range,    "Error: Year must be between 1900 and 2025"
    string_newline_right error_rate_range,    "Error: Rating must be between 0 and 100"
    string_newline_right error_book_not_found, "Error: Book not found"
    string_newline_right error_book_lent,     "Error: Book is already lent"
    string_newline_right error_book_available, "Error: Book is already available"

section .bss
    extern booksCount      ; Current number of books in the system
    extern search_title    ; Pointer to search string buffer

section .text

; === Year Validation ===
_parse_and_validate_year:
    push rbx
    call _parse_digits
    test rax, rax              ; Check if parsing failed
    jz .done
    cmp rax, MIN_YEAR
    jl .invalid
    cmp rax, MAX_YEAR
    jg .invalid
    jmp .done
.invalid:
    print_error error_year_range
    xor rax, rax
.done:
    pop rbx
    ret

; === Rating Validation ===
_parse_and_validate_rate:
    push rbx
    call _parse_digits
    test rax, rax
    jz .done
    cmp rax, MIN_RATE
    jl .invalid
    cmp rax, MAX_RATE
    jg .invalid
    jmp .done
.invalid:
    print_error error_rate_range
    xor rax, rax
.done:
    pop rbx
    ret

; === Digit Parsing from string in RBX ===
_parse_digits:
    push rbx
    xor rax, rax        ; accumulator for parsed value
    xor rcx, rcx        ; index
.parse_loop:
    movzx rsi, byte [rbx + rcx]
    cmp rsi, 0          ; end of string
    je .done
    cmp rsi, '0'
    jl .invalid
    cmp rsi, '9'
    jg .invalid
    sub rsi, '0'        ; convert ASCII to digit
    imul rax, 10
    add rax, rsi
    inc rcx
    jmp .parse_loop
.invalid:
    print_error error_invalid_input
    xor rax, rax
.done:
    pop rbx
    ret

; === String Comparison (strcmp equivalent) ===
_strcmp:
    push rbx
    xor rcx, rcx
.loop:
    movzx rax, byte [rdi + rcx] ; char from first string
    movzx rbx, byte [rsi + rcx] ; char from second string
    cmp rax, rbx
    jne .different
    cmp rax, 0
    je .equal
    inc rcx
    jmp .loop
.different:
    sub rax, rbx
    jmp .done
.equal:
    xor rax, rax
.done:
    pop rbx
    ret

; === Find Book by Title ===
_find_book:
    push rbx
    push r9
    mov r10d, [booksCount]
    test r10d, r10d
    jz .not_found
    xor r9, r9            ; book index
.loop:
    lea rdi, [r9]         ; book index
    imul rdi, Book_size
    add rdi, book         ; address of current book
    mov rsi, search_title
    call _strcmp
    test rax, rax
    jz .found
    inc r9
    cmp r9d, r10d
    jl .loop
.not_found:
    mov rax, -1
    jmp .done
.found:
    mov rax, r9           ; return book index
.done:
    pop r9
    pop rbx
    ret

; === Lend Book ===
_lend_book:
    push rbx
    call _input_title_for_search
    call _find_book
    cmp rax, -1
    je .not_found
    mov r9, rax
    imul r9, Book_size
    lea rbx, [book + r9 + Book.available]
    cmp byte [rbx], 0
    je .already_lent
    mov byte [rbx], 0
    jmp .done
.not_found:
    print_error error_book_not_found
    jmp .done
.already_lent:
    print_error error_book_lent
.done:
    pop rbx
    ret

; === Return Book ===
_return_book:
    push rbx
    call _input_title_for_search
    call _find_book
    cmp rax, -1
    je .not_found
    mov r9, rax
    imul r9, Book_size
    lea rbx, [book + r9 + Book.available]
    cmp byte [rbx], 1
    je .already_available
    mov byte [rbx], 1
    jmp .done
.not_found:
    print_error error_book_not_found
    jmp .done
.already_available:
    print_error error_book_available
.done:
    pop rbx
    ret

; === Remove Book from List ===
_remove_book:
    push rbx
    call _input_title_for_search
    call _find_book
    cmp rax, -1
    je .not_found
    mov r9, rax             ; index of book to delete
    mov r10d, [booksCount]
    dec r10d                ; last valid index
    cmp r9d, r10d
    je .last_book           ; if it's the last one, just decrement count
.shift_loop:
    mov r11, r9
    inc r11
    imul r11, Book_size
    lea rsi, [book + r11]   ; next book
    imul r9, Book_size
    lea rdi, [book + r9]    ; current book
    mov rcx, Book_size
    rep movsb               ; shift books left
    inc r9d
    cmp r9d, r10d
    jl .shift_loop
.last_book:
    dec dword [booksCount]
    jmp .done
.not_found:
    print_error error_book_not_found
.done:
    pop rbx
    ret
