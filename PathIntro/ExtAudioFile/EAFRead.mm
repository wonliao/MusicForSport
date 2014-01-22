#import "EAFRead.h"

#if __has_feature(objc_arc)
#else
#define __bridge
#endif


@implementation EAFRead

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) openFileForRead:(NSURL*)fileURL sr:(Float64)sampleRate channels:(int)numChannels
{
	OSStatus err = noErr;
	UInt32 propSize;		
	
	mExtAFReachedEOF = NO;
	mRpos = 0;
	
	err = ExtAudioFileOpenURL((__bridge CFURLRef)fileURL, &mExtAFRef);
	if (err) {NSLog(@"!!! Error in ExtAudioFileOpen, %ld", err); return err;}
	
	AudioStreamBasicDescription fileFormat;
	propSize = sizeof(fileFormat);
	memset(&fileFormat, 0, sizeof(AudioStreamBasicDescription));
	
	err = ExtAudioFileGetProperty(mExtAFRef, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
	if (err) {NSLog(@"!!! Error in ExtAudioFileGetProperty, %ld", err); return err;}
	
	// when we pass -1 we use the file's native sample rate
	if (sampleRate < 0.) mPlaybackSampleRate = fileFormat.mSampleRate;
	else mPlaybackSampleRate = sampleRate;
	
	mExtAFRateRatio = mPlaybackSampleRate / fileFormat.mSampleRate;
	mExtAFSampleRate = fileFormat.mSampleRate;
	
	AudioStreamBasicDescription clientFormat;
	propSize = sizeof(clientFormat);
	memset(&clientFormat, 0, sizeof(AudioStreamBasicDescription));
	clientFormat.mFormatID				= kAudioFormatLinearPCM;
	clientFormat.mSampleRate			= mPlaybackSampleRate;
	clientFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	clientFormat.mChannelsPerFrame   = numChannels;
	clientFormat.mBitsPerChannel     = sizeof(short) * 8;
	clientFormat.mFramesPerPacket    = 1;
	clientFormat.mBytesPerFrame      = clientFormat.mBitsPerChannel * clientFormat.mChannelsPerFrame / 8;
	clientFormat.mBytesPerPacket     = clientFormat.mFramesPerPacket * clientFormat.mBytesPerFrame;
	clientFormat.mReserved           = 0;
	
	err = ExtAudioFileSetProperty(mExtAFRef, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
	if (err) {NSLog(@"!!! Error in ExtAudioFileSetProperty, %d", (int)err); return err;}
	
	mExtAFNumChannels = numChannels;
	return err;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) closeFile
{
	OSStatus err = noErr;
	if (mExtAFRef) {
		ExtAudioFileDispose(mExtAFRef);
		mExtAFRef = nil;
	}
	return err;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (void) seekToPercent:(Float64)percent
{
	OSStatus err = noErr;
	if (!mExtAFRef)	return;
	SInt64 numFramesInFile = [self fileNumFrames];
	SInt64 seekPos = 0.01 * percent * numFramesInFile;
	
	mRpos = seekPos;
	seekPos /= mExtAFRateRatio;
	
	@synchronized(self) {
		//
		// WORKAROUND for bug in ExtFileAudio
		//	
		SInt64 headerFrames = 0;
		
		AudioConverterRef acRef;
		UInt32 acrsize=sizeof(AudioConverterRef);
		err = ExtAudioFileGetProperty(mExtAFRef, kExtAudioFileProperty_AudioConverter, &acrsize, &acRef);
		if (err) return;
		
		AudioConverterPrimeInfo primeInfo;
		memset(&primeInfo, 0, sizeof(AudioConverterPrimeInfo));
		UInt32 piSize=sizeof(AudioConverterPrimeInfo);
		err = AudioConverterGetProperty(acRef, kAudioConverterPrimeInfo, &piSize, &primeInfo);
		if(err != kAudioConverterErr_PropertyNotSupported) // Only if decompressing
		{
			headerFrames=primeInfo.leadingFrames;
		}
		
		//err =
        ExtAudioFileSeek(mExtAFRef, seekPos+headerFrames);
	}
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (Float64) sampleRate
{
	if (!mExtAFRef)	return 0;
	return mPlaybackSampleRate;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (Float64) fileSampleRate
{
	if (!mExtAFRef)	return 0;
	return mExtAFSampleRate;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (SInt64) tell
{
	if (!mExtAFRef)	return 0;
	return mRpos;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (void) seekToStart
{
	if (!mExtAFRef)	return;
	@synchronized(self) {
		ExtAudioFileSeek(mExtAFRef, 0);	
	}
	mRpos = 0;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio withOffset:(long)offset
{
	OSStatus err = noErr;
	
	if (!mExtAFRef)	return -1;
   	
	int kSegmentSize = (int)(numFrames * mExtAFNumChannels * mExtAFRateRatio + .5);
	if (mExtAFRateRatio < 1.) kSegmentSize = (int)(numFrames * mExtAFNumChannels / mExtAFRateRatio + .5);
	
	AudioBufferList bufList;
	UInt32 numPackets = numFrames; // Frames to read
	UInt32 samples = numPackets * mExtAFNumChannels;
	UInt32 loadedPackets = numPackets;
	
	
	short *data = (short*)malloc(kSegmentSize*sizeof(short));
	if (!data) {
		NSLog(@"data is nil");
		goto error;
	}
	
	
	bufList.mNumberBuffers = 1;
	bufList.mBuffers[0].mNumberChannels = mExtAFNumChannels;
	bufList.mBuffers[0].mData = data; // data is a pointer (short*) to our sample buffer
	bufList.mBuffers[0].mDataByteSize = samples * sizeof(short);
	
	@synchronized(self) {
		err = ExtAudioFileRead(mExtAFRef, &loadedPackets, &bufList);
	}
	if (err) goto error;
	
	if (audio) {
		for (long c = 0; c < mExtAFNumChannels; c++) {
			if (!audio[c]) continue;
			for (long v = 0; v < numFrames; v++) {
				if (v < loadedPackets) audio[c][v+offset] = (float)data[v*mExtAFNumChannels+c] / 32768.f;
				else audio[c][v+offset] = 0.f;
			}
		}
	}
	
error:
	free(data);
	if (err != noErr) return err;
	if (loadedPackets < numFrames) mExtAFReachedEOF = YES;
	mRpos += loadedPackets;
	return loadedPackets;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio
{
	return [self readFloatsConsecutive:numFrames intoArray:audio withOffset:0];
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) readShortsConsecutive:(SInt64)numFrames intoArray:(short**)audio withOffset:(long)offset
{
	OSStatus err = noErr;
	
	if (!mExtAFRef)	return -1;
   	
	int kSegmentSize = (int)(numFrames * mExtAFNumChannels * mExtAFRateRatio + .5);
	if (mExtAFRateRatio < 1.) kSegmentSize = (int)(numFrames * mExtAFNumChannels / mExtAFRateRatio + .5);
	
	AudioBufferList bufList;
	UInt32 numPackets = numFrames; // Frames to read
	UInt32 samples = numPackets * mExtAFNumChannels;
	UInt32 loadedPackets = numPackets;
	
	
	short *data = (short*)malloc(kSegmentSize*sizeof(short));
	if (!data) {
		NSLog(@"data is nil");
		goto error;
	}
	
	
	bufList.mNumberBuffers = 1;
	bufList.mBuffers[0].mNumberChannels = mExtAFNumChannels;
	bufList.mBuffers[0].mData = data; // data is a pointer (short*) to our sample buffer
	bufList.mBuffers[0].mDataByteSize = samples * sizeof(short);
	
	
	@synchronized(self) {
		err = ExtAudioFileRead(mExtAFRef, &loadedPackets, &bufList);
	}
	if (err) goto error;
	
	if (audio) {
		for (long c = 0; c < mExtAFNumChannels; c++) {
			if (!audio[c]) continue;
			for (long v = 0; v < numFrames; v++) {
				if (v < loadedPackets) audio[c][v+offset] = data[v*mExtAFNumChannels+c];
				else audio[c][v+offset] = 0;
			}
		}
	}
	
error:
	free(data);
	if (err != noErr) return err;
	if (loadedPackets < numFrames) mExtAFReachedEOF = YES;
	mRpos += loadedPackets;
	return loadedPackets;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) readShortsConsecutive:(SInt64)numFrames intoArray:(short**)audio
{
	return [self readShortsConsecutive:numFrames intoArray:audio withOffset:0];
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (id)init;
{
	if (!(self = [super init]))
		return nil;
	
	mExtAFRateRatio = 1.;
	mExtAFRef=nil;
	mExtAFNumChannels = 0;
	mExtAFReachedEOF = NO;
	mRpos = 0;
	return self;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------


-(SInt64)fileNumFrames
{
	if (!mExtAFRef) return 0;
	SInt64 nf=0;
	UInt32 propSize = sizeof(SInt64);
	@synchronized (self) {
		OSStatus err = ExtAudioFileGetProperty(mExtAFRef, kExtAudioFileProperty_FileLengthFrames, &propSize, &nf);
		if (err) {NSLog(@"!!! Error in ExtAudioFileGetProperty kExtAudioFileProperty_FileLengthFrames, %ld", err);}
	}
	return (SInt64)(nf * mExtAFRateRatio+.5);
}	

// ---------------------------------------------------------------------------------------------------------------------------------------------
-(void)dealloc
{
	[self closeFile];
#if __has_feature(objc_arc)
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

@end
