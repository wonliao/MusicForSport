#import "IntroControll.h"

@implementation MySongInfo

@synthesize songID;
@synthesize songTitle;
@synthesize songArt;
@synthesize songImg;
@synthesize assetURL;
@synthesize m4aURL;
@synthesize bpm;

@end



@implementation IntroControll

@synthesize tableView = _tableView;
@synthesize userMediaItemCollection;	// the media item collection created by the user, using the media item picker


- (id)initWithFrame:(CGRect)frame pages:(NSArray*)pagesArray
{
    self = [super initWithFrame:frame];
    if(self != nil) {

        mMediaPlayer = [MPMusicPlayerController iPodMusicPlayer];

        
        // 取得應用程式的代理物件參照
        m_coreData = [[CoreData alloc] init];

        m_songList = [[NSMutableArray alloc] init];
        // 更新列表
        [self getSongList];

        m_preparingList = [[NSMutableDictionary alloc] init];

        //Initial Background images
        self.backgroundColor = [UIColor blackColor];
        
        backgroundImage1 = [[UIImageView alloc] initWithFrame:frame];
        [backgroundImage1 setContentMode:UIViewContentModeScaleAspectFill];
        [backgroundImage1 setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self addSubview:backgroundImage1];

        backgroundImage2 = [[UIImageView alloc] initWithFrame:frame];
        [backgroundImage2 setContentMode:UIViewContentModeScaleAspectFill];
        [backgroundImage2 setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self addSubview:backgroundImage2];
        
        //Initial shadow
        UIImageView *shadowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shadow.png"]];
        shadowImageView.contentMode = UIViewContentModeScaleToFill;
        shadowImageView.frame = CGRectMake(0, frame.size.height-300, frame.size.width, 300);
        [self addSubview:shadowImageView];

        
        
        //Initial ScrollView
        scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
        scrollView.backgroundColor = [UIColor clearColor];
        scrollView.pagingEnabled = YES;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.delegate = self;
        [self addSubview:scrollView];
        
        //Initial PageView
        pageControl = [[UIPageControl alloc] init];
        pageControl.numberOfPages = pagesArray.count;
        [pageControl sizeToFit];
        [pageControl setCenter:CGPointMake(frame.size.width/2.0, frame.size.height-50)];
        [self addSubview:pageControl];
        
        //Create pages
        pages = pagesArray;
        
        scrollView.contentSize = CGSizeMake(pages.count * frame.size.width, frame.size.height);
        
        currentPhotoNum = -1;
        
        //insert TextViews into ScrollView
        for(int i = 0; i <  pages.count; i++) {
            IntroView *view = [[IntroView alloc] initWithFrame:frame model:[pages objectAtIndex:i]];
            view.frame = CGRectOffset(view.frame, i*frame.size.width, 0);
            [scrollView addSubview:view];
        }

        CAKeyframeAnimation *animation;
        animation = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
        animation.duration = 50.0f;
        animation.repeatCount = HUGE_VALF;
        animation.values = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:160.0f],
                            [NSNumber numberWithFloat:320.0f],
                            [NSNumber numberWithFloat:160.0f],
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:160.0f], nil];
        animation.keyTimes = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:0.0],
                              [NSNumber numberWithFloat:0.25],
                              [NSNumber numberWithFloat:.5],
                              [NSNumber numberWithFloat:.75],
                              [NSNumber numberWithFloat:1.0], nil];
        
        animation.removedOnCompletion = NO;
        
        [backgroundImage1.layer addAnimation:animation forKey:nil];
        [backgroundImage2.layer addAnimation:animation forKey:nil];

        // 新增歌按鈕
        addSongBtn = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [addSongBtn addTarget:self action:@selector(aMethod:) forControlEvents:UIControlEventTouchDown];
        [addSongBtn setTitle:@"Add New Song" forState:UIControlStateNormal];
        addSongBtn.frame = CGRectMake(160, 20.0, 160.0, 40.0);
        [backBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [addSongBtn setHidden:YES];
        [self addSubview:addSongBtn];

        // 返回按鈕
        backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [backBtn addTarget:self action:@selector(closeMenu:) forControlEvents:UIControlEventTouchDown];
        [backBtn setTitle:@"Back" forState:UIControlStateNormal];
        backBtn.frame = CGRectMake(10, 20.0, 160.0, 40.0);
        [backBtn setHidden:YES];
        [backBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [self addSubview:backBtn];

        // 歌單按鈕
        songListBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [songListBtn addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchDown];
        [songListBtn setTitle:@"Song List" forState:UIControlStateNormal];
        songListBtn.frame = CGRectMake(10, 20.0, 160.0, 40.0);
        [songListBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [self addSubview:songListBtn];

        /*
        UIImage *cdImg = nil;
        if([m_songList count] > 0) {
            MySongInfo *songInfo = [m_songList objectAtIndex:playingIndex];
            NSData *imageData = songInfo.songImg;
            cdImg = [UIImage imageWithData:imageData];
        } else {
            cdImg = [UIImage imageNamed:@"white.png"];
        }
        songListBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [songListBtn setBackgroundImage:cdImg forState:UIControlStateNormal];
        [songListBtn addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchDown];
        songListBtn.frame = CGRectMake(100, 60.0, 120.0, 120.0);
        songListBtn.layer.masksToBounds = YES;  //這行要有才能顯示出來
        songListBtn.layer.cornerRadius = 60.0f; //邊角15.0f，自行設定邊角圓弧度
        [self addSubview:songListBtn];
        */
        // 旋轉圖片
        //[self rotate360WithDuration:1.0 repeatCount:999 withLayer:songListBtn.layer];


        // 播放/暫停按鈕
        UIImage *playImg = [UIImage imageNamed:@"play_white.png"];
        playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [playBtn setBackgroundImage:playImg forState:UIControlStateNormal];
        [playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchDown];
        playBtn.frame = CGRectMake(140, 270.0, 40.0, 40.0);
        [self addSubview:playBtn];
        
        // 前進按鈕
        UIImage *forwardImg = [UIImage imageNamed:@"forward_white.png"];
        forwardBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [forwardBtn setBackgroundImage:forwardImg forState:UIControlStateNormal];
        [forwardBtn addTarget:self action:@selector(forwardBtnClick:) forControlEvents:UIControlEventTouchDown];
        forwardBtn.frame = CGRectMake(230, 270.0, 40.0, 40.0);
        [self addSubview:forwardBtn];
        
        // 倒回按鈕
        UIImage *rewindImg = [UIImage imageNamed:@"rewind_white.png"];
        rewindBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [rewindBtn setBackgroundImage:rewindImg forState:UIControlStateNormal];
        [rewindBtn addTarget:self action:@selector(rewindBtnClick:) forControlEvents:UIControlEventTouchDown];
        rewindBtn.frame = CGRectMake(50, 270.0, 40.0, 40.0);
        [self addSubview:rewindBtn];

        // 列表
        CGRect rect = CGRectMake(0, 60, 320, 200);
        self.tableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStyleGrouped];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.backgroundView = nil;
        self.tableView.backgroundColor = [UIColor clearColor];
        [self.tableView setHidden:YES];
        [self addSubview:self.tableView];

        [self initShow];

        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];

        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

        isPlaying = NO;
    }

    return self;
}

