; Main file for the library catalog management program
global _start                       ; Entry point of the program
global booksCount                   ; Export booksCount variable for external use
extern _add_book                    ; External function to add a new book
extern _print_all_books             ; External function to print all books
extern _lend_book                   ; External function to lend a book
extern _return_book                 ; External function to return a book
extern _remove_book                 ; External function to remove a book
extern _find_book_by_title          ; External function to search for a book by title
extern _sort_books_by_title         ; External function to sort books by title
extern _save_books_to_file          ; External function to save books to a file
extern _load_books_from_file        ; External function to load books from a file

; Macros
%macro print 1                     ; Macro to print a string to stdout
    mov rax, 1                     ; Set syscall number for write
    mov rdi, 1                     ; Set file descriptor to stdout (1)
    mov rsi, %1                    ; Set pointer to string
    mov rdx, %1_len                ; Set string length
    syscall                        ; Call kernel to print
%endmacro

%macro input_string 2              ; Macro to read a string from stdin
    mov rax, 0                     ; Set syscall number for read
    mov rdi, 0                     ; Set file descriptor to stdin (0)
    mov rsi, %1                    ; Set pointer to buffer
    mov rdx, %2                    ; Set maximum length to read
    syscall                        ; Call kernel to read input
%endmacro

%macro clear_screen 0              ; Macro to clear the terminal screen
    mov rax, 1                     ; Set syscall number for write
    mov rdi, 1                     ; Set file descriptor to stdout (1)
    mov rsi, clear_screen_msg      ; Set pointer to clear screen escape sequence
    mov rdx, clear_screen_len      ; Set length of clear screen message
    syscall                        ; Call kernel to clear screen
%endmacro

%macro print_menu 0                ; Macro to print the menu options
    print menu_add                 ; Print "Add a new book" option
    print menu_output              ; Print "Output the list of all books" option
    print menu_lend                ; Print "Lend a book" option
    print menu_return              ; Print "Return a book" option
    print menu_remove              ; Print "Remove a book" option
    print menu_search              ; Print "Search for a book by title" option
    print menu_sort_by_title       ; Print "Sort books by title" option
    print menu_save_books_to_file  ; Print "Save books to file" option
    print menu_load_books_from_file ; Print "Load books from file" option
    print menu_exit                ; Print "Exit" option
    print menu_choice              ; Print "Your choice: " prompt
%endmacro

%macro string_newline_right 2      ; Macro to define a string with newline and length
%1: db %2, 10, 0                   ; Define string with newline and null terminator
%1_len: equ $ - %1                 ; Calculate length of string
%endmacro

%macro string 2                    ; Macro to define a string with length
%1: db %2, 0                       ; Define string with null terminator
%1_len: equ $ - %1                 ; Calculate length of string
%endmacro

section .rodata
    ; Menu option strings with newline
    string_newline_right menu_add,    "1 - Add a new book"              ; Menu option for adding a book
    string_newline_right menu_output, "2 - Output the list of all books" ; Menu option for listing books
    string_newline_right menu_lend,   "3 - Lend a book"                 ; Menu option for lending a book
    string_newline_right menu_return, "4 - Return a book"               ; Menu option for returning a book
    string_newline_right menu_remove, "5 - Remove a book"               ; Menu option for removing a book
    string_newline_right menu_search, "6 - Search for a book by title"  ; Menu option for searching by title
    string_newline_right menu_sort_by_title, "7 - Sort books by title"  ; Menu option for sorting by title
    string_newline_right menu_save_books_to_file, "8 - Save books to file" ; Menu option for saving to file
    string_newline_right menu_load_books_from_file, "9 - Load books from file" ; Menu option for loading from file
    string_newline_right menu_exit,   "0 - Exit"                       ; Menu option for exiting
    string_newline_right return_to_menu, "Press any key to return to the menu" ; Prompt to return to menu
    string menu_choice, "Your choice: " ; Prompt for user input choice
    clear_screen_msg db 27, '[2J', 27, '[H', 0 ; ANSI escape sequence to clear screen and move cursor to top-left
    clear_screen_len equ $ - clear_screen_msg ; Length of clear screen message

section .bss
    command resb 4                 ; Buffer for user command input (4 bytes)
    booksCount resd 1              ; Reserve space for number of books (4 bytes)

section .text
_start:
    mov dword [booksCount], 0      ; Initialize book counter to 0

.print_menu:
    print return_to_menu           ; Print "Press any key to return to the menu"
    input_string command, 4        ; Read user input into command buffer (max 4 bytes)
    clear_screen                   ; Clear the terminal screen
    print_menu                     ; Display the menu options
    input_string command, 4        ; Read user choice into command buffer (max 4 bytes)
    clear_screen                   ; Clear the terminal screen
    cmp byte [command], '1'        ; Check if user chose option 1
    je .add_book                   ; Jump to add book if selected
    cmp byte [command], '2'        ; Check if user chose option 2
    je .print_all_books            ; Jump to print all books if selected
    cmp byte [command], '3'        ; Check if user chose option 3
    je .lend_book                  ; Jump to lend book if selected
    cmp byte [command], '4'        ; Check if user chose option 4
    je .return_book                ; Jump to return book if selected
    cmp byte [command], '5'        ; Check if user chose option 5
    je .remove_book                ; Jump to remove book if selected
    cmp byte [command], '6'        ; Check if user chose option 6
    je .search_book                ; Jump to search book if selected
    cmp byte [command], '7'        ; Check if user chose option 7
    je .sort_by_title              ; Jump to sort by title if selected
    cmp byte [command], '8'        ; Check if user chose option 8
    je .save_books_to_file         ; Jump to save books to file if selected
    cmp byte [command], '9'        ; Check if user chose option 9
    je .load_books_from_file       ; Jump to load books from file if selected
    cmp byte [command], '0'        ; Check if user chose option 0
    je _exit                       ; Jump to exit if selected
    jmp .print_menu                ; If invalid choice, redisplay menu

.add_book:
    call _add_book                 ; Call function to add a new book
    jmp .print_menu                ; Return to menu

.print_all_books:
    call _print_all_books          ; Call function to print all books
    jmp .print_menu                ; Return to menu

.lend_book:
    call _lend_book                ; Call function to lend a book
    jmp .print_menu                ; Return to menu

.return_book:
    call _return_book              ; Call function to return a book
    jmp .print_menu                ; Return to menu

.remove_book:
    call _remove_book              ; Call function to remove a book
    jmp .print_menu                ; Return to menu

.search_book:
    call _find_book_by_title       ; Call function to search for a book by title
    jmp .print_menu                ; Return to menu

.sort_by_title:
    call _sort_books_by_title      ; Call function to sort books by title
    jmp .print_menu                ; Return to menu

.save_books_to_file:
    call _save_books_to_file       ; Call function to save books to file
    jmp .print_menu                ; Return to menu

.load_books_from_file:
    call _load_books_from_file     ; Call function to load books from file
    jmp .print_menu                ; Return to menu
    
_exit:
    mov rax, 60                    ; Set syscall number for exit
    mov rdi, 0                     ; Set exit code to 0
    xor rdi, rdi                   ; Clear rdi (redundant but ensures zero)
    syscall                        ; Call kernel to exit program