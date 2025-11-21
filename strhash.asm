section .text
global hash_string
; int hash_string(char *str);
hash_string:
	push	rbp
	mov	rbp, rsp
	; get string from the stack
	; source index should store the jit
	mov	rsi, [rbp+16]
	; rax will hold the hash
	xor	rax, rax
	; hold on to your asshole
.hashLoop:
	cmp	byte [rsi], 0
	je	.hashEnd
	; Multiply rax by 31
	mov	rbx, rax
	; (rax*32)-rax == rax*31
	shl	rax, 5
	sub	rax, rbx
	xor	rbx, rbx
	mov	bl, byte [rsi]
	add	rax, rbx
	inc	rsi
	jmp	.hashLoop
.hashEnd:
	mov	rsp, rbp
	pop	rbp
	ret
