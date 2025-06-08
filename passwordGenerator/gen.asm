
%include "macroses.inc"

; External function declarations
extern openRandomDevice
extern closeRandomDevice
extern generatePassword
extern printPassword
extern savePasswordToFile
extern openOutputFile
extern closeOutputFile
extern parseNumber
extern strcmp
extern strcpy

section .data
    ; Configuration variables
    passwordLength dq 12      ; Default password length
    useNumbers dq 1           ; Include numbers (1 = yes, 0 = no)
    useCapital dq 1           ; Include capital letters
    useLowercase dq 1         ; Include lowercase letters
    useSymbols dq 1           ; Include special symbols
    saveToFile dq 0           ; Save to file (1 = yes, 0 = no)
    passwordCount dq 1        ; Number of passwords to generate

section .bss
    filePath resb 256         ; Buffer for output file path
    password resb 256         ; Buffer for generated password

section .rodata
    ; Constants
    PASS_LEN_MIN equ 1        ; Minimum password length
    PASS_LEN_MAX equ 128      ; Maximum password length
    COUNT_MIN equ 1           ; Minimum number of passwords
    COUNT_MAX equ 100         ; Maximum number of passwords
    SYS_EXIT equ 60           ; System call: exit

    ; Messages
    string_with_len MSG_USAGE, "Usage: password_generator -l [length] -no_num -no_cl -no_lc -no_sym -file [filename] -help -c [count]", 10
    string_with_len MSG_ERROR_LENGTH, "Error: Invalid password length (1-128)", 10
    string_with_len MSG_ERROR_COUNT, "Error: Invalid password count (1-100)", 10
    string_with_len MSG_ERROR_NO_CHARS, "Error: All character types disabled", 10
    string_with_len MSG_ERROR_OPEN, "Error: Cannot open random device", 10
    string_with_len MSG_ERROR_READ, "Error: Cannot read random data", 10
    string_with_len MSG_ERROR_CLOSE, "Error: Cannot close random device", 10
    string_with_len MSG_ERROR_FILE_WRITE, "Error: Cannot write to file", 10

    ; Command-line argument strings
    string_simple ARG_LENGTH, "-l"
    string_simple ARG_NO_NUM, "-no_num"
    string_simple ARG_NO_CL, "-no_cl"
    string_simple ARG_NO_LC, "-no_lc"
    string_simple ARG_NO_SYM, "-no_sym"
    string_simple ARG_FILE, "-file"
    string_simple ARG_COUNT, "-c"
    string_simple ARG_HELP, "-help"

section .text
global _start
global passwordLength
global useNumbers
global useCapital
global useLowercase
global useSymbols
global saveToFile
global filePath
global password

; Program entry point
_start:
    ; Parse command-line arguments
    call parseArgs
    test rax, rax
    jz .exit                  ; Exit if parsing failed (e.g., -help)

    ; Validate configuration
    cmp qword [passwordLength], PASS_LEN_MIN
    jl .errorLength
    cmp qword [passwordLength], PASS_LEN_MAX
    jg .errorLength
    cmp qword [passwordCount], COUNT_MIN
    jl .errorCount
    cmp qword [passwordCount], COUNT_MAX
    jg .errorCount

    ; Check if at least one character type is enabled
    mov rax, [useNumbers]
    or rax, [useCapital]
    or rax, [useLowercase]
    or rax, [useSymbols]
    test rax, rax
    jz .errorNoChars

    ; Open output file if required
    cmp qword [saveToFile], 1
    jne .skipFileOpen
    call openOutputFile
    test rax, rax
    jz .errorFileOpen

.skipFileOpen:
    ; Open random device
    call openRandomDevice
    test rax, rax
    jz .errorOpen

.generateLoop:
    ; Generate a password
    call generatePassword
    test rax, rax
    jz .errorRead

    ; Output or save the password
    cmp qword [saveToFile], 1
    je .savePassword
    call printPassword
    jmp .nextIteration

.savePassword:
    call savePasswordToFile
    test rax, rax
    jz .errorFileWrite

.nextIteration:
    ; Decrement password count and continue if needed
    dec qword [passwordCount]
    jnz .generateLoop

    ; Clean up
    call closeRandomDevice
    test rax, rax
    jz .errorClose
    cmp qword [saveToFile], 1
    jne .exit
    call closeOutputFile

