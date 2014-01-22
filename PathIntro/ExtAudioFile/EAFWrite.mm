#import "EAFWrite.h"


#if __has_feature(objc_arc)
#else
	#define __bridge
#endif

// ---------------------------------------------------------------------------------------------------------------------------------------------


// Convenience function to dispose of our audio buffers
void DestroyAudioBufferList(AudioBufferList* list)
{
	UInt32						i;
	
	if(list) {
		for(i = 0; i < list->mNumberBuffers; i++) {
			if(list->mBuffers[i].mData) {
				free(list->mBuffers[i].mData);
				list->mBuffers[i].mData = NULL;
			}
		}
		free(list);
		list = NULL;
	}
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

// Convenience function to allocate our audio buffers
AudioBufferList *AllocateAudioBufferList(UInt32 numChannels, UInt32 size)
{
	AudioBufferList*			list;
	UInt32						i;
	
	list = (AudioBufferList*)calloc(1, sizeof(AudioBufferList) + numChannels * sizeof(AudioBuffer));
	if(list == NULL)
		return NULL;
	
	list->mNumberBuffers = numChannels;
	for(i = 0; i < numChannels; ++i) {
		list->mBuffers[i].mNumberChannels = 1;
		list->mBuffers[i].mDataByteSize = size;
		list->mBuffers[i].mData = calloc(1, size);
		if(list->mBuffers[i].mData == NULL) {
			DestroyAudioBufferList(list);
			return NULL;
		}
	}
	return list;
}


@implementation EAFWrite

// ---------------------------------------------------------------------------------------------------------------------------------------------

// not all formats are supported on the iPhone. While some might work on the simulator they will cause a 'fmt?' error on the actual device

-(void)SetupStreamAndFileFormatForType:(AudioFileTypeID)aftid withSR:(float) sampleRate channels:(long) numChannels wordlength:(long)numBits
{
	memset(&mStreamFormat, 0, sizeof(AudioStreamBasicDescription));
	numBits /= 8;
	numBits *= 8;
	switch (aftid)
	{
		case kAudioFileAIFFType:
		{
			mType = aftid;
			mStreamFormat.mChannelsPerFrame		= numChannels;
			mStreamFormat.mSampleRate			= sampleRate;
			mStreamFormat.mFormatID				= kAudioFormatLinearPCM;
			mStreamFormat.mFormatFlags			= kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
			mStreamFormat.mBitsPerChannel		= numBits;
			mStreamFormat.mBytesPerFrame		= mStreamFormat.mChannelsPerFrame * mStreamFormat.mBitsPerChannel / 8;
			mStreamFormat.mFramesPerPacket		= 1;
			mStreamFormat.mBytesPerPacket		= mStreamFormat.mBytesPerFrame * mStreamFormat.mFramesPerPacket;
		} break;
			
		case kAudioFileAIFCType:
		{
			mType = aftid;
			mStreamFormat.mChannelsPerFrame		= numChannels;
			mStreamFormat.mSampleRate			= sampleRate;
			mStreamFormat.mFormatID				= kAudioFormatAppleIMA4;
			mStreamFormat.mFormatFlags			= 0;
			mStreamFormat.mBitsPerChannel		= 0;
			mStreamFormat.mBytesPerFrame		= 0;
			mStreamFormat.mFramesPerPacket		= 1;
			mStreamFormat.mBytesPerPacket		= 0;
		} break;
			
		case kAudioFileCAFType:
		{
			mType = aftid;
			mStreamFormat.mChannelsPerFrame		= numChannels;
			mStreamFormat.mSampleRate			= sampleRate;
			mStreamFormat.mFormatID				= kAudioFormatLinearPCM;
			mStreamFormat.mFormatFlags			= kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
			mStreamFormat.mBitsPerChannel		= numBits;
			mStreamFormat.mBytesPerFrame		= mStreamFormat.mChannelsPerFrame * mStreamFormat.mBitsPerChannel / 8;
			mStreamFormat.mFramesPerPacket		= 1;
			mStreamFormat.mBytesPerPacket		= mStreamFormat.mBytesPerFrame * mStreamFormat.mFramesPerPacket;
		} break;
			
		case kAudioFileM4AType:
		{	
			mType = aftid;
			mStreamFormat.mChannelsPerFrame		= numChannels;
			mStreamFormat.mSampleRate			= sampleRate;
			mStreamFormat.mFormatID				= kAudioFormatMPEG4AAC;
			mStreamFormat.mFormatFlags			= kAudioFormatFlagIsBigEndian;
			mStreamFormat.mBitsPerChannel		= 0;
			mStreamFormat.mBytesPerFrame		= 0;
			mStreamFormat.mFramesPerPacket		= 1024;
			mStreamFormat.mBytesPerPacket		= 0;
		} break;
			
			
		case kAudioFileWAVEType:
		{	
			mType = aftid;
			mStreamFormat.mChannelsPerFrame		= numChannels;
			mStreamFormat.mSampleRate			= sampleRate;
			mStreamFormat.mFormatID				= kAudioFormatLinearPCM;
			mStreamFormat.mFormatFlags			= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
			mStreamFormat.mBitsPerChannel		= numBits;
			mStreamFormat.mBytesPerFrame		= mStreamFormat.mChannelsPerFrame * mStreamFormat.mBitsPerChannel / 8;
			mStreamFormat.mFramesPerPacket		= 1;
			mStreamFormat.mBytesPerPacket		= mStreamFormat.mBytesPerFrame * mStreamFormat.mFramesPerPacket;
		} break;
			
			
		case kAudioFileSoundDesigner2Type:
		{	
			mType = aftid;
			mStreamFormat.mChannelsPerFrame		= numChannels;
			mStreamFormat.mSampleRate			= sampleRate;
			mStreamFormat.mFormatID				= kAudioFormatLinearPCM;
			mStreamFormat.mFormatFlags			= kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
			mStreamFormat.mBitsPerChannel		= numBits;
			mStreamFormat.mBytesPerFrame		= mStreamFormat.mChannelsPerFrame * mStreamFormat.mBitsPerChannel / 8;
			mStreamFormat.mFramesPerPacket		= 1;
			mStreamFormat.mBytesPerPacket		= mStreamFormat.mBytesPerFrame * mStreamFormat.mFramesPerPacket;
		} break;
			
			
		case kAudioFileNextType:
		{	
			mType = aftid;
			mStreamFormat.mChannelsPerFrame		= numChannels;
			mStreamFormat.mSampleRate			= sampleRate;
			mStreamFormat.mFormatID				= kAudioFormatLinearPCM;
			mStreamFormat.mFormatFlags			= kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
			mStreamFormat.mBitsPerChannel		= numBits;
			mStreamFormat.mBytesPerFrame		= mStreamFormat.mChannelsPerFrame * mStreamFormat.mBitsPerChannel / 8;
			mStreamFormat.mFramesPerPacket		= 1;
			mStreamFormat.mBytesPerPacket		= mStreamFormat.mBytesPerFrame * mStreamFormat.mFramesPerPacket;
		} break;			
	}
}



// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) openFileForWrite:(NSURL*)inPath sr:(Float64)sampleRate channels:(int)numChannels wordLength:(int)numBits type:(AudioFileTypeID)aftid
{
	OSStatus err = noErr;
	AudioConverterRef conv = NULL;

	[self SetupStreamAndFileFormatForType:aftid withSR:sampleRate channels:numChannels wordlength:numBits];
	
	mAudioChannels = mStreamFormat.mChannelsPerFrame;
	mOutputFormat.mFormatID         = kAudioFormatLinearPCM;
	mOutputFormat.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kLinearPCMFormatFlagIsNonInterleaved;
	mOutputFormat.mSampleRate       = sampleRate;
	mOutputFormat.mBitsPerChannel   = sizeof(short) * 8;
	mOutputFormat.mChannelsPerFrame = mAudioChannels;
	mOutputFormat.mFramesPerPacket  = 1;
	mOutputFormat.mBytesPerFrame    = ( mOutputFormat.mBitsPerChannel / 8 );
	mOutputFormat.mBytesPerPacket   = mOutputFormat.mBytesPerFrame * mOutputFormat.mFramesPerPacket;
	
	
	// Create new audio file
	err = AudioFileCreateWithURL((__bridge CFURLRef) inPath, mType, &mStreamFormat, kAudioFileFlags_EraseFile, &mAfid);
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "AudioFileCreate FAILED! %d '%-4.4s'\n",(int)err, formatID);
		return err;
	}
	
	err = ExtAudioFileWrapAudioFileID(mAfid, true, &mOutputAudioFile);
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "ExtAudioFileWrapAudioFileID FAILED! %d '%-4.4s'\n",(int)err, formatID);
		return err;
	}
	
	err = ExtAudioFileSetProperty(mOutputAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &mOutputFormat);
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "ExtAudioFileSetProperty FAILED! %d '%-4.4s'\n",(int)err, formatID);
		return err;
	}
	
	if (mStreamFormat.mChannelsPerFrame == 1 && mOutputFormat.mChannelsPerFrame == 2)
	{
		UInt32 size = sizeof(AudioConverterRef);
		err = ExtAudioFileGetProperty(mOutputAudioFile, kExtAudioFileProperty_AudioConverter, &size, &conv);
		if (conv)
		{
			SInt32 channelMap[] = { 0, 0 };
			err = AudioConverterSetProperty(conv, kAudioConverterChannelMap, 2*sizeof(SInt32), channelMap);
		}
	}
	
	return err;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (void) closeFile
{
	AudioFileOptimize(mAfid);
	ExtAudioFileDispose(mOutputAudioFile);
	AudioFileClose(mAfid);
	fflush(0);
}

