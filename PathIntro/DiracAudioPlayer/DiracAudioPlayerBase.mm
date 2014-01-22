#import "DiracAudioPlayerBase.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnitProperties.h>
#include "Dirac.h"
#include "Utilities.h"

#pragma mark Callbacks


// ---------------------------------------------------------------------------------------------------------------------------
/*
 This is the playback callback that our AudioUnit calls in order to get new data. In an iOS callback
 we're not allowed to use calls that can block, so we're using the callback to copy data from our internal
 cache (which is filled on a separate worker thread, see explanation at processAudioThread for more detail). 
 */
static OSStatus PlaybackCallback(void *inRefCon, 
								 AudioUnitRenderActionFlags *ioActionFlags, 
								 const AudioTimeStamp *inTimeStamp, 
								 UInt32 inBusNumber, 
								 UInt32 inNumberFrames, 
								 AudioBufferList *ioData) 
{    
	
	// this points to our class instance
	DiracAudioPlayerBase *Self = (__bridge DiracAudioPlayerBase *)inRefCon;
	if (!Self) return -1;
	
	int numChannels = Self.mNumChannels;
	
	// get the actual audio buffer from the ABL	
	AudioBuffer buffer = ioData->mBuffers[0];
	
	// this points to the buffer that is going to be filled with our data
	SInt16 *ioBuffer = (SInt16*)buffer.mData;
	
	// this is how much data will be in our buffer once we're done
	buffer.mDataByteSize = numChannels * inNumberFrames * sizeof(SInt16);
	
	long audioBufferReadPos = Self.mAudioBufferReadPos;		// store this in a temporary to avoid ObjC call overhead
	long totalFramesPlayed = Self.mTotalFramesPlayed;		// store this in a temporary to avoid ObjC call overhead
	long totalFramesGenerated = Self.mTotalFramesGenerated;		// store this in a temporary to avoid ObjC call overhead
	SInt16 **audioBuffer = Self.mAudioBuffer;
	
	// loop through all frames and channels to copy the data into our AudioBuffer
	for (long s = 0; s < inNumberFrames; s++) {
		for (long c = 0; c < numChannels; c++) {
			ioBuffer[numChannels*s+c] = audioBuffer[c][audioBufferReadPos];
			SInt16 av = abs(ioBuffer[numChannels*s+c]);
			if (av > Self.mPeak[c])
				Self.mPeak[c] = av;
			
		}
		
		// advance our read position and make sure we stay within limits
		audioBufferReadPos++;
		totalFramesPlayed++;
		if (audioBufferReadPos > kAudioBufferNumFrames-1)
			audioBufferReadPos = 0;
		
		if (totalFramesPlayed >= totalFramesGenerated && !Self.mIsProcessing) {
#ifdef DEBUG
			printf("mTotalFramesPlayed = %d >= mTotalFramesGenerated = %d && !Self.mIsProcessing\n", (int)totalFramesPlayed, (int)totalFramesGenerated);
			printf("\t\tstopping - processing has quit\n");
#endif
			[Self performSelectorOnMainThread:@selector(stopAll:) withObject:Self waitUntilDone:NO];
			goto end;
		}
		
	}	
end:
	Self.mAudioBufferReadPos = audioBufferReadPos;
	Self.mTotalFramesPlayed = totalFramesPlayed;
    return noErr;
}


#pragma mark DiracAudioPlayerBase Class


@implementation DiracAudioPlayerBase


#pragma mark second thread

// ---------------------------------------------------------------------------------------------------------------------------
-(void)processAudioThread:(id)param
{
#if __has_feature(objc_arc)
	@autoreleasepool {
#else
		// Each thread needs its own AutoreleasePool
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#endif
		
		[NSException raise:NSInternalInconsistencyException 
					format:@"\n\n!!! You must override %@ in a subclass !!!\n\n", NSStringFromSelector(_cmd)];
		
		
#if __has_feature(objc_arc)
	}
#else
	[pool release];
#endif
}

#pragma mark delegate

// ---------------------------------------------------------------------------------------------------------------------------

-(void)setDelegate:(id)delegate
{
	mDelegate = delegate;
}
// ---------------------------------------------------------------------------------------------------------------------------

-(id)delegate
{
	return mDelegate;
}

