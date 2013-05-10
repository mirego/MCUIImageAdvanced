//
//  UIImage+MCRetina.m
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

#import "UIImage+MCRetina.h"
#import "UIImage+ProportionalFill.h"
#import "ShrinkPNG.h"

#include <sys/stat.h>
#include <sys/time.h>
#include <mach/mach.h>
#include <mach/mach_host.h>

@implementation UIImage (MCRetina)

+ (UIImage*)imageNamedRetina:(NSString *)name
{
    return [self imageNamedRetina:name useMemoryCache:YES];
}

+ (UIImage*)imageNamedRetina:(NSString *)name useMemoryCache:(BOOL)useMemoryCache
{
    return [self imageNamedRetina:name useMemoryCache:useMemoryCache logLoadError:NO];
}

+ (natural_t)totalMemory
{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize; host_page_size(host_port, &pagesize);

    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");

    /* Stats in bytes */
    natural_t mem_used = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
    natural_t mem_free = (vm_stat.free_count) * pagesize;
    natural_t mem_total = mem_used + mem_free;

    return mem_total;
}

+ (NSString*)mcCleanImageName:(NSString *)name
{
    // If path extension is PNG, remove it from key
    NSString* pathExtension = [name pathExtension];
    if ([[pathExtension lowercaseString] isEqualToString:@"png"])
        pathExtension = nil;

    // Remove ~iphone/~ipad
    name = [name stringByDeletingPathExtension];
    if ([name hasSuffix:@"~iphone"])
        name = [name substringToIndex:[name length] - 7];
    else if ([name hasSuffix:@"~ipad"])
        name = [name substringToIndex:[name length] - 5];

    // Remove @2x
    if ([name hasSuffix:@"@2x"])
        name = [name substringToIndex:[name length] - 3];

    // Remove -568h
    if ([name hasSuffix:@"-568h"])
        name = [name substringToIndex:[name length] - 5];

    // Put back path extension
    if ([pathExtension length] > 0)
        name = [name stringByAppendingPathExtension:pathExtension];

    return name;
}

+ (UIImage*)imageNamedRetina:(NSString *)name useMemoryCache:(BOOL)useMemoryCache logLoadError:(BOOL)logLoadError
{
    // If name is empty, return nil
    name = [self mcCleanImageName:name];
    if ((name == nil) || [name isEqualToString:@""])
        return nil;

    static NSCache* imageCache = nil;
    static NSMutableDictionary* imagePathCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCache = [[NSCache alloc] init];
        imageCache.name = @"imageNamedRetina";
        imageCache.totalCostLimit = [self totalMemory] / 4; // A quarter of available memory
        imagePathCache = [[NSMutableDictionary alloc] init];
    });

    // Get image from cache
    UIImage* image = (useMemoryCache ? [imageCache objectForKey:name] : nil);
    if (image == nil) {
        // Get image path from cache
        NSString* imagePath = [imagePathCache valueForKey:name];
        if (imagePath == nil) {
            // Get image path
            NSString* resource = [name stringByDeletingPathExtension];
            NSString* type = [name pathExtension];
            if (type == nil || [type isEqualToString:@""])
                type = @"png";

            UIUserInterfaceIdiom userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
            NSInteger systemVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
            NSInteger scale = (systemVersion >= 4) ? [[UIScreen mainScreen] scale] : 1;
            NSInteger height = CGRectGetHeight([[UIScreen mainScreen] bounds]);

            if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                // Check for iPad specific retina+ and normal versions
                if (imagePath == nil && scale >= 2)
                    imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"@%dx~ipad", scale] ofType:type];
                if (imagePath == nil)
                    imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingString:@"~ipad"] ofType:type];

            } else if (userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
                // Check for iPhone/iPod specific retina+ and normal versions
                if (imagePath == nil && scale >= 2) {
                    if (height >= 568) { // iPhone 4 inch
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"-%dh@%dx~iphone", height, scale] ofType:type];

                        if (imagePath == nil)
                            imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"-%dh~iphone", height] ofType:type];

                    } else {
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"@%dx~iphone", scale] ofType:type];

                        if (imagePath == nil)
                            imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingString:@"~iphone"] ofType:type];
                    }
                }
            }

            // Check for retina+ and normal versions
            if (imagePath == nil && scale >= 2) {
                if (height >= 568) { // iPhone 4 inch
                    imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"-%dh@%dx", height, scale] ofType:type];
                }

                if (imagePath == nil)
                    imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"@%dx", scale] ofType:type];
            }

            // Load resource "as is"
            if (imagePath == nil)
                imagePath = [[NSBundle mainBundle] pathForResource:resource ofType:type];

            // Check for retina version and shrink it
            if (imagePath == nil) {
                imagePath = [self pathForNonRetinaResource:resource ofType:type image:&image];
            }
        }

        // Load image
        if (imagePath != nil) {
            image = [UIImage imageWithContentsOfFile:imagePath];
        }

        // Check if image was loaded
        if (image != nil) {
            // Cache image
            if (useMemoryCache) {
                NSUInteger cost = image.size.width * image.size.height;
                cost *= ((image.CGImage) ? (CGImageGetBitsPerPixel(image.CGImage) / 8) : 4);
                [imageCache setObject:image forKey:name cost:cost];
            }

            // Cache image path
            [imagePathCache setValue:imagePath forKey:name];

        } else {
            // Log error
            if (logLoadError) {
                NSLog(@"imageNamedRetina failed\nCannot load image '%@'", name);
            }
        }
    }

    return image;
}