// 旋轉圖片
- (void)rotate360WithDuration:(CGFloat)duration repeatCount:(float)repeatCount withLayer:(CALayer *)layer
{
    
	CABasicAnimation *fullRotation;
	fullRotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
	fullRotation.fromValue = [NSNumber numberWithFloat:0];
	fullRotation.toValue = [NSNumber numberWithFloat:((360 * M_PI) / 180)];
	fullRotation.duration = duration;
	if (repeatCount == 0)
		fullRotation.repeatCount = MAXFLOAT;
	else
		fullRotation.repeatCount = repeatCount;
    
	[layer addAnimation:fullRotation forKey:@"360"];
}

- (IBAction)playBtnClick:(id)sender
{
    //NSLog(@"playBtnClick");
    
    if([m_songList count] <= 0) {
        
        [self performSelector:@selector(showMenu:) withObject:self afterDelay:0.1];
        [self performSelector:@selector(aMethod:) withObject:self afterDelay:0.1];
    } else {
        
        if( isPlaying == YES ) {
            
            isPlaying = NO;
            UIImage *playImg = [UIImage imageNamed:@"play_white.png"];
            [playBtn setBackgroundImage:playImg forState:UIControlStateNormal];
            
            [self stopSong];
        } else {
            
            isPlaying = YES;
            UIImage *playImg = [UIImage imageNamed:@"pause_white.png"];
            [playBtn setBackgroundImage:playImg forState:UIControlStateNormal];
            
            [self playSong];
        }
    }
}

