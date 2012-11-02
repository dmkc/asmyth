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
	subi sp, sp, 12
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r4, 8(sp)
	
	#determine interrupt source
	rdctl et, ctl4
	andi et, et, 0x1000000
	movi r16, 0x1000000
	beq r16, et, HANDLE_AUDIO_INTERRUPT
	
	br DONE_INTERRUPT
	
	
HANDLE_AUDIO_INTERRUPT:
	movia et, sample_count
	
	ldw r4, 0(et)
	call playPulse
	
	br DONE_INTERRUPT

DONE_INTERRUPT:
	ldw ra, 0(sp)
	ldw r16, 4(sp)
	ldw r4, 8(sp)
	addi sp, sp, -12

	subi ea, ea, 4
	eret
	
.text
initialize:
	# initialize audio codec
	movia r18, ADDR_AUDIODACFIFO
	movi r17, 0b0011
	stwio r17, 0(r18)
	
	# initialize timer
	/*movia r18, ADDR_TIMER
	movia r17, 50000000 
	stwio r17, 8(r18)
	srli r17, r17, 16
	stwio r17, 12(r18)
	# clear the timer
	stwio r0, 0(r18)		
	# start, continue, interrupt enable
	movui r17, 0b111			
	stwio r17, 4(r18)*/	
	
	# set ienable for audio codec to 1
	movi r16, 0xfff
	wrctl ctl3, r16
	
	movi r16, 0b1
	wrctl ctl0, r16 /* Set PIE bit to 1 */
	ret
	
debug:
	rdctl r2, ctl0
	ret

/* Takes a frequency in r4 and volume in r5 and generates a full wave 
 * Returns the number of samples in one full wave, and populates the pulse buffer
 *
 */
createPulse:
	movia r16, SAMPLE_RATE
	
	# total samples per wave
	div r2, r16, r4	
	
	# r17 is half of complete wave
	movi r16, 2
	div r17, r2, r16
	mov r19, r17
	movia r18, pulse_queue

/* 
	r5 - amplitude
	r17 is count of samples
	r18 is the pulse_queue addr
*/
pulse_high_loop:
	beq r19, r0, pulse_high_loop_end
	stw r5, 0(r18)
	
	addi r18, r18, 4
	subi r19, r19, 1
	br pulse_high_loop
	
pulse_high_loop_end:
	mov r19, r17
	sub r5, r0, r5
pulse_low_loop:
	beq r19, r0, pulse_low_loop_end
	stw r5, 0(r18)
	
	addi r18, r18, 4
	subi r19, r19, 1
	br pulse_low_loop

pulse_low_loop_end:
	ret
	
/* Takes a frequency in r4 and volume in r5 and generates a full saw wave 
 * Returns the number of samples in one full wave, and populates the saw buffer
 */
createSaw:
	movia r16, SAMPLE_RATE
	movia r19, saw_queue
	
	#total samples per wave is in r17
	div r17, r16, r4
	
	# r18 contains the size of the step
	add r18, r5, r5
	div r18, r18, r17
	
	#set r20 as amp
	mov r20, r5
saw_loop:
	ble r17, r0, saw_loop_end
	
	sub r20, r20, r18
	stw r20, 0(r19)
	
	addi r19, r19, 4
	subi r17, r17, 1
	br saw_loop
saw_loop_end:
	ret
/* Play samples from sample queue

   r4  - number of samples to play
   r17 - temp
   r18 - current queue position
   r19 - address of the end of queue
   r20 - contains number of spaces left in right channel
*/

playPulse:
	movia r16, ADDR_AUDIODACFIFO
	
	ldwio r20, 4(r16)
	# Get the write space in Right Channel
	movia r21, 0x00ff0000
	and r20, r20, r21
	srli r20, r20, 16
	# r20 contains the number of spaces left in the Right Channel.
	
	# set r18 as the current queue position
	movia r17, queue_pointer
	ldw   r18, 0(r17)
	
	movia r17, sample_count
	ldw   r17, 0(r17)
	muli  r17, r17, 4
	movia r19, pulse_queue
	# r19 contains the address of the end of the queue
	add   r19, r19, r17

play_pulse_loop:
	beq r20, r0,  play_pulse_loop_end
	
	# check if we're at the end of playable sample queue
	ble r18, r19, play_pulse_push_samples
	# if so, restart from beginning
	movia r18, pulse_queue

play_pulse_push_samples:
	ldwio r17, 0(r18)
	stwio r17, 8(r16)
	stwio r17, 12(r16)
	
	addi r18, r18, 4
	subi r20, r20, 1
	br play_pulse_loop
play_pulse_loop_end:
	# save queue pointer to memory
	movia r17, queue_pointer
	stw r18, 0(r17)
	ret
	
echoMic:
	movia r2,ADDR_AUDIODACFIFO
	ldwio r3,4(r2)      /* Read fifospace register */
	andi  r3,r3,0xff    /* Extract # of samples in Input Right Channel FIFO */
	beq   r3,r0,echoMic  /* If no samples in FIFO, go back to start */
	ldwio r3,8(r2)
	muli  r3, r3, 2
	stwio r3,8(r2)      /* Echo to left channel */
	ldwio r3,12(r2)
	stwio r3,12(r2)     /* Echo to right channel */
	br echoMic

	
