//
//  ShrinkPNG.h
//  MCUIImageAdvanced
//
//  Created by Francois Lambert on 11-12-13.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//
//  Source: https://github.com/hollance/ShrinkPng
//

#import <Foundation/Foundation.h>

@interface ShrinkPNG : NSObject

+ (CGImageRef)newShrinkedImageWithCGImage:(CGImageRef)inImage;
+ (CGImageRef)newShrinkedImageWithContentsOfFile:(NSString *)filename;

@end
