//
//  SavedImage+custom.m
//  s3images
//
//  Created by dev on 1/13/14.
//  Copyright (c) 2014 dev. All rights reserved.
//

#import "SavedImage+custom.h"

@implementation SavedImage (custom)

- (NSURL*)url
{
    return [NSURL URLWithString:self.urlString];
}

- (void)setUrl:(NSURL *)url
{
    self.urlString = url.absoluteString;
}

@end
