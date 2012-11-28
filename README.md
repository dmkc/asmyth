**asmyth** is a monophonic synthesizer written mostly in Assembly for the 
NIOS II RISC platform and Altera DE2 board. The synth has the following features:

* 3x oscillators
* ASR type envelope
* transpose
* legato
* release length adjustable through LEGO sensor through GPIO.

As a MIDI or fader controllers weren't handy, most of the controls are set
up to use either DE2's switches, the sensor, or via a PS/2 keyboard.

###Notes###

* This was a project for the ECE385 course. Due to the time limitations,
  proprietary platform, and other excuses, the code is pretty
  spaghetti-ish in places. Then again, if you've ended up with a DE2
  board, you're likely in academia already (and presumably expect as much), 
  since nobody in their right
  mind would drop a few hundred for these boards when a Raspberry Pi is
  both your good old ARM *and* is a hundred or two dollars easier on the
  wallet.
* A lot of the commits are signed by me, but [anenene](https://github.com/anenene) and I generally worked together committing under my name.
