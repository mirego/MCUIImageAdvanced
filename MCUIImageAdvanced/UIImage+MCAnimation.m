//
//  UIImage+MCAnimation.m
//  MCUIImageAdvanced
//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//

#import "UIImage+MCAnimation.h"
#import "UIImage+MCRetina.h"
#import "UIImage+ProportionalFill.h"

@implementation UIImage (MCAnimation)

//////////////////////////////////////////////////////////////
#pragma mark animated images
//////////////////////////////////////////////////////////////
+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSUInteger)imageQuantity
{
    return [self animationImagesWithPrefix:imagesPrefix imageQuantity:imageQuantity resizeImages:CGSizeZero mask:@"%u"];
}

+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSUInteger)imageQuantity resizeImages:(CGSize)resizeImages
{
    return [self animationImagesWithPrefix:imagesPrefix imageQuantity:imageQuantity resizeImages:resizeImages mask:@"%u"];
}

+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSUInteger)imageQuantity resizeImages:(CGSize)resizeImages mask:(NSString *)mask
{
    return [self animationImagesWithPrefix:imagesPrefix imageQuantity:imageQuantity resizeImages:resizeImages mask:mask startingIndex:0];
}

+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix imageQuantity:(NSUInteger)imageQuantity resizeImages:(CGSize)resizeImages mask:(NSString *)mask startingIndex:(NSUInteger)startingIndex
{
    if (imageQuantity == 0) {
        return nil;
    }
    
    // Load the images from disk
    NSMutableArray* imageArray = [[NSMutableArray alloc] initWithCapacity:imageQuantity];
    for (NSUInteger index = startingIndex, end = (imageQuantity + startingIndex); index < end; ++index) {
        // Create image path from mask, load image, add it
        NSString* imageName = [imagesPrefix stringByAppendingFormat:mask, index];
        UIImage* image = [UIImage imageNamedRetina:imageName];
        
        // Resize image if requested to (IMPROVEMENT: Cache resized copy)
        if ((resizeImages.width > 0) && (resizeImages.height > 0)) {
            image = [image imageScaledToFitSize:resizeImages];
        }
        
        if ((image != nil)) {
            [imageArray addObject:image];
        } else {
            NSLog(@"Cannot load image: %@", imageName);
        }
    }
    
    return imageArray;
}

@end
