//
//  UIImage+MCRetina.h
//  MCUIImageAdvanced
//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MCRetina)

/**
 */
+ (UIImage *)imageNamedRetina:(NSString *)name;

/**
 */
+ (UIImage *)imageNamedRetina:(NSString *)name useMemoryCache:(BOOL)useMemoryCache;

/**
 */
+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor;

/**
 */
+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode;

/**
 */
+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayName:(NSString *)overlayName shadowName:(NSString *)shadowName;

/**
 */
+ (UIImage*)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode overlayName:(NSString *)overlayName shadowName:(NSString *)shadowName;

/** Pre-shrink all @2x image in background
 *  progressBlock will be called with index and count set to -1 if nothing is to be done (no need to warmup images)
 */
+ (void)imageNamedRetinaWarmupWithProgressBlock:(void (^)(NSString* imageName, NSUInteger index, NSUInteger count))progressBlock;

/**
 */
- (UIImage *)scaledImageFromScale:(CGFloat)fromScale;

/**
 */
- (UIImage *)scaledImageFromScale:(CGFloat)fromScale toScale:(CGFloat)toScale;

@end
