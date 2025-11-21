extern create_map
extern write_item
extern get_item
%define	MAP_SIZE 100
%define	ADD_PROMPTS 2
section .data
	introMsg:
		db "This program is meant an example of my hashmap implementation.",10
		db "You'll be prompted to enter a few keys and values,",10
		db "which will be added to a hashmap. Then you'll be able to use",10
		db "those keys to retrieve the values.",10
	introLen	equ $-introMsg
	keyMsg:
		db "Enter a key for that value: "
	keyLen		equ $-keyMsg
	valueMsg:
		db "Enter a value: "
	valueLen	equ $-valueMsg
	key2Msg:
		db "Enter a key to retrieve: "
	key2Len		equ $-key2Msg
	invalMsg:
		db "No value for given key",10
	invalLen	equ $-invalMsg
	testKey:
		db "test",0
	testVal:
		db "This is a value",10,0
	newline:
		db 10
section .bss
	map		resq 1
	genbuff		resb 2048
	input		resb 64
section .text
global _start
_start:
	;print intro
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, introMsg
	mov	rdx, introLen
	;syscall
	mov	rax, MAP_SIZE
	push	rax
	call	create_map
	cmp	rax, 0
	jle	exit
	mov	qword [map], rax
	mov	r13, ADD_PROMPTS
	mov	r12, genbuff
addLoop:
	;val
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, valueMsg
	mov	rdx, valueLen
	syscall
	mov	rax, 0
	mov	rdi, 1
	mov	rsi, input
	mov	rdx, 64
	syscall

	mov	rcx, rax
	mov	rsi, input
	mov	rdi, r12
	rep	movsb
	push	r12
	mov	r12, rdi
	inc	r12

	;key
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, keyMsg
	mov	rdx, keyLen
	syscall
	mov	rax, 0
	mov	rdi, 1
	mov	rsi, input
	mov	rdx, 64
	syscall

	mov	rcx, rax
	mov	rsi, input
	mov	rdi, r12
	rep	movsb
	mov	byte [rdi], 0
	push	r12
	mov	r12, rdi
	inc	r12
	
	mov	rax, qword [map]
	push	rax
	call	write_item
	dec	r13
	cmp	r13, 0
	jne	addLoop

loop:

	mov	rax, 1
	mov	rdi, 1
	mov	rsi, key2Msg
	mov	rdx, key2Len
	syscall
	mov	rax, 0
	mov	rdi, 1
	mov	rsi, input
	mov	rdx, 64
	syscall
	add	rax, input
	;dec	rax
	mov	byte [rax], 0
	mov	rax, input
	push	rax
	mov	rax, qword [map]
	push	rax
	call	get_item
	cmp	rax, 0
	jl	.inval
	jl	exit
	push	rax
.lenLoop:
	inc	rax
	cmp	byte [rax], 0
	jne	.lenLoop
	mov	rdx, rax
	pop	rsi
	sub	rdx, rsi
	mov	rdi, 1
	mov	rax, 1
	syscall
	jmp	loop

.inval:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, invalMsg
	mov	rdx, invalLen
	syscall
	jmp	loop

exit:
	mov	rax, 60
	mov	rdi, 0
	syscall
