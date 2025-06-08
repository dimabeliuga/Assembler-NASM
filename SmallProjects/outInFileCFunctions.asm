global main

extern fopen          ; Declare external function for opening a file
extern fputs          ; Declare external function for writing to a file
extern fclose         ; Declare external function for closing a file

section .data
    filename: db "test.txt", 0   ; File name string, null-terminated
    message: db "Hello World", 10, 0 ; Message to write to file, with newline and null terminator
    openmode: db "w", 0          ; File open mode ("w" for write), null-terminated

section .text
; in order to use external functions you need to declare main(as an entry point) instead of _start
main:
    sub rsp, 8                   ; Align stack by subtracting 8 bytes (for 16-byte alignment)
    mov rdi, filename            ; Set first argument: pointer to filename
    mov rsi, openmode            ; Set second argument: pointer to open mode
    call fopen                   ; Call fopen to open the file (returns file pointer in rax)

    mov qword [rsp], rax         ; Store file pointer on stack

    mov rdi, message             ; Set first argument: pointer to message
    mov rsi, [rsp]               ; Set second argument: file pointer from stack
    call fputs                   ; Call fputs to write message to file

    mov rdi, [rsp]               ; Set first argument: file pointer from stack
    call fclose                  ; Call fclose to close the file

    add rsp, 8                   ; Restore stack by adding 8 bytes

    ret                          ; Return from main (exits program)
