section .data
    msg db "Symbol: 0", 10, 0     ; Message template with placeholder for digit, newline, and null terminator
    msg_final db "Finish", 10, 0   ; Final message with newline and null terminator

section .text
    global _start                  ; Declare _start as the entry point

_start:
    mov rcx, 78                    ; Set loop counter to 78 (number of iterations)
    mov rbx, 0                     ; Initialize counter for digits (starts at 0)

mainloop:
    mov rax, rbx                   ; Copy counter to rax for manipulation
    add al, '0'                    ; Convert number to ASCII digit (e.g., 0 -> '0')
    mov [msg + 8], al              ; Update digit in message string (at offset 8)

    push rcx                       ; Save loop counter (syscall modifies rcx)
    mov rax, 1                     ; Set syscall number for write
    mov rdi, 1                     ; Set file descriptor to stdout (1)
    mov rsi, msg                   ; Set pointer to message string
    mov rdx, 10                    ; Set length of message (10 bytes)
    syscall                        ; Call kernel to print message
    pop rcx                        ; Restore loop counter

    inc rbx                        ; Increment digit counter
    loop mainloop                  ; Decrease rcx and loop if rcx != 0

    mov rax, 1                     ; Set syscall number for write
    mov rdi, 1                     ; Set file descriptor to stdout (1)
    mov rsi, msg_final             ; Set pointer to final message
    mov rdx, 7                     ; Set length of final message (7 bytes)
    syscall                        ; Call kernel to print final message

exit:
    mov rax, 60                    ; Set syscall number for exit
    xor rdi, rdi                   ; Set exit code to 0
    syscall                        ; Call kernel to exit program