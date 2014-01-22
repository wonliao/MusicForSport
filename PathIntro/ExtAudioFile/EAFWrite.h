#include <AudioToolbox/AudioToolbox.h>

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

@interface EAFWrite : NSObject 
{
	ExtAudioFileRef mOutputAudioFile;
	
	UInt32	mAudioChannels;
	AudioStreamBasicDescription	mOutputFormat;
	
	AudioStreamBasicDescription	mStreamFormat;
	AudioFileTypeID mType;
	AudioFileID mAfid;
}

-(void)SetupStreamAndFileFormatForType:(AudioFileTypeID)aftid withSR:(float) sampleRate channels:(long) numChannels wordlength:(long)numBits;
- (OSStatus) openFileForWrite:(NSURL*)inPath sr:(Float64)sampleRate channels:(int)numChannels wordLength:(int)numBits type:(AudioFileTypeID)aftid;
- (void) closeFile;
-(OSStatus) writeFloats:(long)numFrames fromArray:(float **)data;
-(OSStatus) writeShorts:(long)numFrames fromArray:(short **)data;


@end
