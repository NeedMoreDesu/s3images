//
//  Constants.m
//  s3images
//
//  Created by dev on 1/10/14.
//  Copyright (c) 2014 dev. All rights reserved.
//

#import "Constants.h"

@implementation Constants

+(NSString *)pictureBucket
{
    return [[NSString stringWithFormat:@"%@-%@", AMAZON_S3_PICTURE_BUCKET, AMAZON_S3_ACCESS_KEY_ID] lowercaseString];
}

@end
