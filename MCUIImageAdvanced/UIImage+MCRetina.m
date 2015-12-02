//
//  Copyright (c) 2013-2015, Mirego
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

+ (UIImage*)imageNamedRetina:(NSString *)name inDirectory:(NSString *)subpath
{
    return [self imageNamedRetina:name useMemoryCache:NO logLoadError:NO inDirectory:subpath];
}

+ (UIImage*)imageNamedRetina:(NSString *)name useMemoryCache:(BOOL)useMemoryCache
{
    return [self imageNamedRetina:name useMemoryCache:useMemoryCache logLoadError:NO inDirectory:nil];
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
    natural_t mem_used = (natural_t)((vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize);
    natural_t mem_free = (natural_t)((vm_stat.free_count) * pagesize);
    natural_t mem_total = mem_used + mem_free;
    
    return mem_total;
}

+ (NSString*)mcCleanImageName:(NSString *)name
{
    // If path extension is PNG, remove it from key
    NSString* pathExtension = [name pathExtension];
    if ([[pathExtension lowercaseString] isEqualToString:@"png"])
        pathExtension = nil;
    
    // Remove device suffix
    name = [name stringByDeletingPathExtension];
    if ([name hasSuffix:@"~iphone"])
        name = [name substringToIndex:[name length] - 7];
    else if ([name hasSuffix:@"~ipad"])
        name = [name substringToIndex:[name length] - 5];
    
    // Remove scale suffix
    // FIXME Make more generic
    if ([name hasSuffix:@"@2x"])
        name = [name substringToIndex:[name length] - 3];
    else if ([name hasSuffix:@"@3x"])
        name = [name substringToIndex:[name length] - 3];
    
    // Remove height suffix
    // FIXME Make more generic
    if ([name hasSuffix:@"-568h"])      // iPhone 5
        name = [name substringToIndex:[name length] - 5];
    else if ([name hasSuffix:@"-667h"]) // iPhone 6 - 4.7 inch
        name = [name substringToIndex:[name length] - 5];
    else if ([name hasSuffix:@"-736h"]) // iPhone 6 Plus - 5.5 inch
        name = [name substringToIndex:[name length] - 5];
    
    // Put back path extension
    if ([pathExtension length] > 0)
        name = [name stringByAppendingPathExtension:pathExtension];
    
    return name;
}

+ (UIImage*)imageNamedRetina:(NSString *)originalName useMemoryCache:(BOOL)useMemoryCache logLoadError:(BOOL)logLoadError inDirectory:(NSString *)subpath
{
    // If name is empty, return nil
    NSString *name = [self mcCleanImageName:originalName];
    if ([name length] == 0) {
        return nil;
    }
    
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
        // When a subpath is specified, the cache can't be used because we can't assume that it's always the same subpath.
        NSString* imagePath = nil;
        if ([subpath length] == 0) {
            imagePath = [imagePathCache valueForKey:name];
        }
        
        if (imagePath == nil) {
            // Get image path
            NSString* resource = [name stringByDeletingPathExtension];
            NSString* type = [name pathExtension];
            if (type.length == 0) {
                type = @"png";
            }
            
            UIUserInterfaceIdiom userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
            NSInteger scale = [[UIScreen mainScreen] scale];
            NSInteger height = CGRectGetHeight([[UIScreen mainScreen] bounds]);
            
            if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                // Check for iPad specific retina+ and normal versions
                if (scale >= 2) {
                    imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"@%ldx~ipad", (long)scale] ofType:type inDirectory:subpath];
                }
                
                if (imagePath == nil) {
                    imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingString:@"~ipad"] ofType:type inDirectory:subpath];
                }
                
            } else if (userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
                // Check for iPhone/iPod specific retina+ and normal versions
                if (height >= 568) {
                    if (scale >= 2) {
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"-%ldh@%ldx~iphone", (long)height, (long)scale] ofType:type inDirectory:subpath];
                    }
                    
                    if (imagePath == nil) {
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"-%ldh~iphone", (long)height] ofType:type inDirectory:subpath];
                    }
                }
                
                if (imagePath == nil) {
                    if (scale >= 2) {
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"@%ldx~iphone", (long)scale] ofType:type inDirectory:subpath];
                    }
                    
                    if (imagePath == nil) {
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingString:@"~iphone"] ofType:type inDirectory:subpath];
                    }
                }
            }
            
            // Check for retina+ and normal versions
            if (imagePath == nil) {
                if (height >= 568) {
                    if (scale >= 2) {
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"-%ldh@%ldx", (long)height, (long)scale] ofType:type inDirectory:subpath];
                    }
                    
                    if (imagePath == nil) {
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"-%ldh", (long)height] ofType:type inDirectory:subpath];
                    }
                }
                
                if (imagePath == nil) {
                    if (scale >= 2) {
                        imagePath = [[NSBundle mainBundle] pathForResource:[resource stringByAppendingFormat:@"@%ldx", (long)scale] ofType:type inDirectory:subpath];
                    }
                    
                    if (imagePath == nil) {
                        imagePath = [[NSBundle mainBundle] pathForResource:resource ofType:type inDirectory:subpath];
                    }
                }
            }
            
            // Check for retina version and shrink it
            if (imagePath == nil && scale == 1) {
                imagePath = [self pathForNonRetinaResource:resource ofType:type image:&image];
            }
        }
        
        // Load image
        if (imagePath != nil) {
            image = [UIImage imageWithContentsOfFile:imagePath];
        }
        
        // Fallback to imageNamed:
        if (image == nil) {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                NSInteger height = CGRectGetHeight([[UIScreen mainScreen] bounds]);
                if (height >= 568) {
                    image = [UIImage imageNamed:[originalName stringByAppendingFormat:@"-%ldh", (long)height]];
                }
            }
            
            if (image == nil) {
                image = [UIImage imageNamed:originalName];
            }
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
    NSInteger scale = [[UIScreen mainScreen] scale];
    if (scale > 1) {
        if (progressBlock) {
            progressBlock(nil, -1, -1);
        }
        
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
            } else if ([resource hasSuffix:@"@3x"]) {
                [resource deleteCharactersInRange:NSMakeRange([resource length] - [@"@3x" length], [@"@3x" length])];
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
    
    static NSString* resourcePath = nil;
    static NSString* cachePath = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        resourcePath = [[NSBundle mainBundle] resourcePath];
        cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"imageNamedRetina"];
    });
    
    // Get @2x file path
    file = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:type];
    
    // Find the path to the cache file
    NSString* cacheFile;
    if (file != nil) {
        // "resourcePath" is used so we can place images in ??.lproj folders in similar folders in cache
        cacheFile = [[cachePath stringByAppendingPathComponent:[file substringFromIndex:[resourcePath length]]] stringByDeletingPathExtension];
    } else {
        // File is probably in an asset catalog, which doesn't support localization, use the name
        cacheFile = [cachePath stringByAppendingPathComponent:name];
    }
    
    // Safely remove the @2x from cache file name
    NSString* deviceSuffix = ([cacheFile hasSuffix:@"~ipad"] ? @"~ipad" : ([cacheFile hasSuffix:@"~iphone"] ? @"~iphone" : @""));
    cacheFile = [cacheFile substringToIndex:(cacheFile.length - [deviceSuffix length])];
    NSString* scaleSuffix = ([cacheFile hasSuffix:@"@2x"] ? @"@2x" : @"");
    cacheFile = [cacheFile substringToIndex:(cacheFile.length - [scaleSuffix length])];
    cacheFile = [cacheFile stringByAppendingString:deviceSuffix];
    cacheFile = [cacheFile stringByAppendingPathExtension:type];
    
    // Check if file is in cache and has same timestamp
    struct stat fileStat;
    if (file != nil) {
        if (stat([file UTF8String], &fileStat) == 0) {
            struct stat cacheFileStat;
            if (stat([cacheFile UTF8String], &cacheFileStat) == 0) {
                if (memcmp(&(fileStat.st_mtimespec), &(cacheFileStat.st_mtimespec), sizeof(struct timespec)) != 0) {
                    [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:NULL]; // Delete outdated file
                }
            }
        }
    }
    
    // If file doesn't exist in cache, create it
    if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile] == NO) {
        // Load image at retina resolution and shrink it
        UIImage *shrinkedImage;
        
        if (file != nil) {
            // Load @2x image from disk and shrink it
            CGImageRef imageRef = [ShrinkPNG newShrinkedImageWithContentsOfFile:file];
            shrinkedImage = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            
        } else {
            // Load available image from asset catalog
            UIImage *imageToShrink;
            if ([type length] == 0) {
                imageToShrink = [UIImage imageNamed:name];
            } else {
                imageToShrink = [UIImage imageNamed:[name stringByAppendingPathExtension:type]];
            }
            
            // If image doesn't exists, return now
            if (imageToShrink == nil) {
                return nil;
            }
            
            // If available image is already at correct scale, use it
            if (imageToShrink.scale == 1) {
                if ((image != nil)) {
                    *image = imageToShrink;
                }
                
                return nil;
            }
            
            // If necessary, scale it so it's possible to use ShrinkPNG
            if (imageToShrink.scale > 2) {
                imageToShrink = [imageToShrink scaledImageFromScale:imageToShrink.scale toScale:2.0f];
            }
            
            // Shrink image
            CGImageRef imageRef = [ShrinkPNG newShrinkedImageWithCGImage:[imageToShrink CGImage]];
            shrinkedImage = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        
        // Cache image to disk
        NSError* error = nil;
        if ([[NSFileManager defaultManager] createDirectoryAtPath:[cacheFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSData* cacheData = nil;
            if ([type isEqualToString:@"png"]) {
                cacheData = UIImagePNGRepresentation(shrinkedImage);
            } else if ([type isEqualToString:@"jpg"] || [type isEqualToString:@"jpeg"]) {
                cacheData = UIImageJPEGRepresentation(shrinkedImage, 0.85f);
            } else {
                cacheData = UIImagePNGRepresentation(shrinkedImage);
            }
            
            if (cacheData != nil) {
                NSError* error = nil;
                if ([cacheData writeToFile:cacheFile options:(NSDataWritingAtomic) error:&error]) {
                    if (file != nil) {
                        // Set the timestamp on the cached file to the one on the original file so we can detect changes in original that will trigger a reload
                        struct timeval times[2];
                        TIMESPEC_TO_TIMEVAL(&(times[0]), &(fileStat.st_atimespec));
                        TIMESPEC_TO_TIMEVAL(&(times[1]), &(fileStat.st_mtimespec));
                        utimes([cacheFile UTF8String], times);
                    }
                    
                    // Reload image from disk so we have less dirty memory (memory that can't be dumped and reload from disk under memory pressure)
                    shrinkedImage = nil;
                    
                } else {
                    NSLog(@"imageNamedRetina error\nCannot save 1x image to '%@'\n%@", cacheFile, [error localizedDescription]);
                    cacheFile = nil;
                }
                
            } else {
                NSLog(@"imageNamedRetina error\nCannot save 1x image to '%@'\nCacheData is nil", cacheFile);
                cacheFile = nil;
            }
            
        } else {
            NSLog(@"imageNamedRetina error\nCannot save 1x image to '%@'\n%@", cacheFile, [error localizedDescription]);
            cacheFile = nil;
        }
    }
    
    if ((image != nil)) {
        *image = shrinkedImage;
    }
    
    return cacheFile;
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
    
    id key = @[name ?: [NSNull null], tintColor, overlayName ?: [NSNull null], shadowName ?: [NSNull null]];
    UIImage* image = [cache objectForKey:key];
    
    if (image == nil) {
        // Load image
        image = [UIImage imageNamedRetina:name];
        if (image == nil) {
            return nil;
        }
        
        if ([image respondsToSelector:@selector(imageAsset)]) {
            UIImageAsset *imageAsset = [[UIImageAsset alloc] init];
            UITraitCollection *scale = [UITraitCollection traitCollectionWithDisplayScale:image.scale];
            UITraitCollection *idiom = [UITraitCollection traitCollectionWithUserInterfaceIdiom:[[UIDevice currentDevice] userInterfaceIdiom]];
            UITraitCollection *horizontalCompact = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];
            UITraitCollection *horizontalRegular = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];
            UITraitCollection *verticalCompact = [UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassCompact];
            UITraitCollection *verticalRegular = [UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassRegular];
            
            // Generate tinted Any/Any image
            UITraitCollection *anyAnyTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom]];
            UIImage *anyAnyImage = [self mrg_tintImage:image tintColor:tintColor overlayBlendMode:overlayBlendMode overlayName:overlayName shadowName:shadowName traitCollection:anyAnyTraitCollection];
            [imageAsset registerImage:anyAnyImage withTraitCollection:anyAnyTraitCollection];
            
            // Generate all other combinations of images *if they are available*
            NSArray *traitCollections =
            @[
              [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom, horizontalCompact]],
              [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom, horizontalRegular]],
              [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom, verticalCompact]],
              [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom, verticalRegular]],
              [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom, horizontalCompact, verticalCompact]],
              [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom, horizontalCompact, verticalRegular]],
              [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom, horizontalRegular, verticalCompact]],
              [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, idiom, horizontalRegular, verticalRegular]],
              ];
            
            for (UITraitCollection *traitCollection in traitCollections) {
                UIImage *traitImage = [image.imageAsset imageWithTraitCollection:traitCollection];
                if ([traitImage.traitCollection isEqual:traitCollection]) {
                    traitImage = [self mrg_tintImage:image tintColor:tintColor overlayBlendMode:overlayBlendMode overlayName:overlayName shadowName:shadowName traitCollection:traitCollection];
                    [imageAsset registerImage:traitImage withTraitCollection:traitCollection];
                }
            }
            
            image = [imageAsset imageWithTraitCollection:image.traitCollection];
            
        } else {
            image = [self mrg_tintImage:image tintColor:tintColor overlayBlendMode:overlayBlendMode overlayName:overlayName shadowName:shadowName traitCollection:nil];
        }
        
        // Cache image
        if ((image != nil)) {
            [cache setObject:image forKey:key];
        }
    }
    
    return image;
}

