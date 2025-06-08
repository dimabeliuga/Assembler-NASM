; Utility functions for string manipulation and file operations
; Used by the password generator program

%include "macroses.inc"                 
; Include macro definitions

; External variables
extern filePath                         ; External variable for file path

section .bss
    randomFileDescriptor resq 1         ; Reserve space for random device file descriptor (8 bytes)
    outputFileDescriptor resq 1         ; Reserve space for output file descriptor (8 bytes)

section .rodata
    ; System call numbers
    SYS_OPEN equ 2                     ; Syscall number for open
    SYS_CLOSE equ 3                    ; Syscall number for close

    ; File open flags
    O_RDONLY equ 0                     ; Flag for read-only mode
    O_WRONLY equ 1                     ; Flag for write-only mode
    O_CREAT equ 0x40                   ; Flag to create file if it doesn't exist
    O_TRUNC equ 0x200                  ; Flag to truncate file if it exists
    FILE_MODE equ 0x1B4                ; File permissions (0644 in octal, rw-r--r--)

    ; Random device paths
    string_simple RANDOM_DEVICE, "/dev/random"   ; Path to /dev/random (true random data)
    string_simple URANDOM_DEVICE, "/dev/urandom" ; Path to /dev/urandom (pseudo-random data)

section .text
global openRandomDevice                 ; Export function to open random device
global closeRandomDevice                ; Export function to close random device
global openOutputFile                   ; Export function to open output file
global closeOutputFile                  ; Export function to close output file
global parseNumber                      ; Export function to parse string to number
global strcmp                           ; Export function to compare strings
global strcpy                           ; Export function to copy strings
global randomFileDescriptor             ; Export random file descriptor variable
global outputFileDescriptor             ; Export output file descriptor variable

; Open random device (/dev/urandom preferred for reliability)
; Returns: rax = 1 (success), 0 (error)
openRandomDevice:
    mov rax, SYS_OPEN                  ; Set syscall to open
    mov rdi, URANDOM_DEVICE            ; Set path to /dev/urandom
    mov rsi, O_RDONLY                  ; Set read-only mode
    xor rdx, rdx                       ; Clear mode (no special permissions needed)
    syscall                            ; Call kernel to open file
    cmp rax, 0                         ; Check if syscall returned error
    jl .error                          ; Jump to error if rax < 0
    mov [randomFileDescriptor], rax    ; Store file descriptor
    mov rax, 1                         ; Return success (1)
    ret                                ; Return from function
.error:
    xor rax, rax                       ; Return error (0)
    ret                                ; Return from function

; Close random device
; Returns: rax = 1 (success), 0 (error)
closeRandomDevice:
    mov rax, SYS_CLOSE                 ; Set syscall to close
    mov rdi, [randomFileDescriptor]    ; Load random device file descriptor
    syscall                            ; Call kernel to close file
    cmp rax, 0                         ; Check if syscall was successful
    je .success                        ; Jump to success if rax == 0
    xor rax, rax                       ; Return error (0)
    ret                                ; Return from function
.success:
    mov rax, 1                         ; Return success (1)
    ret                                ; Return from function

; Open output file for writing
; Returns: rax = 1 (success), 0 (error)
openOutputFile:
    mov rax, SYS_OPEN                  ; Set syscall to open
    mov rdi, filePath                  ; Set path to output file
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC ; Set flags: write-only, create, truncate
    mov rdx, FILE_MODE                 ; Set file permissions (0644)
    syscall                            ; Call kernel to open file
    test rax, rax                      ; Check if syscall returned error
    js .error                          ; Jump to error if rax < 0
    mov [outputFileDescriptor], rax    ; Store file descriptor
    mov rax, 1                         ; Return success (1)
    ret                                ; Return from function
.error:
    xor rax, rax                       ; Return error (0)
    ret                                ; Return from function

; Close output file
; Returns: rax = 1 (success), 0 (error)
closeOutputFile:
    mov rax, SYS_CLOSE                 ; Set syscall to close
    mov rdi, [outputFileDescriptor]    ; Load output file descriptor
    syscall                            ; Call kernel to close file
    cmp rax, 0                         ; Check if syscall was successful
    je .success                        ; Jump to success if rax == 0
    xor rax, rax                       ; Return error (0)
    ret                                ; Return from function
