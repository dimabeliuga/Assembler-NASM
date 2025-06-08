global _start

section .data
    enterMsg db "Enter element (to finish input 'X'): ", 0 ; Prompt for user input
    enterMsg_len equ $ - enterMsg                          ; Length of prompt message
    errorInvalidNumber db "[Error]: Invalid number format", 10, 0 ; Error message for invalid input
    ; 10 - newLine, 0 - end of the line symbol
    errorInvalidNumber_len equ $ - errorInvalidNumber       ; Length of invalid number error message
    errorArrayFull db "[Error]: Array is full", 10, 0      ; Error message for full array
    errorArrayFull_len equ $ - errorArrayFull              ; Length of array full error message
    arrayContents db "Array contents:", 10, 0              ; Message before printing array
    arrayContents_len equ $ - arrayContents                ; Length of array contents message
    choiceSortAlgorithm db "Choose sorting algorithm:", 10, "1 - Selection Sort", 10, "2 - Bubble Sort", 10, "3 - Insertion Sort", 10, "4 - Quick Sort", 10, "Enter your choice (1-4): ", 0
    choiceSortAlgorithm_len equ $ - choiceSortAlgorithm
    errorInvalidChoice db "[Error]: Invalid choice. Please enter 1-4", 10, 0
    errorInvalidChoice_len equ $ - errorInvalidChoice
    msgBubbleSort: db "---Bubble Sort---", 10, 0
    msgBubbleSort_len: equ $ - msgBubbleSort
    msgSelectionSort: db "---Selection Sort---", 10, 0
    msgSelectionSort_len: equ $ - msgSelectionSort
    msgInserSort: db "---Insert Sort---", 10, 0
    msgInserSort_len: equ $ - msgInserSort 
    msgQuickSort: db "---Qucik Sort---", 10, 0
    msgQuickSort_len: equ $ - msgQuickSort 
    
    space db " ", 0                                        ; Space character for separating numbers
    space_len equ $ - space                                ; Length of space (1 byte)
    newline db 10, 0                                       ; Newline character for line break
    newline_len equ $ - newline                            ; Length of newline (1 byte)

; Uninitialized data is declared in the "section .bss" section
section .bss
    element resb 12         ; Buffer for input string (12 bytes)
    array resd 255          ; Array to store up to 255 32-bit numbers
    arraySize resd 1        ; Variable to store the number of elements in array
    choice resb 2           ; Buffer for sorting algorithm choice

; section for constants
section .rodata
    ARRAY_MAX_CAPACITY equ 255 ; Maximum array capacity
    SYS_WRITE equ 1         ; System call number for write
    SYS_READ equ 0          ; System call number for read
    STDIN equ 0             ; File descriptor for stdin
    STDOUT equ 1            ; File descriptor for stdout
    STDERR equ 2            ; File descriptor for stderr

; %macro name parametrs_number
; --code here --
; %endmacro 

; Macro to print a string with its length
%macro print 1
    mov rax, SYS_WRITE      ; Set syscall to write
    mov rdi, STDOUT         ; Set output to stdout
    mov rsi, %1             ; Point to string
    mov rdx, %1_len         ; Set string length
    syscall                 ; Call kernel
%endmacro

; Macro to print an error message to stderr
%macro print_error 1
    mov rax, SYS_WRITE      ; Set syscall to write
    mov rdi, STDERR         ; Set output to stderr
    mov rsi, %1             ; Point to error message
    mov rdx, %1_len         ; Set error message length
    syscall                 ; Call kernel
%endmacro

; Macro to read input into element buffer
%macro inputElement 0
    mov rax, SYS_READ       ; Set syscall to read
    mov rdi, STDIN          ; Set input to stdin
    mov rsi, element        ; Point to input buffer
    mov rdx, 12             ; Maximum input length (12 bytes)
    syscall                 ; Call kernel
    mov [element + rax - 1], byte 0 ; Replace newline with null terminator
    mov rdi, rax            ; Store number of characters read in rdi
