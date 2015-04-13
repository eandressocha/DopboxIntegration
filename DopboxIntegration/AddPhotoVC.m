//
//  AddPhotoVC.m
//  DopboxIntegration
//
//  Created by Andres Socha on 4/11/15.
//  Copyright (c) 2015 AndreSocha. All rights reserved.
//
//
//UIViewController *controller = nil;
//controller = [[AddPhotoVC alloc]initWithFilesystem:self.filesystem root: self.root];
//[self.navigationController pushViewController:controller animated:YES];
#import "DropboxPicsTVC.h"
#import "AddPhotoVC.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface AddPhotoVC () <UITextViewDelegate>

@property (nonatomic, retain)UIImageView *imagewindow;
@property (nonatomic, assign) BOOL imagewindowloaded;
@property (nonatomic, strong)UIImage *image;
@property (nonatomic, strong) NSURL *imageURL;

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) DBFile *file;
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, assign) BOOL textViewLoaded;
@property (nonatomic, retain) NSTimer *writeTimer;

@property (nonatomic, retain) DBFilesystem *filesystem;
@property (nonatomic, retain) DBPath *root;
@property (nonatomic, retain) NSMutableArray *contents;
@property (nonatomic, assign) BOOL creatingFolder;
@property (nonatomic, retain) DBPath *fromPath;
@property (nonatomic, retain) UITableViewCell *loadingCell;

@end

@implementation AddPhotoVC

- (id)initWithFilesystem:(DBFilesystem *)filesystem root:(DBPath *)root {
    if ((self = [super init])) {
        self.filesystem = filesystem;
        self.root = root;
        self.navigationItem.title = @"Add Photo";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(didPressCamera)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)];
    }
    return self;
}
//////////////////

- (void)unloadViews {
    self.imagewindow = nil;
//    self.activityIndicator = nil;
//    self.textView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imagewindow = [[UIImageView alloc]initWithFrame:self.view.bounds];
    self.imagewindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.imagewindow];
    
//    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
//    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    self.textView.delegate = self;
//    [self.view addSubview:self.textView];
    
//    self.activityIndicator = [[UIActivityIndicatorView alloc]
//                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    CGRect frame = self.activityIndicator.frame;
//    frame.origin.x = floorf(self.view.bounds.size.width/2 - frame.size.width/2);
//    frame.origin.y = floorf(self.view.bounds.size.height/2 - frame.size.height/2);
//    self.activityIndicator.frame = frame;
//    [self.view addSubview:self.activityIndicator];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    __weak AddPhotoVC *weakSelf = self;
//    [_file addObserver:self block:^() { [weakSelf reload]; }];
//    [self.navigationController setToolbarHidden:YES];
//    [self reload];
    __weak AddPhotoVC *weakSelf = self;
    [_filesystem addObserver:self block:^() { [weakSelf reload]; }];
    [self.navigationController setToolbarHidden:YES];
    [self reload];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [_file removeObserver:self];
//    [self saveChanges];
    [_filesystem removeObserver:self];
//    [self saveChanges];
}

//if ([self isPhotoAvailable]) {
//    [_file writeData:[self actualPic] error:nil];
//    [self.navigationController popViewControllerAnimated:TRUE];
//    
//}
//[self reload];

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/////////////////
#pragma mark - image related methods

-(void) setImage:(UIImage *)image{
    self.imagewindow.image = image;
    [[NSFileManager defaultManager]removeItemAtURL:_imageURL error:NULL];
    self.imageURL = nil;
}
-(UIImage *)image{
    return self.imagewindow.image;
}
-(BOOL)isPhotoAvailable{
    if (!self.image) {
        [self alert:@"No photo taken!"];
        return NO;
    }
    return YES;
}

#pragma mark - camera related methods

