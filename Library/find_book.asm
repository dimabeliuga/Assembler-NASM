extern _input_title_for_search      ; External function to input the title to search

extern _find_book                   ; External function to search for the book by title

extern book                         ; External symbol representing the array of book structures

extern _print_book                  ; External function to print book information

global _find_book_by_title          ; Exported function: entry point for finding a book by title

%include "str_book.inc"             ; Include file with constants/macros related to books

; --- Macro Definitions ---

; Macro to print a string using Linux sys_write (stdout)
%macro print 1
    mov rax, 1                      ; syscall number for sys_write
    mov rdi, 1                      ; file descriptor: stdout
    mov rsi, %1                     ; address of the string
    mov rdx, %1_len                 ; length of the string
    syscall                         ; make the system call
%endmacro

; Macro to define a null-terminated string ending with a newline
%macro string_newline_right 2
%1: db %2, 10, 0                    ; define the string with newline and null terminator
%1_len: equ $ - %1                 ; calculate and define string length (excluding null)
%endmacro

section .data
    string_newline_right promt_book_not_found, "Message: Book not found" ; Message if no match is found

section .text
_find_book_by_title:
    call _input_title_for_search   ; Prompt the user and read a book title
    call _find_book                ; Call function to find the book index in the collection
    cmp rax, -1                    ; If returned -1, book was not found
    je .not_found                  ; Jump to 'not found' handler

    mov r9, rax                    ; Store the index of the found book in r9
    imul r9, Book_size             ; Multiply by size of one book to get byte offset
    lea rbx, [book + r9]           ; Calculate the address of the found book
    call _print_book               ; Print the book information
    jmp .done                      ; Jump to function end

.not_found:
    print promt_book_not_found     ; Print the "not found" message

.done:
    ret                            ; Return from the function
