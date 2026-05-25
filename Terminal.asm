; =====================================================================
; Null OS Core - x86 Assembly Terminal Shell (32-bit)
; =====================================================================

[BITS 32]
global _shell_start

_shell_start:
    call clear_screen
    
.prompt_loop:
    call print_prompt
    mov edi, input_buffer       ; EDI points to input storage
    mov ecx, 0                  ; ECX keeps track of character count

.read_key:
    ; Poll the keyboard controller status port
    in al, 0x64
    test al, 0x01               ; Is output buffer full? (Key waiting?)
    jz .read_key                ; If not, loop and keep waiting

    ; Read the actual scancode from keyboard data port
    in al, 0x60
    
    ; Test if it's a key-release event (bit 7 set)
    test al, 0x80
    jnz .read_key               ; Ignore key release, wait for next press

    ; --- Simple Scancode to ASCII Translation (Example subset) ---
    cmp al, 0x1C                ; Enter key scancode
    je .enter_pressed
    cmp al, 0x0E                ; Backspace key scancode
    je .backspace_pressed
    
    ; Convert character (Assuming standard layout mappings)
    call scancode_to_ascii     ; Returns ASCII in AL
    cmp al, 0                   ; If unmapped, ignore
    je .read_key

    ; Store and print the character
    cmp ecx, 79                 ; Don't overflow the 80-char buffer
    jge .read_key
    mov [edi + ecx], al         ; Save to buffer
    inc ecx
    call print_char             ; Print to screen
    jmp .read_key

.backspace_pressed:
    jecxz .read_key             ; If buffer empty (ECX=0), do nothing
    dec ecx
    call do_backspace
    jmp .read_key

.enter_pressed:
    mov byte [edi + ecx], 0     ; Null-terminate input string
    call print_newline
    
    ; --- Command Evaluation ---
    mov esi, input_buffer
    
    ; Check "clear"
    mov edi, cmd_clear
    call string_compare
    jc .exec_clear

    ; Check "sysinfo"
    mov edi, cmd_sysinfo
    call string_compare
    jc .exec_sysinfo

    ; Unknown command handling
    jmp .unknown_cmd

.exec_clear:
    call clear_screen
    jmp .prompt_loop

.exec_sysinfo:
    mov esi, msg_sysinfo
    call print_string
    jmp .prompt_loop

.unknown_cmd:
    cmp ecx, 0                  ; If they just hit enter, don't throw error
    je .prompt_loop
    mov esi, msg_unknown
    call print_string
    jmp .prompt_loop


; =====================================================================
; Helper Functions
; =====================================================================

print_prompt:
    mov esi, prompt_str
    call print_string
    ret

print_string:
    ; ESI points to null-terminated string
.loop:
    lodsb
    cmp al, 0
    je .done
    call print_char
    jmp .loop
.done:
    ret

print_char:
    ; AL contains ASCII character. Writes to current VGA cursor position.
    push eax
    push ebx
    mov ebx, [vga_cursor]
    mov byte [ebx], al          ; Write ASCII character byte
    mov byte [ebx+1], 0x0F      ; Attribute byte: White text on Black
    add ebx, 2
    mov [vga_cursor], ebx
    pop ebx
    pop eax
    ret

print_newline:
    push eax
    push edx
    ; Round cursor up to next line (multiples of 160 bytes per row)
    mov eax, [vga_cursor]
    sub eax, 0xB8000
    mov edx, 0
    mov ecx, 160
    div ecx                     ; EAX = current row
    inc eax                     ; Move to next row
    mul ecx
    add eax, 0xB8000
    mov [vga_cursor], eax
    pop edx
    pop eax
    ret

do_backspace:
    sub dword [vga_cursor], 2
    mov ebx, [vga_cursor]
    mov word [ebx], 0x0F20      ; Write space character to erase
    ret

clear_screen:
    mov edi, 0xB8000
    mov ecx, 80 * 25
    mov ax, 0x0F20              ; Blank space attribute
    rep stosw
    mov dword [vga_cursor], 0xB8000
    ret

string_compare:
    ; ESI = user input, EDI = command to match against
    ; Returns Carry Flag (CF) set if match, cleared if no match
.loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .no_match
    cmp al, 0
    je .match
    inc esi
    inc edi
    jmp .loop
.no_match:
    clc                         ; Clear carry flag (false)
    ret
.match:
    stc                         ; Set carry flag (true)
    ret

scancode_to_ascii:
    ; Basic quick translation for illustration
    cmp al, 0x10 return 'q'

; =====================================================================
; Data Section
; =====================================================================
vga_cursor   dd 0xB8000
prompt_str   db "null-os@core:/$ ", 0
cmd_clear    db "clear", 0
cmd_sysinfo  db "sysinfo", 0
msg_sysinfo  db "Null OS Core [Assembly Shell v1.0]", 0x0A, "Size: Under 1KB", 0x0A, 0
msg_unknown  db "null-sh: command not found", 0x0A, 0

SECTION .bss
input_buffer resb 80
