global hash_string
; int hash_string(char *str);
hash_string:
	; get string from the stack
	; source index should store the jit
	pop	rsi
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
	add	rax, byte [rsi]
	inc	rsi
	jmp	.hashLoop
.hashEnd:
	
	ret
