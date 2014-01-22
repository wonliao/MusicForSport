#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "EAFRead.h"
#include "Dirac.h"

//#define DEBUG	1

#define kAudioBufferNumFrames	8192		/* number of frames in our cache */
#define kOversample				1			/* leave at this value in this version */

#ifndef __has_feature      // Optional.
	#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif


#if __has_feature(objc_arc)
#else
	#define __bridge
#endif


#define kOutputBus 0
#define kInputBus 1


@interface DiracAudioPlayerBase : NSObject 
{
	AudioComponentInstance mAudioUnit;

	NSURL *mInUrl;
	
	EAFRead *mReader;
	void *mDirac;
	float mSampleRate;
	
	SInt16 **mAudioBuffer;
	long mAudioBufferReadPos;
	long mAudioBufferWritePos;
	
	NSThread *mWorkerThread;
	
	float mTimeFactor, mPitchFactor;
	int mNumberOfLoops;
	int mNumChannels;
	int mLoopCount;
	BOOL mIsPrepared;
	BOOL mIsProcessing;
	volatile BOOL mHasFinishedPlaying;
	
	/*volatile*/ SInt64 mTotalFramesPlayed;
	/*volatile*/ SInt64 mTotalFramesConsumed;
	/*volatile*/ SInt64 mTotalFramesGenerated;
	UInt64 mTotalFramesInFile;
	
	float mVolume;
	SInt16 *mPeak;
	SInt16 *mPeakOut;
	
	BOOL mIsRunning;
	
	id mDelegate;
	
}


- (void) processAudioThread:(id)param;	// !!! OVERRIDE THIS!!!

- (void) setDelegate:(id)delegate;
- (id) delegate;

- (void) changeDuration:(float)duration;
- (void) changePitch:(float)pitch;
- (NSInteger) numberOfLoops;
- (void) setNumberOfLoops:(NSInteger)loops;
- (void) updateMeters;
- (float) peakPowerForChannel:(NSUInteger)channelNumber;
- (id) initWithContentsOfURL:(NSURL*)inUrl channels:(int)channels error: (NSError **)error;
- (BOOL) prepareToPlay;
- (NSUInteger) numberOfChannels;
- (NSTimeInterval) fileDuration;
- (NSTimeInterval) currentTime;
- (void) play;
- (NSURL*) url;
- (void) setVolume:(float)volume;
- (float) volume;
- (BOOL) playing;
- (void) pause;
- (void) stop;
- (void) dealloc;
- (void) setCurrentTime:(NSTimeInterval)time;



// private calls and accessors, do not use
- (void) notifyDelegateDidFinishPlaying:(DiracAudioPlayerBase*)player successfully:(BOOL)flag;
- (void) HandleDemoTimeout:(id)param;
- (void) stopProcessing;
- (void) stopAll:(id)param;
- (void) triggerPlay:(id)param;
@property (readonly) AudioComponentInstance mAudioUnit;
@property (readonly) EAFRead *mReader;
@property (readonly) SInt16 **mAudioBuffer;
@property (readonly) void *mDirac;
@property (readwrite) long mAudioBufferReadPos;
@property (readwrite) /*volatile*/ SInt64 mTotalFramesPlayed;
@property (readwrite) /*volatile*/ SInt64 mTotalFramesConsumed;
@property (readwrite) /*volatile*/ SInt64 mTotalFramesGenerated;
@property (readonly) long mAudioBufferWritePos;
@property (readonly) BOOL mIsProcessing;
@property (readonly) UInt64 mTotalFramesInFile;
@property (readwrite) float mVolume;
@property (readonly) SInt16 *mPeak;
@property (readonly) BOOL mIsPrepared;
@property (readonly) int mNumberOfLoops;
@property (readwrite) int mLoopCount;
@property (readonly) int mNumChannels;


@end


@interface NSObject (DiracAudioPlayerBaseDelegate)
- (void)diracPlayerDidFinishPlaying:(DiracAudioPlayerBase *)player successfully:(BOOL)flag;
@end


