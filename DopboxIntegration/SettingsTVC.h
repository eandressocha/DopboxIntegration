//
//  SettingsTVC.h
//  DopboxIntegration
//
//  Created by Andres Socha on 4/11/15.
//  Copyright (c) 2015 AndreSocha. All rights reserved.
//
#import <Dropbox/Dropbox.h>
#import <UIKit/UIKit.h>

@interface SettingsTVC : UITableViewController
- (void)showDataForAccount:(DBAccount*)account fileSystem:(DBFilesystem*)filesystem;
@end
