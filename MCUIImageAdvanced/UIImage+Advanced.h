//
//  UIImage+Advanced.h
//  MCUIImageAdvanced
//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(Advanced)

/////////////////////////////////////////////////////
#pragma mark methods resizing images
/////////////////////////////////////////////////////
/** @name Resizing and Cropping
 */

/**
 */
- (UIImage*)resizedImageToSize:(CGSize)size;

/**
 */
- (UIImage*)resizedImageToSize:(CGSize)size opaque:(BOOL)opaque;

/**
 */
- (UIImage*)resizedImageToSize:(CGSize)size opaque:(BOOL)opaque inSize:(CGSize)inSize;

/**
 */
- (UIImage*)resizedImageToSize:(CGSize)size opaque:(BOOL)opaque inSize:(CGSize)inSize backgroundColor:(UIColor *)backgroundColor;

/**
 */
- (UIImage*)resizedImageToSize:(CGSize)size opaque:(BOOL)opaque inSize:(CGSize)inSize backgroundColor:(UIColor *)backgroundColor foregroundColor:(UIColor *)foregroundColor;

/**
 */
- (CGSize)proportionalSizeScaledToSize:(CGSize)targetSize;

/**
 */
+ (CGSize)proportionalSizeForSize:(CGSize)imageSize scaledToSize:(CGSize)targetSize;

/**
 */
- (UIImage*)croppedImageToRect:(CGRect)rect;

/**
 */
- (UIImage*)imageWithRoundedCornersRadius:(CGFloat)cornerRadius;

/**
 */
- (UIImage*)imageWithRoundedCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii;

//////////////////////////////////////////////////////////////
#pragma mark Image and color blending
//////////////////////////////////////////////////////////////
/** @name Blending
 */

/** Create an image resulting of a blend of the main image and all
 *  given layers.
 *
 *  @see blendedImageWithImage:layers:blendModes:defaultBlendMode:
 */
+ (UIImage*)blendedImageWithImage:(UIImage*)image
                           layers:(NSArray*)layers
                        blendMode:(CGBlendMode)blendMode;

/** Create an image resulting of a blend of the main image and all
 *  given layers.
 * 
 *  @param The main image on which every layers are drawn.
 *  @param Each item is a layer of type UIColor or UIImage.
 *         The last item is the top most layer.
 *         Use the UIColor alpha value to control the transparency.
 * 
 *  @param Array allowing to override the default blend mode for every layers.
 *         Use NSNumber with int values.
 * 
 *         If the item quantity is lower than the layer array, the default blend
 *         mode will be used for the last layers.
 * 
 *         If the item quantity is equal to the layer array, the default blend
 *         mode is ignored.
 * 
 *         If the item quantity is higher to the layer array, the last items are 
 *         ignored and the default blend mode is also ignored.
 * 
 *  @param Default blend mode used when not specified for a layer in the array.
 *         Not used if a blend mode is specified for every layers.
 */
+ (UIImage*)blendedImageWithImage:(UIImage*)image
                           layers:(NSArray*)layers
                       blendModes:(NSArray*)blendModes
                 defaultBlendMode:(CGBlendMode)defaultBlendMode;

/** Create an image resulting of a blend of the main image and all
 *  given layers.
 *
 *  @see blendedImageWithImage:layers:blendModes:defaultBlendMode:
 */
+ (void)blendedImageInContext:(CGContextRef)context
                     withRect:(CGRect)rect
                        image:(UIImage*)image
                       layers:(NSArray*)layers
                   blendModes:(NSArray*)blendModes
             defaultBlendMode:(CGBlendMode)defaultBlendMode;

//////////////////////////////////////////////////////////////
#pragma mark
//////////////////////////////////////////////////////////////
/** @name Loading
 */

/**
 */
+ (UIImage*)imageNamedNoCache:(NSString *)name;

/**
 */
+ (UIImage*)imageNamedRetina:(NSString *)name;

/**
 */
+ (UIImage*)imageNamedRetina:(NSString *)name useMemoryCache:(BOOL)useMemoryCache;

/**
 */
+ (UIImage*)imageNamedRetina:(NSString *)name tintColor:(UIColor*)tintColor;

/**
 */
+ (UIImage*)imageNamedRetina:(NSString *)name tintColor:(UIColor*)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode;

/**
 */
+ (UIImage*)imageNamedRetina:(NSString *)name tintColor:(UIColor*)tintColor overlayName:(NSString *)overlayName shadowName:(NSString*)shadowName;

/**
 */
+ (UIImage*)imageNamedRetina:(NSString *)name tintColor:(UIColor*)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode overlayName:(NSString *)overlayName shadowName:(NSString*)shadowName;

/** Pre-shrink all @2x image in background
 *  progressBlock will be called with index and count set to -1 if nothing is to be done (no need to warmup images)
 */
+ (void)imageNamedRetinaWarmupWithProgressBlock:(void (^)(NSString* imageName, NSUInteger index, NSUInteger count))progressBlock;

/**
 */
- (UIImage*)scaledImageFromScale:(CGFloat)fromScale;

/**
 */
- (UIImage*)scaledImageFromScale:(CGFloat)fromScale toScale:(CGFloat)toScale;

//////////////////////////////////////////////////////////////
#pragma mark
//////////////////////////////////////////////////////////////
/** @name Effects
 */

/**
 */
+ (UIImage *)gradientImageWithColors:(NSArray *)colors height:(CGFloat)height cornerRadius:(CGFloat)cornerRadius edgeInsets:(UIEdgeInsets)edgeInsets;
+ (UIImage *)gradientImageWithColors:(NSArray *)colors width:(CGFloat)width cornerRadius:(CGFloat)cornerRadius edgeInsets:(UIEdgeInsets)edgeInsets;
//////////////////////////////////////////////////////////////
#pragma mark
//////////////////////////////////////////////////////////////
/** @name Animations
 */

/**
 */
+ (NSArray*)animationImagesWithPrefix:(NSString*)imagesPrefix imageQuantity:(NSInteger)imageQuantity;

/**
 */
+ (NSArray*)animationImagesWithPrefix:(NSString*)imagesPrefix imageQuantity:(NSInteger)imageQuantity resizeImages:(CGSize)resizeImages;

/**
 */
+ (NSArray*)animationImagesWithPrefix:(NSString*)imagesPrefix imageQuantity:(NSInteger)imageQuantity resizeImages:(CGSize)resizeImages mask:(NSString*)mask;

/**
 */
+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSInteger)imageQuantity resizeImages:(CGSize)resizeImages mask:(NSString *)mask startingIndex:(NSInteger)startingIndex;

@end
