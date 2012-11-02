.global main
.equ ADDR_AUDIODACFIFO, 0x10003040

.section .exceptions, "ax"
# Interrupt handler: just check source of interrupt
IHANDLER:
	# save context
	subi sp, sp, 12
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r4, 8(sp)
	
	#determine interrupt source
	rdctl et, ctl4
	andi et, et, 0x1000000
	movi r16, 0x1000000
	beq r16, et, DONE_INTERRUPT

DONE_INTERRUPT:
	ldw ra, 0(sp)
	ldw r16, 4(sp)
	ldw r4, 8(sp)
	addi sp, sp, -12

	subi ea, ea, 4
	eret
	
	
.text
main:
	movia r18, ADDR_AUDIODACFIFO
	
	# enable read and write audio FIFO interrupts
	movi r17, 0b0011
	stwio r17, 0(r18)

	# enable interrupts on IRQ6
	movi r16, 0x1000000
	wrctl ctl3, r16
	
	# enable interrupts globally (PIE bit)
	movi r16, 0b1
	wrctl ctl0, r16

# almost verbatim example from audio webpage: 
# echo L and R mic channels to output
loop:	
	movia r2,ADDR_AUDIODACFIFO
	ldwio r3,4(r2)      /* Read fifospace register */
	andi  r3,r3,0xff    /* Extract # of samples in Input Right Channel FIFO */
	beq   r3,r0,loop  /* If no samples in FIFO, go back to start */
	ldwio r3,8(r2)
	stwio r3,8(r2)      /* Echo to left channel */
	ldwio r3,12(r2)
	stwio r3,12(r2)     /* Echo to right channel */
wait_for_interrupt:	
	br wait_for_interrupt
