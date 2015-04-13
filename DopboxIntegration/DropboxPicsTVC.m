//
//  DropboxPicsTVC.m
//  DopboxIntegration
//
//  Created by Andres Socha on 4/11/15.
//  Copyright (c) 2015 AndreSocha. All rights reserved.
//

#import "DropboxPicsTVC.h"

@interface DropboxPicsTVC ()<UIActionSheetDelegate>
@property (nonatomic, retain) DBFilesystem *filesystem;
@property (nonatomic, retain) DBPath *root;
@property (nonatomic, retain) NSMutableArray *contents;
@property (nonatomic, assign) BOOL creatingFolder;
@property (nonatomic, retain) DBPath *fromPath;
@property (nonatomic, retain) UITableViewCell *loadingCell;
@property (nonatomic, assign) BOOL loadingFiles;
@property (nonatomic, assign, getter=isMoving) BOOL moving;
@end

@implementation DropboxPicsTVC

- (id)initWithFilesystem:(DBFilesystem *)filesystem root:(DBPath *)root {
    if ((self = [super init])) {
        self.filesystem = filesystem;
        self.root = root;
        self.navigationItem.title = [root isEqual:[DBPath root]] ? @"Dropbox" : [root name];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_filesystem removeObserver:self];
}


#pragma mark - UIViewController methods

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    __weak DropboxPicsTVC *weakSelf = self;
    [_filesystem addObserver:self block:^() { [weakSelf reload]; }];
    [_filesystem addObserver:self forPathAndChildren:self.root block:^() { [weakSelf loadFiles]; }];
    [self.navigationController setToolbarHidden:NO];
    [self loadFiles];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_filesystem removeObserver:self];
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_contents) return 1;
    
    return [_contents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_contents) {
        return self.loadingCell;
    }
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    DBFileInfo *info = [_contents objectAtIndex:[indexPath row]];
    cell.textLabel.text = [info.path name];
    if (info.isFolder) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DBFileInfo *info = [_contents objectAtIndex:[indexPath row]];
    if ([_filesystem deletePath:info.path error:nil]) {
        [_contents removeObjectAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        NSLog(@"Error: There was an error deleting that file.");
        [self reload];
    }
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((NSInteger)[_contents count] <= [indexPath row]) return;
    
    DBFileInfo *info = [_contents objectAtIndex:[indexPath row]];
    
    if (!_moving) {
        UIViewController *controller = nil;
        if (info.isFolder) {
            controller = [[DropboxPicsTVC alloc] initWithFilesystem:_filesystem root:info.path];
        } else {
            DBFile *file = [_filesystem openFile:info.path error:nil];
            if (!file) {
                NSLog(@"Error: There was an error opening your note");
                return;
            }
            //controller = [[NoteController alloc] initWithFile:file];
        }
        
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        self.fromPath = info.path;
        
        UIAlertView *alertView =
        [[UIAlertView alloc]
         initWithTitle:@"Choose a destination" message:nil delegate:self
         cancelButtonTitle:@"Cancel" otherButtonTitles:@"Move", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    }
}

#pragma mark - private methods

- (void)loadFiles {
    if (_loadingFiles) return;
    _loadingFiles = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        NSArray *immContents = [_filesystem listFolder:_root error:nil];
        NSMutableArray *mContents = [NSMutableArray arrayWithArray:immContents];
//        [mContents sortUsingFunction:sortFileInfos context:NULL];
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.contents = mContents;
            _loadingFiles = NO;
            [self reload];
        });
    });
}

- (void)reload {
    [self.tableView reloadData];
    if (_filesystem.status.upload.inProgress) {
            
            UIActivityIndicatorView *activityIndicator =
            [[UIActivityIndicatorView alloc]
             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [activityIndicator startAnimating];
            UIBarButtonItem *uploadItem =
            [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
            uploadItem.style = UIBarButtonItemStylePlain;
        }
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
         target:self action:@selector(didPressAddPic)];
}

- (void)didPressAddPic {
    AddPhotoVC *controller = [[AddPhotoVC alloc] initWithFilesystem:_filesystem root:_root];
    [self.navigationController pushViewController:controller animated:YES];

}

- (void)createAt:(NSString *)input {
    if (!_creatingFolder) {
        NSString *noteFilename = [NSString stringWithFormat:@"%@.txt", input];
        DBPath *path = [_root childPath:noteFilename];
        DBFile *file = [_filesystem createFile:path error:nil];
        
        if (!file) {
            NSLog(@"Unable to create note An error has occurred");
        } else {
//            AddPhotoVC controller = [[AddPhotoVC alloc]initWithFilesystem:_filesystem root:_root];
//            [self.navigationController pushViewController:controller animated:YES];
        }
    } else {
        DBPath *path = [_root childPath:input];
        BOOL success = [_filesystem createFolder:path error:nil];
        if (!success) {
            NSLog(@"Unable to be create folder An error has occurred");
        } else {
            DropboxPicsTVC *controller =
            [[DropboxPicsTVC alloc] initWithFilesystem:_filesystem root:path];
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

- (DBAccount *)account {
    return _filesystem.account;
}

- (UITableViewCell *)loadingCell {
    if (!_loadingCell) {
        _loadingCell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        _loadingCell.textLabel.text = @"Loading...";
        _loadingCell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _loadingCell;
}

@end
