//
//  Copyright (c) 2013-2018, Mirego
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

#import "UIImage+MCFilePath.h"

@implementation UIImage (MCRetina)

+ (UIImage*)imageFromFilePath:(NSString *)path
{
    return [self imageFromFilePath:path useMemoryCache:YES];
}

+ (UIImage*)imageFromFilePath:(NSString *)path useMemoryCache:(BOOL)useMemoryCache
{
    return [self imageFromFilePath:path useMemoryCache:useMemoryCache logLoadError:NO];
}

+ (UIImage*)imageFromFilePath:(NSString *)path useMemoryCache:(BOOL)useMemoryCache logLoadError:(BOOL)logLoadError
{
    if ([path length] == 0) {
        return nil;
    }
    
    static NSCache* imageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCache = [[NSCache alloc] init];
        imageCache.name = @"imageFromFilePath";
    });
    
    // Get image from cache
    UIImage* image = (useMemoryCache ? [imageCache objectForKey:path] : nil);
    if (image == nil) {
        
        image = [UIImage imageWithContentsOfFile:path];
        
        // Check if image was loaded
        if (image != nil) {
            image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] orientation:[image imageOrientation]];
            
            // Cache image
            if (useMemoryCache) {
                [imageCache setObject:image forKey:path];
            }
        } else {
            // Log error
            if (logLoadError) {
                NSLog(@"imageFromFilePath failed\nCannot load image '%@'", path);
            }
        }
    }
    
    return image;
}

+ (UIImage *)imageFromFilePath:(NSString *)path tintColor:(UIColor *)tintColor
{
    if ([path length] == 0) {
        return nil;
    }
    
    if (tintColor == nil) {
        tintColor = [UIColor whiteColor];
    }
    
    // TODO: Add disk cache
    static NSCache* cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.name = @"[UIImage imageFromFilePath:tintColor:]";
    });
    
    id key = @[path ?: [NSNull null], tintColor];
    UIImage* image = [cache objectForKey:key];
    
    if (image == nil) {
        // Load image
        image = [UIImage imageFromFilePath:path];
        if (image == nil) {
            return nil;
        }
        
        image = [self mrg_tintImage:image tintColor:tintColor];
        
        // Cache image
        if ((image != nil)) {
            [cache setObject:image forKey:key];
        }
    }
    
    return image;
}

+ (UIImage *)mrg_tintImage:(UIImage *)originalImage tintColor:(UIColor *)tintColor
{
    CGRect rect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, originalImage.scale);
    
    // Tint image
    [tintColor set];
    UIRectFill(rect);
    [originalImage drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Add resizing
    if (!UIEdgeInsetsEqualToEdgeInsets(originalImage.capInsets, UIEdgeInsetsZero)) {
        image = [image resizableImageWithCapInsets:originalImage.capInsets resizingMode:originalImage.resizingMode];
    }
    
    return image;
}

@end
