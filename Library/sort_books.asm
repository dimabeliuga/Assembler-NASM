; Function to sort books by title using insertion sort
extern book                         ; External array of book structures
extern booksCount                   ; External variable for number of books
extern _strcmp                      ; External function for string comparison

global _sort_books_by_title         ; Export function to sort books by title

%include "str_book.inc"             
; Include book structure definitions

section .bss
    temp_book resb Book_size        ; Reserve space for temporary book structure

section .text

_sort_books_by_title:
    push rbx                        ; Save rbx register
    push r12                        ; Save r12 register
    push r13                        ; Save r13 register
    push r14                        ; Save r14 register

    mov r12d, [booksCount]          ; Load number of books into r12d
    cmp r12d, 1                     ; Check if 1 or fewer books
    jle .done                       ; If true, skip sorting (already sorted)

    mov r13d, 1                     ; Initialize outer loop counter (i = 1)
.outer_loop:
    mov r14d, r13d                  ; Copy i to r14d
    imul r14, Book_size             ; Calculate offset for book[i]
    lea rsi, [book + r14]           ; Load address of book[i] into rsi
    lea rdi, [temp_book]            ; Load address of temp_book into rdi
    mov rcx, Book_size              ; Set size of book structure
    rep movsb                       ; Copy book[i] to temp_book

    mov r15d, r13d                  ; Initialize inner loop counter (j = i)
.inner_loop:
    test r15d, r15d                 ; Check if j == 0
    jz .insert                      ; If true, insert temp_book

    mov r10d, r15d                  ; Copy j to r10d
    dec r10d                        ; Calculate j-1
    imul r10, Book_size             ; Calculate offset for book[j-1]

    lea rdi, [book + r10]           ; Load address of book[j-1] into rdi
    lea rsi, [temp_book]            ; Load address of temp_book into rsi
    call _strcmp                    ; Compare titles (book[j-1].title, temp_book.title)
    test rax, rax                   ; Check if book[j-1].title > temp_book.title
    jle .insert                     ; If not, insert temp_book

    ; Shift book[j-1] to book[j]
    mov r11d, r15d                  ; Copy j to r11d
    imul r11, Book_size             ; Calculate offset for book[j]
    lea rdi, [book + r11]           ; Load address of book[j] into rdi
    lea rsi, [book + r10]           ; Load address of book[j-1] into rsi
    mov rcx, Book_size              ; Set size of book structure
    rep movsb                       ; Copy book[j-1] to book[j]

    dec r15d                        ; Decrement inner loop counter (j--)
    jmp .inner_loop                 ; Continue inner loop

.insert:
    mov r11d, r15d                  ; Copy j to r11d
    imul r11, Book_size             ; Calculate offset for book[j]
    lea rdi, [book + r11]           ; Load address of book[j] into rdi
    lea rsi, [temp_book]            ; Load address of temp_book into rsi
    mov rcx, Book_size              ; Set size of book structure
    rep movsb                       ; Copy temp_book to book[j]

    inc r13d                        ; Increment outer loop counter (i++)
    cmp r13d, r12d                  ; Check if i < booksCount
    jl .outer_loop                  ; If true, continue outer loop

.done:
    pop r14                         ; Restore r14 register
    pop r13                         ; Restore r13 register
    pop r12                         ; Restore r12 register
    pop rbx                         ; Restore rbx register
    ret                             ; Return from function