- (IBAction)forwardBtnClick:(id)sender
{
    //NSLog(@"forwardBtnClick");

    if([m_songList count] <= 0) return;

    isPlaying = YES;
    UIImage *playImg = [UIImage imageNamed:@"pause_white.png"];
    [playBtn setBackgroundImage:playImg forState:UIControlStateNormal];

    [self nextSong];
}

- (IBAction)rewindBtnClick:(id)sender
{
    //NSLog(@"rewindBtnClick");

    if([m_songList count] <= 0) return;

    isPlaying = YES;
    UIImage *playImg = [UIImage imageNamed:@"pause_white.png"];
    [playBtn setBackgroundImage:playImg forState:UIControlStateNormal];

    [self rewindSong];
}


// 更新列表
-(void)getSongList
{
    // 列表無物件時，讀取資料庫
    if([m_songList count] <= 0) {
        
        NSMutableArray *list = [m_coreData loadDataFromSongList];
        for(int i=0; i<[list count]; i++) {
        
            SongInfo *songInfo = [list objectAtIndex:i];
            
            MySongInfo *mySongInfo = [[MySongInfo alloc] init];
            mySongInfo.songID = songInfo.songID;
            mySongInfo.songTitle = songInfo.songTitle;
            mySongInfo.songArt = songInfo.songArt;
            mySongInfo.songImg = songInfo.songImg;
            mySongInfo.assetURL = songInfo.assetURL;
            mySongInfo.m4aURL = songInfo.m4aURL;
            mySongInfo.bpm = songInfo.bpm;

            [m_songList addObject:mySongInfo];
        }
    }
    NSLog(@"m_songList(%d)", [m_songList count]);


    [self.tableView reloadData];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void) tick
{
    [scrollView setContentOffset:CGPointMake((currentPhotoNum+1 == pages.count ? 0 : currentPhotoNum+1)*self.frame.size.width, 0) animated:YES];
}

- (void) initShow
{
    int scrollPhotoNumber = MAX(0, MIN(pages.count-1, (int)(scrollView.contentOffset.x / self.frame.size.width)));

    if(scrollPhotoNumber != currentPhotoNum) {
        
        //NSLog(@"scrollPhotoNumber(%d)", scrollPhotoNumber);
        
        currentPhotoNum = scrollPhotoNumber;
        
        //backgroundImage1.image = currentPhotoNum != 0 ? [(IntroModel*)[pages objectAtIndex:currentPhotoNum-1] image] : nil;
        backgroundImage1.image = [(IntroModel*)[pages objectAtIndex:currentPhotoNum] image];
        backgroundImage2.image = currentPhotoNum+1 != [pages count] ? [(IntroModel*)[pages objectAtIndex:currentPhotoNum+1] image] : nil;

        [self changeSongDuration];
        
        /*
        // 旋轉圖片
        float duration = (5.0 / (currentPhotoNum + 1));
        NSLog(@"duration(%f)", duration);
        [self rotate360WithDuration:duration repeatCount:999 withLayer:songListBtn.layer];
        */
    }
    
    float offset =  scrollView.contentOffset.x - (currentPhotoNum * self.frame.size.width);

    //left
    if(offset < 0) {
        pageControl.currentPage = 0;
        
        offset = self.frame.size.width - MIN(-offset, self.frame.size.width);
        backgroundImage2.alpha = 0;
        backgroundImage1.alpha = (offset / self.frame.size.width);
    
    //other
    } else if(offset != 0) {
        //last
        if(scrollPhotoNumber == pages.count-1) {
            pageControl.currentPage = pages.count-1;
            
            backgroundImage1.alpha = 1.0 - (offset / self.frame.size.width);
        } else {
            
            pageControl.currentPage = (offset > self.frame.size.width/2) ? currentPhotoNum+1 : currentPhotoNum;
            
            backgroundImage2.alpha = offset / self.frame.size.width;
            backgroundImage1.alpha = 1.0 - backgroundImage2.alpha;
        }
    //stable
    } else {
        pageControl.currentPage = currentPhotoNum;
        backgroundImage1.alpha = 1;
        backgroundImage2.alpha = 0;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scroll
{
    [self initShow];
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scroll
{
    if(timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    [self initShow];
}



#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [m_songList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *ProductCellIdentifier = @"ProductCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ProductCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ProductCellIdentifier];
    }

    //NSLog(@"row(%d)", indexPath.row);
    MySongInfo* songInfo = [m_songList objectAtIndex:indexPath.row];
    if(songInfo) {
        
        //NSLog(@"id(%@) title(%@)", songInfo.songID, songInfo.songTitle);
        
        NSArray *viewsToRemove = [cell subviews];
        for (UIView *v in viewsToRemove) {
            if([v isKindOfClass:[UILabel class]]) {
                [v removeFromSuperview];
            }
        }

        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor whiteColor];
        [cell setBackgroundColor:[UIColor clearColor]];

        // 專輯封面
        NSData *imageData = songInfo.songImg;
        UIImage *myImg = [UIImage imageWithData:imageData];
        int w = myImg.size.width;
        int h = myImg.size.height;
        if( w > h ) w = h;
        if( h > w ) h = w;
        CGImageRef imageRef = CGImageCreateWithImageInRect([myImg CGImage], CGRectMake(0, 0, w, h));
        [cell.imageView setFrame:CGRectMake(0, 0, 40, 40)];
        [cell.imageView setImage:[UIImage imageWithCGImage:imageRef]];
        CGImageRelease(imageRef);
        cell.imageView.layer.borderWidth = 2;
        cell.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        cell.imageView.layer.cornerRadius = CGRectGetHeight(cell.imageView.bounds) / 2;
        cell.imageView.clipsToBounds = YES;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(255, 15, 50, 20)];
        label.text = @"";

        
        // 準備中
        if( [songInfo.m4aURL isEqualToString:@""] ) {

            // 歌名
            cell.textLabel.text = @"preparing";

            // 歌手
            cell.detailTextLabel.text  = songInfo.songArt;

            [label setText:@""];
        } else if( [songInfo.m4aURL isEqualToString:@"iCloud"] ) {
            
            // 歌名
            cell.textLabel.text = songInfo.songTitle;
            
            // 歌手
            cell.detailTextLabel.text = songInfo.songArt;
            
            [label setText:@"iCloud"];
        } else {
            
            // 歌名
            cell.textLabel.text = songInfo.songTitle;
            
            // 歌手
            cell.detailTextLabel.text = songInfo.songArt;

            [label setText:@""];
        }
        
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        [cell addSubview:label];
    }
    
    return cell;
}

