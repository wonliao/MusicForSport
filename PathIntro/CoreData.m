//
//  CoreData.m
//  kBar
//
//  Created by wonliao on 13/3/25.
//
//
#import "CoreData.h"
#import "SongInfo.h"  // 可錄歌曲列表的資料庫互動類別


@implementation CoreData

@synthesize m_manageObjectContext;
@synthesize m_manageObjectModel;
@synthesize m_persistentStoreCoordinator;


// 傳回這個應用程式目錄底下的Documents子目錄
- (NSURL *) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager]
             URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask] lastObject];
}

// 傳回這個應用程式中管理資料庫的Persistent Store Coordinator物件
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
    // 如果已經初始化就直接傳回
    if( m_persistentStoreCoordinator != nil ) {

        return m_persistentStoreCoordinator;
    }

    // 從Documents目錄下指定物件的路徑
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"data.sqlite"];

    NSError *error = nil;

    // 初始化並傳回
    m_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if( ![m_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {

        NSLog( @"在存取資料庫時發生不可預期的錯誤 %@, %@", error, [error userInfo]);
    }

    return m_persistentStoreCoordinator;
}

// 傳回這個應用程式中的物件模型管理員，負責讀取data model
- (NSManagedObjectModel *) managedObjectModel
{
    // 如果物件已經初始化過就直接回傳
    if( m_manageObjectModel != nil ) {

        return m_manageObjectModel;
    }

    // 沒有的話就直接載入該檔案之後回傳
    // 在URLForResource中傳入書名
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"myCoreData" withExtension:@"momd"];

    // 從Model檔案中實例化m_managedObjectModel
    m_manageObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    return m_manageObjectModel;
}

// 傳回這個應用程式的物件文本管理員，用來作物件的同步
- (NSManagedObjectContext *) managedObjectContext
{
    // 如果物件已經初始化就直接回傳
    if( m_manageObjectContext != nil ) {

        return m_manageObjectContext;
    }

    // 不然就使用persistentStoreCoordinator從資料庫中讀取
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    if( coordinator != nil ) {

        m_manageObjectContext = [[NSManagedObjectContext alloc] init];
        [m_manageObjectContext setPersistentStoreCoordinator:coordinator];
    }

    return m_manageObjectContext;
}

// 將物件同步進Core Data
- (void) saveContext
{
    NSError *error = nil;

    // 取得NSManagedObjectContext物件
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];

    // 如果存在就進行儲存的動作
    if( managedObjectContext != nil ) {

        // 如果資料有變更就進行儲存
        if( [managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {

            //資料儲存發生錯誤
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (BOOL) checkSongList
{
    // 設定從Core Data框架中取出Beverage的Entity
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SongList" inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];

    NSError* error = nil;
    // 執行存取的指令並且將資料載入returnObjs
    NSMutableArray* returnObjs = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
    if( returnObjs && [returnObjs count] > 0 ) return YES;

    return NO;
}

- (void) clearSongList
{
    // 設定從Core Data框架中取出Beverage的Entity
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SongList" inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];

    NSError* error = nil;
    // 執行存取的指令並且將資料載入returnObjs
    NSMutableArray* returnObjs = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];

    // 刪除全部
    for( SongInfo* currentSongInfo in returnObjs ) {

        [[self managedObjectContext] deleteObject: currentSongInfo];
    }
}

// 刪除歌的資料
- (void) removeOneSong:(NSString *)songID
{
    // 設定從Core Data框架中取出Beverage的Entity
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SongList" inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];
    
    NSError* error = nil;
    // 執行存取的指令並且將資料載入returnObjs
    NSMutableArray* returnObjs = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
    
    // 刪除
    for( SongInfo* currentSongInfo in returnObjs ) {
        
        if( [currentSongInfo.songID isEqualToString: songID] ) {
            
            [[self managedObjectContext] deleteObject: currentSongInfo];
            
        }
    }

    [self saveContext];
}


- (void) addDataToSongList:(NSString *)songID withTitle:(NSString *)songTitle withArt:(NSString *)songArt withImg:(NSData *)songImg withAssetURL:(NSString *)assetURL withM4aURL:(NSString *)m4aURL withBpm:(NSString *)bpm
{
    NSError* error = nil;

    // 設定從Core Data框架中取出Beverage的Entity
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SongList" inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];

    // 執行存取的指令並且將資料載入returnObjs
    NSMutableArray* returnObjs = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];

    // 刪除 songID 重覆的資料
    for( SongInfo* currentSongInfo in returnObjs ) {

        if( [currentSongInfo.songID isEqualToString: songID] ) {

            [[self managedObjectContext] deleteObject: currentSongInfo];
        }
    }

    // 新增一個entity
    SongInfo *songInfo = (SongInfo*)[NSEntityDescription insertNewObjectForEntityForName:@"SongList" inManagedObjectContext:[self managedObjectContext]];
    songInfo.songID = songID;
    songInfo.songTitle = songTitle;
    songInfo.songArt = songArt;
    songInfo.songImg = songImg;
    songInfo.assetURL = assetURL;
    songInfo.m4aURL = m4aURL;
    songInfo.bpm = bpm;
    

    // 準備將Entity存進Core Data
    if( ![[self managedObjectContext] save:&error]) {
        
        NSLog(@"新增遇到錯誤");
    }
}

- (id) loadDataFromSongList
{
    // 設定從Core Data框架中取出Beverage的Entity
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SongList" inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];
/*
    NSSortDescriptor * firstNameDescriptor;
    firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createTime"
                                                      ascending:YES
                                                       selector:@selector(localizedCaseInsensitiveCompare:)];
    [request setSortDescriptors:[NSArray arrayWithObjects:firstNameDescriptor, nil]];
*/
    NSError* error = nil;
    // 執行存取的指令並且將資料載入returnObjs
    NSMutableArray* returnObjs = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];

    return returnObjs;
}


@end
