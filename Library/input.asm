; Functions for data input
global _add_book                       ; Entry point for adding a book
global _input_title_for_search        ; Function to input a title for search
global search_title                   ; Global buffer for storing searched title
global book                           ; Global book array
global MAX_BOOKS                      ; Maximum number of books allowed

extern _parse_and_validate_year       ; External function for year input validation
extern _parse_and_validate_rate       ; External function for rating input validation
extern _strcmp                        ; String comparison function
extern _find_book                     ; External function to find a book by title

%include "str_book.inc"               ; Include file for book field offsets

; --- Macro Definitions ---

%macro print 1
    mov rax, 1                        ; syscall number for sys_write
    mov rdi, 1                        ; file descriptor: stdout
    mov rsi, %1                       ; address of the string
    mov rdx, %1_len                   ; length of the string
    syscall
%endmacro

%macro print_error 1
    mov rax, 1                        ; syscall number for sys_write
    mov rdi, 2                        ; file descriptor: stderr
    mov rsi, %1                       ; error message address
    mov rdx, %1_len                   ; error message length
    syscall
%endmacro

%macro input_string 2
    mov rax, 0                        ; syscall number for sys_read
    mov rdi, 0                        ; file descriptor: stdin
    mov rsi, %1                       ; input buffer
    mov rdx, %2                       ; max bytes to read
    syscall
%endmacro

%macro string 2
%1: db %2, 0                          ; null-terminated string
%1_len: equ $ - %1                    ; length of the string
%endmacro

%macro string_newline_right 2
%1: db %2, 10, 0                      ; string with newline + null terminator
%1_len: equ $ - %1                    ; length of the string
%endmacro

section .rodata
    STRING_MAX_LEN equ 32            ; Max length for title/author
    MIN_TITLE equ 5                  ; Minimum title length
    MIN_AUTHOR equ 8                 ; Minimum author name length
    MAX_BOOKS equ 250                ; Max number of books in library

    string prompt_title,  "Enter title (min 5 chars, max 32 chars): "
    string prompt_author, "Enter author (min 8 chars, max 32 chars): "
    string prompt_year,   "Enter year (1900-2025): "
    string prompt_rate,   "Enter rating (0-100): "
    string prompt_search_title, "Enter book title: "

    string_newline_right error_empty_title,  "Error: Title must be at least 5 characters"
    string_newline_right error_empty_author, "Error: Author must be at least 8 characters"
    string_newline_right error_invalid_char, "Error: Only letters, spaces, and dots allowed"
    string_newline_right error_array_full,   "Error: Library is full"
    string_newline_right error_book_found,   "Error: a book with this title already exists in the database"

section .bss
    book resb Book_size * MAX_BOOKS          ; Book array in memory
    input_buffer resb 12                     ; Buffer for year/rating input
    search_title resb 32                     ; Buffer for entered book title
    extern booksCount                        ; External counter of books

section .text
_add_book:
    push rbx                                 ; Preserve rbx register
    mov r9d, [booksCount]                    ; Load current book count
    cmp r9d, MAX_BOOKS                       ; Compare with max allowed
    jge .library_full                        ; If full, jump to error handler
    mov r10, r9                              ; Copy count to r10
    imul r10, Book_size                      ; Offset in book array
    lea r9, [book + r10]                     ; r9 points to the book slot

.input_title:
    print prompt_title                       ; Prompt user for title
    input_string search_title, STRING_MAX_LEN ; Read title from stdin
    cmp rax, MIN_TITLE + 1                   ; Check if input is too short
    jl .error_title                          ; Too short: print error
    mov byte [search_title + rax - 1], 0     ; Replace '\n' with null terminator

    call _find_book                          ; Check if title already exists
    cmp rax, -1
    je .book_not_found                       ; If not found, continue
    print error_book_found                   ; Otherwise, show error
    jmp .input_title                         ; Ask for title again

.book_not_found:
    mov rcx, STRING_MAX_LEN
    lea rdi, [r9]                            ; Destination: title field
    xor rax, rax
    rep stosb                                ; Zero out the title field

    lea rsi, [search_title]                  ; Source: user input
    lea rdi, [r9]                            ; Destination: book title field
    mov rcx, STRING_MAX_LEN
    rep movsb                                ; Copy title to book struct

    add r9, Book.author                      ; Move pointer to author field

.input_author:
    print prompt_author
    input_string r9, STRING_MAX_LEN          ; Read author input directly into field
    cmp rax, MIN_AUTHOR + 1
    jl .error_author
    mov byte [r9 + rax - 1], 0               ; Replace '\n' with null terminator
    call _validate_string                    ; Validate characters
    test rax, rax
    jz .input_author                         ; Retry on invalid input
    add r9, Book.year - Book.author          ; Move pointer to year field

.input_year:
    print prompt_year
    input_string input_buffer, 12
    lea rbx, [input_buffer]
    mov byte [rbx + rax - 1], 0              ; Null-terminate the input
    call _parse_and_validate_year
    test rax, rax
    jz .input_year                           ; Retry on failure
    mov [r9], eax                            ; Store year
    add r9, Book.rate - Book.year            ; Move pointer to rating field

.input_rate:
    print prompt_rate
    input_string input_buffer, 12
    lea rbx, [input_buffer]
    mov byte [rbx + rax - 1], 0
    call _parse_and_validate_rate
    test rax, rax
    jz .input_rate                           ; Retry on failure
    mov [r9], eax                            ; Store rating
    add r9, Book.available - Book.rate       ; Move to availability field
    mov byte [r9], 1                         ; Mark book as available

    inc dword [booksCount]                  ; Increase total book count
    pop rbx
    ret

.error_title:
    print_error error_empty_title
    jmp .input_title

.error_author:
    print_error error_empty_author
    jmp .input_author

.library_full:
    print_error error_array_full
    pop rbx
    ret

; --- String validation: allows only A-Z, a-z, space, dot ---
_validate_string:
    push rbx
    mov rbx, r9
    xor rcx, rcx
.check_char:
    movzx rsi, byte [rbx + rcx]              ; Load next character
    cmp rsi, 0
    je .valid                                ; End of string
    cmp rsi, 'A'
    jl .check_space
    cmp rsi, 'z'
    jg .invalid
    cmp rsi, 'Z'
    jle .next
    cmp rsi, 'a'
    jge .next
    jmp .invalid
.check_space:
    cmp rsi, ' '
    je .next
    cmp rsi, '.'
    je .next
    jmp .invalid
.next:
    inc rcx
    jmp .check_char
.invalid:
    print_error error_invalid_char
    xor rax, rax                             ; Return 0 (false)
    jmp .done
.valid:
    mov rax, 1                               ; Return 1 (true)
.done:
    pop rbx
    ret

_input_title_for_search:
    print prompt_search_title
    input_string search_title, STRING_MAX_LEN
    mov byte [search_title + rax - 1], 0     ; Replace '\n' with null terminator
    ret
