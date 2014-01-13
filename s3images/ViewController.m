//
//  ViewController.m
//  s3images
//
//  Created by dev on 1/9/14.
//  Copyright (c) 2014 dev. All rights reserved.
//

#import "ViewController.h"
#import "CoreData.h"

#import "UnsavedImage.h"
#import "SavedImage+custom.h"

#import "NSManagedObject+Helpers.h"
#import "NSManagedObjectContext+Helpers.h"
#import "Constants.h"
#import <AWSRuntime/AWSRuntime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    blockSelf = self;
    NSLog(@"saved images: %@", [[[CoreData sharedInstance].mainMOC
                                fetchObjectsForEntityName:@"SavedImage"
                                sortDescriptors:nil
                                limit:0
                                predicate:nil] map:^id(SavedImage *item) {
        return [NSString stringWithFormat:@"name: %@, url: %@;", item.name, item.url];
    }]);
    [self sendUnsavedImages:nil];
    
    if(self.s3 == nil)
    {
        // Initial the S3 Client.
        self.s3 = [[AmazonS3Client alloc]
                   initWithAccessKey:AMAZON_S3_ACCESS_KEY_ID
                   withSecretKey:AMAZON_S3_SECRET_KEY];
        self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
        
        NSLog(@"bucket: %@", [Constants pictureBucket]);
        
        // Create the picture bucket.
        S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc]
                                                      initWithName:[Constants pictureBucket]
                                                      andRegion:[S3Region USWest2]];
        S3CreateBucketResponse *createBucketResponse = [self.s3 createBucket:createBucketRequest];

        if(createBucketResponse.error != nil &&
           // don't show "bucket exists" error
           !([createBucketResponse.error.domain isEqual: @"com.amazonaws.iossdk.ServiceErrorDomain"] &&
             createBucketResponse.error.code == 409))
        {
            NSLog(@"Error: %@", createBucketResponse.error);
        }
    }
    
    [self launchController];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)launchController
{
    ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] init];
    elcPicker.maximumImagesCount = -1;
    elcPicker.imagePickerDelegate = self;
    
    [self presentViewController:elcPicker animated:NO completion:nil]; // <- animated NO because now I'm using it at program startup. May be changed later.
}

-(void)saveBrowserURL:(NSString*)imageName
// must be called on backgroundMOC
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // Set the content type so that the browser will treat the URL as an image.
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        override.contentType = @"image/jpeg";
        
        // Request a pre-signed URL to picture that has been uplaoded.
        S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
        gpsur.key                     = imageName;
        gpsur.bucket                  = [Constants pictureBucket];
        gpsur.expires                 = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600]; // Added an hour's worth of seconds to the current time.
        gpsur.responseHeaderOverrides = override;
        
        // Get the URL
        NSError *error = nil;
        NSURL *url = [self.s3 getPreSignedURL:gpsur error:&error];
        
        if(url == nil)
        {
            if(error != nil)
            {
                NSLog(@"Error: %@", error);
            }
        }
        else
        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                // Display the URL in Safari
//                [[UIApplication sharedApplication] openURL:url];
//            });
            [[CoreData sharedInstance].backgroundMOC performBlock:^{
                SavedImage *image =
                [SavedImage
                 newObjectWithContext:[CoreData sharedInstance].backgroundMOC
                 entity:nil];
                image.name = imageName;
                image.url = url;
                
                NSError *error = nil;
                [[CoreData sharedInstance].backgroundMOC save:&error];
                if (error)
                    NSLog(@"%@", error);
                
                NSLog(@"saved image: %@ url: %@", imageName, url);
            }];
        }
    });
}

