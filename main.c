#include <stdio.h>

//// GLOBALS
struct Queue{
	int position;
	int length;
	int sample_queue[10000];
};

typedef struct Queue Queue;

int Queue_get_sample(Queue*);
int Queue_get_length(Queue*);
int Queue_set_length(Queue*, int length);

// Queue of samples to be pushed to AudioCodec's FIFO
Queue pulse_queue;
Queue saw_queue;

void initialize();
void playBuffer();
void createPulse(Queue*, int frequency, signed int amp);
void createSaw(  Queue*, int frequency, signed int amp);
int  debug();

int main() {
	createSaw(&saw_queue, 55, 90000000);
	createPulse(&pulse_queue, 54, 90000000);

	initialize();
	//pulse_queue[0] = 7;
	

	while(1){ 
		//*ADDR_RLED = *ADDR_SLIDESWITCHES;
		// loop forevaaa
	}
}
