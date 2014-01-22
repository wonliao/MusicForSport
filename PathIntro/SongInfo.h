//
//  RecordSongList.h
//  kBar
//
//  Created by wonliao on 13/3/25.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SongInfo : NSManagedObject

@property (nonatomic, retain) NSString *songID;
@property (nonatomic, retain) NSString *songTitle;
@property (nonatomic, retain) NSString *songArt;
@property (nonatomic, retain) NSData *songImg;
@property (nonatomic, retain) NSString *assetURL;
@property (nonatomic, retain) NSString *m4aURL;
@property (nonatomic, retain) NSString *bpm;

@end
