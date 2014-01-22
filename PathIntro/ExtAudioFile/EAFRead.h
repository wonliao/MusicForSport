#include <AudioToolbox/AudioToolbox.h>

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

@interface EAFRead : NSObject {
 	ExtAudioFileRef mExtAFRef;
   int mExtAFNumChannels;
	double mExtAFRateRatio;
	BOOL mExtAFReachedEOF;
	Float64 mPlaybackSampleRate;
	Float64 mExtAFSampleRate;
	SInt64 mRpos;
}

- (OSStatus) openFileForRead:(NSURL*)fileURL sr:(Float64)sampleRate channels:(int)numChannels;
- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio;
- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio withOffset:(long)offset;
- (OSStatus) readShortsConsecutive:(SInt64)numFrames intoArray:(short**)audio;
- (OSStatus) readShortsConsecutive:(SInt64)numFrames intoArray:(short**)audio withOffset:(long)offset;
- (OSStatus) closeFile;
- (SInt64) fileNumFrames;
- (void) seekToStart;
- (void) seekToPercent:(Float64)percent;
- (Float64) sampleRate;
- (SInt64) tell;
-(void)dealloc;

@end
