//
//  ViewController.m
//  DopboxIntegration
//
//  Created by Andres Socha on 4/11/15.
//  Copyright (c) 2015 AndreSocha. All rights reserved.
//

#import "ViewController.h"
#import <Dropbox/Dropbox.h>
#import "AddPhotoViewController.h"

@interface ViewController ()

@end

@implementation ViewController
- (IBAction)dropBoxConnect {
    NSLog(@"Connect Button was pressed");
    //Making the call
    [[DBAccountManager sharedManager] linkFromController:self];
}

//in

//Prepare for segue modal view for the camera
//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
//    if ([segue.destinationViewController isKindOfClass:[AddPhotoViewController class]]) {
//        AddPhotoViewController *apvc = (AddPhotoViewController*)segue.destinationViewController;
//        //apvc.photographerTakingPhoto = self.photographer;
//    }
//}


//out

//Method to be called when unwinding
-(IBAction)addedPhoto :(UIStoryboardSegue *)segue{
    if ([segue.sourceViewController isKindOfClass:[AddPhotoViewController class]]) {
        NSLog(@"AddPhotoViewController unexpectedly did not add a photo");
//        AddPhotoViewController *apvc = (AddPhotoViewController *)segue.sourceViewController;
//    Photo *addedPhoto = apvc.addedPhoto;
//        if(addedPhoto){
//            //[self.mapView addAnnotation:addedPhoto];
//        }
//        else{
//            NSLog(@"AddPhotoViewController unexpectedly did not add a photo");
        }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