+ (void)imageNamedRetinaWarmupWithProgressBlock:(void (^)(NSString* imageName, NSUInteger index, NSUInteger count))progressBlock
{
    NSInteger systemVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
    NSInteger scale = (systemVersion >= 4) ? [[UIScreen mainScreen] scale] : 1;
    if (scale > 1) {
        if (progressBlock)
            progressBlock(nil, -1, -1);

        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* resourcePath = [[NSBundle mainBundle] resourcePath];

        // Get list of PNG resources
        NSError* error = nil;
        NSArray* resources = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:&error] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject hasSuffix:@".png"];
        }]];

        UIUserInterfaceIdiom userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
        NSString* suffixSkip = ((userInterfaceIdiom != UIUserInterfaceIdiomPad) ? @"~ipad" : @"~iphone");
        NSString* suffixStrip = ((userInterfaceIdiom != UIUserInterfaceIdiomPad) ? @"~iphone" : @"~ipad");

        NSMutableSet* resourcesSet = [[NSMutableSet alloc] initWithCapacity:[resources count]];
        for (NSString* file in resources) {
            NSMutableString* resource = [[file stringByDeletingPathExtension] mutableCopy];
            if ([resource hasSuffix:suffixSkip])
                continue;

            if ([resource hasSuffix:suffixStrip]) {
                [resource deleteCharactersInRange:NSMakeRange([resource length] - [suffixStrip length], [suffixStrip length])];
            }
            if ([resource hasSuffix:@"@2x"]) {
                [resource deleteCharactersInRange:NSMakeRange([resource length] - [@"@2x" length], [@"@2x" length])];
            }

            [resourcesSet addObject:resource];
        }
        resources = [[resourcesSet allObjects] sortedArrayUsingSelector:@selector(compare:)];

        // Pre-convert all @2x images to non-retina (only if the non-retina version doesn't exists)
        NSUInteger index = 0, count = [resources count];
        for (NSString* resource in resources) {
            if (progressBlock)
                progressBlock(resource, index, count);

            [self pathForNonRetinaResource:[resource stringByDeletingPathExtension] ofType:@"png"];
            index++;
        }

        if (progressBlock)
            progressBlock(nil, count, count);
    });
}

+ (NSString *)pathForNonRetinaResource:(NSString *)name ofType:(NSString *)type
{
    return [self pathForNonRetinaResource:name ofType:type image:NULL];
}

