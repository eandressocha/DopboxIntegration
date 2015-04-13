//
//  AppDelegate.m
//  DopboxIntegration
//
//  Created by Andres Socha on 4/11/15.
//  Copyright (c) 2015 AndreSocha. All rights reserved.
//
//#import "DropboxPicsTVC.h"
#import "AppDelegate.h"
#import "ViewController.h"
#import <Dropbox/Dropbox.h>
#import "SettingsTVC.h"

#define APP_KEY     @"9moiv7qedk99z7f"
#define APP_SECRET  @"e3ziwu8zf1ig2ds"

@interface AppDelegate ()
@property (nonatomic, retain) UINavigationController *rootController;
@property (nonatomic, retain) SettingsTVC *settingsController;
@end

@implementation AppDelegate

+ (AppDelegate *)sharedDelegate {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //Creating a DBAccountManager object
    DBAccountManager* accountMgr = [[DBAccountManager alloc]
                                    initWithAppKey:APP_KEY
                                    secret:APP_SECRET];
    [DBAccountManager setSharedManager:accountMgr];
    
    //Account already linked check
    if (accountMgr.linkedAccount) {
        [self checkAccountandCreateFileSystem:accountMgr.linkedAccount];
    }
    _settingsController = [[SettingsTVC alloc] init];
    DBAccount *account = [accountMgr.linkedAccounts objectAtIndex:0];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:_settingsController];
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        DropboxPicsTVC *piclistcontroller =
        [[DropboxPicsTVC alloc]initWithFilesystem:filesystem root:[DBPath root]];
        [nav pushViewController:piclistcontroller animated:NO];
    }
    self.rootController = nav;
    
    self.window.rootViewController = nav;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(BOOL)checkAccountandCreateFileSystem:(DBAccount *)account{
    //Checking the account is linked
    if (!account || !account.linked) {
        NSLog(@"No account linked\n");
        return NO;
    }
    //Create a file system if there is no file system created
    DBFilesystem *dropboxfilesystem = [DBFilesystem sharedFilesystem];
    if(!dropboxfilesystem){
        dropboxfilesystem = [[DBFilesystem alloc]initWithAccount:account];
        [DBFilesystem setSharedFilesystem:dropboxfilesystem];
    }
    return YES;
}

//Handling request sent by controller action
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        DropboxPicsTVC *folderController =
        [[DropboxPicsTVC alloc] initWithFilesystem:filesystem root:[DBPath root]];
        [self.rootController pushViewController:folderController animated:YES];
    }
    
    return YES;
}
//-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)source annotation:(id)annotation{
//    DBAccount *account = [[DBAccountManager sharedManager]handleOpenURL:url];
//    if(account){
//        NSLog(@"All linked successfully");
//        [self checkAccountandCreateFileSystem:account];

        
//        //Creating a file system if it does not exist
//        DBFilesystem *filesystem = [DBFilesystem sharedFilesystem];
//        
//        if (!filesystem) {
//            filesystem = [[DBFilesystem alloc] initWithAccount:account];
//            [DBFilesystem setSharedFilesystem:filesystem];
//        }
        
//        //List contents in a folder from the filesystem
//        DBError *error = nil;
//        NSArray *contents = [filesystem listFolder:[DBPath root] error:&error];
//        if (!contents){
//            NSLog(@"Error listing root folder");
//            return YES;
//        }
//        
//        for (DBFileInfo *info in contents) {
//            NSString *fileInfoLine = [NSString stringWithFormat:@"    %@, %@\n",
//                                      info.path, info.modifiedTime];
//            NSLog(@"file content: %@", fileInfoLine);
//        }
        
//        return YES;
//    }
//    return NO;
//}
@end