- (void)sendUnsavedImage:(UnsavedImage*)unsavedImage withDelay:(NSNumber*)delay
{
    void (^ imageSendAttempt) (void);
    imageSendAttempt =
    ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        });
        
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc]
                                   initWithKey:unsavedImage.name
                                   inBucket:[Constants pictureBucket]];
        por.contentType = @"image/jpeg";
        por.data        = unsavedImage.data;
        
        // Put the image data into the specified s3 bucket and object.
        S3PutObjectResponse *putObjectResponse = [self.s3 putObject:por];
        
        if(putObjectResponse.error != nil)
        {
            NSLog(@"Error: %@, name: %@, attemptsLeft: %@", putObjectResponse.error, unsavedImage.name, unsavedImage.attemptsLeft);
            if(unsavedImage.attemptsLeft.intValue > 0)
            {
                unsavedImage.attemptsLeft = [NSNumber numberWithInt: unsavedImage.attemptsLeft.intValue - 1];
                [[CoreData sharedInstance].backgroundMOC save: nil];
                NSLog(@"Resending %@ with delay %@", unsavedImage.name, TIMEOUT_BETWEEN_ATTEMPTS);
                [blockSelf sendUnsavedImage:unsavedImage withDelay:TIMEOUT_BETWEEN_ATTEMPTS];
            }
            else
            {
                NSLog(@"Maximum number of attempts reached for %@", unsavedImage.name);
                [[CoreData sharedInstance].backgroundMOC deleteObject:unsavedImage];
                [[CoreData sharedInstance].backgroundMOC save: nil];
            }
        }
        else
        {
            NSLog(@"The image %@ was successfully uploaded.", unsavedImage.name);
            [blockSelf saveBrowserURL:unsavedImage.name];
            [[CoreData sharedInstance].backgroundMOC deleteObject:unsavedImage];
            [[CoreData sharedInstance].backgroundMOC save: nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    };
    if(delay)
    {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TIMEOUT_BETWEEN_ATTEMPTS.floatValue * 1000 * NSEC_PER_MSEC));
        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [[CoreData sharedInstance].backgroundMOC performBlock:imageSendAttempt];
        });

    }
    else
    {
        [[CoreData sharedInstance].backgroundMOC performBlock:imageSendAttempt];
    }
}

- (void)sendUnsavedImages:(NSArray*)unsavedImages
{
    if(unsavedImages)
        [unsavedImages enumerateObjectsUsingBlock:^(UnsavedImage *unsavedImage, NSUInteger idx, BOOL *stop) {
            [self sendUnsavedImage:unsavedImage withDelay:nil];
        }];
    else
    {
        [self sendUnsavedImages:
         [[CoreData sharedInstance].backgroundMOC
          fetchObjectsForEntityName:@"UnsavedImage"
          sortDescriptors:nil
          limit:0
          predicate:nil]];
    }
}

#pragma mark - ELC Image Picker Controller delegate methods

- (void)elcImagePickerController:(ELCImagePickerController *)picker
   didFinishPickingMediaWithInfo:(NSArray *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    int64_t now = [[NSDate date] timeIntervalSince1970]*1000000;
    
    for (NSDictionary *dict in info) {
        
    }
    NSArray *unsavedImagesIDs =
    [info
     mapWithBlockIndexed:^id(NSUInteger idx, NSDictionary *dict) {
         UIImage *image = [dict objectForKey:UIImagePickerControllerOriginalImage];
         NSData *data = [NSData dataWithData:UIImageJPEGRepresentation(image, 100)];
         NSString *name = [NSString stringWithFormat:@"%lld_%d", now, idx];
         UnsavedImage *unsavedImage = [UnsavedImage
                                       newObjectWithContext:[CoreData sharedInstance].mainMOC
                                       entity:nil];
         
         unsavedImage.data = data;
         unsavedImage.name = name;
         unsavedImage.attemptsLeft = RESEND_ATTEMPTS;
         
         return unsavedImage.objectID;
     }];
    
    NSError *error = nil;
    [CoreData save:&error];
    if(error)
        NSLog(@"%@", error);
    
    NSArray *unsavedImages =
    [unsavedImagesIDs map:^id(NSManagedObjectID *item) {
        return [[CoreData sharedInstance].backgroundMOC objectWithID:item];
    }];
    
    [self sendUnsavedImages:unsavedImages];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
