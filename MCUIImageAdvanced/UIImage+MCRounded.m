//
//  UIImage+MCRounded.m
//  MCUIImageAdvanced
//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
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
