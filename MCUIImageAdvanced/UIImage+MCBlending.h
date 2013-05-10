//
//  UIImage+MCBlending.h
//
//  Copyright (c) 2013, Mirego
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//  - Neither the name of the Mirego nor the names of its contributors may
//    be used to endorse or promote products derived from this software without
//    specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
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
