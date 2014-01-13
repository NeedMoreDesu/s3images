//
//  ViewController.h
//  s3images
//
//  Created by dev on 1/9/14.
//  Copyright (c) 2014 dev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ELCImagePickerController/ELCImagePickerController.h>
#import <AWSS3/AWSS3.h>

#import "UnsavedImage.h"

@interface ViewController : UIViewController
<ELCImagePickerControllerDelegate>
{
    __block ViewController *blockSelf;
}

@property (nonatomic, retain) AmazonS3Client *s3;

- (void)sendUnsavedImage:(UnsavedImage*)unsavedImage withDelay:(NSNumber*)delay;

@end