.success:
    mov rax, 1                         ; Return success (1)
    ret                                ; Return from function

; Parse string to number
; Input: rsi = pointer to string
; Returns: rax = number, or 0 if invalid
parseNumber:
    push rbx                           ; Save rbx register
    push rcx                           ; Save rcx register
    push rdx                           ; Save rdx register
    
    xor rax, rax                       ; Clear result (number)
    xor rcx, rcx                       ; Clear digit counter
    
    ; Check for empty string
    cmp byte [rsi], 0                  ; Check if first byte is null
    je .error                          ; Jump to error if empty

.loop:
    movzx rbx, byte [rsi + rcx]        ; Load byte from string
    test rbx, rbx                      ; Check for null terminator
    jz .done                           ; Jump to done if end of string
    cmp rbx, '0'                       ; Check if byte is less than '0'
    jl .error                          ; Jump to error if not a digit
    cmp rbx, '9'                       ; Check if byte is greater than '9'
    jg .error                          ; Jump to error if not a digit
    
    ; Check for overflow (simple check)
    cmp rax, 1000000                   ; Check if number exceeds limit
    jg .error                          ; Jump to error if overflow
    
    sub rbx, '0'                       ; Convert ASCII to number
    imul rax, 10                       ; Multiply current result by 10
    add rax, rbx                       ; Add new digit
    inc rcx                            ; Move to next byte
    jmp .loop                          ; Continue parsing

.error:
    xor rax, rax                       ; Return 0 for invalid number
.done:
    pop rdx                            ; Restore rdx register
    pop rcx                            ; Restore rcx register
    pop rbx                            ; Restore rbx register
    ret                                ; Return from function

; Compare two strings
; Input: rsi = first string, rdi = second string
; Returns: rax = 1 (equal), 0 (not equal)
strcmp:
    push rbx                           ; Save rbx register
    push rcx                           ; Save rcx register
    
    xor rcx, rcx                       ; Initialize byte index
    
.loop:
    movzx rax, byte [rsi + rcx]        ; Load byte from first string
    movzx rbx, byte [rdi + rcx]        ; Load byte from second string
    
    ; Check if both strings ended
    test rax, rax                      ; Check if first string ended
    jz .checkEnd                       ; Jump to check second string end
    
    ; Compare current characters
    cmp rax, rbx                       ; Compare bytes
    jne .notEqual                      ; Jump if bytes differ
    
    inc rcx                            ; Move to next byte
    jmp .loop                          ; Continue comparison

.checkEnd:
    ; First string ended, check if second also ended
    test rbx, rbx                      ; Check if second string ended
    jnz .notEqual                      ; Jump if second string continues
    mov rax, 1                         ; Return 1 (strings equal)
    pop rcx                            ; Restore rcx register
    pop rbx                            ; Restore rbx register
    ret                                ; Return from function

.notEqual:
    xor rax, rax                       ; Return 0 (strings not equal)
    pop rcx                            ; Restore rcx register
    pop rbx                            ; Restore rbx register
    ret                                ; Return from function

; Copy string from source to destination
; Input: rsi = source string, rdi = destination buffer
; Note: Destination buffer must be large enough
strcpy:
    push rax                           ; Save rax register
    push rcx                           ; Save rcx register
    
    xor rcx, rcx                       ; Initialize byte index
    
.loop:
    mov al, [rsi + rcx]                ; Read byte from source
    mov [rdi + rcx], al                ; Write byte to destination
    test al, al                        ; Check for null terminator
    jz .done                           ; Jump if end of string
    inc rcx                            ; Move to next byte
    cmp rcx, 255                       ; Check for buffer overflow
    jge .done                          ; Jump if max length reached
    jmp .loop                          ; Continue copying

.done:
    pop rcx                            ; Restore rcx register
    pop rax                            ; Restore rax register
    ret                                ; Return from function