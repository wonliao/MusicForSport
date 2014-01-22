#include "Utilities.h"


#pragma mark Helper Functions

// ---------------------------------------------------------------------------------------------------------------------------

void checkStatus(int status)
{
	if (status)
		printf("Status not 0! %d\n", status);
}
// ---------------------------------------------------------------------------------------------------------------------------

long wrappedDiff(long in1, long in2, long wrap)
{
	long m1 = in2-in1;
	if (m1 < 0) m1 = (in2+wrap)-in1;
	return m1;
}
// ---------------------------------------------------------------------------------------------------------------------------

void DeallocateAudioBuffer(SInt16 **audio, int numChannels)
{
	if (!audio) return;
	for (long v = 0; v < numChannels; v++) {
		if (audio[v]) {
			free(audio[v]);
			audio[v] = NULL;
		}
	}
	free(audio);
	audio = NULL;
}
// ---------------------------------------------------------------------------------------------------------------------------

void DeallocateAudioBuffer(float **audio, int numChannels)
{
	if (!audio) return;
	for (long v = 0; v < numChannels; v++) {
		if (audio[v]) {
			free(audio[v]);
			audio[v] = NULL;
		}
	}
	free(audio);
	audio = NULL;
}
// ---------------------------------------------------------------------------------------------------------------------------

float **AllocateAudioBuffer(int numChannels, int numFrames)
{
	// Allocate buffer for output
	float **audio = (float**)malloc(numChannels*sizeof(float*));
	if (!audio) return NULL;
	memset(audio, 0, numChannels*sizeof(float*));
	for (long v = 0; v < numChannels; v++) {
		audio[v] = (float*)malloc(numFrames*sizeof(float));
		if (!audio[v]) {
			DeallocateAudioBuffer(audio, numChannels);
			return NULL;
		}
		else memset(audio[v], 0, numFrames*sizeof(float));
	}
	return audio;
}	
// ---------------------------------------------------------------------------------------------------------------------------

SInt16 **AllocateAudioBufferSInt16(int numChannels, int numFrames)
{
	// Allocate buffer for output
	SInt16 **audio = (SInt16**)malloc(numChannels*sizeof(SInt16*));
	if (!audio) return NULL;
	memset(audio, 0, numChannels*sizeof(SInt16*));
	for (long v = 0; v < numChannels; v++) {
		audio[v] = (SInt16*)malloc(numFrames*sizeof(SInt16));
		if (!audio[v]) {
			DeallocateAudioBuffer(audio, numChannels);
			return NULL;
		}
		else memset(audio[v], 0, numFrames*sizeof(SInt16));
	}
	return audio;
}	
// ---------------------------------------------------------------------------------------------------------------------------

void ClearAudioBuffer(float **audio, long numChannels, long numFrames)
{
	for (long v = 0; v < numChannels; v++) {
		memset(audio[v], 0, numFrames*sizeof(float));
	}
}
// ---------------------------------------------------------------------------------------------------------------------------

void ClearAudioBuffer(SInt16 **audio, long numChannels, long numFrames)
{
	for (long v = 0; v < numChannels; v++) {
		memset(audio[v], 0, numFrames*sizeof(SInt16));
	}
}

// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
