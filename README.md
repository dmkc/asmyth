**asmyth** is a monophonic synthesizer written mostly in Assembly for the 
NIOS II RISC platform and Altera DE2 board. The synth has the following features:

* 3x oscillators
* ASR type envelope
* transpose
* legato
* release length adjustable through LEGO sensor through GPIO.

As a MIDI or fader controllers weren't handy, most of the controls are set
up to use either DE2's switches, the sensor, or via a PS/2 keyboard.

This was a project for the ECE385 course. A lot of the commits are signed by me, 
but [anenene](https://github.com/anenene) and I generally worked together committing under my name.