// ---------------------------------------------------------------------------------------------------------------------------------------------


-(OSStatus) writeShorts:(long)numFrames fromArray:(short **)data
{
	OSStatus	err = noErr;
	
	if (!data)		return -1;
	if (!numFrames)	return -1;
	
	AudioBufferList *abl = AllocateAudioBufferList(mStreamFormat.mChannelsPerFrame, numFrames*sizeof(short));
	if (!abl)		return -1;
	
	for (long c = 0; c < mStreamFormat.mChannelsPerFrame; c++) {
		abl->mBuffers[c].mNumberChannels = 1;
		abl->mBuffers[c].mDataByteSize = numFrames*sizeof(short);
		if (data[c]) {
			short *buffer = (short*)abl->mBuffers[c].mData;
			for (long v = 0; v < numFrames; v++) {
				buffer[v] = data[c][v];
			}
		}
		else 	memset(abl->mBuffers[c].mData, 0, numFrames*sizeof(short));
	}
	
	err = ExtAudioFileWrite(mOutputAudioFile, numFrames, abl);
	
	DestroyAudioBufferList(abl);
	
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "ExtAudioFileWrite FAILED! %d '%-4.4s'\n",(int)err, formatID);
		return err;
	}
	
	return err;
	
}
// ---------------------------------------------------------------------------------------------------------------------------------------------


