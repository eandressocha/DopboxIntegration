//
//  AddPhotoVC.m
//  DopboxIntegration
//
//  Created by Andres Socha on 4/11/15.
//  Copyright (c) 2015 AndreSocha. All rights reserved.
//
//
#import "DropboxPicsTVC.h"
#import "AddPhotoVC.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface AddPhotoVC () <UITextViewDelegate>

@property (nonatomic, retain)UIImageView *imagewindow;
@property (nonatomic, strong)UIImage *image;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, retain) DBFilesystem *filesystem;
@property (nonatomic, retain) DBPath *root;


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

#pragma mark - ViewController lifecycle related methods

- (void)unloadViews {
    self.imagewindow = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imagewindow = [[UIImageView alloc]initWithFrame:self.view.bounds];
    self.imagewindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.imagewindow];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    __weak AddPhotoVC *weakSelf = self;
    [_filesystem addObserver:self block:^() { [weakSelf reload]; }];
    [self.navigationController setToolbarHidden:YES];
    [self reload];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_filesystem removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

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

-(void)didPressDone{
    
    if ([self isPhotoAvailable]) {
        [self createFile];
        [self.navigationController popViewControllerAnimated:TRUE];

    }
    [self reload];
}

@end
