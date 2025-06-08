; Функции для сохранения и загрузки книг в файл
extern book
extern booksCount
extern MAX_BOOKS
extern search_title
extern _find_book

global _save_books_to_file
global _load_books_from_file

%include "str_book.inc"


; Макросы
%macro print 1
    mov rax, 1
    mov rdi, 1
    mov rsi, %1
    mov rdx, %1_len
    syscall
%endmacro

%macro print_error 1
    mov rax, 1
    mov rdi, 2
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


%macro input_string 2
    mov rax, 0
    mov rdi, 0
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

%macro string_newline_right 2
%1: db %2, 10, 0
%1_len: equ $ - %1
%endmacro

%macro string 2
%1: db %2, 0
%1_len: equ $ - %1
%endmacro


section .rodata
    ; system calls 
    SYS_OPEN   equ 257
    SYS_WRITE  equ 1
    SYS_CLOSE  equ 3
    SYS_READ   equ 0

    ; flags for open
    O_RDONLY   equ 0
    O_WRONLY   equ 1
    O_CREAT    equ 0x40
    O_TRUNC    equ 0x200
    FILE_MODE  equ 0x1B4  

    ; messages 
    string_newline_right prompt_file_name, "Enter file name: "
    string_newline_right error_file_open,  "Error: Cannot open file"
    string_newline_right error_file_read,  "Error: File read error"
    string_newline_right error_file_write, "Error: File write error"
    string_newline_right error_file_close, "Error: File close error"
    string_newline_right error_no_books,   "Error: No books to save"
    string_newline_right error_too_many_books, "Error: Too many books in file"
    string_newline_right error_invalid_filename, "Error: Invalid file name"
    string error_book_found_start, 'Error: Book with title: "'
    string_newline_right error_book_found_end, '" already exists'
    string_newline_right success_save, "Books saved successfully"
    string_newline_right success_load, "Books loaded successfully"
    string_newline_right file_empty,   "File is empty"

section .bss
    temp_book resb Book_size 
    file_name resb 256        
    file_descriptor resq 1    
    temp_count resd 1         

section .text
_save_books_to_file:
    push rbx
    ; check if there is a book to store
    cmp dword [booksCount], 0
    je .no_books

    call _input_filename
    test rax, rax
    jz .invalid_filename

    call _open_file_for_write
    cmp rax, -1
    je .error_open
    mov [file_descriptor], rax

    ; write books count
    mov rax, SYS_WRITE
    mov rdi, [file_descriptor]
    lea rsi, booksCount
    mov rdx, 4
    syscall
    cmp rax, 4
    jne .error_write

; Write an array of books
    mov r9d, [booksCount]
    imul r9, Book_size
    mov rax, SYS_WRITE
    mov rdi, [file_descriptor]
    mov rsi, book
    mov rdx, r9
    syscall
    cmp rax, r9
    jne .error_write

    call _close_file
    print success_save
    jmp .done

.no_books:
    print_error error_no_books
    jmp .done
.invalid_filename:
    print_error error_invalid_filename
    jmp .done
.error_open:
    print_error error_file_open
    jmp .done
.error_write:
    print_error error_file_write
    call _close_file
    jmp .done

.done:
    pop rbx
    ret

_load_books_from_file:
    push rbx
; Requesting file name
    call _input_filename
    test rax, rax
    jz .invalid_filename

    call _open_file_for_read
    cmp rax, -1
    je .error_open
    mov [file_descriptor], rax

    ; reads number of books
    mov rax, SYS_READ
    mov rdi, [file_descriptor]
    mov rsi, temp_count
    mov rdx, 4
    syscall
    cmp rax, 4
    jne .error_read

    cmp dword [temp_count], 0
    je .file_empty

; Check if the number of books does not exceed MAX_BOOKS
    mov eax, [booksCount]     
    mov r10d, eax             
    add eax, [temp_count]     
    cmp eax, MAX_BOOKS        
    jg .too_many_books        
   
    mov r10, [booksCount]             
    imul r10, Book_size               
    lea r11, [book + r10]             

    xor r9, r9

.loop:
    cmp r9, [temp_count]
    jge .done_reading

; Read one book into a temporary buffer
    mov rax, SYS_READ
    mov rdi, [file_descriptor]
    lea rsi, [temp_book]
    mov rdx, Book_size
    syscall
    cmp rax, Book_size
    jne .error_read

; Copy title from temp_book to search_title to find duplicate
    lea rsi, [temp_book]
    lea rdi, [search_title]
    mov rcx, 32         
    rep movsb

    call _find_book
    cmp rax, -1
    jne .book_found 

; Copy the entire temp_book structure to the books array
    mov eax, [booksCount]
    imul rax, Book_size
    lea rdi, [book + rax]
    lea rsi, [temp_book]
    mov rcx, Book_size
    rep movsb

    inc dword [booksCount]

.next_book:
    inc r9
    jmp .loop

.book_found:
    print_error error_book_found_start
    print_len search_title, 32
    print_error error_book_found_end
    jmp .next_book

.done_reading:
    call _close_file
    print success_load
    jmp .done

.file_empty:
    print file_empty
    call _close_file
    jmp .done
.invalid_filename:
    print_error error_invalid_filename
    jmp .done
.error_open:
    print_error error_file_open
    jmp .done
.error_read:
    print_error error_file_read
    call _close_file
    jmp .done
.too_many_books:
    print_error error_too_many_books
    call _close_file
    jmp .done
.done:
    pop rbx
    ret

_input_filename:
    push rbx
    print prompt_file_name
    input_string file_name, 256
    cmp rax, 2          
    jl .invalid
    mov byte [file_name + rax - 1], 0  ; delete '\n'
    mov rax, 1          
    jmp .done
.invalid:
    xor rax, rax        
.done:
    pop rbx
    ret
    
_open_file_for_write:
    mov rax, SYS_OPEN
    mov rdi, -100                ; AT_FDCWD
    mov rsi, file_name
    mov rdx, O_WRONLY | O_CREAT | O_TRUNC
    mov r10, FILE_MODE
    syscall
    ret

_open_file_for_read:
    mov rax, SYS_OPEN
    mov rdi, -100                ; AT_FDCWD
    mov rsi, file_name
    mov rdx, O_RDONLY
    xor r10, r10
    syscall
    ret

_close_file:
    mov rax, SYS_CLOSE
    mov rdi, [file_descriptor]
    syscall
    cmp rax, 0
    jne .error
    ret
.error:
    print_error error_file_close
    ret
    