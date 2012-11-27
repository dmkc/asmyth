.global calculateSamples
.global createPulse
.global createSaw
.global playPulse
.global initialize
.global debug
.global debug
.global IHANDLER
.global wrapInEnvelope
.global getAdjustEnvelopeSize

.equ ADDR_AUDIODACFIFO, 0x10003040
.equ ADDR_TIMER, 0x10002000
.equ ADDR_SLIDESWITCHES, 0x10000040
.equ ADDR_RLED, 0x10000000
.equ ADDR_PS2,0x10000100
.equ ADDR_JP1, 0x10000060
.equ SAMPLE_RATE, 48000

# Interrupt handlers
.section .exceptions, "ax"
IHANDLER:
	#save context
	subi sp, sp, 12
	stw ra, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	
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
	

# AUDIO INTERRUPT HANDLING
HANDLE_AUDIO_INTERRUPT:
	call playBuffer
	br DONE_INTERRUPT
	

# KEYBOARD INTERRUPT HANDLING
HANDLE_KEYBOARD_INTERRUPT:
	movia r8, ADDR_PS2
	
	# figure out key code
	ldbio et, 0(r8)

	# check if key was released
	movia r8, lastKeyInterrupt
	ldw r9, 0(r8)
	
	movi r8, 0xfffffff0
	beq r9, r8, KEY_STORE_LAST
	# check if key has been released
	beq et, r8, KEY_BREAK

	# figure out frequency multiplier based on key code
	movia r8, frequencyOffset

	KEYPRESS_HANDLE:	
		KEY_1:
			movi r9, 0x1c
			bne et, r9, KEY_2
			movi r9, 0
			br KEYPRESS_DONE
		KEY_2:
			movi r9, 0x1d
			bne et, r9, KEY_3
			movi r9, 5
			br KEYPRESS_DONE
		KEY_3:
			movi r9, 0x1b
			bne et, r9, KEY_4
			movi r9, 9
			br KEYPRESS_DONE
		KEY_4:
			movi r9, 0x24
			bne et, r9, KEY_5
			movi r9, 14
			br KEYPRESS_DONE
		KEY_5:
			movi r9, 0x23
			bne et, r9, KEY_6
			movi r9, 18
			br KEYPRESS_DONE
		KEY_6:
			movi r9, 0x2b
			bne et, r9, KEY_7
			movi r9, 23
			br KEYPRESS_DONE
		KEY_7:
			movi r9, 0x2c
			bne et, r9, KEY_8
			movi r9, 28
			br KEYPRESS_DONE
		KEY_8:
			movi r9, 0x34
			bne et, r9, KEY_9
			movi r9, 32
			br KEYPRESS_DONE
		KEY_9:
			movi r9, 0x35
			bne et, r9, KEY_10
			movi r9, 37
			br KEYPRESS_DONE
		KEY_10:
			movi r9, 0x33
			bne et, r9, KEY_11
			movi r9, 41
			br KEYPRESS_DONE
		KEY_11:
			movi r9, 0x3c
			bne et, r9, KEY_12
			movi r9, 46
			br KEYPRESS_DONE
		KEY_12:
			movi r9, 0x3b
			bne et, r9, KEY_13
			movi r9, 51
			br KEYPRESS_DONE
		KEY_13:
			movi r9, 0x42
			bne et, r9, KEYPRESS_UNKNOWN
			movi r9, 55
			br KEYPRESS_DONE
		
		KEYPRESS_DONE:
            mov et, r9

            # Figure out if we need legato
			movia r8, keyPressed
            ldw r8, 0(r8)
            beq r0, r8, KEYPRESS_DONE_SAVE
            # If key already marked pressed, then turn on legato
            movia r8, enableLegato
            movi r9, 0x1
            stw r9, 0(r8)
            movia r8, legatoFrequency
            stw et, 0(r8)
            br KEYPRESS_DONE_MARK_DONE

            # Just save frequency offset if legato is off
            KEYPRESS_DONE_SAVE:
            	movia r8, frequencyOffset
                stw et, 0(r8)
            KEYPRESS_DONE_MARK_DONE:
                # mark key as pressed 
                movi r9, 0x1
                movia r8, keyPressed
                stw r9, 0(r8)
                movia r8, regenerateWave
                stw r9, 0(r8)

                call handleNoteChange
                br KEY_STORE_LAST

		KEYPRESS_UNKNOWN:
			br DONE_INTERRUPT

		# set keyPressed to false
		KEY_BREAK:
			mov r9, r0
			movia r8, keyPressed
			stw r9, 0(r8)
            # disable legato as well
            movia r8, enableLegato
            stw r0, 0(r8)
			br KEY_STORE_LAST

	KEY_STORE_LAST:
		movia r8, lastKeyInterrupt
		stw et, 0(r8)
		br DONE_INTERRUPT

	DONE_INTERRUPT:
		ldw ra, 0(sp)
		ldw r8, 4(sp)
		ldw r9, 8(sp)
		addi sp, sp, 12

		subi ea, ea, 4
		eret
	
