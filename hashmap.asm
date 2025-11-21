%macro	enter 0
	push	rbp
	mov	rbp, rsp
%endmacro
%macro	leave 0
	mov	rsp, rbp
	pop	rbp
%endmacro
section .text
; Size is ALWAYS # of elements
extern	hash_string
; Data:
; struct item{
;	uint64	hash;
;	void*	value;
;	item*	next;
;}
; struct map{
;	uint64	size; // in qwords
;	void*	extra; // the next bit of free memory we have to store colisions
;	item[]	array;
;}
global get_item;{
; void*	get_item(map* map, char* key);
get_item:
	enter
	; map in r8
	mov	r8, [rbp+16]
	mov	rax, [rbp+24]
	push	rax
	call	hash_string
	; hash in rax
	push	rax
	xor	rdx, rdx
	; size in rsi
	mov	rsi, qword [r8]
	div	rsi
	; index in rdx
	mov	rax, rdx
	xor	rdx, rdx
	mov	rsi, 24
	mul	rsi
	; offset in rax
	add	r8, 16
	; start of the array
	add	r8, rax
	; location of the item
	pop	rax
.collisionLoop:
	cmp	qword [r8], rax
	je	.collisionEnd
	add	r8, 16	; offset of next
	mov	r8, qword [r8]
	cmp	r8, 0
	je	.eInval
	jmp	.collisionLoop
.collisionEnd:
	mov	rax, qword [r8+8]
	leave
	ret
.eInval:
	mov	rax, -1
	leave
	ret
;}
global write_item;{
global add_item
global update_item
; void	write_item(map* map, char* key, void* value):
; aliases for pussies
update_item:
add_item:
write_item:
	enter
	; hash they/them key
	; map*
	mov	r8, qword [rbp+16]
	; next up in the stack is the key, we don't care about the actual value so we just get the hash
	mov	rax, qword [rbp+24]
	push	rax
	call	hash_string
	; rax now has the hash
	push	rax
	; calculate index
	; index = hash % size
	; get the size
	; r8 has the map, the first qword is the size
	mov	rsi, qword [r8]
	; Divide the hash by the size to get the index
	; rax is always the dividend, divide it by rsi
	; rdx can extend rax so if there's anything leftover in there it'll try to divide that too and fuck shit up
	xor	rdx, rdx
	div	rsi
	; rdx has the remainder, this is our index
	; each element of the array is 24 bytes 
	; the memory address of our thang is &map+16+rdx*24
	mov	rax, rdx
	xor	rdx,rdx
	mov	rsi, 24
	mul	rsi	; rax*24
	; rax now has our offset
	mov	rsi, r8
	add	rsi, 16
	add	rsi, rax
	;rsi now points to our slot in the array
	pop	rax
	; rax has our hash
	; check for collisions
	cmp	qword [rsi], 0
	je	.noCollision	; if there isn't a hash written at this index it's open
	; if there is we need to check if it's the same
	cmp	qword [rsi], rax
	je	.noCollision
	; if it isn't the same we need to write it to the extra space
	; and update the pointer in the preceding collision values to reflect the situation
	; first we need to follow the linked list
.collisionLoop:
	add	rsi, 16 ; offset of the item pointer
	cmp	qword [rsi], 0
	je	.collisionEnd
	; update our item pointer
	mov	rsi, qword [rsi]
	jmp	.collisionLoop
.collisionEnd:
	; rsi points to the next field of the last collided item
	add	r8, 8 ; the 2nd qword in the map struct is a pointer to the extra space
	mov	r8, qword [r8]	; get the free space pointer
	mov	qword [rsi], r8	; store the free space pointer 
	mov	rsi, r8 ; write to the free space pointer
.noCollision:
	; add to array
	; item.hash = hash
	mov	qword [rsi], rax
	mov	rax, qword [rbp+32]
	; item.value = value
	mov	qword [rsi+8], rax
	leave
	ret
;}
global create_map;{
; map*	create_map(int size);
create_map:
	push	rbp
	mov	rbp, rsp
	; Allocate memory
	mov	rax, 9
	mov	rdi, 0
	mov	rsi, [rbp+16]
	push	rsi	; sto fo l8r
	shl	rsi, 5	; size*32
	mov	rdx, 3	; PROT_READ | PROT_WRITE
	mov	r10, 34	; MAP_ANONYMOUS | MAP_PRIVATE
	mov	r8, -1	; jus in cas
	mov	r9, 0
	syscall
	pop	rsi
	cmp	rax, 0
	jle	.ret
	; rax has our new memory
	push	rax
	; rsi has the size we wurz given
	; first part of the jit should be the size anyhows
	mov	qword [rax], rsi
	; all we have left to do is get the end of the yup
	; the first element of the array is at rax+16
	; each element of the array is 24 bytes
	; there are rsi elements of the array
	; rsi*24 = the size of the array in bytes
	; the array therefore must end at rax+16+rsi*24
	add	rax, 16
	push	rax	; we need rax for multiplication
	mov	rax, rsi
	mov	rsi, 24 ; rsi becomes the markiplier
	xor	rdx, rdx ; gotta
	mul	rsi
	; verily rax has the # of bytes of the array
	; we desire this in rsi for consistancy
	mov	rsi, rax
	; this is the start of the array
	pop	rax
	; this must be the end of the array
	add	rsi, rax
	sub	rax, 8	; this is hwere we want to store that
	mov	qword [rax], rsi
	; now the struct is setup as i want
	pop	rax	; we could have just subtracted 8 again but i already pushed it earlier so im not gonn do that
	; rax has the map* so we're done
.ret:
	mov	rsp, rbp
	pop	rbp
	ret
;}
global destroy_map;{
;int	destroy_map(map*);
destroy_map:
	enter
	mov	rax, 11
	pop	rdi
	mov	rsi, qword [rdi]; # of items
	shl	rsi, 5 ; # of items * 32 for jit size
	syscall
	leave
	ret
;}