.exit:
    mov rax, SYS_EXIT
    xor rdi, rdi              ; Exit code 0
    syscall

.errorLength:
    print_error MSG_ERROR_LENGTH, MSG_ERROR_LENGTH_len
    jmp .exit
.errorCount:
    print_error MSG_ERROR_COUNT, MSG_ERROR_COUNT_len
    jmp .exit
.errorNoChars:
    print_error MSG_ERROR_NO_CHARS, MSG_ERROR_NO_CHARS_len
    jmp .exit
.errorOpen:
    print_error MSG_ERROR_OPEN, MSG_ERROR_OPEN_len
    jmp .exit
.errorRead:
    print_error MSG_ERROR_READ, MSG_ERROR_READ_len
    call closeRandomDevice
    jmp .exit
.errorClose:
    print_error MSG_ERROR_CLOSE, MSG_ERROR_CLOSE_len
    jmp .exit
.errorFileOpen:
    print_error MSG_ERROR_OPEN, MSG_ERROR_OPEN_len
    jmp .exit
.errorFileWrite:
    print_error MSG_ERROR_FILE_WRITE, MSG_ERROR_FILE_WRITE_len
    call closeRandomDevice
    call closeOutputFile
    jmp .exit

; Parse command-line arguments
; Returns: rax = 1 (success), 0 (error or help)
parseArgs:
    mov rax, [rsp + 8]        ; argc
    cmp rax, 1                ; Check if no arguments provided
    jle .done
    mov r12, rax              ; Save argc
    mov r13, 0                ; Argument index
    lea rbx, [rsp + 16]       ; argv pointer

.parseLoop:
    inc r13                   ; Next argument
    cmp r13, r12
    jge .done                 ; Exit if no more arguments
    mov rsi, [rbx + r13 * 8]  ; Current argument

    ; Check for -help
    mov rdi, ARG_HELP
    call strcmp
    cmp rax, 1
    je .help

    ; Check for -no_num
    mov rdi, ARG_NO_NUM
    call strcmp
    cmp rax, 1
    je .setNoNum

    ; Check for -no_cl
    mov rdi, ARG_NO_CL
    call strcmp
    cmp rax, 1
    je .setNoCapital

    ; Check for -no_lc
    mov rdi, ARG_NO_LC
    call strcmp
    cmp rax, 1
    je .setNoLowercase

    ; Check for -no_sym
    mov rdi, ARG_NO_SYM
    call strcmp
    cmp rax, 1
    je .setNoSymbols

    ; Check for -l
    mov rdi, ARG_LENGTH
    call strcmp
    cmp rax, 1
    je .setLength

    ; Check for -c
    mov rdi, ARG_COUNT
    call strcmp
    cmp rax, 1
    je .setCount

    ; Check for -file
    mov rdi, ARG_FILE
    call strcmp
    cmp rax, 1
    je .setFile

    ; Unknown argument, continue
    jmp .parseLoop

.setNoNum:
    mov qword [useNumbers], 0
    jmp .parseLoop

.setNoCapital:
    mov qword [useCapital], 0
    jmp .parseLoop

.setNoLowercase:
    mov qword [useLowercase], 0
    jmp .parseLoop

.setNoSymbols:
    mov qword [useSymbols], 0
    jmp .parseLoop

.setLength:
    inc r13
    cmp r13, r12
    jge .done
    mov rsi, [rbx + r13 * 8]
    call parseNumber
    test rax, rax
    jz .parseLoop             ; Skip if invalid number
    mov [passwordLength], rax
    jmp .parseLoop

.setCount:
    inc r13
    cmp r13, r12
    jge .done
    mov rsi, [rbx + r13 * 8]
    call parseNumber
    test rax, rax
    jz .parseLoop             ; Skip if invalid number
    mov [passwordCount], rax
    jmp .parseLoop

.setFile:
    inc r13
    cmp r13, r12
    jge .done
    mov rsi, [rbx + r13 * 8]
    mov rdi, filePath
    call strcpy
    mov qword [saveToFile], 1
    jmp .parseLoop

.help:
    print MSG_USAGE, MSG_USAGE_len
    xor rax, rax              ; Return 0 for help
    ret

.done:
    mov rax, 1                ; Return 1 for success
    ret