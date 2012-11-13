.global Queue_get_sample
.global Queue_get_length
.global Queue_set_length

/* Get value of sample at next queue position.

   r4 - address of queue
   r10, r11 - temps
*/

.text
Queue_get_sample:
	# Load queue position
	ldw r10, 0(r4)
	
	# Load queue length
	ldw r11, 4(r4)
	# r11 now contains the last position in queue
	
	# Check if position has run off
	blt r10, r11, get_sample_end
	stw r0, 0(r4)
	mov r10, r0

get_sample_end:
	muli r10, r10, 4
	addi r11, r4, 8
	add r10, r11, r10
	ldw r2, 0(r10) 
	
	ldw r10, 0(r4)
	addi r10, r10, 1
	stw r10, 0(r4)
	ret
	
Queue_get_length:
	ldw r2, 4(r4)
	ret
	
Queue_set_length:
	stw r5, 4(r4)
	ret
	