#import <UIKit/UIKit.h>
#import "CoreData.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    CoreData *m_coreData;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CoreData *m_coreData;


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

@end
