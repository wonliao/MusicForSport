void checkStatus(int status);
long wrappedDiff(long in1, long in2, long wrap);
void DeallocateAudioBuffer(SInt16 **audio, int numChannels);
void DeallocateAudioBuffer(float **audio, int numChannels);
float **AllocateAudioBuffer(int numChannels, int numFrames);
SInt16 **AllocateAudioBufferSInt16(int numChannels, int numFrames);
void ClearAudioBuffer(float **audio, long numChannels, long numFrames);
void ClearAudioBuffer(SInt16 **audio, long numChannels, long numFrames);