-(OSStatus) writeFloats:(long)numFrames fromArray:(float **)data
{
	OSStatus	err = noErr;
	
	if (!data)		return -1;
	if (!numFrames)	return -1;
	
	AudioBufferList *abl = AllocateAudioBufferList(mStreamFormat.mChannelsPerFrame, numFrames*sizeof(short));
	if (!abl)		return -1;

	for (long c = 0; c < mStreamFormat.mChannelsPerFrame; c++) {
		abl->mBuffers[c].mNumberChannels = 1;
		abl->mBuffers[c].mDataByteSize = numFrames*sizeof(short);
		if (data[c]) {
			short *buffer = (short*)abl->mBuffers[c].mData;
			for (long v = 0; v < numFrames; v++) {
				if (data[c][v] > 0.999)		data[c][v] = 0.999;
				else if (data[c][v] < -1.)	data[c][v] = -1.;
				buffer[v] = (short)(data[c][v]*32768.f);
			}
		}
		else 	memset(abl->mBuffers[c].mData, 0, numFrames*sizeof(short));
	}
	
	err = ExtAudioFileWrite(mOutputAudioFile, numFrames, abl);

	DestroyAudioBufferList(abl);
	
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "ExtAudioFileWrite FAILED! %d '%-4.4s'\n",(int)err, formatID);
		return err;
	}
	
	return err;
	
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (id)init;
{
	if (!(self = [super init]))
		return nil;
	
	return self;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------


-(void)dealloc
{
	[self closeFile];
#if __has_feature(objc_arc)
	;
#else
	[super dealloc];
#endif

}

// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------


@end
