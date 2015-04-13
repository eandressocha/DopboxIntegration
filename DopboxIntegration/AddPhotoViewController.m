//
//  AddPhotoViewController.m
//  DopboxIntegration
//
//  Created by Andres Socha on 4/11/15.
//  Copyright (c) 2015 AndreSocha. All rights reserved.
//

#import "AddPhotoViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface AddPhotoViewController ()<UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong)UIImage *image;
@property (nonatomic, strong) NSURL *imageURL;

@end

@implementation AddPhotoViewController

//@synthesize imageURL = _imageURL;

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
    }
}
-(void) setImage:(UIImage *)image{
    self.imageView.image = image;
    [[NSFileManager defaultManager]removeItemAtURL:_imageURL error:NULL];
    self.imageURL = nil;
}
-(UIImage *)image{
    return self.imageView.image;
}
- (IBAction)cancel {
    self.imageURL = nil;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}
- (IBAction)takePhoto {
    UIImagePickerController *uiipc = [[UIImagePickerController alloc]init];
    uiipc.delegate = self;
    uiipc.mediaTypes = @[(NSString *)kUTTypeImage];
    uiipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    uiipc.allowsEditing = YES;
    [self presentViewController:uiipc animated:YES completion:NULL];
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
- (IBAction)done {
}

#define UNWIND_SEGUE_IDENTIFIER @"Do Add Photo"
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
//        //NSManagedObjectContext *context = self.photographerTakingPhoto.manageObjectContext; //Must create a handle in the database
////        if (context) {
////            Photo *photo = //create a photo
////        }
//    }
    
    //Save image before unwinding back to the main view controller
    
        //out = photo;
    self.imageURL = nil;
    
}
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    if ([identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
        if (!self.image) {
            [self alert:@"No photo taken!"];
            return NO;
        }
        return YES;
    }
        
    else{
        return [super shouldPerformSegueWithIdentifier: identifier sender:sender];
    }
}

-(void)alert:(NSString *)msg{
    [[[UIAlertView alloc]initWithTitle:@"Add Photo"
                               message:msg
                              delegate:nil
                     cancelButtonTitle:nil
                     otherButtonTitles:@"OK", nil]show];
}

-(void)fatalAlert:(NSString *)msg{
    [[[UIAlertView alloc]initWithTitle:@"Add Photo"
                               message:msg
                              delegate:self
                     cancelButtonTitle:nil
                     otherButtonTitles:@"OK", nil]show];
}
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [self cancel];
}
-(NSURL *)uniqueNameURL{
    NSArray *documentDirectories =[[NSFileManager defaultManager]URLsForDirectory:NSDocumentationDirectory inDomains:NSUserDomainMask];
    NSString *unique = [NSString stringWithFormat:@"%.0f", floor([NSDate timeIntervalSinceReferenceDate])];
    return [[documentDirectories firstObject]URLByAppendingPathComponent:unique];
}
-(NSURL *)imageURL{
    if (!_imageURL && self.image) {
        NSURL *url = [self uniqueNameURL];
        if (url) {
            NSData *imageData = UIImageJPEGRepresentation(self.image, 1.0);
            if ([imageData writeToURL:url atomically:YES]) {
                _imageURL = url;
            }
        }
    }
    return _imageURL;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
@end