+ (NSString *)pathForNonRetinaResource:(NSString *)name ofType:(NSString *)type image:(UIImage **)image
{
    UIImage* shrinkedImage = nil;

    // Load @1x file
    NSString* file = [[NSBundle mainBundle] pathForResource:name ofType:type];
    if (file != nil) {
        return file;
    }

    // Load @2x file
    file = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:type];
    if (file != nil) {
        static NSString* resourcePath = nil;
        static NSString* cachePath = nil;

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            resourcePath = [[NSBundle mainBundle] resourcePath];
            cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"imageNamedRetina"];
        });

        // Find the path to the cache file (resourcePath is used so we can place images in ??.lproj folders in similar folders in cache)
        NSString* cacheFile = [[cachePath stringByAppendingPathComponent:[file substringFromIndex:[resourcePath length]]] stringByDeletingPathExtension];

        // Safely remove the @2x from file name
        NSString* suffix = (([cacheFile hasSuffix:@"~ipad"]) ? @"~ipad" : ([cacheFile hasSuffix:@"~iphone"] ? @"~iphone" : @""));
        cacheFile = [cacheFile substringToIndex:(cacheFile.length - [suffix length])];
        cacheFile = [cacheFile hasSuffix:@"@2x"] ? [cacheFile substringToIndex:(cacheFile.length - [@"@2x" length])] : cacheFile;
        cacheFile = [cacheFile stringByAppendingString:suffix];
        cacheFile = [cacheFile stringByAppendingPathExtension:type];

        // Check if file is in cache and has same timestamp
        struct stat fileStat;
        if (stat([file UTF8String], &fileStat) == 0) {
            struct stat cacheFileStat;
            if (stat([cacheFile UTF8String], &cacheFileStat) == 0) {
                if (memcmp(&(fileStat.st_mtimespec), &(cacheFileStat.st_mtimespec), sizeof(struct timespec)) == 0) {
                    file = cacheFile;
                    cacheFile = nil; // cacheFile nil tells that the file was found in cache
                }
            }

            // Check if file was *not* found in cache
            if (cacheFile != nil) {
                // Load image at retina resolution and shrink it
                CGImageRef imageRef = [ShrinkPNG newShrinkedImageWithContentsOfFile:file];
                shrinkedImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);

                // Cache image to disk
                NSError* error = nil;
                if ([[NSFileManager defaultManager] createDirectoryAtPath:[cacheFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSData* cacheData = nil;
                    if ([type isEqualToString:@"png"]) {
                        cacheData = UIImagePNGRepresentation(shrinkedImage);
                    } else if ([type isEqualToString:@"png"] || [type isEqualToString:@"jpeg"]) {
                        cacheData = UIImageJPEGRepresentation(shrinkedImage, 0.85f);
                    } else {
                        cacheData = UIImagePNGRepresentation(shrinkedImage);
                    }

                    if (cacheData != nil) {
                        NSError* error = nil;
                        if ([cacheData writeToFile:cacheFile options:(NSDataWritingAtomic) error:&error]) {
                            // Set the timestamp on the cached file to the one on the original file so we can detect changes in original that will trigger a reload
                            struct timeval times[2];
                            TIMESPEC_TO_TIMEVAL(&(times[0]), &(fileStat.st_atimespec));
                            TIMESPEC_TO_TIMEVAL(&(times[1]), &(fileStat.st_mtimespec));
                            utimes([cacheFile UTF8String], times);

                            // Reload image from disk so we have less dirty memory (memory that can't be dumped and reload from disk under memory pressure)
                            file = cacheFile;
                            shrinkedImage = nil;
                        } else {
                            NSLog(@"imageNamedRetina error\nCannot save 1x image to '%@'\n%@", cacheFile, [error localizedDescription]);
                        }
                    } else {
                        NSLog(@"imageNamedRetina error\nCannot save 1x image to '%@'\nCacheData is nil", cacheFile);
                    }
                } else {
                    NSLog(@"imageNamedRetina error\nCannot save 1x image to '%@'\n%@", cacheFile, [error localizedDescription]);
                }
            }
        }
    }

    if ((image != nil)) {
        *image = shrinkedImage;
    }

    return file;
}