// 刪除歌單
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// 刪除歌單
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {

        //NSString *index = [NSString stringWithFormat:@"%d", indexPath.row];
        //NSLog(@"remove index(%@)", index);
        
        if(indexPath.row == playingIndex) [self stopSong];
        
        
        MySongInfo *songInfo = [m_songList objectAtIndex:indexPath.row];
        
        
        // 刪除檔案
        NSString *fileName = songInfo.songID;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *myDocumentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSString *pathToDelete = [myDocumentsDirectory stringByAppendingPathComponent:fileName];
        
        NSError *error = nil;
        BOOL removeSuccess = [[NSFileManager defaultManager] removeItemAtPath: pathToDelete error: &error];
        if (removeSuccess) {
            
            NSLog(@"success");
        } else {
            // Error handling
            NSLog(@"error");
        }
               
        
        [m_coreData removeOneSong:songInfo.songID];

        [m_songList removeObjectAtIndex:indexPath.row];

        // 更新列表
        [self getSongList];
    }
}

-(NSString*)filePath{

    NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    //NSLog(@"%@",path);
    return path;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    playingIndex = indexPath.row;
    //NSLog(@"playingIndex(%d) indexPath.row(%d)", playingIndex, indexPath.row);
    
    if([m_songList count] > 0 && [m_songList objectAtIndex:indexPath.row]) {
    
        isPlaying = YES;
        UIImage *playImg = [UIImage imageNamed:@"pause_white.png"];
        [playBtn setBackgroundImage:playImg forState:UIControlStateNormal];
        
        [self playSong];
    } else {
        
        NSLog(@"no song");
    }
}

- (void)diracPlayerDidFinishPlaying:(DiracAudioPlayerBase *)player successfully:(BOOL)flag
{
    [self nextSong];
}

