; Secure Password Generator in NASM Assembly 
; Uses /dev/random with a fallback to /dev/urandom
; Supports the following command-line arguments:
; -s [number]   : password length (default: 12)
; -no_num       : exclude digits
; -no_cl        : exclude uppercase letters
; -nogl         : exclude lowercase letters
; -file [path]  : save generated passwords to a file
; -c [number]   : number of passwords to generate (max: 20, default: 1)

%include "macroses.inc"
section .rodata
    ; System call numbers for file operations
    SYS_OPEN   equ 2          ; Syscall number for opening a file
    SYS_READ   equ 0          ; Syscall number for reading from a file
    SYS_WRITE  equ 1          ; Syscall number for writing to a file
    SYS_CLOSE  equ 3          ; Syscall number for closing a file

    ; File open flags
    O_RDONLY   equ 0          ; Flag for read-only mode
    O_WRONLY   equ 1          ; Flag for write-only mode
    O_CREAT    equ 0x40       ; Flag to create file if it doesn't exist
    O_TRUNC    equ 0x200      ; Flag to truncate file if it exists
    FILE_MODE  equ 0q644      ; File permissions (rw-r--r-- in octal)

    ; Random data source paths
    string random_device, "/dev/random"    ; Path to /dev/random for true random data
    string urandom_device, "/dev/urandom"  ; Path to /dev/urandom for pseudo-random data

    ; Error and usage messages (null-terminated with newline)
    string_newline_right usage, "Usage: ./password_generator [-s length] [-no_num] [-no_cl] [-nogl] [-file path] [-c count]"
    ; Usage message for command-line help
    string_newline_right error_invalid_length, "Error: Invalid password length (1-256)"
    ; Error for invalid password length
    string_newline_right error_invalid_count, "Error: Invalid password count (1-20)"
    ; Error for invalid password count
    string_newline_right error_file_open, "Error: Cannot open file"
    ; Error for file open failure
    string_newline_right error_random_open, "Error: Cannot open random device"
    ; Error for random device open failure
    string_newline_right error_random_read, "Error: Cannot read random data"
    ; Error for random data read failure
    string_newline_right error_file_write, "Error: Cannot write to file"
    ; Error for file write failure
    string_newline_right error_no_charset, "Error: No character sets enabled"
    ; Error when no character sets are enabled

    ; Character set for password generation
    chars: db "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
    ; Allowed characters for passwords
    chars_len: equ $ - chars               ; Length of character set

    ; Command-line argument strings for comparison
    string no_num_str, "-no_num"           ; Flag to disable numbers in passwords
    string no_cl_str, "-no_cl"             ; Flag to disable capital letters
    string nogl_str, "-nogl"               ; Flag to disable lowercase letters
    string s_str, "-s"                     ; Flag for specifying password length
    string file_str, "-file"               ; Flag for specifying output file
    string c_str, "-c"                     ; Flag for specifying password count

section .bss
    password resb 257         ; Buffer for one password (256 bytes + newline)
    random_buf resb 256       ; Buffer for random bytes from /dev/random or /dev/urandom
    file_path resb 256        ; Buffer for output file path
    file_descriptor resq 1    ; Storage for file descriptor (8 bytes)
    random_fd resq 1          ; Storage for random device descriptor (8 bytes)

section .data
    length dq 12              ; Default password length (12 characters)
    count dq 1                ; Default number of passwords to generate (1)
    use_numbers dq 1          ; Flag to include numbers (1 = yes, 0 = no)
    use_capital dq 1          ; Flag to include capital letters (1 = yes, 0 = no)
    use_lowercase dq 1        ; Flag to include lowercase letters (1 = yes, 0 = no)
    save_to_file dq 0         ; Flag to save passwords to file (1 = yes, 0 = no)
section .text
global _start

_start:
    ; save registers 
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; comand line parsing 
    call _parse_args
    test rax, rax
    jz .error_usage

    ; check the correctness of the parameters
    cmp qword [length], 1
    jl .error_length
    cmp qword [length], 256
    jg .error_length
    cmp qword [count], 1
    jl .error_count
    cmp qword [count], 20
    jg .error_count

    ; check that at least one character type is allowed
    mov rax, [use_numbers]
    or  rax, [use_capital]
    or  rax, [use_lowercase]
    jnz .ok_charset
    print_error error_no_charset
    jmp .exit
.ok_charset:

    ; opens a file with random data 
    call _open_random_device
    test rax, rax
    jz .error_random_open

    ; opens file to save generated passwords(if user chose it) 
    cmp qword [save_to_file], 1
    jne .generate_loop
    call _open_output_file
    test rax, rax
    jz .error_file_open

.generate_loop:
    ; generates one password 
    call _generate_password

    ; dispaly or save the password 
    cmp qword [save_to_file], 1
    je .save_to_file
    call _print_password
    jmp .next_iteration

