//
//  UIImage+MCBlending.m
//  MCUIImageAdvanced
//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//

#import "UIImage+MCBlending.h"

@implementation UIImage (MCBlending)

+ (UIImage*)blendedImageWithImage:(UIImage *)image layers:(NSArray *)layers blendMode:(CGBlendMode)blendMode
{
    return [self blendedImageWithImage:image layers:layers blendModes:nil defaultBlendMode:blendMode];
}

+ (UIImage*)blendedImageWithImage:(UIImage *)image layers:(NSArray *)layers blendModes:(NSArray *)blendModes defaultBlendMode:(CGBlendMode)defaultBlendMode
{
    if (image == nil) {
        return nil;
    }
    
    // Create the rect based on the given image
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // Create an image context used to create an image
    if (UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0); // 0.0 = scale factor to support the native device scaling (retina display support)
    else
        UIGraphicsBeginImageContext(image.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self blendedImageInContext:context
                       withRect:rect
                          image:image
                         layers:layers
                     blendModes:blendModes
               defaultBlendMode:defaultBlendMode];
    
    // Create an image from the drawing context
    UIImage* blendedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return blendedImage;
}

+ (void)blendedImageInContext:(CGContextRef)context withRect:(CGRect)rect image:(UIImage *)image layers:(NSArray *)layers blendModes:(NSArray *)blendModes defaultBlendMode:(CGBlendMode)defaultBlendMode
{
    if (context == nil || image == nil) {
        return;
    }
    
    // Save the given context
    CGContextSaveGState(context);
    
    // Setup the context to invert everything drawn on the Y axis because the UIImage and CGImage have opposite y axis.
    CGContextTranslateCTM(context, 0.0f, CGRectGetHeight(rect));
    CGContextScaleCTM(context, 1.0f, -1.0f);
    
    // Draw main image
    if (image != nil) {
        CGContextDrawImage(context, rect, image.CGImage);
    }
    
    // Loop through all layers to draw them all
    if (layers != nil) {
        for (NSUInteger ii = 0; ii < layers.count; ii++) {
            // Blend mode
            if (blendModes != nil && ii < blendModes.count) {
                CGContextSetBlendMode (context, [[blendModes objectAtIndex:ii] intValue]);
            } else {
                CGContextSetBlendMode (context, defaultBlendMode);
            }
            
            id layer = [layers objectAtIndex:ii];
            if ([layer isKindOfClass:[UIColor class]]) {
                // Draw UIColor
                UIColor* layerColor = layer;
                CGContextSetFillColorWithColor(context, layerColor.CGColor);      
                CGContextFillRect (context, rect);
            } else if ([layer isKindOfClass:[UIImage class]]) {
                // Draw UIImage
                UIImage* layerImage = layer;
                CGContextDrawImage(context, rect, layerImage.CGImage);
            }
        }
    }
    
    // Restore the original drawing context
    CGContextRestoreGState(context);
}

@end