- (void)playSong
{
    //NSLog(@"playingIndex(%d)", playingIndex);
    
    if([m_songList count] <= 0) return;
    
    MySongInfo* songInfo = [m_songList objectAtIndex:playingIndex];
    if( songInfo ) {
        
        NSString *fileName = songInfo.m4aURL;
        //NSLog(@"fileName(%@)", fileName);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString * myDocumentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        
        NSString *inputSound  = [myDocumentsDirectory stringByAppendingPathComponent:fileName];
        NSURL *inUrl = [NSURL fileURLWithPath:inputSound];

        if([mDiracAudioPlayer playing])     [mDiracAudioPlayer stop];

        if([mMediaPlayer playbackState] == MPMusicPlaybackStatePlaying) {
           
            [mMediaPlayer stop];
            [NSThread sleepForTimeInterval:0.5];
            
        }
        
        if( [songInfo.m4aURL isEqualToString:@"iCloud"] ) {
            
            if(mMediaPlayer == nil)  mMediaPlayer = [MPMusicPlayerController iPodMusicPlayer];
            
            MPMediaQuery* assetQuery = [[MPMediaQuery alloc] init];
            MPMediaPropertyPredicate* predicate = [MPMediaPropertyPredicate predicateWithValue:songInfo.songTitle forProperty:MPMediaItemPropertyTitle];
            [assetQuery addFilterPredicate:predicate];
            
            [mMediaPlayer setQueueWithQuery:assetQuery];
            
            [mMediaPlayer play];
        } else {
            
            NSError *error = nil;
            mDiracAudioPlayer = nil;
            mDiracAudioPlayer = [[DiracFxAudioPlayer alloc] initWithContentsOfURL:inUrl channels:1 error:&error];
            
            [mDiracAudioPlayer setDelegate:self];
            [mDiracAudioPlayer setDelegate:self];
            [mDiracAudioPlayer setNumberOfLoops:0];
            
            [mDiracAudioPlayer play];
            [self changeSongDuration];
            
        }
    }
}

-(void)stopSong
{
    //NSLog(@"playingIndex(%d)", playingIndex);
    
    if([m_songList count] <= 0) return;
    
    MySongInfo* songInfo = [m_songList objectAtIndex:playingIndex];
    if( songInfo ) {

        if( [songInfo.m4aURL isEqualToString:@"iCloud"] ) {

            //if(mMediaPlayer == nil)  mMediaPlayer = [MPMusicPlayerController iPodMusicPlayer];
            [mMediaPlayer stop];
        } else {

            [mDiracAudioPlayer stop];
        }
    }
}

-(void)nextSong
{
    if([m_songList count] <= 0) return;

    playingIndex++;
    if( playingIndex >= [m_songList count] ) playingIndex = 0;

    [self playSong];
}

-(void)rewindSong
{
    if([m_songList count] <= 0) return;

    playingIndex--;
    if( playingIndex < 0 ) playingIndex = [m_songList count] - 1;
    
    [self playSong];
}

- (IBAction) aMethod:(id)sender
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    
    picker.delegate						= self;
    picker.allowsPickingMultipleItems	= YES;
    picker.prompt						= NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault animated: YES];
    
    UIViewController* myController = [self getMyController];
    if( myController ) {
        
        [myController presentViewController:picker animated:YES completion:nil];
    }
}

-(void)showMenu:(id)sender
{
    [self.tableView reloadData];
    
    [self.tableView setHidden:NO];
    [addSongBtn setHidden:NO];
    [editBtn setHidden:NO];
    [backBtn setHidden:NO];
    [songListBtn setHidden:YES];
}

-(void)closeMenu:(id)sender
{
    [self.tableView setHidden:YES];
    [addSongBtn setHidden:YES];
    [editBtn setHidden:YES];
    [backBtn setHidden:YES];
    [songListBtn setHidden:NO];
}

-(UIViewController *) getMyController {
    
    Class vcc = [UIViewController class];
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass: vcc]) {
            
            return (UIViewController *)responder;
        }
    }
    
    return nil;
}


#pragma mark Media item picker delegate methods________

