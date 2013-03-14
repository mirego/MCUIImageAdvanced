//
//  UIImage+MCRounded.h
//  MCUIImageAdvanced
//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MCRounded)

/**
 */
- (UIImage*)imageWithRoundedCornersRadius:(CGFloat)cornerRadius;

/**
 */
- (UIImage*)imageWithRoundedCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii;

/**
 */
+ (UIImage *)gradientImageWithColors:(NSArray *)colors height:(CGFloat)height cornerRadius:(CGFloat)cornerRadius edgeInsets:(UIEdgeInsets)edgeInsets;

/**
 */
+ (UIImage *)gradientImageWithColors:(NSArray *)colors width:(CGFloat)width cornerRadius:(CGFloat)cornerRadius edgeInsets:(UIEdgeInsets)edgeInsets;

@end
