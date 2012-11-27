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
    int attackStep;
    // default release of 1 second
    int releaseLength;
    int releaseLeft;
    int releaseStep;
};

typedef struct Envelope Envelope;

Envelope masterEnvelope;

/* Legato
 */
struct Legato {
    int doLegato;
    int length;
    // frequency of wave in samples
    int targetSamples;
    int stepSize;
    // increase num of samples by 2 every `counter`
    int counter;
    int counterLength;
    int totalSteps;
};

typedef struct Legato Legato;
Legato legato;

// whether a key is currently pressed. Used by envelope.
int keyPressed;
int keyReleased;
int lastKeyInterrupt;
// a flag set by keyboard interrupt handler to make sure the waveforms 
// are regenerated
int regenerateWave;
// how much to multiply the base frequency by. Used to play 12 notes.
int frequencyOffset;
int frequencyOffsetSamples;
int baseFrequency;
int masterAmplitude;
// release lengths
int minReleaseLength;
int maxReleaseLength;

// Method headers
void initialize();
void playBuffer();
void createPulse(Queue*, int samples, signed int amp);
void createSaw(  Queue*, int samples, signed int amp);
int  debug();

/**
 * Generate waveforms for all oscillators.
 *
 * Use baseFrequency + frequencyOffset as frequencies.
 */
void createWaves() {
	createSaw(&saw1_queue, frequencyOffsetSamples, masterAmplitude);
	createPulse(&saw2_queue, frequencyOffsetSamples+5, masterAmplitude);
	createPulse(&pulse_queue, frequencyOffsetSamples-5, masterAmplitude);
	
	regenerateWave = 0;
}


/**
 * Where things begin.
 */
int main() {
	frequencyOffset = 0;
	frequencyOffsetSamples = 873;
	baseFrequency = 55;
    masterAmplitude = 90000000;
    minReleaseLength = 0;
    maxReleaseLength = 48000;
    //default attack is half second long
    masterEnvelope.attackLength = maxReleaseLength;
    masterEnvelope.attackStep = masterAmplitude/masterEnvelope.attackLength;
    // default release is 1 second long
    masterEnvelope.releaseLength = 24000;
    masterEnvelope.releaseStep = masterAmplitude/masterEnvelope.releaseLength;

    // Legato settings
    legato.length = 24000;

	createWaves();
	initialize();

	while(1){ 
		// loop forevaaa
	}
}


