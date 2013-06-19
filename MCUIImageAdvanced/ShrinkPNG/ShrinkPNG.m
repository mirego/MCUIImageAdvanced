//
//  ShrinkPNG.h
//  Source: https://github.com/hollance/ShrinkPng
//
//  Copyright (c) 2011-2012 Matthijs Hollemans
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <ImageIO/ImageIO.h>
#import <CoreGraphics/CoreGraphics.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ShrinkPNG.h"

@implementation ShrinkPNG

CGImageRef CreateImageFromFileAtPath(NSString *filename);
CGImageRef CreateImageFromFileAtPath(NSString *filename) {
	CGDataProviderRef provider = CGDataProviderCreateWithFilename([filename UTF8String]);
	if (provider == NULL) {
		NSLog(@"Cannot open '%@'", filename);
		return NULL;
	}
    
	CGImageRef image;
    
    if ([filename hasSuffix:@"png"]) {
        image = CGImageCreateWithPNGDataProvider(provider, NULL, false, kCGRenderingIntentDefault);
    } else if ([filename hasSuffix:@"jpg"] || [filename hasSuffix:@"jpeg"]) {
        image = CGImageCreateWithJPEGDataProvider(provider, NULL, false, kCGRenderingIntentDefault);
    } else {
        image = CGImageCreateWithPNGDataProvider(provider, NULL, false, kCGRenderingIntentDefault);
    }
    
	CGDataProviderRelease(provider);
	return image;
}

unsigned char *CreateBytesFromImage(CGImageRef image);
unsigned char *CreateBytesFromImage(CGImageRef image)
{
	size_t width = CGImageGetWidth(image);
	size_t height = CGImageGetHeight(image);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL) {
		NSLog(@"Cannot create color space");
		return NULL;
	}
    
	void *contextData = calloc(width * height, 4);
	if (contextData == NULL) {
		NSLog(@"Cannot allocate memory");
		CGColorSpaceRelease(colorSpace);
		return NULL;
	}
    
	CGContextRef context = CGBitmapContextCreate(contextData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
    
	if (context == NULL) {
		NSLog(@"Cannot create context");
		free(contextData);
		return NULL;
	}
    
	CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
	CGContextDrawImage(context, rect, image);
	unsigned char *imageData = CGBitmapContextGetData(context);
	CGContextRelease(context);
#ifdef __clang_analyzer__ // Shut-up static analyser
    free(contextData);
#endif
    
	return imageData;
}

CGImageRef CreateImageFromBytes(unsigned char *data, size_t width, size_t height, unsigned int withAlpha);
CGImageRef CreateImageFromBytes(unsigned char *data, size_t width, size_t height, unsigned int withAlpha) {
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL) {
		NSLog(@"Cannot create color space");
		return NULL;
	}
    
	CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, withAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst);
	CGColorSpaceRelease(colorSpace);
    
	if (context == NULL) {
		NSLog(@"Cannot create context");
		return NULL;
	}
    
	CGImageRef ref = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	return ref;
}

unsigned char *ShrinkBitmapData(unsigned char *inData, size_t width, size_t height);
unsigned char *ShrinkBitmapData(unsigned char *inData, size_t width, size_t height)
{
	unsigned char *outData = ((width*height) > 0) ? (unsigned char *)calloc(width*height, 4) : NULL;
	if (outData == NULL) {
		NSLog(@"Cannot allocate memory");
		return NULL;
	}
    
	unsigned char *ptr = outData;
    
	for (int y = 0; y < height; y += 2) {
		for (int x = 0; x < width; x += 2) {
			size_t offset1 = (y*width + x)*4;    // top left
			size_t offset2 = offset1 + 4;        // top right
			size_t offset3 = offset1 + width*4;  // bottom left
			size_t offset4 = offset3 + 4;        // bottom right
            
			int a1 = inData[offset1 + 0];
			int r1 = inData[offset1 + 1];
			int g1 = inData[offset1 + 2];
			int b1 = inData[offset1 + 3];
            
			int a2 = inData[offset2 + 0];
			int r2 = inData[offset2 + 1];
			int g2 = inData[offset2 + 2];
			int b2 = inData[offset2 + 3];
            
			int a3 = inData[offset3 + 0];
			int r3 = inData[offset3 + 1];
			int g3 = inData[offset3 + 2];
			int b3 = inData[offset3 + 3];
            
			int a4 = inData[offset4 + 0];
			int r4 = inData[offset4 + 1];
			int g4 = inData[offset4 + 2];
			int b4 = inData[offset4 + 3];
            
			// We do +2 in order to round up if the remainder is 0.5 or more.
			int r = (r1 + r2 + r3 + r4 + 2) / 4;
			int g = (g1 + g2 + g3 + g4 + 2) / 4;
			int b = (b1 + b2 + b3 + b4 + 2) / 4;
			int a = (a1 + a2 + a3 + a4 + 2) / 4;
            
			*ptr++ = a;
			*ptr++ = r;
			*ptr++ = g;
			*ptr++ = b;
		}
	}
    
	return outData;
}

+ (CGImageRef)newShrinkedImageWithCGImage:(CGImageRef)inImage logName:(NSString *)logName {
	if (inImage != NULL) {
		size_t width = CGImageGetWidth(inImage);
		size_t height = CGImageGetHeight(inImage);
        
#if TARGET_IPHONE_SIMULATOR
        // NOTE: #ifdef TARGET_IPHONE_SIMULATOR is necessary since NSAssert won't be removed when compiling with flags for BugSense (and we don't want the user to experience a crash)
        NSAssert(((width % 2) == 0 && (height % 2) == 0), @"Cannot shrink non power of 2 image: %@", logName);
#endif
        if ((width % 2) != 0 || (height % 2) != 0) {
            NSLog(@"Cannot shrink non power of 2 image: %@", logName);
            return NULL;
        }
        
		unsigned char *inData = CreateBytesFromImage(inImage);
        
		if (inData != NULL) {
			unsigned char *outData = ShrinkBitmapData(inData, width, height);
			free(inData);
            
			if (outData != NULL) {
				CGImageAlphaInfo alpha = CGImageGetAlphaInfo(inImage);
				unsigned int hasAlpha = (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast);
				CGImageRef outImage = CreateImageFromBytes(outData, width / 2, height / 2, hasAlpha);
				free(outData);
                return outImage;
			}
		}
	}
    
	return NULL;
}

+ (CGImageRef)newShrinkedImageWithCGImage:(CGImageRef)inImage {
	return [self newShrinkedImageWithCGImage:inImage logName:[NSString stringWithFormat:@"%p", inImage]];
}

+ (CGImageRef)newShrinkedImageWithContentsOfFile:(NSString *)filename {
    if (filename == nil || [filename isEqualToString:@""])
        return NULL;
    
    CGImageRef inImage = CreateImageFromFileAtPath(filename);
    CGImageRef outImage = NULL;

    if (inImage != NULL) {
        outImage = [self newShrinkedImageWithCGImage:inImage logName:filename];
		CGImageRelease(inImage);
    }
    
    return outImage;
}

@end