.save_to_file:
    call _save_password_to_file
    test rax, rax
    jz .error_file_write

.next_iteration:
    ; reduce the password counter 
    dec qword [count]
    jnz .generate_loop

    ; close the file 
    call _close_random_device
    cmp qword [save_to_file], 1
    jne .exit
    call _close_output_file

.exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rax, 60               ; SYS_EXIT
    xor rdi, rdi              ; return code (0) 
    syscall

.error_usage:
    print_error usage
    jmp .exit
.error_length:
    print_error error_invalid_length
    jmp .exit
.error_count:
    print_error error_invalid_count
    jmp .exit
.error_random_open:
    print_error error_random_open
    jmp .exit
.error_file_open:
    print_error error_file_open
    call _close_random_device
    jmp .exit
.error_file_write:
    print_error error_file_write
    call _close_random_device
    call _close_output_file
    jmp .exit

_parse_args:
    ; parse argc and argv
    mov rax, [rsp + 16]       ; argc
    cmp rax, 1                ; check if there are parameters
    je .parse_done            ; use default parameters 
    
    lea rbx, [rsp + 24]       ; argv
    mov r12, rax              ; r12 = argc
    mov r13, 1                ; r13 = index of the current parametr(start from 1) 

.parse_loop:
    cmp r13, r12
    jge .parse_done

    ; current argument 
    mov rsi, [rbx + r13 * 8]

    ; compare with known flags 
    mov rdi, no_num_str
    call _strcmp
    cmp rax, 1
    je .set_no_num

    mov rsi, [rbx + r13 * 8]  ; restore the argument 
    mov rdi, no_cl_str
    call _strcmp
    cmp rax, 1
    je .set_no_cl

    mov rsi, [rbx + r13 * 8]
    mov rdi, nogl_str
    call _strcmp
    cmp rax, 1
    je .set_nogl

    mov rsi, [rbx + r13 * 8]
    mov rdi, s_str
    call _strcmp
    cmp rax, 1
    je .set_s

    mov rsi, [rbx + r13 * 8]
    mov rdi, file_str
    call _strcmp
    cmp rax, 1
    je .set_file

    mov rsi, [rbx + r13 * 8]
    mov rdi, c_str
    call _strcmp
    cmp rax, 1
    je .set_c

    ; if the argument is unkown, skip it 
    inc r13
    jmp .parse_loop

.set_no_num:
    mov qword [use_numbers], 0
    inc r13
    jmp .parse_loop

.set_no_cl:
    mov qword [use_capital], 0
    inc r13
    jmp .parse_loop

.set_nogl:
    mov qword [use_lowercase], 0
    inc r13
    jmp .parse_loop

.set_s:
    inc r13
    cmp r13, r12
    jge .parse_done           ; if there is no value after -s, ignore it 
    mov rsi, [rbx + r13 * 8]
    call _parse_number
    test rax, rax
    jz .skip_s                ; if it is not number, skip it 
    mov [length], rax
.skip_s:
    inc r13
    jmp .parse_loop

.set_file:
    inc r13
    cmp r13, r12
    jge .parse_done           ; if there is no value after -f, skip it 
    mov rsi, [rbx + r13 * 8]  ; getting the path to the file 
    mov rdi, file_path        
    call _strcpy
    mov qword [save_to_file], 1
    inc r13
    jmp .parse_loop

.set_c:
    inc r13
    cmp r13, r12
    jge .parse_done           ; if there is no value after -c, skip it 
    mov rsi, [rbx + r13 * 8]
    call _parse_number
    test rax, rax
    jz .skip_c                ; if it is not number, ignore it 
    mov [count], rax
.skip_c:
    inc r13
    jmp .parse_loop

.parse_done:
    mov rax, 1                
    ret

; String comparing: rsi — first string, rdi — second string 
_strcmp:
    xor rcx, rcx
.loop:
    mov al, [rsi + rcx]
    mov dl, [rdi + rcx]
    test al, al               ; check the end of the first string 
    jz .check_end
    cmp al, dl
    jne .not_equal
    inc rcx
    jmp .loop
.check_end:
    test dl, dl               ; check the end of the second string 
    jnz .not_equal            ; if it is not the end, the strings are not equal 
.equal:
    mov rax, 1
    ret
.not_equal:
    xor rax, rax
    ret

; string copying 
_strcpy:
    xor rcx, rcx
.loop:
    mov al, [rsi + rcx]
    mov [rdi + rcx], al
    test al, al
    jz .done
    inc rcx
    jmp .loop
.done:
    ret

; Parsing a number from a string
_parse_number:
    xor rax, rax              ; result 
    xor rcx, rcx              ; counter 
