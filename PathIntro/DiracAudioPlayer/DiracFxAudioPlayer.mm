#import "DiracFxAudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnitProperties.h>
#include "Dirac.h"
#include "Utilities.h"


#pragma mark Callbacks


#pragma mark DiracFxAudioPlayer Class


@implementation DiracFxAudioPlayer



// ---------------------------------------------------------------------------------------------------------------------------
/* 
 This is where the actual processing happens. We create a background thread that constantly reads from the file,
 processes audio data and writes it into a cache (mAudioBuffer). If there is enough data in the cache already we don't call
 Dirac on this pass and simply wait until we see that our PlaybackCallback has consumed enough frames.
 
 Note that you might need to change thread priority (via [NSthread setThreadPriority:XX]), cache size (via kAudioBufferNumFrames)
 and hi water mark (by changing the line "if (wd > 2*kAudioBufferNumFrames/3)" below) depending on what else is going on
 in your app. 
 */
-(void)processAudioThread:(id)param
{
#if __has_feature(objc_arc)
	@autoreleasepool {
#else
		// Each thread needs its own AutoreleasePool
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#endif
		
		// If our Dirac instance is still valid we have run into a previous instance that has not been
		// deleted yet because the process has not fully stopped. The only use case where this can
		// occur is with DiracLE, because every parameter change needs to trigger -stop and -play.
		// In this case we simply wait a short period of time and then try again.
		if (mDirac) {
			NSLog(@"Running into existing Dirac instance - retrying");
			[NSThread sleepForTimeInterval:.2];
			[self performSelectorOnMainThread:@selector(triggerPlay:) withObject:self waitUntilDone:NO];
			goto end;
		}
		{
			
			
#ifdef DEBUG
			NSLog(@"entering thread");
#endif	
			mReader = [[EAFRead alloc] init];
			[mReader openFileForRead:mInUrl sr:kOversample*mSampleRate channels:mNumChannels];
			
			mTotalFramesInFile = [mReader fileNumFrames] / kOversample + DiracFxLatencyFrames(kOversample*mSampleRate);
#ifdef DEBUG
			NSLog(@"mTotalFramesInFile = %d", (int)mTotalFramesInFile);
#endif	
			
			mAudioBufferReadPos = mAudioBufferWritePos = 0;
			
			// Before starting processing we set up our Dirac instance
			mDirac = DiracFxCreate(kDiracQualityBest, kOversample*mSampleRate, mNumChannels);
			if (!mDirac) {
				printf("!! ERROR !!\n\n\tCould not create DiracFx instance\n\tCheck sample rate!\n");
				exit(-1);
			}	
			
			// This is the number of frames each call to Dirac will add to the cache.
			long numFrames = 512;
			
			// Allocate buffer for Dirac output
			short **audioIn = AllocateAudioBufferSInt16(mNumChannels, numFrames);
			short **audioOut = AllocateAudioBufferSInt16(mNumChannels, DiracFxMaxOutputBufferFramesRequired(2.0, 1.0, numFrames));
			
			long ret = 0;
			long framesOut = 0;
			mLoopCount = 0;
			
		again:
			
			// MAIN PROCESSING LOOP STARTS HERE
			for(;;) {
				
				if([[NSThread currentThread] isCancelled]) {
					mIsProcessing = NO;
#ifdef DEBUG
					NSLog(@"Thread has been cancelled");
#endif
					break;
				}
				
				// first we determine if we actually need to add new data to the cache. If the distance
				// between read and write position in the cache is still larger than 2/3 the cache size 
				// we assume there is still enough data so we simply skip processing this time
				long wd = wrappedDiff(mAudioBufferReadPos, mAudioBufferWritePos, kAudioBufferNumFrames);
				if (wd > 2*kAudioBufferNumFrames/3) {
					// if you're getting drop-outs decrease this value. We only use it to avoid hogging
					// the CPU with the above comparison when there is nothing to do
					[NSThread sleepForTimeInterval:.01];
					continue;
				}
				// call DiracProcess to produce new frames
				ret = [mReader readShortsConsecutive:numFrames intoArray:audioIn];
				long nf;// = numFrames;
				if (ret > 0) {
                    nf = ret;
                } else {
                    break;
                }
				
				framesOut = DiracFxProcess(mTimeFactor, mPitchFactor, audioIn, audioOut, nf, mDirac);
				
				mTotalFramesConsumed	+= nf;
				mTotalFramesGenerated	+= framesOut;
				
				// add them to the cache
				for (long v = 0; v < framesOut; v++) {
					for (long c = 0; c < mNumChannels; c++) {
						mAudioBuffer[c][mAudioBufferWritePos] = audioOut[c][v] * mVolume;
					}
					mAudioBufferWritePos++;
					if (mAudioBufferWritePos > kAudioBufferNumFrames-1)
						mAudioBufferWritePos = 0;
				}
			}
			mLoopCount++;
			
			if (framesOut == kDiracErrorDemoTimeoutReached) {
				[self performSelectorOnMainThread:@selector(HandleDemoTimeout:) withObject:self waitUntilDone:NO];
			} else {
				
				if ((ret >= 0 && mIsProcessing) && ((mLoopCount <= mNumberOfLoops) || mNumberOfLoops < 0)) {
#ifdef DEBUG
					NSLog(@"Loop has exited - rewinding %d", mLoopCount);
#endif
					mTotalFramesConsumed = 0;
					[mReader seekToStart];
					goto again;
				} else {
#ifdef DEBUG
					NSLog(@"Loop has ended %d", mLoopCount);
#endif
				}
				
			}
			
			mIsProcessing = NO;
			
			// Free buffer for output
			DeallocateAudioBuffer(audioIn, mNumChannels);
			DeallocateAudioBuffer(audioOut, mNumChannels);
			
			DiracFxDestroy(mDirac);
			mDirac = NULL;
#if __has_feature(objc_arc)
			mReader = nil;
#else
			[mReader release];
			mReader = nil;
#endif
			
			
#ifdef DEBUG
			NSLog(@"exiting thread");
#endif
			
		}
	end:
		;	// need empty statement after label to make compiler happy
		
		// release the pool
#if __has_feature(objc_arc)
	}
#else
	[pool release];
#endif
	
	
}





@end

