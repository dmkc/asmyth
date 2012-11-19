#include <stdio.h>

//// GLOBALS
/* 
 * Queue of audio samples for an oscillator.
 */
struct Queue{
	int position;
	int length;
	int sample_queue[96000];
};

typedef struct Queue Queue;

int Queue_get_sample(Queue*);
int Queue_get_length(Queue*);
int Queue_set_length(Queue*, int length);

// Queue of samples to be pushed to AudioCodec's FIFO
Queue pulse_queue;
Queue saw1_queue;
Queue saw2_queue;

/*
 * Volume envelope. Describes how volume of an oscillator
 * changes over time once a note is triggered.
 */
struct Envelope {
    int attackLength;
    int attackLeft;
    // default release of 1 second
    int releaseLength;
    int releaseLeft;
};

typedef struct Envelope Envelope;

Envelope masterEnvelope;

// whether a key is currently pressed. Used by envelope.
int keyPressed;
// a flag set by keyboard interrupt handler to make sure the waveforms 
// are regenerated
int regenerateWave;
// how much to multiply the base frequency by. Used to play 12 notes.
int frequencyOffset;
int baseFrequency;
int masterAmplitude;

// Method headers
void initialize();
void playBuffer();
void createPulse(Queue*, int frequency, signed int amp);
void createSaw(  Queue*, int frequency, signed int amp);
int  debug();

/**
 * Where things begin.
 */
int main() {
	frequencyOffset = 0;
	baseFrequency = 55;
    masterAmplitude = masterAmplitude;
    // default release is 1 second long
    masterEnvelope.releaseLength = 48000;

	createWaves();
	initialize();

	while(1){ 
		// loop forevaaa
	}
}

/**
 * Generate waveforms for all oscillators.
 *
 * Use baseFrequency + frequencyOffset as frequencies.
 */
void createWaves() {
	createSaw(&saw1_queue, 
		baseFrequency + frequencyOffset, masterAmplitude);
	createPulse(&saw2_queue, 
		baseFrequency + frequencyOffset - 1, masterAmplitude);
	createPulse(&pulse_queue, 
		baseFrequency + frequencyOffset + 1, masterAmplitude);
	
	regenerateWave = 0;
}
