#import <UIKit/UIKit.h>
#import "IntroView.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "DiracFxAudioPlayer.h"

#import "CoreData.h"
#import "SongInfo.h"  // 可錄歌曲列表的資料庫互動類別

@interface MySongInfo: NSObject

@property (nonatomic, retain) NSString *songID;
@property (nonatomic, retain) NSString *songTitle;
@property (nonatomic, retain) NSString *songArt;
@property (nonatomic, retain) NSData *songImg;
@property (nonatomic, retain) NSString *assetURL;
@property (nonatomic, retain) NSString *m4aURL;
@property (nonatomic, retain) NSString *bpm;

@end


@interface IntroControll : UIView<UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, MPMediaPickerControllerDelegate, AVAudioPlayerDelegate> {
    
    
    UIImageView *backgroundImage1;
    UIImageView *backgroundImage2;
    
    UIScrollView *scrollView;
    UIPageControl *pageControl;
    NSArray *pages;
    
    NSTimer *timer;
    
    int currentPhotoNum;

    MPMediaItemCollection		*userMediaItemCollection;
    
    // CoreData 物件
    CoreData *m_coreData;
    
    NSMutableArray *m_songList;
    
    DiracFxAudioPlayer *mDiracAudioPlayer;
    MPMusicPlayerController* mMediaPlayer;
    
    NSInteger playingIndex;
 
    NSMutableDictionary *m_preparingList;
    
    UIImageView *imageToMove;

    UIButton *addSongBtn;
    UIButton *editBtn;
    UIButton *backBtn;
    UIButton *songListBtn;
    
    UIButton *playBtn;
    UIButton *forwardBtn;
    UIButton *rewindBtn;
    
    BOOL isPlaying;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, retain)	MPMediaItemCollection	*userMediaItemCollection;


- (id)initWithFrame:(CGRect)frame pages:(NSArray*)pages;

- (void)diracPlayerDidFinishPlaying:(DiracAudioPlayerBase *)player successfully:(BOOL)flag;


@end
