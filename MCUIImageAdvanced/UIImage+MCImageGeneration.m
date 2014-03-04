//
//  UIImage+MCImageGeneration.m
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

#import "UIImage+MCImageGeneration.h"

@implementation UIImage (MCImageGeneration)

+ (UIImage *)mc_generateImageOfSize:(CGSize)size color:(UIColor *)color
{
    return [UIImage mc_generateImageOfSize:size color:color opaque:YES];
}

+ (UIImage *)mc_generateImageOfSize:(CGSize)size color:(UIColor *)color opaque:(BOOL)opaque
{
    if (![UIImage isValidSize:size]) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0f);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(currentContext, color.CGColor);
    CGContextFillRect(currentContext, CGRectMake(0.0f, 0.0f, size.width, size.height));
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

+ (UIImage *)mc_generateImageOfSize:(CGSize)size verticalGradientColors:(NSArray *)colors {
    return [self mc_generateImageOfSize:size verticalGradientColors:colors opaque:YES];
}

+ (UIImage *)mc_generateImageOfSize:(CGSize)size horizontalGradientColors:(NSArray *)colors {
    return [self mc_generateImageOfSize:size horizontalGradientColors:colors opaque:YES];
}

+ (UIImage *)mc_generateImageOfSize:(CGSize)size verticalGradientColors:(NSArray *)colors opaque:(BOOL)opaque
{
    if (![UIImage isValidSize:size] || ![UIImage isValidGradientColors:colors]) {
        return nil;
    }
    
    CGGradientRef gradient = [self gradientFromColors:colors];
    
    UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0f);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextFillRect(currentContext, CGRectMake(0.0f, 0.0f, size.width, size.height));
    CGFloat midX = floorf(size.width / 2.0f);
    CGPoint startPoint = CGPointMake(midX, 0.0f);
    CGPoint endPoint = CGPointMake(midX, size.height);
    CGContextDrawLinearGradient(currentContext, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

+ (UIImage *)mc_generateImageOfSize:(CGSize)size horizontalGradientColors:(NSArray *)colors opaque:(BOOL)opaque
{
    if (![UIImage isValidSize:size] || ![UIImage isValidGradientColors:colors]) {
        return nil;
    }
    
    CGGradientRef gradient = [self gradientFromColors:colors];
    
    UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0f);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextFillRect(currentContext, CGRectMake(0.0f, 0.0f, size.width, size.height));
    CGFloat midY = floorf(size.height / 2.0f);
    CGPoint startPoint = CGPointMake(0.0f, midY);
    CGPoint endPoint = CGPointMake(size.width, midY);
    CGContextDrawLinearGradient(currentContext, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

+ (UIImage *)mc_generateCircleImageOfSize:(CGSize)size color:(UIColor *)color
{
    if (![UIImage isValidSize:size]) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(currentContext, color.CGColor);
    CGContextFillEllipseInRect(currentContext, CGRectMake(0.0f, 0.0f, size.width, size.height));
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

+ (UIImage *)mc_generateCircleImageOfSize:(CGSize)size fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor strokeWidth:(CGFloat)strokeWidth
{
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(strokeWidth / 2.0, strokeWidth / 2.0, size.width - strokeWidth, size.height - strokeWidth);
    CGContextSetFillColorWithColor(currentContext, fillColor.CGColor);
    CGContextSetLineWidth(currentContext, strokeWidth);
    CGContextSetStrokeColorWithColor(currentContext, strokeColor.CGColor);
    CGContextBeginPath(currentContext);
    CGContextAddEllipseInRect(currentContext, rect);
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

+ (BOOL)isValidSize:(CGSize)size
{
    return size.width > 0.0f && size.height > 0.0f;
}

+ (BOOL)isValidGradientColors:(NSArray *)colors
{
    if ([colors count] < 2) return NO;
    for (id color in colors) {
        if (![color isKindOfClass:[UIColor class]]) {
            return NO;
        }
    }
    return YES;
}

+ (CGGradientRef)gradientFromColors:(NSArray *)colors
{
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef) [self cgColorsFromColors:colors], nil);
    CGColorSpaceRelease(space);
    return gradient;
}

+ (NSArray *)cgColorsFromColors:(NSArray *)colors
{
    NSMutableArray *colorRefs = [NSMutableArray arrayWithCapacity:[colors count]];
    for (UIColor *color in colors) {
        [colorRefs addObject:(id)color.CGColor];
    }
    return colorRefs;
}

@end
