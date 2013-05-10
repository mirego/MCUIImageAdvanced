//
//  UIImage+MCAnimation.m
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
