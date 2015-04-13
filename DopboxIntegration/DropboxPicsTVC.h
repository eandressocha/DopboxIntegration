//
//  DropboxPicsTVC.h
//  DopboxIntegration
//
//  Created by Andres Socha on 4/11/15.
//  Copyright (c) 2015 AndreSocha. All rights reserved.
//
#import <Dropbox/Dropbox.h>
#import <UIKit/UIKit.h>
#import "AccountController.h"
#import "AddPhotoVC.h"


@interface DropboxPicsTVC : UITableViewController <AccountController>
//- (id)initWithFilesystem:(DBFilesystem *)filesystem root:(DBPath *)root ;
//@property (nonatomic, strong)NSURL *photo;
@end
