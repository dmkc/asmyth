.global createPulse
.global createSaw
.global playPulse
.global initialize
.global debug
.global IHANDLER
.equ ADDR_AUDIODACFIFO, 0x10003040
.equ ADDR_TIMER, 0x10002000
.equ SAMPLE_RATE, 48000

.section .exceptions, "ax"
IHANDLER:
	#save context
	subi sp, sp, 4
	stw ra, 0(sp)
	
	#determine interrupt source
	rdctl et, ctl4
	andi et, et, 0b1000000
	movi r8, 0b1000000
	beq r8, et, HANDLE_AUDIO_INTERRUPT
	
	br DONE_INTERRUPT
	
	
HANDLE_AUDIO_INTERRUPT:
	call playPulse
	
	br DONE_INTERRUPT

DONE_INTERRUPT:
	ldw ra, 0(sp)
	addi sp, sp, -4

	subi ea, ea, 4
	eret
	
.text
initialize:
	# initialize audio codec
	movia r10, ADDR_AUDIODACFIFO
	movi r9, 0b10
	stwio r9, 0(r10)
	
	# initialize timer
	/*movia r10, ADDR_TIMER
	movia r9, 50000000 
	stwio r9, 8(r10)
	srli r9, r9, 16
	stwio r9, 12(r10)
	# clear the timer
	stwio r0, 0(r10)		
	# start, continue, interrupt enable
	movui r9, 0b111			
	stwio r9, 4(r10)*/	
	
	# set ienable for audio codec to 1
	movi r8, 0xfff
	wrctl ctl3, r8
	
	movi r8, 0b1
	wrctl ctl0, r8 /* Set PIE bit to 1 */
	ret
	
debug:
	rdctl r2, ctl0
	ret

/* Takes a frequency in r4 and volume in r5 and generates a full wave 
 * Returns the number of samples in one full wave, and populates the pulse buffer
 *
 */
createPulse:
	movia r8, SAMPLE_RATE
	
	# total samples per wave
	div r2, r8, r4	
	
	# r9 is half of complete wave
	movi r8, 2
	div r9, r2, r8
	mov r11, r9
	movia r10, pulse_queue

/* 
	r5 - amplitude
	r9 is count of samples
	r10 is the pulse_queue addr
*/
pulse_high_loop:
	beq r11, r0, pulse_high_loop_end
	stw r5, 0(r10)
	
	addi r10, r10, 4
	subi r11, r11, 1
	br pulse_high_loop
	
pulse_high_loop_end:
	mov r11, r9
	sub r5, r0, r5
pulse_low_loop:
	beq r11, r0, pulse_low_loop_end
	stw r5, 0(r10)
	
	addi r10, r10, 4
	subi r11, r11, 1
	br pulse_low_loop

pulse_low_loop_end:
	ret
	
/* Takes a frequency in r4 and volume in r5 and generates a full saw wave 
 * Returns the number of samples in one full wave, and populates the saw buffer
 */
createSaw:
	movia r8, SAMPLE_RATE
	movia r11, saw_queue
	
	#total samples per wave is in r9
	div r9, r8, r4
	
	# r10 contains the size of the step
	add r10, r5, r5
	div r10, r10, r9
	
	#set r12 as amp
	mov r12, r5
saw_loop:
	ble r9, r0, saw_loop_end
	
	sub r12, r12, r10
	stw r12, 0(r11)
	
	addi r11, r11, 4
	subi r9, r9, 1
	br saw_loop
saw_loop_end:
	ret
/* Play samples from sample queue

   r4  - number of samples to play
   r9 - temp
   r10 - current queue position
   r11 - address of the end of queue
   r12 - contains number of spaces left in right channel
*/

playPulse:
	movia r8, ADDR_AUDIODACFIFO
	
	ldwio r12, 4(r8)
	# Get the write space in Right Channel
	movia r13, 0x00ff0000
	and r12, r12, r13
	srli r12, r12, 16
	# r12 contains the number of spaces left in the Right Channel.
	
	# set r10 as the current queue position
	movia r9, queue_pointer
	ldw   r10, 0(r9)
	
	movia r9, sample_count
	ldw   r9, 0(r9)
	muli  r9, r9, 4
	movia r11, pulse_queue
	# r11 contains the address of the end of the queue
	add   r11, r11, r9

play_pulse_loop:
	beq r12, r0,  play_pulse_loop_end
	
	# check if we're at the end of playable sample queue
	ble r10, r11, play_pulse_push_samples
	
	# in case if so, restart from beginning
	movia r10, pulse_queue

play_pulse_push_samples:
	ldwio r9, 0(r10)
	stwio r9, 8(r8)
	stwio r9, 12(r8)
	
	addi r10, r10, 4
	subi r12, r12, 1
	br play_pulse_loop
play_pulse_loop_end:
	# save queue pointer to memory
	movia r9, queue_pointer
	stw r10, 0(r9)
	ret
