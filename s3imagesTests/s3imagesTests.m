//
//  s3imagesTests.m
//  s3imagesTests
//
//  Created by dev on 1/9/14.
//  Copyright (c) 2014 dev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ViewController.h"
#import "CoreData.h"
#import "UnsavedImage.h"
#import "SavedImage+custom.h"

@interface s3imagesTests : XCTestCase

@end

@implementation s3imagesTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testViewControllerIsProperlyLoaded
{
    ViewController *vc = [[ViewController alloc] init];
    [vc view];
    XCTAssertNotNil(vc.s3, @"Should load properly");
}

- (void)testSendImageWith0AttemptsIn1Sec
{
    ViewController *vc = [[ViewController alloc] init];
    [vc view];
    
    NSString *key = @"123";
    NSData *data = [@"qwe" dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSArray *previouslySavedArray =
    [[CoreData sharedInstance].mainMOC
     fetchObjectsForEntityName:@"SavedImage"
     sortDescriptors:nil
     limit:0
     predicate:@"name = %@", key];
    if(previouslySavedArray.count > 0)
    {
        SavedImage *previouslySaved = previouslySavedArray[0];
        [[CoreData sharedInstance].mainMOC deleteObject:previouslySaved];
        NSError *error = nil;
        [[CoreData sharedInstance].mainMOC save:&error];
        XCTAssertNil(error, @"Error during saving");
    }
    
    [[CoreData sharedInstance].backgroundMOC performBlock:^{
        UnsavedImage *unsaved = [UnsavedImage
                                 newObjectWithContext:[CoreData sharedInstance].backgroundMOC
                                 entity:nil];
        unsaved.name = key;
        unsaved.data = data;
        unsaved.attemptsLeft = @0;
        
        [vc
         sendUnsavedImage:unsaved
         withDelay:nil];
    }];
    
    [NSThread sleepForTimeInterval:1.0f];
    
    NSArray *savedArray =
    [[CoreData sharedInstance].mainMOC
     fetchObjectsForEntityName:@"SavedImage"
     sortDescriptors:nil
     limit:0
     predicate:@"name = %@", key];
    if(savedArray.count > 0)
    {
        XCTFail(@"Finished successfylly with 0 attempts");
    }
    
}

- (void)testSendImageWith1AttemptIn1Sec
{
    ViewController *vc = [[ViewController alloc] init];
    [vc view];
    
    NSString *key = @"123";
    NSData *data = [@"qwe" dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSArray *previouslySavedArray =
    [[CoreData sharedInstance].mainMOC
     fetchObjectsForEntityName:@"SavedImage"
     sortDescriptors:nil
     limit:0
     predicate:@"name = %@", key];
    if(previouslySavedArray.count > 0)
    {
        SavedImage *previouslySaved = previouslySavedArray[0];
        [[CoreData sharedInstance].mainMOC deleteObject:previouslySaved];
        NSError *error = nil;
        [[CoreData sharedInstance].mainMOC save:&error];
        XCTAssertNil(error, @"Error during saving");
    }
    
    [[CoreData sharedInstance].backgroundMOC performBlock:^{
        UnsavedImage *unsaved = [UnsavedImage
                                 newObjectWithContext:[CoreData sharedInstance].backgroundMOC
                                 entity:nil];
        unsaved.name = key;
        unsaved.data = data;
        unsaved.attemptsLeft = @1;
        
        [vc
         sendUnsavedImage:unsaved
         withDelay:nil];
    }];
    
    [NSThread sleepForTimeInterval:1.0f];
    
    NSArray *savedArray =
    [[CoreData sharedInstance].mainMOC
     fetchObjectsForEntityName:@"SavedImage"
     sortDescriptors:nil
     limit:0
     predicate:@"name = %@", key];
    if(savedArray.count > 0)
    {
        SavedImage *savedImage = savedArray[0];
        XCTAssert(savedImage.url, @"No url associated with saved image");
        NSData *obtainedData = [NSData dataWithContentsOfURL:savedImage.url];
        XCTAssert([obtainedData isEqualToData:data], @"data stored on s3 is not equal to sent data");
    }
    else
    {
        XCTFail(@"No saved image for name %@", key);
    }
    
}

@end
