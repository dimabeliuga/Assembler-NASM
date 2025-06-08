; Функции вывода данных
global _print_all_books
global _print_digit
global _print_book
extern book

%include "str_book.inc"

; Макросы
%macro print 1
    mov rax, 1
    mov rdi, 1
    mov rsi, %1
    mov rdx, %1_len
    syscall
%endmacro

%macro print_len 2
    mov rax, 1
    mov rdi, 1
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

%macro string 2
%1: db %2, 0
%1_len: equ $ - %1
%endmacro

%macro string_newline_left 2
%1: db 10, %2, 0
%1_len: equ $ - %1
%endmacro

%macro string_newline_right 2
%1: db %2, 10, 0
%1_len: equ $ - %1
%endmacro



section .rodata
    STRING_MAX_LEN equ 32
    string_newline_right output_start, "----------List of books----------"
    string_newline_right output_end,   "--------------------------------"
    string_newline_left output_title,  "Title: "
    string_newline_left output_author, "Author: "
    string_newline_left output_year,   "Year: "
    string_newline_left output_rate,   "Rating: "
    string_newline_left output_status, "Status: "
    string status_available, "Available"
    string status_lent,      "Lent out"

    string newline, 10

section .bss
    output_buffer resb 12
    extern booksCount

section .text
_print_all_books:
    push rbx
    print output_start          ; Вывод заголовка
    mov r10d, [booksCount]      ; Количество книг
    test r10d, r10d             ; Если 0, завершаем
    jz .done
    xor r9, r9                  ; Счётчик книг
.loop:
    mov rbx, r9
    imul rbx, Book_size
    lea rbx, [book + rbx]
    call _print_book         ; Вывод книги
    inc r9                      ; Следующая книга
    cmp r9d, r10d
    jl .loop
.done:
    print output_end           ; Вывод "--------------------------------"
    print newline
    pop rbx
    ret

_print_book:
    print output_title          ; Вывод "Title: "
    mov rsi, rbx                ; Адрес title
    call _print_string          ; Вывод строки title
    print output_author         ; Вывод "Author: "
    add rbx, Book.author        ; Переход к author
    mov rsi, rbx
    call _print_string          ; Вывод строки author
    print output_year           ; Вывод "Year: "
    add rbx, Book.year - Book.author  ; Переход к year
    mov edi, [rbx]              ; Загрузка year
    call _print_digit           ; Вывод числа
    print output_rate           ; Вывод "Rating: "
    add rbx, Book.rate - Book.year    ; Переход к rate
    mov edi, [rbx]              ; Загрузка rate
    call _print_digit           ; Вывод числа
    print output_status         ; Вывод "Status: "
    add rbx, Book.available - Book.rate  ; Переход к available
    movzx rsi, byte [rbx]
    cmp rsi, 1
    je .available
    print_len status_lent, status_lent_len
    jmp .done
.available:
    print_len status_available, status_available_len
.done:
    print newline
    ret

_print_string:
    push rbx
    mov rbx, rsi                ; rsi - адрес строки
    xor rcx, rcx                ; Счётчик длины
.find_len:
    cmp byte [rbx + rcx], 0     ; Поиск нуль-терминатора
    je .print
    inc rcx
    jmp .find_len
.print:
    mov rax, 1                  ; Вызов write
    mov rdi, 1                  ; stdout
    mov rsi, rbx                ; Адрес строки
    mov rdx, rcx                ; Длина строки
    syscall
    pop rbx
    ret

_print_digit:
    push rbx
    mov eax, edi
    mov rbx, 10
    lea rsi, [output_buffer + 11]
    mov rcx, rsi
    test eax, eax
    jge .reverse_loop
    neg eax
    dec rsi
    mov byte [rsi], '-'
.reverse_loop:
    xor edx, edx
    div rbx
    dec rsi
    add dl, '0'
    mov [rsi], dl
    test eax, eax
    jnz .reverse_loop
    mov rdx, rcx
    sub rdx, rsi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rbx
    ret