// ---------------------------------------------------------------------------------------------------------------------------

- (void)notifyDelegateDidFinishPlaying:(DiracAudioPlayerBase*)player successfully:(BOOL)flag
{
	if (mDelegate) {
		if ([mDelegate respondsToSelector:@selector(diracPlayerDidFinishPlaying:successfully:)] == YES) {
			[mDelegate diracPlayerDidFinishPlaying:player successfully:flag];
		} else {
			NSLog(@"\t!!! PROBLEM: %@ is a delegate of class %@ and does not respond to diracPlayerDidFinishPlaying:", [[mDelegate class] description], [[self class] description]);
		}
	}
}
#pragma mark main thread

// ---------------------------------------------------------------------------------------------------------------------------

- (void)HandleDemoTimeout:(id)param
{
	[self stop];
	ClearAudioBuffer(mAudioBuffer, mNumChannels, kAudioBufferNumFrames);
	
#if TARGET_OS_IPHONE

#if __has_feature(objc_arc)
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Demo Timeout" message:@"The demo timeout of this evaluation version has been reached. Please relaunch the app to continue with the evaluation" delegate:self cancelButtonTitle:@"Ok"
										  otherButtonTitles:nil];
	[alert show];
#else /* non-ARC */

	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Demo Timeout" message:@"The demo timeout of this evaluation version has been reached. Please relaunch the app to continue with the evaluation" delegate:self cancelButtonTitle:@"Ok"
										   otherButtonTitles:nil] autorelease];
	[alert show];
#endif /* __has_feature(objc_arc) */

#else /* MacOS X */
	NSRunAlertPanel(@"Demo Timeout", @"The demo timeout of this evaluation version has been reached. Please relaunch the app to continue with the evaluation", @"Ok", nil, nil);
#endif /* TARGET_OS_IPHONE */

}

// ---------------------------------------------------------------------------------------------------------------------------

-(void)changeDuration:(float)duration
{
#ifdef DEBUG
	NSLog(@"changeDuration %f", duration);
#endif
	mTimeFactor = duration/kOversample;	
}
// ---------------------------------------------------------------------------------------------------------------------------

-(void)changePitch:(float)pitch
{
#ifdef DEBUG
	NSLog(@"changePitch %f", pitch);
#endif
	mPitchFactor = kOversample*pitch;
}
// ---------------------------------------------------------------------------------------------------------------------------

-(NSInteger)numberOfLoops
{
	return mNumberOfLoops;
}

// ---------------------------------------------------------------------------------------------------------------------------

-(void)setNumberOfLoops:(NSInteger)loops
{
	mNumberOfLoops = loops;
}
// ---------------------------------------------------------------------------------------------------------------------------

-(void)updateMeters
{
	for (long v = 0; v < mNumChannels; v++) {
		if (mPeak[v] >= 0) {
			mPeakOut[v] = mPeak[v];
			mPeak[v] = -1;
		}
	}
}
// ---------------------------------------------------------------------------------------------------------------------------

- (float)peakPowerForChannel:(NSUInteger)channelNumber
{
	if (channelNumber > mNumChannels-1) return 0.f;
	
	if (!mPeakOut[channelNumber])
		return -160.f;
	
	return 20.f*log10f((float)mPeakOut[channelNumber] / 32768.f);
}

// ---------------------------------------------------------------------------------------------------------------------------

