//
//  UIImage+Advanced.m
//  UIImageAdvanced

//
//  Created by Simon Audet on 10-08-03.
//  Copyright (c) 2012 Mirego Inc. All rights reserved.
//

#import "UIImage+Advanced.h"
#import "UIImage+ProportionalFill.h"
#import "ShrinkPNG.h"

#include <sys/stat.h>
#include <sys/time.h>
#include <mach/mach.h>
#include <mach/mach_host.h>

@implementation UIImage(Advanced)

/////////////////////////////////////////////////////
#pragma mark methods resizing images
/////////////////////////////////////////////////////
- (UIImage*)resizedImageToSize:(CGSize)size {
    return [self resizedImageToSize:size opaque:NO];
}

- (UIImage*)resizedImageToSize:(CGSize)size opaque:(BOOL)opaque {
    if (UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0);
    else
        UIGraphicsBeginImageContext(size);
    
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();    
    return image;
}

- (UIImage*)resizedImageToSize:(CGSize)size opaque:(BOOL)opaque inSize:(CGSize)inSize {
    return [self resizedImageToSize:size opaque:opaque inSize:inSize backgroundColor:nil];
}

- (UIImage*)resizedImageToSize:(CGSize)size opaque:(BOOL)opaque inSize:(CGSize)inSize backgroundColor:(UIColor *)backgroundColor {
    return [self resizedImageToSize:size opaque:opaque inSize:inSize backgroundColor:backgroundColor foregroundColor:nil];
}