+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor
{
    return [self imageNamedRetina:name tintColor:tintColor overlayBlendMode:kCGBlendModeOverlay overlayName:[name stringByAppendingString:@"_overlay"] shadowName:[name stringByAppendingString:@"_shadow"]];
}

+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode
{
    return [self imageNamedRetina:name tintColor:tintColor overlayBlendMode:overlayBlendMode overlayName:[name stringByAppendingString:@"_overlay"] shadowName:[name stringByAppendingString:@"_shadow"]];
}

+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayName:(NSString *)overlayName shadowName:(NSString *)shadowName
{
    return [self imageNamedRetina:name tintColor:tintColor overlayBlendMode:kCGBlendModeOverlay overlayName:overlayName shadowName:shadowName];
}

+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode overlayName:(NSString *)overlayName shadowName:(NSString *)shadowName
{
    if (tintColor == nil) {
        tintColor = [UIColor whiteColor];
    }

    // TODO: Add disk cache
    static NSCache* cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.name = @"[UIImage imageNamedRetina:tintColor:overlayName:shadowName:]";
    });

    NSString* key = [NSString stringWithFormat:@"%@-%@-%@-%@", name, tintColor, overlayName, shadowName];
    UIImage* image = [cache objectForKey:key];

    if (image == nil) {
        // Load image
        image = [UIImage imageNamedRetina:name];
        if (image == nil)
            return nil;

        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);

        // Tint image
        [tintColor set];
        UIRectFill(rect);
        [image drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0f];

        // Add overlay
        UIImage* imageOverlay = [UIImage imageNamedRetina:overlayName useMemoryCache:YES logLoadError:NO];
        if ((imageOverlay != nil)) {
            [imageOverlay drawInRect:rect blendMode:overlayBlendMode alpha:1.0f];
        }

        // Add shadow
        UIImage* imageShadow = [UIImage imageNamedRetina:shadowName useMemoryCache:YES logLoadError:NO];
        if ((imageShadow != nil)) {
            image = UIGraphicsGetImageFromCurrentImageContext();
            CGContextClearRect(UIGraphicsGetCurrentContext(), rect);

            [imageShadow drawInRect:rect];
            [image drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0f];
        }

        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        // Cache image
        if ((image != nil)) {
            [cache setObject:image forKey:key];
        }
    }

    return image;
}

- (UIImage *)scaledImageFromScale:(CGFloat)fromScale
{
    return [self scaledImageFromScale:fromScale toScale:[[UIScreen mainScreen] scale]];
}

- (UIImage *)scaledImageFromScale:(CGFloat)fromScale toScale:(CGFloat)toScale
{
    // If same scale, do nothing
    if (fromScale == toScale) {
        return self;
    }

    // If image half scale and image is a power of two, shrink (optimal)
    UIImage* image = nil;
    if (fromScale == 2.0f && toScale == 1.0f) {
        size_t width = self.size.width;
        size_t height = self.size.height;

        if ((width % 2) == 0 && (height % 2) == 0) {
            CGImageRef imageRef = [ShrinkPNG newShrinkedImageWithCGImage:[self CGImage]];
            if ((imageRef != NULL)) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
        }
    }

    // If no image, scale
    if (image == nil) {
        image = [self imageScaledToFitSize:CGSizeMake(self.size.width * (toScale / fromScale), self.size.height * (toScale / fromScale))];
    }

    // If no image, set scale to "fromScale" (paranoid mode)
    if (image == nil) {
        image = [UIImage imageWithCGImage:[self CGImage] scale:fromScale orientation:[self imageOrientation]];
    }

    return image;
}

@end