.parse_loop:
    movzx rbx, byte [rsi + rcx]
    test rbx, rbx             ; check whether it is the end of the string or not 
    jz .done
    cmp rbx, '0'
    jl .error
    cmp rbx, '9'
    jg .error
    sub rbx, '0'
    imul rax, rax, 10         
    add rax, rbx
    inc rcx
    jmp .parse_loop
.error:
    xor rax, rax
.done:
    ret

; Opening the random data device (/dev/random or /dev/urandom)
_open_random_device:
    ; Trying to open /dev/random
    mov rax, SYS_OPEN
    mov rdi, random_device
    mov rsi, O_RDONLY
    syscall
    test rax, rax
    js .try_urandom           ; If a problem occures, try to open urandom
    mov [random_fd], rax
    mov rax, 1                
    ret
.try_urandom:
    mov rax, SYS_OPEN
    mov rdi, urandom_device
    mov rsi, O_RDONLY
    syscall
    test rax, rax
    js .fail                  ; If there is a fail too, exit
    mov [random_fd], rax
    mov rax, 1                
    ret
.fail:
    xor rax, rax              ; error
    ret

; closing the random data device 
_close_random_device:
    mov rax, SYS_CLOSE
    mov rdi, [random_fd]
    test rdi, rdi
    js .skip                  
    syscall
.skip:
    ret

; opening a file for writting 
_open_output_file:
    mov rax, SYS_OPEN
    mov rdi, file_path
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, FILE_MODE
    syscall
    test rax, rax
    js .error                 ; (rax < 0) - error
    mov [file_descriptor], rax
    mov rax, 1                ; success
    ret
.error:
    xor rax, rax              ; error 
    ret

; file closing 
_close_output_file:
    mov rax, SYS_CLOSE
    mov rdi, [file_descriptor]
    test rdi, rdi
    js .skip                  ; if fd < 0, skip 
    syscall
.skip:
    ret

; password generation 
_generate_password:
    ; read random data 
    mov rax, SYS_READ
    mov rdi, [random_fd]
    mov rsi, random_buf
    mov rdx, [length]
    syscall
    cmp rax, [length]
    jne .error_read           ; If less bytes are read, an error occurs.

    xor rbx, rbx              ; Index in the password 
    xor rsi, rsi              ; Index in the random_buf
.generate_loop:
    cmp rbx, [length]
    jge .done
    cmp rsi, rax              ; Compare with the number of bytes read
    jl .use_random
; If random_buf runs out, read more
    mov rax, SYS_READ
    mov rdi, [random_fd]
    mov rsi, random_buf
    mov rdx, [length]
    syscall
    cmp rax, 0
    jle .error_read           ; reading error
    xor rsi, rsi
.use_random:
    movzx rcx, byte [random_buf + rsi]
    inc rsi
    
; Convert byte to character index
    xor rdx, rdx
    mov rax, rcx
    mov rcx, chars_len
    div rcx                   
    
; Get a symbol from the alphabet
    movzx rax, byte [chars + rdx]
    
; Checking if a character is valid
    push rsi
    mov rsi, rax              
    call _is_valid_char
    pop rsi
    
    test rax, rax
    jz .generate_loop         ; If invalid, try the next byte
    
; Save the symbol in the password
    mov [password + rbx], al
    inc rbx
    jmp .generate_loop

.error_read:
    print_error error_random_read
    jmp _start.exit

    
.done:
    mov byte [password + rbx], 10  ; add '\n'
    mov byte [password + rbx + 1], 0  ; add \0 
    ret
    

; Check if character is valid
; rsi contains the character to check
_is_valid_char:
    mov rax, rsi              ; restore a symbol 
    
; Checking lowercase letters
    cmp qword [use_lowercase], 0
    je .check_capital
    cmp al, 'a'
    jl .check_capital
    cmp al, 'z'
    jle .valid

.check_capital:
; Checking capital letters
    cmp qword [use_capital], 0
    je .check_numbers
    cmp al, 'A'
    jl .check_numbers
    cmp al, 'Z'
    jle .valid

.check_numbers:
    ; checking numbers 
    cmp qword [use_numbers], 0
    je .check_special
    cmp al, '0'
    jl .check_special
    cmp al, '9'
    jle .valid

.check_special:
    
    cmp al, '!'
    jl .invalid
    cmp al, ')'
    jle .valid

.invalid:
    xor rax, rax
    ret
.valid:
    mov rax, 1
    ret

; output the password  
_print_password:
    mov rax, SYS_WRITE
    mov rdi, 1                ; stdout
    mov rsi, password
    mov rdx, [length]
    inc rdx                   
    syscall
    ret

; storing the password in a file 
_save_password_to_file:
    mov rax, SYS_WRITE
    mov rdi, [file_descriptor]
    mov rsi, password
    mov rdx, [length]
    inc rdx                   
    syscall
    cmp rax, rdx
    je .success
    xor rax, rax              ; error
    ret
.success:
    mov rax, 1                
    ret