%endmacro


; Macro to read choice input
%macro inputChoice 0
    mov rax, SYS_READ       ; Set syscall to read
    mov rdi, STDIN          ; Set input to stdin
    mov rsi, choice         ; Point to choice buffer
    mov rdx, 2              ; Maximum input length (2 bytes)
    syscall                 ; Call kernel
    mov [choice + rax - 1], byte 0 ; Replace newline with null terminator
%endmacro


; code section 
section .text
_start:
    mov dword [arraySize], 0 ; Initialize array size to 0
._input_loop:
    print enterMsg           ; Print input prompt
    inputElement             ; Read user input
    call _checkNumber        ; Check and process input
    cmp rax, 1               ; Check if input is 'X' (end input)
    jne ._input_loop         ; If not 'X', continue input loop
    
._choise_loop:
    print choiceSortAlgorithm
    inputChoice
    call validateChoice
    cmp rax, 0
    je ._choise_loop

    cmp rax, 1
    je ._sort_with_bubble
    cmp rax, 2
    je ._sort_with_selection
    cmp rax, 3
    je ._sort_with_insertion
    cmp rax, 4
    je ._sort_with_quick

._sort_with_bubble:
    print msgBubbleSort
    call bubble_sort     
    jmp ._print_and_exit
._sort_with_selection:
    print msgSelectionSort
    call selectionSort      
    jmp ._print_and_exit
._sort_with_insertion:
    print msgInserSort
    call insertionSort      
    jmp ._print_and_exit
._sort_with_quick:
    print msgQuickSort
    call _quickSort      

._print_and_exit:
    call _printArray         ; Print sorted array
    jmp _exit                ; Exit program

_exit:
    xor rdi, rdi             ; Set return code to 0
    mov rax, 60              ; Set syscall to exit
    syscall                  ; Call kernel to exit


validateChoice:
    ; Check if choice is a single digit from 1 to 4
    mov al, [choice]        ; Load first character
    cmp al, '1'
    jl ._invalid_choice
    cmp al, '4'
    jg ._invalid_choice
    
    ; Check if it's only one character (next should be null)
    mov al, [choice + 1]
    cmp al, 0
    jne ._invalid_choice
    
    ; Valid choice - convert to number and return
    mov al, [choice]
    sub al, '0' 
    movzx rax, al 
    ret

._invalid_choice:
    print_error errorInvalidChoice
    mov rax, 0 
    ret


; Function: Check and convert input string to number
; Input: rsi - pointer to string (element), rdi - string length
; Output: rax - 0 (continue input), 1 (input ended, 'X'), -1 (error)
; If valid number, add it to array
_checkNumber:
    push rbx                 ; Save rbx register
    push r12                 ; Save r12 register
    mov rbx, rsi             ; Save pointer to string
    cmp rdi, 2               ; Check if input is just newline
    jg .no_exit_sign         ; If more than newline, check for 'X'

    movzx rsi, byte [rbx]    ; Load first character
    or rsi, 0x20             ; Convert to lowercase
    cmp rsi, 'x'             ; Check if input is 'x' or 'X'
    je .exit_input           ; If 'X', end input

.no_exit_sign:
    xor rax, rax             ; Clear result (number)
    xor rcx, rcx             ; Clear character counter
    mov r12, 1               ; Set number sign to positive (+1)
    movzx rsi, byte [rbx]    ; Load first character
    cmp rsi, '-'             ; Check for negative sign
    jne .no_sign             ; If not '-', skip
    mov r12, -1              ; Set sign to negative (-1)
    inc rcx                  ; Skip sign character
