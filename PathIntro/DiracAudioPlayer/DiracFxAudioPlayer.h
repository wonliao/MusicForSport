#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "EAFRead.h"
#import "DiracAudioPlayerBase.h"


@interface DiracFxAudioPlayer : DiracAudioPlayerBase
{
}

-(void)processAudioThread:(id)param;

@end