.text
initialize:
	# initialize lego controller
	movia r10, ADDR_JP1
	movia r9, 0x07f557ff
	stwio r9, 4(r10)

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

/*
 * Calculate number of samples needed to represent a complete
 * wave of `r4` frequency
 */
calculateSamples:
	movia r8, SAMPLE_RATE
	div r2, r8, r4	
    ret
    

/* Takes address of queue in r4, frequency in r5 and volume in r6 and  
 * generates a full wave and populates the pulse buffer
 *
 */
createPulse:

	movia r8, SAMPLE_RATE
    mov r9, r4
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

	pulse_low_loop_end:
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
	mov r9, r4
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
	
	# regenerate the waves, e.g. if a key has been pressed
	movia r8, regenerateWave
	ldw r8, 0(r8)
	beq r8, r0, playBuffer_setup

	call createWaves

	playBuffer_setup:
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
		mov r4, r2
		call wrapInEnvelope
		stwio r2, 8(r8)
		stwio r2, 12(r8)
		
		subi r12, r12, 1
		br play_pulse_loop

	play_pulse_loop_end:
		ldw ra, 0(sp)
		addi sp, sp, 4
		ret

/* Combines the samples of all active waves 
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
	
	# Combine pulse wave (switch 1)
	movi r18, 0x1
	bne r17, r18, combine_saw1
	
	movia r4, pulse_queue
	call Queue_get_sample
	
	# r19 is how many oscillators we have total
	add r20, r20, r2
	addi r19, r19, 1

	# Add saw1 (switch #2)
	combine_saw1:
		ldwio r17, 0(r16)
		andi r17, r17, 0x2
		
		movi r18, 0x2
		bne r17, r18, combine_saw2
		
		movia r4, saw1_queue
		call Queue_get_sample
		
		add r20, r20, r2
		addi r19, r19, 1

	# Add saw2 (switch #3)
	combine_saw2:
		ldwio r17, 0(r16)
		andi r17, r17, 0x4
		
		movi r18, 0x4
		bne r17, r18, combine_saw2_divide
		
		movia r4, saw2_queue
		call Queue_get_sample
		
		add r20, r20, r2
		addi r19, r19, 1

	combine_saw2_divide:
		# prevent divide by zero
		beq r19, r0, combine_teardown
		div r2, r20, r19

	# boost amplitude if more than 1 oscillator is on
	boost_amplitude:
		beq  r19, r0, combine_teardown
		movi r18, 1
		# a single oscillator doesn't need boosting
		beq  r19, r18, combine_teardown

		boost_amplitude_2osc:
			movi r18, 2
			add r2, r2, r2
			beq  r18, r19, combine_teardown

		boost_amplitude_3osc:
			add r2, r2, r2

	combine_teardown:	
		ldw ra, 0(sp)
		ldw r16, 4(sp)
		ldw r17, 8(sp)
		ldw r18, 12(sp)
		ldw r19, 16(sp)
		ldw r20, 20(sp)
		addi sp, sp, 24
		ret

# Do what needs to happen after a key change, e.g. envelope
handleNoteChange:
	subi sp, sp, 16
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r2, 12(sp)

	movia r16, masterEnvelope
	call getAdjustEnvelopeSize
	movia r17, maxReleaseLength
	ldw r17, 0(r17)
	sub r17, r17, r2
	stw r17, 12(r16)

	# restore envelope release/attack values
	ldw r17, 12(r16)
	stw r17, 16(r16)
	ldw r17, 0(r16)
	stw r17, 4(r16)
    
    handleNoteChange_teardown:
        ldw ra, 0(sp)
        ldw r16, 4(sp)
        ldw r17, 8(sp)
		stw r2, 12(sp)
        addi sp, sp, 16
        ret

# Poll sensors to check for input. Change envelope sized based on sensors.
getAdjustEnvelopeSize:
	subi sp, sp, 16
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	
	movia r16, ADDR_JP1
	# enable sensor 0
	movia r17, 0xfffffbff
	stwio r17, 0(r16)

	ldwio r17, 0(r16)
	srli r17, r17, 11
	andi r17, r17, 0x1
	cmpeqi r17, r17, 0x1
	bne r17, r0, getAdjustEnvelopeSizeTeardown
	# Else, sensor 0 is valid (low)
	ldwio r17, 0(r16)
	srli r17, r17, 27
	andi r17, r17, 0x0000000f

	movia r16, maxReleaseLength
	movia r18, minReleaseLength
	ldw r16, 0(r16)
	ldw r18, 0(r18)
	sub r16, r16, r18
	
	movi r18, 0xb
	mul r16, r16, r17
	div r16, r16, r18
	#r16 is the amount to adjust the release by
	mov r2, r16

getAdjustEnvelopeSizeTeardown:
	ldw ra, 0(sp)
	ldw r16, 4(sp)
	ldw r17, 8(sp)
	ldw r18, 12(sp)
	addi sp, sp, 16
	ret

# Wrap a sample into the envelope
wrapInEnvelope:
    # if keyPressed, then if there is still attack left, 
    # begin/continue attack. Else, simply return
    # otherwise, decrease volume down sample by sample
    # starting at masterAmplitude down to 0
    # Remember to drop down to 0 for positive and negative values.
    subi sp, sp, 8
	stw ra, 0(sp)
	stw r16, 4(sp)

	movia r16, keyPressed
	ldw r16, 0(r16)
	beq r16, r0, wrapInEnvelope_keyRelease
	# the key is still being pressed. Check if there is
	# any attack left.
	movia r16, masterEnvelope
	ldw r16, 4(r16)
	#bne r16, r0, wrapInEnvelope_keyAttack
	mov r2, r4
	br wrapInEnvelope_teardown

	wrapInEnvelope_keyAttack:
		movia r16, masterEnvelope
		ldw r17, 4(r16)
		subi r17, r17, 1
		stw r17, 4(r16)

		ldw r18, 0(r16)
		sub r18, r18, r17
		ldw r17, 8(r16)
		mul r17, r17, r18

		mov r2, r17

		br wrapInEnvelope_teardown

	wrapInEnvelope_keyRelease:		
		mov r2, r0
		movia r16, masterEnvelope

		# check whether release has finished
		ldw r17, 16(r16)
		beq r17, r0, wrapInEnvelope_teardown
		subi r17, r17, 1
		stw r17, 16(r16)

		ldw r18, 12(r16)
		sub r18, r18, r17
		ldw r17, 20(r16)
		mul r17, r17, r18

		bgt r4, r0, wrapInEnvelope_keyRelease_substract

	wrapInEnvelope_keyRelease_add:
		add r2, r4, r17
		blt r2, r0, wrapInEnvelope_teardown
		mov r2, r0
		br wrapInEnvelope_teardown

	wrapInEnvelope_keyRelease_substract:
		sub r2, r4, r17
		bgt r2, r0, wrapInEnvelope_teardown
		mov r2, r0 

	wrapInEnvelope_teardown:
		ldw ra,  0(sp)
		ldw r16, 4(sp)
		addi sp, sp, 8
		ret