- (UIImage*)resizedImageToSize:(CGSize)size opaque:(BOOL)opaque inSize:(CGSize)inSize backgroundColor:(UIColor *)backgroundColor foregroundColor:(UIColor *)foregroundColor {
    if (size.width <= 0 || size.height <= 0 || inSize.width <= 0 || inSize.height <= 0)
        return nil;
    
    if (UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(inSize, opaque, 0.0);
    else
        UIGraphicsBeginImageContext(inSize);
    
    if (opaque == YES) {
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        CGFloat alpha = CGColorGetAlpha([backgroundColor CGColor]);
        if (alpha > 0)
            CGContextSetFillColorWithColor(currentContext, [backgroundColor CGColor]);
        else
            CGContextSetFillColorWithColor(currentContext, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(currentContext, CGRectMake(0, 0, inSize.width, inSize.height));
    }
    
    [self drawInRect:CGRectMake(floorf((inSize.width - size.width) * 0.5), floorf((inSize.height - size.height) * 0.5), size.width, size.height)];
    
    if (foregroundColor) {
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(currentContext, [foregroundColor CGColor]);
        CGContextFillRect(currentContext, CGRectMake(0, 0, inSize.width, inSize.height));
    }
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();    
    return image;
}

- (UIImage*)croppedImageToRect:(CGRect)rect
{
    //create a context to do our clipping in
    if (UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0); // 0.0 = scale factor to support retina display
    else
        UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    //create a rect with the size we want to crop the image to
    //the X and Y here are zero so we start at the beginning of our
    //newly created context
    CGRect clippedRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
    CGContextClipToRect( currentContext, clippedRect);
    
    //create a rect equivalent to the full size of the image
    //offset the rect by the X and Y we want to start the crop
    //from in order to cut off anything before them
    CGRect drawRect = CGRectMake(rect.origin.x * -1,
                                 rect.origin.y * -1,
                                 self.size.width,
                                 self.size.height);
    
    //draw the image to our clipped context using our offset rect
    //CGContextDrawImage(currentContext, drawRect, imageToCrop.CGImage);
    [self drawInRect:drawRect];
    
    //pull the image from our cropped context
    UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    //Note: this is autoreleased
    return cropped;
}

- (UIImage *)imageWithRoundedCornersRadius:(CGFloat)radius {
    return [self imageWithRoundedCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
}

- (UIImage *)imageWithRoundedCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii {
    if (self.size.width <= 0 || self.size.width <= 0)
        return self;
    
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    if (UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    else
        UIGraphicsBeginImageContext(rect.size);
    
    [[UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:cornerRadii] addClip];
    [self drawInRect:rect];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

//////////////////////////////////////////////////////////////
#pragma mark Image and color blending
//////////////////////////////////////////////////////////////
+ (UIImage*)blendedImageWithImage:(UIImage*)image
                           layers:(NSArray*)layers
                        blendMode:(CGBlendMode)blendMode {
    return [self blendedImageWithImage:image
                                layers:layers
                            blendModes:nil
                      defaultBlendMode:blendMode];
}

+ (UIImage*)blendedImageWithImage:(UIImage*)image
                           layers:(NSArray*)layers
                       blendModes:(NSArray*)blendModes
                 defaultBlendMode:(CGBlendMode)defaultBlendMode {
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
    
    // Create an AUTORELEASE image from the drawing context
    UIImage* blendedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return blendedImage;
}

+ (void)blendedImageInContext:(CGContextRef)context
                     withRect:(CGRect)rect
                        image:(UIImage*)image
                       layers:(NSArray*)layers
                   blendModes:(NSArray*)blendModes
             defaultBlendMode:(CGBlendMode)defaultBlendMode {
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
        for (NSUInteger i = 0; i < layers.count; i++) {
            // Blend mode
            if (blendModes != nil && i < blendModes.count) {
                CGContextSetBlendMode (context, [[blendModes objectAtIndex:i] intValue]);
            } else {
                CGContextSetBlendMode (context, defaultBlendMode);
            }
            
            id layer = [layers objectAtIndex:i];
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

+ (CGSize)proportionalSizeForSize:(CGSize)imageSize scaledToSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetSize.width / imageSize.width;
        CGFloat heightFactor = targetSize.height / imageSize.height;
        CGFloat scaleFactor = (widthFactor < heightFactor) ? widthFactor : heightFactor;
        targetSize = CGSizeMake(ceilf(imageSize.width * scaleFactor), ceilf(imageSize.height * scaleFactor));
    }
    
    return targetSize;
}

- (CGSize)proportionalSizeScaledToSize:(CGSize)targetSize {
    return [UIImage proportionalSizeForSize:[self size] scaledToSize:targetSize];
}

+ (UIImage*)imageNamedNoCache:(NSString *)name {
    return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:nil]];
}

+ (UIImage*)imageNamedRetina:(NSString *)name {
    return [self imageNamedRetina:name useMemoryCache:YES];
}

+ (UIImage*)imageNamedRetina:(NSString *)name useMemoryCache:(BOOL)useMemoryCache {
    return [self imageNamedRetina:name useMemoryCache:useMemoryCache logLoadError:NO];
}

+ (natural_t)totalMemory {
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

+ (NSString*)mcCleanImageName:(NSString *)name {
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

+ (UIImage*)imageNamedRetina:(NSString *)name useMemoryCache:(BOOL)useMemoryCache logLoadError:(BOOL)logLoadError {
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

+ (void)imageNamedRetinaWarmupWithProgressBlock:(void (^)(NSString* imageName, NSUInteger index, NSUInteger count))progressBlock {
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

+ (NSString *)pathForNonRetinaResource:(NSString *)name ofType:(NSString *)type {
    return [self pathForNonRetinaResource:name ofType:type image:NULL];
}

+ (NSString *)pathForNonRetinaResource:(NSString *)name ofType:(NSString *)type image:(UIImage **)image {
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


+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor {
    return [self imageNamedRetina:name tintColor:tintColor overlayBlendMode:kCGBlendModeOverlay overlayName:[name stringByAppendingString:@"_overlay"] shadowName:[name stringByAppendingString:@"_shadow"]];
}

+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode {
    return [self imageNamedRetina:name tintColor:tintColor overlayBlendMode:overlayBlendMode overlayName:[name stringByAppendingString:@"_overlay"] shadowName:[name stringByAppendingString:@"_shadow"]];
}

+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayName:(NSString *)overlayName shadowName:(NSString *)shadowName {
    return [self imageNamedRetina:name tintColor:tintColor overlayBlendMode:kCGBlendModeOverlay overlayName:overlayName shadowName:shadowName];
}

+ (UIImage *)imageNamedRetina:(NSString *)name tintColor:(UIColor *)tintColor overlayBlendMode:(CGBlendMode)overlayBlendMode overlayName:(NSString *)overlayName shadowName:(NSString *)shadowName {
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

- (UIImage*)scaledImageFromScale:(CGFloat)fromScale {
    return [self scaledImageFromScale:fromScale toScale:[[UIScreen mainScreen] scale]];
}

- (UIImage*)scaledImageFromScale:(CGFloat)fromScale toScale:(CGFloat)toScale {
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

//////////////////////////////////////////////////////////////
#pragma mark
//////////////////////////////////////////////////////////////



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
        if (height > 0.0)
        {
            size = CGSizeMake(3 + (cornerRadius * 2) + (edgeInsets.left + edgeInsets.right), height);
        }
        else
        {
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
        if (height > 0.0)
        {
            CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, CGRectGetMaxY(rect)), kCGGradientDrawsAfterEndLocation);
        }
        else
        {
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

//////////////////////////////////////////////////////////////
#pragma mark animated images
//////////////////////////////////////////////////////////////
+ (NSArray*)animationImagesWithPrefix:(NSString*)imagesPrefix
                        imageQuantity:(NSInteger)imageQuantity {
    return [self animationImagesWithPrefix:imagesPrefix imageQuantity:imageQuantity resizeImages:CGSizeZero mask:@"%i"];
}

+ (NSArray*)animationImagesWithPrefix:(NSString*)imagesPrefix
                        imageQuantity:(NSInteger)imageQuantity
                         resizeImages:(CGSize)resizeImages {
    return [self animationImagesWithPrefix:imagesPrefix imageQuantity:imageQuantity resizeImages:resizeImages mask:@"%i"];
}

+ (NSArray*)animationImagesWithPrefix:(NSString*)imagesPrefix
                        imageQuantity:(NSInteger)imageQuantity
                         resizeImages:(CGSize)resizeImages
                                 mask:(NSString*)mask {
    return [self animationImagesWithPrefix:imagesPrefix imageQuantity:imageQuantity resizeImages:resizeImages mask:mask startingIndex:0];
}

+ (NSArray *)animationImagesWithPrefix:(NSString *)imagesPrefix
                         imageQuantity:(NSInteger)imageQuantity
                          resizeImages:(CGSize)resizeImages
                                  mask:(NSString *)mask
                         startingIndex:(NSInteger)startingIndex {
    if (imageQuantity <= 0)
        return nil;
    
    // Load the images from disk
    NSMutableArray* imageArray = [[NSMutableArray alloc] initWithCapacity:imageQuantity];
    for (NSInteger index = startingIndex; index < (imageQuantity + startingIndex); index++) {
        // Create image path from mask, load image
        NSString* imageName = [imagesPrefix stringByAppendingFormat:mask, index];
        UIImage* image = [UIImage imageNamedRetina:imageName];
        
        // Resize image if requested to
        // FIXME: Cache resized copy
        if ((resizeImages.width > 0) && (resizeImages.height > 0)) {
            image = [image imageScaledToFitSize:resizeImages];
        }
        
        [imageArray addObject:image];
    }
    
    return imageArray;
}

@end