- (id) initWithContentsOfURL:(NSURL*)inUrl channels:(int)channels error: (NSError **)error
{
	//*error = nil;
    if (error != NULL) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:noErr userInfo:nil];
  
	
	self = [super init];
	
	if (self) {
		
		mDelegate = nil;
		mInUrl = [inUrl copy];
		mIsPrepared = NO;
		mIsProcessing = NO;
		mWorkerThread = nil;
		mTotalFramesInFile = 0;
		mIsRunning = NO;
		mVolume = 1.0;
		mLoopCount = mNumberOfLoops = 0;
		mHasFinishedPlaying = YES;
		
		if (channels < 1) channels = 1;
		else if (channels > 2) channels = 2;
		mNumChannels = channels;
		
		mPeak = new SInt16[mNumChannels];
		mPeakOut = new SInt16[mNumChannels];
		
		for (long v = 0; v < mNumChannels; v++) {
			mPeakOut[v] = 0;
			mPeak[v] = -1;
		}
		
		OSStatus status = noErr;
		mTimeFactor = 1./kOversample;
		mPitchFactor = kOversample;
		// This is boilerplate code to set up CoreAudio on iOS in order to play audio via its default output
		
		// Desired audio component
		AudioComponentDescription desc;
		desc.componentType = kAudioUnitType_Output;
#if TARGET_OS_IPHONE
		desc.componentSubType = kAudioUnitSubType_RemoteIO;
#else
		desc.componentSubType = kAudioUnitSubType_HALOutput;
#endif
		desc.componentManufacturer = kAudioUnitManufacturer_Apple;
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		
		// Get ref to component
		AudioComponent defaultOutput = AudioComponentFindNext(NULL, &desc);
		
		// Get matching audio unit
		status = AudioComponentInstanceNew(defaultOutput, &mAudioUnit);
		checkStatus(status);
		
		// this is the format we want
		AudioStreamBasicDescription audioFormat;
		mSampleRate=audioFormat.mSampleRate			= 44100.00;
		audioFormat.mFormatID			= kAudioFormatLinearPCM;
		audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		audioFormat.mFramesPerPacket	= 1;
		audioFormat.mChannelsPerFrame	= mNumChannels;
		audioFormat.mBitsPerChannel		= 16;
		audioFormat.mBytesPerPacket		= sizeof(short)*mNumChannels;
		audioFormat.mBytesPerFrame		= sizeof(short)*mNumChannels;
		
		status = AudioUnitSetProperty(mAudioUnit, 
									  kAudioUnitProperty_StreamFormat, 
									  kAudioUnitScope_Input, 
									  kOutputBus, 
									  &audioFormat, 
									  sizeof(audioFormat));
		checkStatus(status);
		
		// here we set up CoreAudio in order to call our PlaybackCallback
		AURenderCallbackStruct callbackStruct;
		callbackStruct.inputProc = PlaybackCallback;
		callbackStruct.inputProcRefCon = (__bridge void*) self;
		status = AudioUnitSetProperty(mAudioUnit, 
									  kAudioUnitProperty_SetRenderCallback, 
									  kAudioUnitScope_Input, 
									  kOutputBus,
									  &callbackStruct, 
									  sizeof(callbackStruct));
		checkStatus(status);
		
		
		// Initialize unit
		status = AudioUnitInitialize(mAudioUnit);
		checkStatus(status);
		
		// here we allocate our audio cache
		mAudioBuffer = AllocateAudioBufferSInt16(mNumChannels, kAudioBufferNumFrames);
		
		// Avoid delay when hitting play by making sure the graph is pre-initialized
		//status = AudioOutputUnitStart(mAudioUnit);
		//status = AudioOutputUnitStop(mAudioUnit);
		
		[self prepareToPlay];
		
		
		
		if (error != NULL) *error = [NSError errorWithDomain: NSOSStatusErrorDomain code:noErr userInfo: nil];
		
		return self;
	}
	if (error != NULL) *error = [NSError errorWithDomain: NSOSStatusErrorDomain code:-1 userInfo: nil];
	
	return nil;
}
// ---------------------------------------------------------------------------------------------------------------------------

-(BOOL)prepareToPlay
{
	if (!mIsPrepared) {
		mTotalFramesPlayed = 0;
		mTotalFramesConsumed = 0;
		mTotalFramesGenerated = 0;
		mLoopCount = 0;
		mIsProcessing = YES;
		// this kicks off our background worker thread that does the actual Dirac processing
		mWorkerThread = [[NSThread alloc] initWithTarget:self selector:@selector(processAudioThread:) object:nil];
		[mWorkerThread start];
		mIsPrepared = YES;
	}
	return YES;
}
// ---------------------------------------------------------------------------------------------------------------------------

-(void)stopProcessing
{
	[mWorkerThread cancel];
#if __has_feature(objc_arc)
#else
	[mWorkerThread release];
#endif
	mWorkerThread = nil;
	mIsPrepared = NO;
}

// ---------------------------------------------------------------------------------------------------------------------------

-(NSUInteger)numberOfChannels
{
	return mNumChannels;
}

// ---------------------------------------------------------------------------------------------------------------------------

