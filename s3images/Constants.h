//
//  Constants.h
//  s3images
//
//  Created by dev on 1/10/14.
//  Copyright (c) 2014 dev. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RESEND_ATTEMPTS @3
#define TIMEOUT_BETWEEN_ATTEMPTS @2.0

#define AMAZON_S3_ACCESS_KEY_ID          @"AKIAIP4SADPALASOCYYQ"
#define AMAZON_S3_SECRET_KEY             @"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"

#define AMAZON_S3_PICTURE_BUCKET         @"picture-bucket"

@interface Constants : NSObject

/**
 * Utility method to create a bucket name using the Access Key Id.  This will help ensure uniqueness.
 */
+(NSString *)pictureBucket;

@end
