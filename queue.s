.global Queue_get_sample
.global Queue_get_length
.global Queue_set_length

/* Get value of sample at next queue position.

   r4 - address of queue
   r16, r17 - temps
*/

.text
Queue_get_sample:
	subi sp, sp, 8
	stw r16, 0(sp)
	stw r17, 4(sp)
	
	# Load queue position
	ldw r16, 0(r4)
	
	# Load queue length
	ldw r17, 4(r4)
	# r17 now contains the last position in queue
	
	# Check if position has run off
	blt r16, r17, get_sample_end
	stw r0, 0(r4)
	mov r16, r0

get_sample_end:
	muli r16, r16, 4
	addi r17, r4, 8
	add r16, r17, r16
	ldw r2, 0(r16) 
	
	ldw r16, 0(r4)
	addi r16, r16, 1
	stw r16, 0(r4)
	
	ldw r16, 0(sp)
	ldw r17, 4(sp)
	addi sp, sp, 8
	ret
	
Queue_get_length:
	ldw r2, 4(r4)
	ret
	
Queue_set_length:
	stw r5, 4(r4)
	ret
	