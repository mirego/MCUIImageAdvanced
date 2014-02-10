# MCUIImageAdvanced - UIImage advanced
[![Badge w/ Version](https://cocoapod-badges.herokuapp.com/v/MCUIImageAdvanced/badge.png)](https://cocoadocs.org/docsets/MCUIImageAdvanced)
[![Badge w/ Platform](https://cocoapod-badges.herokuapp.com/p/MCUIImageAdvanced/badge.png)](https://cocoadocs.org/docsets/MCUIImageAdvanced)


Utility methods for [`UIImage`](http://developer.apple.com/library/ios/#documentation/UIKit/Reference/UIImage_Class/Reference/Reference.html).

## Using

### Animations

An easy way of creating a `NSArray` of `UIImage` for annimation for `UIImageView` `setAnimationImages:`

```objective-c

#import 'UIImage+MCAdvanced.h'

- (void)funWithAnimations
{
  // UIImage array animations to use with the UIImageView setAnimationImages:
  // expects file name to be numbered sequentialy.
  NSArray* animationImages = [UIImage animationImagesWithPrefix:@"funWithAnimations" imageQuantity:24];
  // [funWithAnimations0.png, funWithAnimations1.png, funWithAnimations2,png, ... funWithAnimations23.png]

  // Save as above put resizes the images as specified. Use CGSizeZero for original size
  NSArray* small = [UIImage animationImagesWithPrefix:@"funWithAnimations" imageQuantity:24 resizeImages:CGSizeMake(44,44)];

  // Save as the first one but specify the number format
  NSArray* zeroPrefixed = [UIImage animationImagesWithPrefix:@"funWithAnimations" imageQuantity:24 resizeImages:CGSizeZero mask:@"%02u"];
  // [funWithAnimations00.png, funWithAnimations01.png, funWithAnimations02,png, ... funWithAnimations23.png]

  // Same as the first one but starting at 1
  NSArray*  = [UIImage animationImagesWithPrefix:@"funWithAnimations" imageQuantity:24 resizeImages:CGSizeZero mask:@"%u" startingIndex:1];
  // [funWithAnimations1.png, funWithAnimations2.png, funWithAnimations3,png, ... funWithAnimations24.png]
}
```

### Blending images and colors

Blend `UIImage` and `UIColor` together using different [`CGBlendMode`](https://developer.apple.com/library/ios/#documentation/graphicsimaging/reference/CGContext/Reference/reference.html).

```objective-c
#import 'UIImage+MCAdvanced.h'

- (void)funWithBlending
{

  // Blend images
  // layers: NSArray of UIColor and/or UIImage (the last item is the top most layer).
  UIImage *blendedImage = [UIImage blendedImageWithImage:srcImage
                                                  layers:@[[UIColor colorWithWhite:1.0 alpha:0.2]]
                                               blendMode:kCGBlendModeNormal;

  // Same as above bug using different blendModes for each layer.
  UIImage *blendedImage = [UIImage blendedImageWithImage:srcImage
                                                  layers:@[[UIColor colorWithWhite:1.0 alpha:0.2],[UIColor colorWithWhite:0.2 alpha:0.2]]
                                              blendModes:@[@(kCGBlendModeLuminosity),@(kCGBlendModeDarken)]
                                        defaultBlendMode:kCGBlendModeNormal];

  // Render a blended image in a specific CGContext
  UIImage *blendedImage = [UIImage blendedImageInContext:ctx
                                                withRect:CGSizeMake(CGBitmapContextGetWidth(ctx),CGBitmapContextGetHeight(ctx))
                                                   image:srcImage
                                                  layers:@[[UIColor colorWithWhite:1.0 alpha:0.2]]
                                              blendModes:nil
                                        defaultBlendMode:kCGBlendModeNormal];
}
```

### Generating simple images

Obtain simple `UIImage`s drawned with CoreGraphics

```objective-c
#import 'UIImage+MCAdvanced.h'

- (void)funWithImageGeneration
{
  // Square opaque image
  UIImage *redSquareImage = [UIImage mc_generateImageOfSize:CGSizeMake(100,100) color:[UIColor redcolor]];
                                                  
  // Square translucent image
  UIImage *redTranslucentSquareImage = [UIImage mc_generateImageOfSize:CGSizeMake(100,100) color:[[UIColor redcolor] colorWithAlphaComponent:0.5f] opaque:NO];
 
  // Circle image
  UIImage *redCircleImage = [UIImage mc_generateCircleImageOfSize:CGSize(100,100) color:[UIColor redcolor]];  
}
```


### Retina and non-retina images (@2x)

Make your application smaller by keeping only the `@2x` resources. The retina
image call will load the `@2x` version and generate the standard definition.
Keeping it in a memory cache for performance if needed.

```objective-c
- (void)funWithRetinaImages
{
  // Load funWithRetinaImage@2x.png
  UIImage* img = [UIImage imageNamedRetina:@"funWithRetinaImage.png"];

  // Force loading the image from flash every time.
  UIImage* img = [UIImage imageNamedRetina:@"funWithRetinaImage.png" useMemoryCache:NO];

  // Load the image with the proper resolution and tint it.
  UIImage* img = [UIImage imageNamedRetina:@"funWithRetinaImage.png" tintColor:[UIColor colorWithWhite:1.0 alpha:0.2]]

  // Load an image from disk and tint it using a specific blendmode
  UIImage* img = [UIImage imageNamedRetina:@"funWithRetinaImage.png" tintColor:[UIColor colorWithWhite:1.0 alpha:0.2] overlayBlendMode:kCGBlendModeOverlay];

  // Load an image from disk and tint it using another image and, if needed,
  // with a shadow using an image too (use nil if not needed).
  UIImage* img = [UIImage imageNamedRetina:@"funWithRetinaImage.png" tintColor:[UIColor colorWithWhite:1.0 alpha:0.2] overlayName:@"overlay.png" shadowName:nil];

  // Pre-shrink all @2x image in the resources in the background.
  // `progressBlock` will be called with index and count set to -1 if nothing
  // is to be done (no need to warmup images).
  UIImage* img = [UIImage imageNamedRetinaWarmupWithProgressBlock:(void (^)(NSString* imageName, NSUInteger index, NSUInteger count))progressBlock];
}
```

## Adding to your project

If you're using [`CocoaPods`](http://cocoapods.org/), there's nothing simpler.
Add the following to your [`Podfile`](http://docs.cocoapods.org/podfile.html)
and run `pod install`

```ruby
pod 'MCUIImageAdvanced', :git => 'https://github.com/mirego/MCUIImageAdvanced.git'
```

Don't forget to `#import "UIImage+MCAdvanced.h"` where it's needed.


## License

MCUIImageAdvanced is © 2013 [Mirego](http://www.mirego.com) and may be freely
distributed under the [New BSD license](http://opensource.org/licenses/BSD-3-Clause).
See the [`LICENSE.md`](https://github.com/mirego/MCUIImageAdvanced/blob/master/LICENSE.md) file.

## About Mirego

[Mirego](http://mirego.com) is a team of passionate people who believe that work is a place where you can innovate and have fun. We're a team of [talented people](http://life.mirego.com) who imagine and build beautiful Web and mobile applications. We come together to share ideas and [change the world](http://mirego.org).

We also [love open-source software](http://open.mirego.com) and we try to give back to the community as much as we can.
