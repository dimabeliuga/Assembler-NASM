section .data
    ; like int arr[] = {5, 2, 8, 1, 9} in C\C++
    array dq 5, 2, 8, 1, 9        ; Define an array of 64-bit numbers
    array_len equ ($ - array) / 8  ; Calculate array length (number of elements)
    ; $(current adress) - array(start adress) / 8(dq = 8 bytes)
    space db " "                   ; Space character to separate numbers
    ; like char space = ' ';
    newline db 10                  ; Newline character for line break
    buffer db "0000000000"         ; Buffer to convert number to string (up to 10 digits)

section .text
    global _start
    ; main() - start point of the programme
_start:
    ; Set up the loop
    mov rcx, array_len            ; Set counter to array length
    mov rsi, array                ; Point to the start of the array

print_loop:
    ; Save registers used by syscall
    push rcx                      ; Save loop counter in the stack
    push rsi                      ; Save array pointer in the stack

    ; Convert number to string
    mov rax, [rsi]                ; Load current number from array
    call num_to_string            ; Call function to convert number to string

    ; Print the number
    mov rax, 1                    ; Syscall number for sys_write
    mov rdi, 1                    ; File descriptor 1 (stdout)
    mov rsi, buffer               ; Point to buffer with string
    mov rdx, 10                   ; Maximum string length (fixed for simplicity)
    syscall                       ; Call kernel to print

    ; Print a space
    mov rax, 1                    ; Syscall number for sys_write
    mov rdi, 1                    ; File descriptor 1 (stdout)
    mov rsi, space                ; Point to space character
    mov rdx, 1                    ; Length of space (1 byte)
    syscall                       ; Call kernel to print

    ; Restore registers
    pop rsi                       ; Restore array pointer
    pop rcx                       ; Restore loop counter

    ; Move to next element
    add rsi, 8                    ; Move to next number (8 bytes per number)
    loop print_loop               ; Decrease RCX and repeat if RCX != 0

    ; Print newline
    mov rax, 1                    ; Syscall number for sys_write
    mov rdi, 1                    ; File descriptor 1 (stdout)
    mov rsi, newline              ; Point to newline character
    mov rdx, 1                    ; Length of newline (1 byte)
    syscall                       ; Call kernel to print

    ; Exit program
    mov rax, 60                   ; Syscall number for sys_exit
    xor rdi, rdi                  ; Set return code to 0
    syscall                       ; Call kernel to exit

; Function: Converts number in RAX to string in buffer
num_to_string:
    ; Set up conversion
    mov rbx, buffer + 9           ; Point to end of buffer (write right to left)
    mov byte [rbx], 0             ; Add null terminator (for safety)
    mov rcx, 10                   ; Divisor to get digits (base 10)

convert_loop:
    xor rdx, rdx                  ; Clear RDX for division
    div rcx                       ; Divide RAX by 10; RAX = quotient, RDX = remainder (digit)
    add dl, '0'                   ; Convert digit to ASCII
    dec rbx                       ; Move buffer pointer left
    mov [rbx], dl                 ; Store digit in buffer
    test rax, rax                 ; Check if more digits remain
    jnz convert_loop              ; Repeat if RAX != 0

    ; Handle case when number is 0
    cmp rbx, buffer + 9           ; Check if buffer is empty
    jne skip_zero                 ; Skip if digits were written
    dec rbx                       ; Move buffer pointer left
    mov byte [rbx], '0'           ; Write '0' to buffer

skip_zero:
    ; Copy string to start of buffer (to align left)
    mov rsi, rbx                  ; Source: start of number string
    mov rdi, buffer               ; Destination: start of buffer
    mov rcx, buffer + 10          ; Calculate string length
    sub rcx, rbx                  ; Length = end of buffer - start of number
    rep movsb                     ; Copy string to buffer start

    ret                           ; Return from function