-(NSTimeInterval)fileDuration
{
	return (NSTimeInterval)mTotalFramesInFile / mSampleRate;
}

// ---------------------------------------------------------------------------------------------------------------------------

- (void) setCurrentTime:(NSTimeInterval)time
{
	SInt64 seekPos = (SInt64)(time * mSampleRate);
	if (mReader) {
		SInt64 duration = [mReader fileNumFrames];
		if (duration>0 && seekPos < duration) {
			[mReader seekToPercent:(100.*(Float64)seekPos / (Float64)duration)];
			mAudioBufferReadPos = 0;
			mAudioBufferWritePos = 0;
			ClearAudioBuffer(mAudioBuffer, mNumChannels, kAudioBufferNumFrames);
		}			
	}
}

// ---------------------------------------------------------------------------------------------------------------------------

-(NSTimeInterval)currentTime
{
	return (NSTimeInterval)mTotalFramesPlayed / mSampleRate;
}

// ---------------------------------------------------------------------------------------------------------------------------
- (void) play 
{
#ifdef DEBUG
	NSLog(@"Playing");
#endif
	[self prepareToPlay];
	OSStatus status = AudioOutputUnitStart(mAudioUnit);
	checkStatus(status);
	mIsRunning = YES;
	mHasFinishedPlaying = NO;
}
// ---------------------------------------------------------------------------------------------------------------------------
-(NSURL*)url
{
	return mInUrl;
}
// ---------------------------------------------------------------------------------------------------------------------------

-(void)setVolume:(float)volume
{
	if (volume > 1.f)
		volume = 1.f;
	else if (volume < 0.f)
		volume = 0.f;
	
	mVolume = volume;
}
// ---------------------------------------------------------------------------------------------------------------------------

-(float)volume
{
	return 	mVolume;
}
// ---------------------------------------------------------------------------------------------------------------------------

-(BOOL)playing
{
	return 	mIsRunning;
}
// ---------------------------------------------------------------------------------------------------------------------------

- (void) pause 
{
#ifdef DEBUG
	NSLog(@"Pausing @ %f", [self currentTime]);
#endif
	OSStatus status = AudioOutputUnitStop(mAudioUnit);
	checkStatus(status);
	mIsRunning = NO;
}
// ---------------------------------------------------------------------------------------------------------------------------

- (void) stop 
{
#ifdef DEBUG
	NSLog(@"Stopping");
#endif
	ClearAudioBuffer(mAudioBuffer, mNumChannels, kAudioBufferNumFrames);
	[self stopProcessing];
	OSStatus status = AudioOutputUnitStop(mAudioUnit);
	checkStatus(status);
	mIsRunning = NO;
	
}
// ---------------------------------------------------------------------------------------------------------------------------

- (void) dealloc 
{
#ifdef DEBUG
	NSLog(@"dealloc");
#endif
	[self stop];
	
	if (mTotalFramesGenerated && !mHasFinishedPlaying){
		mHasFinishedPlaying = YES;
		//[self notifyDelegateDidFinishPlaying:self successfully:YES];
	}

	AudioUnitUninitialize(mAudioUnit);
#if __has_feature(objc_arc)
	mInUrl = nil;
#else
	[mInUrl release];
#endif
	
	delete[] 	mPeak;
	delete[]	mPeakOut;
	
	
	DeallocateAudioBuffer(mAudioBuffer, mNumChannels);
#if __has_feature(objc_arc)
#else
	[super dealloc];
#endif
}

// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
- (void) stopAll:(id)param
{
	[self stop];
	if (mTotalFramesGenerated && !mHasFinishedPlaying){
		mHasFinishedPlaying = YES;
		[self notifyDelegateDidFinishPlaying:self successfully:YES];
	}
	
}	
// ---------------------------------------------------------------------------------------------------------------------------
- (void) triggerPlay:(id)param
{
	[self play];
}	
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
#pragma mark accessors

@synthesize mAudioUnit, mReader, mVolume, mNumberOfLoops, mNumChannels, mAudioBufferReadPos, mAudioBuffer, mDirac, mLoopCount, mPeak, mAudioBufferWritePos, mIsProcessing, mIsPrepared, mTotalFramesGenerated, mTotalFramesPlayed, mTotalFramesInFile, mTotalFramesConsumed;

@end

