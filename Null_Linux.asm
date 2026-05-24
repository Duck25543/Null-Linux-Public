;help me

[bits 16]	
[org 0x7c00]	

boot_init:
	cld
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00
	
	mov si, banner_text
	call print_string

prompt_init:
	mov si, prompt_symbol
	call print_string
	xor cx, cx
	xor edx, edx

input_loop:
	mov ah, 0x00
	int 0x16
	cmp al, 0x0D
	je execute_line
	cmp al, '0'
	jl input_loop
	cmp al '1'
	jg input_loop

	cmp cx, 32
	jl continue_print
	jge input_loop

continue_print:
	mov ah, 0x0E
	int 0x10
	inc cx
	push ax
	sub al, '0'
	shl edx, 1
	or dl, al
	mov ax, cx
	mov bl, 8
	div bl
	mov bh, ah
	pop ax
	cmp bh, 0
	jne check_done

print_space:
	mov al, ' '
	mov ah, 0x0E
	int 0x10

check_done:
	jmp input_loop

execute_line:
	mov ah, 0x0E
	mov al, 0x0A
	int 0x10
	mov al, 0x0D
	int 0x10

	;--Evaluator Check--
	cmp edx, 15
	je trigger_clear

	jmp prompt_init

trigger_clear:
	mov ax, 0x0003
	int 0x10
	jmp prompt_init

print_string:
	mov ah, 0x0E
.string_loop:
	lodsb
	cmp al, 0
	je .string_done
	int 0x10
	jmp .string_loop
.string_done:
	ret
; ==========================================================
; DATA SEGMENT
; ==========================================================
banner_text:
	db "====================================", 0x0D, 0x0A, \
	   "             NULL LINUX             ", 0x0D, 0x0A, \
	   "            HAVE FUN :)             ", 0x0D, 0x0A, \
	   "====================================", 0x0D, 0x0A, 0
prompt_symbol:
	db "$ ", 0
times 510-($-$$) db 0
dw 0xAA55
