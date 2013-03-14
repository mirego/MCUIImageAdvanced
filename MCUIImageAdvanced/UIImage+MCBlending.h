//
//  UIImage+MCBlending.h
//  MCUIImageAdvanced
//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MCBlending)

/** Create an image resulting of a blend of the main image and all
 *  given layers.
 *
 *  @see blendedImageWithImage:layers:blendModes:defaultBlendMode:
 */
+ (UIImage *)blendedImageWithImage:(UIImage *)image
                            layers:(NSArray *)layers
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
+ (UIImage *)blendedImageWithImage:(UIImage *)image
                            layers:(NSArray *)layers
                        blendModes:(NSArray *)blendModes
                  defaultBlendMode:(CGBlendMode)defaultBlendMode;

/** Create an image resulting of a blend of the main image and all
 *  given layers.
 *
 *  @see blendedImageWithImage:layers:blendModes:defaultBlendMode:
 */
+ (void)blendedImageInContext:(CGContextRef)context
                     withRect:(CGRect)rect
                        image:(UIImage *)image
                       layers:(NSArray *)layers
                   blendModes:(NSArray *)blendModes
             defaultBlendMode:(CGBlendMode)defaultBlendMode;

@end
