//
//  UnsavedImage.h
//  s3images
//
//  Created by dev on 1/10/14.
//  Copyright (c) 2014 dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UnsavedImage : NSManagedObject

@property (nonatomic, retain) NSNumber * attemptsLeft;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * name;

@end
