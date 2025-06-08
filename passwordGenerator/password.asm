; Password generation and output functions for the password generator
; Handles random byte generation, transformation to printable characters, and output

%include "macroses.inc"

; External variables
extern passwordLength
extern useNumbers
extern useCapital
extern useLowercase
extern useSymbols
extern saveToFile
extern password
extern randomFileDescriptor
extern outputFileDescriptor

section .bss
    random_buffer resb 512    ; Buffer for random data
    charset_buffer resb 256   ; Buffer for combined character set

section .rodata
    ; Character sets for different types
    lowercase_chars db "abcdefghijklmnopqrstuvwxyz"  ; Lowercase letters
    lowercase_len equ $ - lowercase_chars             ; Length of lowercase letters
    
    uppercase_chars db "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  ; Uppercase letters
    uppercase_len equ $ - uppercase_chars             ; Length of uppercase letters
    
    number_chars db "0123456789"                     ; Numbers
    number_len equ $ - number_chars                  ; Length of numbers
    
    symbol_chars db "!@#$%^&*()-_=+[]{}|;:,.<>?~"   ; Special symbols
    symbol_len equ $ - symbol_chars                  ; Length of symbols

    ; System calls
    SYS_READ equ 0                                   ; Syscall number for read
    SYS_WRITE equ 1                                  ; Syscall number for write

    ; Messages
    string_with_len MSG_PASSWORD, "Generated password: " ; Message for password output
    newline_char db 10                               ; Newline character

section .text
global generatePassword
global printPassword
global savePasswordToFile

; Generate a password by reading random bytes and transforming them
; Returns: rax = 1 (success), 0 (error)
generatePassword:
    push rbx                     ; Save rbx register
    push r12                     ; Save r12 register
    push r13                     ; Save r13 register
    push r14                     ; Save r14 register
    push r15                     ; Save r15 register

    ; Build combined character set based on settings
    call build_charset           ; Call function to build character set
    test rax, rax                ; Check if character set is empty
    jz .error_no_chars           ; Jump to error if no characters available

    mov r14, rax                 ; Store length of combined character set in r14
    mov r15, 0                   ; Initialize random buffer index in r15

    ; Read initial batch of random data
    call read_random_data        ; Call function to read random data
    test rax, rax                ; Check if read was successful
    jz .error_read               ; Jump to error if read failed

    xor rbx, rbx                 ; Initialize password character counter

.generate_loop:
    cmp rbx, [passwordLength]    ; Compare counter with password length
    jge .done                    ; If counter >= length, finish

    ; Check if more random data is needed
    cmp r15, 256                 ; Check if random buffer index reached limit
    jge .need_more_random        ; If yes, read more random data

    ; Get random character from combined set
    movzx rax, byte [random_buffer + r15] ; Load random byte
    inc r15                      ; Move to next random byte
    
    ; Convert to index in character set
    xor rdx, rdx                 ; Clear remainder
    div r14                      ; Divide by charset length; remainder in rdx
    mov al, [charset_buffer + rdx] ; Get character from combined set
    
    ; Store character in password
    mov [password + rbx], al     ; Save character to password buffer
    inc rbx                      ; Increment password counter
    jmp .generate_loop           ; Continue generating

.need_more_random:
    ; Read new batch of random data
    call read_random_data        ; Call function to read random data
    test rax, rax                ; Check if read was successful
    jz .error_read               ; Jump to error if read failed
    xor r15, r15                 ; Reset random buffer index
    jmp .generate_loop           ; Continue generating

.done:
    mov byte [password + rbx], 0 ; Add null terminator to password
    mov rax, 1                   ; Return success (1)
    jmp .exit                    ; Jump to exit

.error_read:
.error_no_chars:
    xor rax, rax                 ; Return error (0)
    jmp .exit                    ; Jump to exit

.exit:
    pop r15                      ; Restore r15 register
    pop r14                      ; Restore r14 register
    pop r13                      ; Restore r13 register
    pop r12                      ; Restore r12 register
    pop rbx                      ; Restore rbx register
    ret                          ; Return from function

; Read random data into buffer
; Returns: rax = 1 (success), 0 (error)
read_random_data:
    mov rax, SYS_READ            ; Set syscall to read
    mov rdi, [randomFileDescriptor] ; Set random device descriptor
    mov rsi, random_buffer       ; Set buffer for random data
    mov rdx, 512                 ; Set number of bytes to read
    syscall                      ; Call kernel
    cmp rax, 256                 ; Check if enough bytes were read
    jl .error                    ; Jump to error if insufficient bytes
    mov rax, 1                   ; Return success (1)
    ret                          ; Return from function