.no_sign:
.parse_loop:
    movzx rsi, byte [rbx + rcx] ; Load next character
    cmp rsi, 0               ; Check for end of string
    je .convert              ; If end, convert to number
    cmp rsi, '0'             ; Check if character is less than '0'
    jl .invalid              ; If so, invalid input
    cmp rsi, '9'             ; Check if character is greater than '9'
    jg .invalid              ; If so, invalid input
    sub rsi, '0'             ; Convert character to digit
    imul rax, 10             ; Multiply current number by 10
    add rax, rsi             ; Add new digit
    inc rcx                  ; Move to next character
    jmp .parse_loop          ; Continue parsing
.convert:
    imul rax, r12            ; Apply sign to number
    mov r12d, [arraySize]    ; Load current array size
    cmp r12d, ARRAY_MAX_CAPACITY ; Check if array is full
    jge .array_full          ; If full, handle error
    mov [array + r12 * 4], eax ; Store number in array
    inc r12d                 ; Increment array size
    mov [arraySize], r12d    ; Update array size
    mov rax, 0               ; Return 0 (continue input)
    jmp .done                ; Finish
.invalid:
    print_error errorInvalidNumber ; Print invalid number error
    mov rax, -1              ; Return -1 (error)
    jmp .done                ; Finish
.array_full:
    print_error errorArrayFull ; Print array full error
    mov rax, -1              ; Return -1 (error)
    jmp .done                ; Finish
.exit_input:
    mov rax, 1               ; Return 1 (end input)
.done:
    pop r12                  ; Restore r12 register
    pop rbx                  ; Restore rbx register
    ret                      ; Return from function

; Function: Print array contents
; Input: --- 
; Output: --- 
_printArray:
    print arrayContents      ; Print "Array contents:" header
    cmp byte [arraySize], 0  ; Check if array is empty
    jz .end_print            ; If empty, skip printing
    xor rbx, rbx             ; Initialize array index
.print_loop:
    mov edi, [array + rbx * 4] ; Load number from array
    call _print_digit        ; Print the number
    print space              ; Print space separator
    inc rbx                  ; Move to next index
    cmp ebx, [arraySize]     ; Check if end of array reached
    jl .print_loop           ; If not, continue loop
    print newline            ; Print newline at end
.end_print:
    ret                      ; Return from function

; Function: Print number to stdout
; Input: edi - number to print
_print_digit:
    push rbx                 ; Save rbx register
    mov eax, edi             ; Load number to print
    mov rbx, 10              ; Set divisor (base 10)
    lea rsi, [element + 11]  ; Point to end of buffer
    mov rcx, rsi             ; Save end of buffer
    test eax, eax            ; Check if number is negative
    mov r12, 1               ; Set sign to positive
    jge .reverse_loop        ; If positive, skip negation
    neg eax                  ; Make number positive
    mov r12, -1              ; Set sign to negative
.reverse_loop:
    xor edx, edx             ; Clear remainder
    div rbx                  ; Divide by 10: eax = quotient, edx = remainder
    dec rsi                  ; Move buffer pointer left
    add dl, '0'              ; Convert remainder to ASCII
    mov [rsi], dl            ; Store digit in buffer
    test eax, eax            ; Check if more digits remain
    jnz .reverse_loop        ; If yes, continue
    cmp r12, 1               ; Check if number was positive
    je ._positive            ; If positive, skip sign
    dec rsi                  ; Move buffer pointer left
    mov byte [rsi], '-'      ; Add negative sign
._positive:
    mov rdx, rcx             ; Calculate string length
    sub rdx, rsi             ; Length = end - start
    mov rax, SYS_WRITE       ; Set syscall to write
    mov rdi, STDOUT          ; Set output to stdout
    syscall                  ; Call kernel to print
    pop rbx                  ; Restore rbx register
    ret                      ; Return from function

; Function: Bubble sort
bubble_sort:
    mov r12, [arraySize]     ; Load array size
    cmp r12, 1               ; If size <= 1, no sorting needed
    jle .done                ; Exit if done
    dec r12                  ; Decrease size for last iteration
.outer_loop:
    xor r13, r13             ; Reset swap flag
    xor rbx, rbx             ; Reset inner loop index
