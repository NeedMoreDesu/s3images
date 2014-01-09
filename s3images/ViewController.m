//
//  ViewController.m
//  s3images
//
//  Created by dev on 1/9/14.
//  Copyright (c) 2014 dev. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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



#pragma mark - ELC Image Picker Controller delegate methods

- (void)elcImagePickerController:(ELCImagePickerController *)picker
   didFinishPickingMediaWithInfo:(NSArray *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];

    int now = [[NSDate date] timeIntervalSince1970];
    
    for (NSDictionary *dict in info) {
    }
    NSLog(@"%@", [info mapWithBlockIndexed:^id(NSUInteger idx, NSDictionary *dict) {
        UIImage *image = [dict objectForKey:UIImagePickerControllerOriginalImage];
        NSData *data = [NSData dataWithData:UIImageJPEGRepresentation(image, 100)];
        NSString *name = [NSString stringWithFormat:@"%d_%d", now, idx];
        /// todo
        return unsavedImage;
    }]);
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
