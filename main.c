#include <stdio.h>

//// GLOBALS
// Queue of samples to be pushed to AudioCodec's FIFO
int pulse_queue[10000];
// number of samples in the queue
int *queue_length;
// address of where we are in the sample queue since last FIFO emptying
int queue_pointer;
int sample_count;

void initialize();
void playPulse();
int  createPulse(int frequency, signed int amp);
int  debug();

int main() {
	//initialize();
	//pulse_queue[0] = 7;
	sample_count = createPulse(55, 9000000);
	queue_pointer = pulse_queue;
	
	while(1) {
		playPulse();
	}

}