.inner_loop:
    mov eax, [array + rbx * 4] ; Load current element
    mov ecx, [array + rbx * 4 + 4] ; Load next element
    cmp eax, ecx             ; Compare elements
    jle .no_swap             ; If in order, skip swap
    mov [array + rbx * 4], ecx ; Swap elements
    mov [array + rbx * 4 + 4], eax
    mov r13, 1               ; Set swap flag
.no_swap:
    inc rbx                  ; Move to next index
    cmp ebx, r12d            ; Check if end of inner loop
    jl .inner_loop           ; If not, continue inner loop
    test r13, r13            ; Check if any swaps occurred
    jz .done                 ; If no swaps, exit
    dec r12                  ; Decrease outer loop bound
    cmp r12, 0               ; Check if outer loop done
    jge .outer_loop          ; If not, continue outer loop
.done:
    ret                      ; Return from function

; Function: Selection sort
; Input: array - array to sort, arraySize - number of elements
; Output: array sorted in ascending order
selectionSort:
    push rbx                 ; Save rbx register
    push r12                 ; Save r12 register
    push r13                 ; Save r13 register
    mov r12d, [arraySize]    ; Load array size
    cmp r12d, 1              ; If size <= 1, no sorting needed
    jle .done                ; Exit if done
    xor rbx, rbx             ; Initialize outer loop index (i)
.outer_loop:
    mov r13, rbx             ; Set index of minimum element
    lea rax, [rbx + 1]       ; Set inner loop index (j = i + 1)
.inner_loop:
    cmp eax, r12d            ; Check if end of array reached
    jge .swap                ; If yes, perform swap
    mov ecx, [array + rax * 4] ; Load current element
    mov edx, [array + r13 * 4] ; Load minimum element
    cmp ecx, edx             ; Compare with minimum
    jge .no_new_min          ; If not smaller, skip
    mov r13, rax             ; Update minimum index
.no_new_min:
    inc rax                  ; Move to next element
    jmp .inner_loop          ; Continue inner loop
.swap:
    cmp rbx, r13             ; Check if minimum index changed
    je .no_swap              ; If same, skip swap
    mov eax, [array + rbx * 4] ; Load current element
    mov ecx, [array + r13 * 4] ; Load minimum element
    mov [array + r13 * 4], eax ; Swap elements
    mov [array + rbx * 4], ecx
.no_swap:
    inc rbx                  ; Move to next outer loop index
    cmp ebx, r12d            ; Check if outer loop done
    jl .outer_loop           ; If not, continue outer loop
.done:
    pop r13                  ; Restore r13 register
    pop r12                  ; Restore r12 register
    pop rbx                  ; Restore rbx register
    ret                      ; Return from function

; Function: Insertion sort
; Input: array - array to sort, arraySize - number of elements
; Output: array sorted in ascending order
insertionSort:
    push rbx                 ; Save rbx register
    push r12                 ; Save r12 register
    mov r12d, [arraySize]    ; Load array size
    cmp r12d, 1              ; If size <= 1, no sorting needed
    jle .done                ; Exit if done
    mov ebx, 1               ; Initialize outer loop index (i)
.outer_loop:
    mov eax, [array + rbx * 4] ; Load current element to insert
    mov ecx, ebx             ; Set inner loop index (j)
.inner_loop:
    test ecx, ecx            ; Check if at start of array
    jz .insert               ; If yes, insert element
    mov edx, [array + rcx * 4 - 4] ; Load previous element
    cmp edx, eax             ; Compare with current element
    jle .insert              ; If in order, insert
    mov [array + rcx * 4], edx ; Shift element right
    dec rcx                  ; Move left
    jmp .inner_loop          ; Continue inner loop
.insert:
    mov [array + rcx * 4], eax ; Insert element
    inc rbx                  ; Move to next outer loop index
    cmp ebx, r12d            ; Check if end of array
    jl .outer_loop           ; If not, continue outer loop
