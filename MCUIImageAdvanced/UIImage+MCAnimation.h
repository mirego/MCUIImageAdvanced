//
//  UIImage+MCAnimation.h
//  MCUIImageAdvanced
//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MCAnimation)

/**
 */
+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSUInteger)imageQuantity;

/**
 */
+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSUInteger)imageQuantity resizeImages:(CGSize)resizeImages;

/**
 */
+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSUInteger)imageQuantity resizeImages:(CGSize)resizeImages mask:(NSString *)mask;

/**
 */
+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSUInteger)imageQuantity resizeImages:(CGSize)resizeImages mask:(NSString *)mask startingIndex:(NSUInteger)startingIndex;

@end