+(BOOL)canAddPhoto{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage]) {
            return YES;
        }
    }
    return NO;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(![[self class]canAddPhoto]){
        [self fatalAlert:@"Sorry, this device cannot add a photo."];
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

-(void)didPressCamera{
    UIImagePickerController *uiipc = [[UIImagePickerController alloc]init];
    uiipc.delegate = self;
    uiipc.mediaTypes = @[(NSString *)kUTTypeImage];
    uiipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    uiipc.allowsEditing = YES;
    [self presentViewController:uiipc animated:YES completion:NULL];
}
-(void)didPressCancel{
    self.imageURL = nil;
    [self.navigationController popViewControllerAnimated:TRUE];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) image = info[UIImagePickerControllerOriginalImage];
    self.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - file methods
-(NSURL *)uniqueNameURL{
    NSArray *documentDirectories =[[NSFileManager defaultManager]URLsForDirectory:NSDocumentationDirectory inDomains:NSUserDomainMask];
    NSString *unique = [NSString stringWithFormat:@"%.0f", floor([NSDate timeIntervalSinceReferenceDate])];
    return [[documentDirectories firstObject]URLByAppendingPathComponent:unique];
}
//-(NSURL *)imageURL{
//    if (!_imageURL && self.image) {
//        NSURL *url = [self uniqueNameURL];
//        if (url) {
//            NSData *imageData = UIImageJPEGRepresentation(self.image, 1.0);
//            if ([imageData writeToURL:url atomically:YES]) {
//                _imageURL = url;
//            }
//        }
//    }
//    return _imageURL;
//}


-(NSData *)actualPic{
    return UIImageJPEGRepresentation(self.image, 1.0);
}

-(void)createFile{    
    NSString *unique = [NSString stringWithFormat:@"%.0f", floor([NSDate timeIntervalSinceReferenceDate])];
    NSLog(@"%@", unique);
    if(unique){
    NSString *Filename = [NSString stringWithFormat:@"%@.jpg", unique];
        DBPath *newPath = [[DBPath root] childPath:Filename];
        DBFile *newfile = [[DBFilesystem sharedFilesystem] createFile:newPath error:nil];
        if (!newfile) {
            NSLog(@"Unable to create file");
            [self reload];
        }
        else {
            NSData *imageData = UIImageJPEGRepresentation(self.image, 1.0);
            [newfile writeData:imageData error:nil];
        }
        
    }

}

#pragma mark - alerts methods

-(void)fatalAlert:(NSString *)msg{
    [[[UIAlertView alloc]initWithTitle:@"Add Photo"
                               message:msg
                              delegate:self
                     cancelButtonTitle:nil
                     otherButtonTitles:@"OK", nil]show];
}

-(void)alert:(NSString *)msg{
    [[[UIAlertView alloc]initWithTitle:@"Add Photo"
                               message:msg
                              delegate:nil
                     cancelButtonTitle:nil
                     otherButtonTitles:@"OK", nil]show];
}

#pragma mark - private methods

- (void)reload {
    BOOL updateEnabled = YES;
//    if (_file.status.cached) {
//        if (!_textViewLoaded) {
//            _textViewLoaded = YES;
//            NSString *contents = [_file readString:nil];
//            self.textView.text = contents;
//        }
//        
//        [self.activityIndicator stopAnimating];
//        self.textView.hidden = NO;
//        
//        if (_file.newerStatus.cached) {
//            updateEnabled = YES;
//        }
//    } else {
//        [self.activityIndicator startAnimating];
//        self.textView.hidden = YES;
//    }
//    if (_filesystem.status.self) {
//        if (!_textViewLoaded) {
//            _textViewLoaded = YES;
            //NSString *contents = [_filesystem readString:nil];
            //self.textView.text = contents;
//        }
        
//        [self.activityIndicator stopAnimating];
//        self.textView.hidden = NO;
//        self.imagewindow.hidden = NO;
        
//        if (_file.newerStatus.cached) {
//            updateEnabled = YES;
//        }

//    }
//    else {
//        [self.activityIndicator startAnimating];
//        self.textView.hidden = YES;

//        self.imagewindow.hidden = YES;
//    }
//    self.navigationItem.rightBarButtonItem.enabled = updateEnabled;
    
    self.imagewindow.hidden = NO;
    UIBarButtonItem *cancel =
    [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(didPressCancel)];
    cancel.enabled = updateEnabled;//(_contents != nil);
    
    [self.navigationController setToolbarHidden:NO];
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackOpaque];
    
    [self setToolbarItems:[NSArray arrayWithObjects: cancel, nil]];
    self.navigationItem.rightBarButtonItem.enabled = updateEnabled;
    self.navigationItem.leftBarButtonItem.enabled = updateEnabled;
}

- (void)saveChanges {
    if (!_writeTimer) return;
    [_writeTimer invalidate];
    self.writeTimer = nil;
    
    [_file writeString:self.textView.text error:nil];
}

- (void)didPressUpdate {
    [_file update:nil];
    _textViewLoaded = NO;
    [self reload];
}
-(void)didPressDone{
    
    if ([self isPhotoAvailable]) {
        [self createFile];
        [self.navigationController popViewControllerAnimated:TRUE];
//        [_file writeData:[self actualPic] error:nil];
//        [self.navigationController popViewControllerAnimated:TRUE];
//        
////        [self createFile];
////        NSArray *viewControllers = self.navigationController.viewControllers;
////        id<AccountController> accountController =
////        (id<AccountController>)[viewControllers objectAtIndex:1];
////        DBAccount currentaccount = accountController.account;
//        DropboxPicsTVC *controller = [[DropboxPicsTVC alloc]init];
//        [self.navigationController popToViewController:controller animated:YES];
    }
    [self reload];
}

@end