.done:
    pop r12                  ; Restore r12 register
    pop rbx                  ; Restore rbx register
    ret                      ; Return from function


; Function: QuickSort wrapper - call this from main
; This function sets up initial parameters and calls the recursive quickSort
_quickSort:
    push rbx ; Save registers
    push r12
    push r13
    push r14
    
    mov edi, 0 ; Set left index to 0
    mov esi, [arraySize] ; Load array size
    dec esi ; Set right index to size - 1
    cmp esi, 0 ; Check if array has elements
    jle .done ; If empty or single element, exit
    
    call quickSort ; Call recursive quicksort
    
.done:
    pop r14 ; Restore registers
    pop r13
    pop r12
    pop rbx
    ret

; Function: QuickSort (recursive)
; Input: edi - left index, esi - right index
; Output: array sorted in ascending order
quickSort:
    push rbx ; Save rbx register
    push r12 ; Save r12 register
    push r13 ; Save r13 register
    push r14 ; Save r14 register
    
    mov r12d, edi ; Save left index (DON'T reset to 0!)
    mov r13d, esi ; Save right index (DON'T reset to arraySize-1!)
    
    cmp r12d, r13d ; Check if left >= right
    jge .done ; If yes, exit (base case)
    
    mov edi, r12d ; Set left for partition
    mov esi, r13d ; Set right for partition
    call _partition ; Call partition function
    mov r14d, eax ; Save pivot index
    
    ; Sort left subarray: quickSort(left, pivot-1)
    mov edi, r12d ; Set left for left subarray
    lea esi, [r14d - 1] ; Set right to pivot - 1
    cmp edi, esi ; Check if subarray is valid
    jge .skip_left ; Skip if invalid
    call quickSort ; Sort left subarray
    
.skip_left:
    ; Sort right subarray: quickSort(pivot+1, right)
    lea edi, [r14d + 1] ; Set left to pivot + 1
    mov esi, r13d ; Set right for right subarray
    cmp edi, esi ; Check if subarray is valid
    jge .done ; Skip if invalid
    call quickSort ; Sort right subarray
    
.done:
    pop r14 ; Restore r14 register
    pop r13 ; Restore r13 register
    pop r12 ; Restore r12 register
    pop rbx ; Restore rbx register
    ret ; Return from function

; Function: Partition for QuickSort
; Input: edi - left index, esi - right index
; Output: eax - pivot index
_partition:
    push rbx ; Save rbx register
    push r12 ; Save r12 register
    push r13 ; Save r13 register
    
    mov r12d, edi ; Save left index
    mov r13d, esi ; Save right index
    
    ; Choose pivot as last element
    mov eax, [array + r13 * 4] ; Set pivot to array[right]
    mov ebx, r12d ; Set i to left (index of smaller element)
    mov ecx, r12d ; Set j to left (current element)
    
.loop:
    cmp ecx, r13d ; Check if j < right
    jge .place_pivot ; If not, place pivot
    
    mov edx, [array + rcx * 4] ; Load array[j]
    cmp edx, eax ; Compare with pivot
    jg .no_swap ; If greater than pivot, skip swap
    
    ; Swap array[i] and array[j]
    mov r10d, [array + rbx * 4] ; Load array[i]
    mov [array + rbx * 4], edx ; array[i] = array[j]
    mov [array + rcx * 4], r10d ; array[j] = array[i]
    inc ebx ; Increment i
    
.no_swap:
    inc ecx ; Increment j
    jmp .loop ; Continue loop
    
.place_pivot:
    ; Place pivot in correct position
    mov r10d, [array + rbx * 4] ; Load array[i]
    mov [array + rbx * 4], eax ; array[i] = pivot
    mov [array + r13 * 4], r10d ; array[right] = array[i]
    
    mov eax, ebx ; Return pivot index
    
    pop r13 ; Restore r13 register
    pop r12 ; Restore r12 register
    pop rbx ; Restore rbx register
    ret ; Return from function