// Invoked when the user taps the Done button in the media item picker after having chosen
//		one or more media items to play.
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection {
    
    // Dismiss the media item picker.
    UIViewController* myController = [self getMyController];
    if( myController ) {
        
        [myController dismissViewControllerAnimated:YES completion:nil];
	}
    
	// Apply the chosen songs to the music player's queue.
	[self updatePlayerQueueWithMediaCollection: mediaItemCollection];
    
	[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
}

// Invoked when the user taps the Done button in the media item picker having chosen zero
//		media items to play
- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker {
    
    // Dismiss the media item picker.
    UIViewController* myController = [self getMyController];
    if( myController ) {
        
        [myController dismissViewControllerAnimated:YES completion:nil];
	}
    
	[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
}


- (void) updatePlayerQueueWithMediaCollection: (MPMediaItemCollection *) mediaItemCollection {
    
	if (mediaItemCollection) {
        
		if (userMediaItemCollection == nil) {
            
			// apply the new media item collection as a playback queue for the music player
			//[self setUserMediaItemCollection: mediaItemCollection];
            
            for(int i=0; i<[[mediaItemCollection items] count]; i++ ) {
                
                MPMediaItem *item = [[mediaItemCollection items] objectAtIndex:i];
                //NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
                NSString *persistentID = [[item valueForProperty:MPMediaItemPropertyPersistentID] stringValue];
                
                // 檢查是否已經在列表中
                BOOL isExist = NO;
                for(int j=0; j<[m_songList count]; j++){
                    
                    MySongInfo* songInfo = [m_songList objectAtIndex:j];
                    if( [songInfo.songID isEqualToString:persistentID] ) {

                        //NSLog(@"is Exist!! songID(%@) songTitle(%@)", songInfo.songID, songInfo.songTitle);
                        isExist = YES;
                    }
                }
                
                if( isExist == NO ) {

                    NSString *songID = [[item valueForProperty:MPMediaItemPropertyPersistentID] stringValue];
                    NSString *songTitle = [item valueForProperty: MPMediaItemPropertyTitle];
                    NSString *songArt = [item valueForProperty: MPMediaItemPropertyArtist];
                    NSURL *assetURL = [item valueForProperty: MPMediaItemPropertyAssetURL];
                    NSString *songBPM = [[item valueForProperty: MPMediaItemPropertyBeatsPerMinute] stringValue];
                    if( songBPM == nil || [songBPM isEqualToString:@"0"] )   songBPM = @"100";
                    
                    MPMediaItemArtwork *artWork = [item valueForProperty: MPMediaItemPropertyArtwork];
                    UIImage *img = [artWork imageWithSize:CGSizeMake(160.0f, 160.0f)];
                    NSData *songImg = UIImagePNGRepresentation(img);

                    
                    BOOL isCloudItem = [[item valueForProperty: MPMediaItemPropertyIsCloudItem] boolValue];
                    if(isCloudItem == YES) {
                        NSLog(@"IS CloudItem");
                    } else {
                        NSLog(@"NOT CloudItem");
                    }
                    
                    NSLog (@"songID(%@) songTitle(%@) songArt(%@) songBPM(%@) assetURL(%@) ", songID, songTitle, songArt, songBPM, [assetURL absoluteString]);

                    NSString *songM4a = @"";
                    //if( assetURL == nil ) {
                    if(isCloudItem == YES || assetURL == nil) {

                        songM4a = @"iCloud";
    
                        // 存入資料庫
                        [m_coreData addDataToSongList:songID withTitle:songTitle withArt:songArt withImg:songImg withAssetURL:[assetURL absoluteString] withM4aURL:@"iCloud" withBpm:songBPM];
                    } else {

                        // 加入批次處理轉檔列表
                        [m_preparingList setObject:item forKey:songID];
                    }

                    // 加入歌單
                    MySongInfo *songInfo = [[MySongInfo alloc] init];
                    songInfo.songID = songID;
                    songInfo.songTitle = songTitle;
                    songInfo.songArt = songArt;
                    songInfo.songImg = songImg;
                    songInfo.assetURL = [assetURL absoluteString];
                    songInfo.m4aURL = songM4a;
                    songInfo.bpm = songBPM;

                    //int old_count = [m_songList count];
                    [m_songList addObject:songInfo];

                    // 更新列表
                    [self getSongList];
                }
            }

            // 進行批次轉檔處理
            [self preparingIpodMusicToM4a];
		}
	}
}

- (void)preparingIpodMusicToM4a
{
    NSArray *allKeys = [m_preparingList allKeys];
    if([allKeys count] <= 0)    return;

    id key = [[m_preparingList allKeys] objectAtIndex:0];
    id object = [m_preparingList objectForKey:key];

    //NSLog(@"key(%@) object(%@)", key, object);
    [self converIpodMusicToM4a:object];
}


-(void) converIpodMusicToM4a:(MPMediaItem *)song {
    
    NSString *songID = [[song valueForProperty:MPMediaItemPropertyPersistentID] stringValue];
    NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
    NSString *songArt = [song valueForProperty: MPMediaItemPropertyArtist];
    NSURL *assetURL = [song valueForProperty: MPMediaItemPropertyAssetURL];
    NSString *songBPM = [[song valueForProperty: MPMediaItemPropertyBeatsPerMinute] stringValue];
    if( songBPM == nil || [songBPM isEqualToString:@"0"] )   songBPM = @"100";
    
    
    MPMediaItemArtwork *artWork = [song valueForProperty: MPMediaItemPropertyArtwork];
    UIImage *img = [artWork imageWithSize:CGSizeMake(160.0f, 160.0f)];
    NSData *imageData = UIImagePNGRepresentation(img);
    
    NSLog (@"songID(%@) songTitle(%@) songArt(%@) songBPM(%@) assetURL(%@) ", songID, songTitle, songArt, songBPM, [assetURL absoluteString]);
    
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL: assetURL options:nil];

    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset: songAsset
                                                                      presetName:AVAssetExportPresetAppleM4A];
    
    exporter.outputFileType =   @"com.apple.m4a-audio";
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * myDocumentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

    
    NSString *fileName = songID;
    NSString *exportFile = [myDocumentsDirectory stringByAppendingPathComponent:fileName];
    //NSLog(@"fileName(%@) exportFile(%@)", fileName, exportFile);
    
    NSURL *exportURL = [NSURL fileURLWithPath:exportFile];
    exporter.outputURL = exportURL;
    
    // do the export
    // (completion handler block omitted)
    [exporter exportAsynchronouslyWithCompletionHandler:
     ^{
         int exportStatus = exporter.status;
         
         switch (exportStatus)
         {
             case AVAssetExportSessionStatusFailed:
             {
                 NSError *exportError = exporter.error;
                 NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);

                 break;
             }
             case AVAssetExportSessionStatusCompleted:
             {
                 NSString *inputSound  = [myDocumentsDirectory stringByAppendingPathComponent:fileName];
                 NSURL *inUrl = [NSURL fileURLWithPath:inputSound];

                 NSLog (@"AVAssetExportSessionStatusCompleted(%@)", [inUrl absoluteString]);

                 // 存入資料庫
                 [m_coreData addDataToSongList:songID withTitle:songTitle withArt:songArt withImg:imageData withAssetURL:[assetURL absoluteString] withM4aURL:fileName withBpm:songBPM];

                 // 更新列表
                 for(int i=0; i<[m_songList count]; i++) {

                     MySongInfo *songInfo = [m_songList objectAtIndex:i];
                     if([songID isEqualToString:songInfo.songID]) {
 
                         songInfo.m4aURL = fileName;
                         break;
                     }
                 }

                 // 更新歌單
                 [self getSongList];

                 break;
             }
             case AVAssetExportSessionStatusUnknown:
             {
                 NSLog (@"AVAssetExportSessionStatusUnknown"); break;
             }
             case AVAssetExportSessionStatusExporting:
             {
                 NSLog (@"AVAssetExportSessionStatusExporting"); break;
             }
             case AVAssetExportSessionStatusCancelled:
             {
                 NSLog (@"AVAssetExportSessionStatusCancelled"); break;
             }
             case AVAssetExportSessionStatusWaiting:
             {
                 NSLog (@"AVAssetExportSessionStatusWaiting"); break;
             }
             default:
             {
                 NSLog (@"didn't get export status"); break;
             }
         }

         // 準備轉換下一頁歌
         [m_preparingList removeObjectForKey:songID];
         [self preparingIpodMusicToM4a];
     }];
}

- (void)changeSongDuration
{
    if([m_songList count] <= 0 || isPlaying == NO)   return;

    MySongInfo* songInfo = [m_songList objectAtIndex:playingIndex];
    if( songInfo ) {
    
        float bpm = [songInfo.bpm floatValue];
        if(bpm <= 0.0)  bpm = 100.0f;
        
        float newDuration = 1.0f;
        switch (currentPhotoNum) {
            case 0: newDuration =  bpm / 60;   break;
            case 1: newDuration =  bpm / 105;   break;
            case 2: newDuration =  bpm / 125;   break;
            case 3: newDuration =  bpm / 140;   break;
            case 4: newDuration =  bpm / 160;   break;
            default: break;
        }
        
        NSLog(@"currentPhotoNum(%d) bpm(%f) newDuration(%f)", currentPhotoNum, bpm, newDuration);

        [mDiracAudioPlayer changeDuration:newDuration];
    }
}
@end
