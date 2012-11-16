#include <stdio.h>

//// GLOBALS
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

// whether a key is currently pressed. Used by envelope.
int keyPressed;
// a flag set by keyboard interrupt handler to make sure the waveforms 
// are regenerated
int regenerateWave;
// how much to multiply the base frequency by
int frequencyOffset;
int baseFrequency;

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
			 baseFrequency + frequencyOffset, 90000000);
	createSaw(&saw2_queue, 
		 baseFrequency + frequencyOffset, 90000000);
	createPulse(&pulse_queue, 
			baseFrequency + frequencyOffset + 1, 90000000);
	
	regenerateWave = 0;
}
