#import "DiracAudioPlayerBase.h"
#import "EAFRead.h"



@interface DiracAudioPlayer : DiracAudioPlayerBase 
{

}

-(void)changeDuration:(float)duration;
-(void)changePitch:(float)pitch;
-(void)processAudioThread:(id)param;

@end

