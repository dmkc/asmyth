.global createPulse
.global createSaw
.global playPulse
.global initialize
.global debug
.global debug
.global IHANDLER
.equ ADDR_AUDIODACFIFO, 0x10003040
.equ ADDR_TIMER, 0x10002000
.equ ADDR_SLIDESWITCHES, 0x10000040
.equ ADDR_RLED, 0x10000000
.equ ADDR_PS2,0x10000100
.equ SAMPLE_RATE, 48000

.section .exceptions, "ax"
IHANDLER:
	#save context
	subi sp, sp, 4
	stw ra, 0(sp)
	stw r8, 4(sp)
	
	#determine interrupt source
	rdctl et, ctl4
	andi et, et, 0b1000000
	movi r8, 0b1000000
	beq r8, et, HANDLE_AUDIO_INTERRUPT
	
	rdctl et, ctl4
	andi et, et, 0b10000000
	movi r8, 0b10000000
	beq r8, et, HANDLE_KEYBOARD_INTERRUPT
	
	br DONE_INTERRUPT
	
	
HANDLE_AUDIO_INTERRUPT:
	call playBuffer
	br DONE_INTERRUPT
	
HANDLE_KEYBOARD_INTERRUPT:
	movia r8, ADDR_PS2
	
	# check which key has been pressed
	ldbio et, 0(r8)
	
	br DONE_INTERRUPT

DONE_INTERRUPT:
	ldw ra, 0(sp)
	ldw r8, 4(sp)
	addi sp, sp, 4

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
	
	# initalize ps2
	movia r10, ADDR_PS2
	movi r9, 0b1
	stwio r9, 4(r10)
	
	# set ienable for audio codec to 1
	movi r8, 0xfff
	wrctl ctl3, r8
	
	movi r8, 0b1
	wrctl ctl0, r8 /* Set PIE bit to 1 */
	ret
	
debug:
	rdctl r2, ctl0
	ret

/* Takes address of queue in r4, frequency in r5 and volume in r6 and  
 * generates a full wave and populates the pulse buffer
 *
 */
createPulse:
	movia r8, SAMPLE_RATE
	
	# total samples per wave
	div r9, r8, r5	
	# store queue length into struct
	stw r9, 4(r4)
	
	# r9 is half of complete wave
	movi r8, 2
	div r11, r9, r8
	mov r10, r4
	addi r10, r10, 8

/* 
	r6 - amplitude
	r9 is count of samples
	r10 is the pulse_queue addr
*/
pulse_high_loop:
	beq r11, r0, pulse_high_loop_end
	stw r6, 0(r10)
	
	addi r10, r10, 4
	subi r11, r11, 1
	br pulse_high_loop
	
pulse_high_loop_end:
	mov r11, r9
	sub r6, r0, r6
pulse_low_loop:
	beq r11, r0, pulse_low_loop_end
	stw r6, 0(r10)
	
	addi r10, r10, 4
	subi r11, r11, 1
	br pulse_low_loop

pulse_low_loop_end
	ret
	
/* Takes a pointer to a Queue, frequency in r5 and volume in r6 and generates a 
 * full saw wave 
 * Return: number of samples in one full wave, and 
 * populates the saw buffer
 */
createSaw:
	movia r8, SAMPLE_RATE
	mov r11, r4
	# r11 is pointer to sample_queue inside Queue struct
	addi r11, r11, 8
	
	# total samples per wave is in r9
	div r9, r8, r5
	# store queue length into struct
	stw r9, 4(r4)
	
	# r10 is size of each step of the saw
	add r10, r6, r6
	div r10, r10, r9
	
	# r6 is amplitude
	mov r12, r6

saw_loop:
	ble r9, r0, saw_loop_end
	
	sub r12, r12, r10
	stw r12, 0(r11)
	
	addi r11, r11, 4
	subi r9, r9, 1
	br saw_loop

saw_loop_end:
	# Return: sample count for saw wave
	ret
	
/* Play samples from sample queue

   r4  - number of samples to play
   r9  - queue address
   r12 - contains number of spaces left in right channel
*/

playBuffer:
	subi sp, sp, 4
	stw ra, 0(sp)
	movia r8, ADDR_AUDIODACFIFO
	
	ldwio r12, 4(r8)
	# Get the write space in Right Channel
	movia r13, 0x00ff0000
	and r12, r12, r13
	srli r12, r12, 16
	# r12 contains the number of spaces left in the Right Channel.
	
	# r9 is the queue address
	movia r4, pulse_queue

play_pulse_loop:
	beq r12, r0,  play_pulse_loop_end

	call combineWave
	stwio r2, 8(r8)
	stwio r2, 12(r8)
	
	subi r12, r12, 1
	br play_pulse_loop

play_pulse_loop_end:
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

/* Combines the waves of all active waves 
*/
combineWave:
	subi sp, sp, 24
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	
	#r19 contains total number of oscillators
	mov r19, r0
	mov r20, r0
	mov r2, r0
	
	movia r16, ADDR_SLIDESWITCHES
	
	ldwio r17, 0(r16)
	andi r17, r17, 0x1
	
	movi r18, 0x1
	bne r17, r18, check_saw_wave
	
	movia r4, pulse_queue
	call Queue_get_sample
	
	add r20, r20, r2
	addi r19, r19, 1
check_saw_wave:
	ldwio r17, 0(r16)
	andi r17, r17, 0x2
	
	movi r18, 0x2
	bne r17, r18, combine_fin
	
	movia r4, saw_queue
	call Queue_get_sample
	
	add r20, r20, r2
	addi r19, r19, 1
combine_fin:
	# prevent divide by zero
	beq r19, r0, combine_fin2
	div r2, r20, r19 
combine_fin2:	
	ldw ra, 0(sp)
	ldw r16, 4(sp)
	ldw r17, 8(sp)
	ldw r18, 12(sp)
	ldw r19, 16(sp)
	ldw r20, 20(sp)
	addi sp, sp, 24
	ret
	