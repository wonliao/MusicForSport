//
//  CoreData.h
//  kBar
//
//  Created by wonliao on 13/3/25.
//
//

#import <Foundation/Foundation.h>



@interface CoreData : NSObject {

    // 增加Core Data的成員變數
    NSManagedObjectContext *m_manageObjectContext;
    NSManagedObjectModel *m_manageObjectModel;
    NSPersistentStoreCoordinator *m_persistentStoreCoordinator;
}

@property (strong, nonatomic) NSManagedObjectContext *m_manageObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *m_manageObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *m_persistentStoreCoordinator;

// 將物件同步進Core Data
- (void) saveContext;
// 傳回這個應用程式目錄底下的Documents子目錄
- (NSURL *) applicationDocumentsDirectory;
// 傳回這個應用程式中管理資料庫的Persistent Store Coordinator物件
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator;
// 傳回這個應用程式中的物件模型管理員，負責讀取data model
- (NSManagedObjectModel *) managedObjectModel;
// 傳回這個應用程式的物件文本管理員，用來作物件的同步
- (NSManagedObjectContext *) managedObjectContext;




// 歌曲 資料庫管理
- (BOOL) checkSongList;
- (void) clearSongList;
- (void) removeOneSong:(NSString *)songID;
- (void) addDataToSongList:(NSString *)songID withTitle:(NSString *)songTitle withArt:(NSString *)songArt withImg:(NSData *)songImg withAssetURL:(NSString *)assetURL withM4aURL:(NSString *)m4aURL withBpm:(NSString *)bpm;
- (id) loadDataFromSongList;

@end
