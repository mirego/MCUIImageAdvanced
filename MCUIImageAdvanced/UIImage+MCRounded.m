//
//  UIImage+MCRounded.m
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

#import "UIImage+MCRounded.h"

@implementation UIImage (MCRounded)

- (UIImage *)imageWithRoundedCornersRadius:(CGFloat)radius
{
    return [self imageWithRoundedCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
}

- (UIImage *)imageWithRoundedCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii
{
    if (self.size.width <= 0 || self.size.width <= 0)
        return self;

    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    if (UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    else
        UIGraphicsBeginImageContext(rect.size);

    [[UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:cornerRadii] addClip];
    [self drawInRect:rect];

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage *)gradientImageWithColors:(NSArray *)colors height:(CGFloat)height cornerRadius:(CGFloat)cornerRadius edgeInsets:(UIEdgeInsets)edgeInsets
{
    return [self gradientImageWithColors:colors height:height width:0.0 cornerRadius:cornerRadius edgeInsets:edgeInsets];
}

+ (UIImage *)gradientImageWithColors:(NSArray *)colors width:(CGFloat)width cornerRadius:(CGFloat)cornerRadius edgeInsets:(UIEdgeInsets)edgeInsets
{
    return [self gradientImageWithColors:colors height:0.0 width:width cornerRadius:cornerRadius edgeInsets:edgeInsets ];
}

+ (UIImage *)gradientImageWithColors:(NSArray *)colors height:(CGFloat)height width:(CGFloat)width cornerRadius:(CGFloat)cornerRadius edgeInsets:(UIEdgeInsets)edgeInsets
{
    static NSCache* gradientImageCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gradientImageCache = [[NSCache alloc] init];
        gradientImageCache.name = @"gradientImageCache";
    });

    // Check if image was already created
    NSString* gradientImageCacheKey = [NSString stringWithFormat:@"%@/%f/%f/%@", colors, height, cornerRadius, NSStringFromUIEdgeInsets(edgeInsets)];
    UIImage* image = [gradientImageCache objectForKey:gradientImageCacheKey];
    if (image == nil) {
        // Create resizable image
        CGSize size;
        if (height > 0.0) {
            size = CGSizeMake(3 + (cornerRadius * 2) + (edgeInsets.left + edgeInsets.right), height);
        } else {
            size = CGSizeMake(width , 3 + (cornerRadius * 2) + (edgeInsets.top + edgeInsets.bottom));
        }

        CGRect rect = UIEdgeInsetsInsetRect(CGRectMake(0, 0, size.width, size.height), edgeInsets);

        if (UIGraphicsBeginImageContextWithOptions)
            UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        else
            UIGraphicsBeginImageContext(size);

        // Mask context to create rounded corners
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        UIBezierPath* bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
        [bezierPath addClip];

        // Convert UIColor array to CGColor array
        NSMutableArray* CGColors = [NSMutableArray arrayWithCapacity:[colors count]];
        for (UIColor* color in colors) {
            [CGColors addObject:(id)[color CGColor]];
        }

        // Draw the gradient
        CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)CGColors, NULL);
        CGContextClipToRect(context, rect);
        if (height > 0.0) {
            CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, CGRectGetMaxY(rect)), kCGGradientDrawsAfterEndLocation);
        } else {
            CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(CGRectGetMaxX(rect), 0), kCGGradientDrawsAfterEndLocation);
        }
        CGGradientRelease(gradient);

        // Make it auto-resizable
        image = UIGraphicsGetImageFromCurrentImageContext();
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0, edgeInsets.left + cornerRadius + 1, 0, edgeInsets.right + cornerRadius + 1)];
        UIGraphicsEndImageContext();

        // Cache image
        [gradientImageCache setObject:image forKey:gradientImageCacheKey];
    }

    return image;
}

@end