.error:
    xor rax, rax                 ; Return error (0)
    ret                          ; Return from function

; Build combined character set based on settings
; Returns: rax = length of combined character set (0 if no characters)
build_charset:
    push rbx                     ; Save rbx register
    push rcx                     ; Save rcx register
    push rsi                     ; Save rsi register
    push rdi                     ; Save rdi register
    
    xor rbx, rbx                 ; Initialize combined charset counter
    mov rdi, charset_buffer      ; Set pointer to combined charset buffer

    ; Add lowercase letters if enabled
    cmp qword [useLowercase], 0  ; Check if lowercase letters are enabled
    je .skip_lowercase           ; Skip if disabled
    mov rsi, lowercase_chars     ; Set pointer to lowercase characters
    mov rcx, lowercase_len       ; Set length of lowercase characters
    rep movsb                    ; Copy lowercase characters to buffer
    add rbx, lowercase_len       ; Update counter

.skip_lowercase:
    ; Add uppercase letters if enabled
    cmp qword [useCapital], 0    ; Check if uppercase letters are enabled
    je .skip_uppercase           ; Skip if disabled
    mov rsi, uppercase_chars     ; Set pointer to uppercase characters
    mov rcx, uppercase_len       ; Set length of uppercase characters
    rep movsb                    ; Copy uppercase characters to buffer
    add rbx, uppercase_len       ; Update counter

.skip_uppercase:
    ; Add numbers if enabled
    cmp qword [useNumbers], 0    ; Check if numbers are enabled
    je .skip_numbers             ; Skip if disabled
    mov rsi, number_chars        ; Set pointer to number characters
    mov rcx, number_len          ; Set length of number characters
    rep movsb                    ; Copy number characters to buffer
    add rbx, number_len          ; Update counter

.skip_numbers:
    ; Add symbols if enabled
    cmp qword [useSymbols], 0    ; Check if symbols are enabled
    je .skip_symbols             ; Skip if disabled
    mov rsi, symbol_chars        ; Set pointer to symbol characters
    mov rcx, symbol_len          ; Set length of symbol characters
    rep movsb                    ; Copy symbol characters to buffer
    add rbx, symbol_len          ; Update counter

.skip_symbols:
    mov rax, rbx                 ; Return length of combined character set
    
    pop rdi                      ; Restore rdi register
    pop rsi                      ; Restore rsi register
    pop rcx                      ; Restore rcx register
    pop rbx                      ; Restore rbx register
    ret                          ; Return from function

; Print password to stdout
printPassword:
    push rbx                     ; Save rbx register
    push rcx                     ; Save rcx register

    ; Print "Generated password: " message
    print MSG_PASSWORD, MSG_PASSWORD_len ; Print message using macro

    ; Calculate password length
    mov rcx, [passwordLength]    ; Load password length
    
    ; Print the password
    mov rax, SYS_WRITE           ; Set syscall to write
    mov rdi, 1                   ; Set file descriptor to stdout
    mov rsi, password            ; Set pointer to password buffer
    mov rdx, rcx                 ; Set length to password length
    syscall                      ; Call kernel to print

    ; Print newline
    mov rax, SYS_WRITE           ; Set syscall to write
    mov rdi, 1                   ; Set file descriptor to stdout
    mov rsi, newline_char        ; Set pointer to newline character
    mov rdx, 1                   ; Set length to 1 byte
    syscall                      ; Call kernel to print

    pop rcx                      ; Restore rcx register
    pop rbx                      ; Restore rbx register
    ret                          ; Return from function

; Save password to file
savePasswordToFile:
    push rbx                     ; Save rbx register
    
    ; Write password to file
    mov rax, SYS_WRITE           ; Set syscall to write
    mov rdi, [outputFileDescriptor] ; Set file descriptor from variable
    mov rsi, password            ; Set pointer to password buffer
    mov rdx, [passwordLength]    ; Set length to password length
    syscall                      ; Call kernel to write
    cmp rax, [passwordLength]    ; Check if all bytes were written
    jne .error                   ; Jump to error if write failed

    ; Add newline to file
    mov rax, SYS_WRITE           ; Set syscall to write
    mov rdi, [outputFileDescriptor] ; Set file descriptor
    mov rsi, newline_char        ; Set pointer to newline character
    mov rdx, 1                   ; Set length to 1 byte
    syscall                      ; Call kernel to write
    cmp rax, 1                   ; Check if newline was written
    jne .error                   ; Jump to error if write failed

    mov rax, 1                   ; Return success (1)
    jmp .exit                    ; Jump to exit

.error:
    xor rax, rax                 ; Return error (0)

.exit:
    pop rbx                      ; Restore rbx register
    ret                          ; Return from function