%macro	enter 0
	push	rbp
	mov	rbp, rsp
%endmacro
%macro	leave 0
	mov	rsp, rbp
	pop	rbp
%endmacro
%define MAP_EXTRA	8
%define	MAP_ARRAY	16
%define ITEM_VALUE	8
%define ITEM_NEXT	16

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
global remove_item;{
; void*	remove_item(map* map, char* key);
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
	add	r8, ARRAY_OFFEST
	; start of the array
	add	r8, rax
	; location of the item
	pop	rax
	; Is the target the root of a collision list?
	cmp	qword [r8], rax
	jne	.collision
	; if so we have to check for links
	add	r8, ITEM_NEXT	; offset of next
	cmp	qword [r8], 0
	jne	.moveUp
	; no links? just delete the stuff
	sub	r8, 8
	mov	qword [r8], 0
	sub	r8, 8
	mov	qword [r8], 0
	jmp	.exit
.moveUp:
	mov	rsi, qword [r8]
	add	rsi, ITEM_NEXT
	mov	rdi, r8
	std	; right to left
	; set direction flag not the other std
	mov	rcx, 3
	rep	movsq
	; the main array jit is replaced with the data in the next thang over
	; therefore we are done, we don't remove the data in the void buffer because we only append to it
	; so to reclaim it we would have to move EVERYTHING else too
	jmp	.exit
.collision:
	; is the key just invalid?
	cmp	qword [r8], 0
	je	.enInval
	; Otherwise we gotta find out where our jit is
	; use rdi for this because of rep movsq, rdi will be ourjit
.collisionLoop:
	; get pointer to next
	mov	rdi, qword [r8+ITEM_NEXT]
	; check if next is real
	cmp	rdi, 0
	je	.eInval
	; check if next is our target
	cmp	qword [rdi], rax
	je	.collisionEnd
	; otherwise move on
	mov	r8, rdi
	jmp	.collisionLoop
	
.collisionEnd:
	; get the pointer to the item following our target
	mov	rsi, qword [rdi+ITEM_NEXT]
	; Check if there is a following item
	cmp	rsi, 0
	jne	.noNext
	; If there is a following item just copy its data over
	mov	rcx, 3
	std
	rep	movsq
	jmp	.exit
.noNext:
	; If our target is the end of the list, just null the pointer in the preceding item
	mov	qword [r8+ITEM_NEXT], 0
.exit:
	mov	rax, 0
	leave
	ret
.eInval:
	mov	rax, -1
	leave
	ret
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
	add	r8, MAP_ARRAY
	; start of the array
	add	r8, rax
	; location of the item
	pop	rax
.collisionLoop:
	cmp	qword [r8], rax
	je	.collisionEnd
	add	r8, ITEM_NEXT	; offset of next
	mov	r8, qword [r8]
	cmp	r8, 0
	je	.eInval
	jmp	.collisionLoop
.collisionEnd:
	mov	rax, qword [r8+ITEM_VALUE]
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
;void	write_hash(map* map, uint64 hash, void* value);
write_hash:	; internal helper function that allows us to reuse the code in this function
	enter
	; expects the hash in rax, the map in r8, and the value at rbp+32
	mov	r8, qword [rbp+16]
	mov	rax, qword [rbp+24]
	jmp	post_hash
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
post_hash:
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
	add	rsi, MAP_ARRAY
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
	; Check if we encounter the hash in the linked list
	cmp	qword [rsi], rax
	je	.noCollision
	; Go to next item
	add	rsi, ITEM_NEXT ; offset of the item pointer
	cmp	qword [rsi], 0
	je	.collisionEnd
	; update our item pointer
	mov	rsi, qword [rsi]
	jmp	.collisionLoop
.collisionEnd:
	; check that we aren't at the size limit
	; calculate the end
	mov	r9, qword [r8]	; size of the map
	shl	r9, 5		; size * 32 = bytes allocated
	add	r9, r8		; bytes allocated + &map = &end
	sub	r9, 24		; need 24 bytes from the end to write a new item
	add	r8, MAP_EXTRA	; the 2nd qword in the map struct is a pointer to the extra space
	mov	r8, qword [r8]	; &extra
	cmp	r8, r9		; is &extra >= &end?
	jge	.noSpace
	; If not we can write to it
	mov	qword [rsi], r8	; the next field of this item should be the free space pointer
	mov	rsi, r8 ; write to the free space pointer
	; get the map pointer again
	mov	r8, qword [rbp+16]
	; get to extra
	add	r8, MAP_EXTRA
	; add 24
	add	qword [r8], 24
.noCollision:
	; add to array
	; item.hash = hash
	mov	qword [rsi], rax
	mov	rax, qword [rbp+32]
	; item.value = value
	mov	qword [rsi+ITEM_VALUE], rax
	leave
	ret
.noSpace:
	mov	rax, -12
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
	add	rax, MAP_ARRAY
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
	sub	rax, MAP_EXTRA	; this is hwere we want to store that
	mov	qword [rax], rsi
	; now the struct is setup as i want
	pop	rax	; we could have just subtracted 8 again but i already pushed it earlier so im not gonn do that
	; rax has the map* so we're done
.ret:
	mov	rsp, rbp
	pop	rbp
	ret
;}
global resize_map;{
; map*	resize_map(map* map, uint64 size);
resize_map:
	enter
	; push the size onto the stack
	mov	rax, qword [rbp+24]
	push	rax
	call	create_map
	; store the size in r8
	pop	r8
	cmp	rax, 0
	jl	.error
	; rax now has an initialized map 
	; we need to go through the old map and add the values back
	; destination reg just makes sense for the new one
	mov	rdi, rax
	; rsi holds the old
	mov	rsi, qword [rbp+16]
	; work backwards from the bottom
	mov	rax, qword [rsi+MAP_EXTRA]	; pointer to the next free space in the old one
	mov	rsi, rax
.loop:
	sub	rsi, 24	; get to the top of the next item
	cmp	rsi, qword [rbp+16] ; once we've done all them we'll end up 8 bytes above the start of the map
	jle	.end	; we just go
	cmp	qword [rsi], 0 ; if there is no hash we skip
	je	.loop
	; If there is a hash we have some work to do
	; use rax as an intermediary
	; push value*
	mov	rax, qword [rsi+ITEM_VALUE]
	push	rax
	; push hash
	mov	rax, qword [rsi]
	push	rax
	; push map
	push	rdi
	; call helper func to add value
	call	write_hash
	; clear stack
	pop	rax
	pop	rax
	pop	rax
	; continue loop
	jmp	.loop
.end:
	mov	rax, rdi
	leave
	ret
.error:
	leave
	ret
;}
global destroy_map;{
;int	destroy_map(map*);
destroy_map:
	enter
	mov	rax, 11
	mov	rdi, [rbp+16]
	mov	rsi, qword [rdi]; # of items
	shl	rsi, 5 ; # of items * 32 for jit size
	syscall
	leave
	ret
;}