+ (UIImage *)mrg_tintImage:(UIImage *)originalImage tintColor:(UIColor *)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode overlayName:(NSString *)overlayName shadowName:(NSString *)shadowName traitCollection:(UITraitCollection *)traitCollection
{
    if (traitCollection != nil) {
        originalImage = [originalImage.imageAsset imageWithTraitCollection:traitCollection];
    }
    
    CGRect rect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, 0.0f);
    
    // Tint image
    [tintColor set];
    UIRectFill(rect);
    [originalImage drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    
    // Add overlay
    UIImage* imageOverlay = [UIImage imageNamedRetina:overlayName useMemoryCache:YES logLoadError:NO inDirectory:nil];
    if (imageOverlay != nil) {
        if (traitCollection != nil) {
            imageOverlay = [imageOverlay.imageAsset imageWithTraitCollection:traitCollection];
        }
        
        [imageOverlay drawInRect:rect blendMode:overlayBlendMode alpha:1.0f];
    }
    
    // Add shadow
    UIImage* imageShadow = [UIImage imageNamedRetina:shadowName useMemoryCache:YES logLoadError:NO inDirectory:nil];
    if (imageShadow != nil) {
        if (traitCollection != nil) {
            imageShadow = [imageShadow.imageAsset imageWithTraitCollection:traitCollection];
        }

        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        CGContextClearRect(UIGraphicsGetCurrentContext(), rect);
        
        [imageShadow drawInRect:rect];
        [image drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0f];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Add resizing
    if (!UIEdgeInsetsEqualToEdgeInsets(originalImage.capInsets, UIEdgeInsetsZero)) {
        image = [image resizableImageWithCapInsets:originalImage.capInsets resizingMode:originalImage.resizingMode];
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
