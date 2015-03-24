//
//  SWNinePatchImageFactory.m
//  SWNinePatchImageFactory
//
//  Created by shiami on 7/10/14.
//  Copyright (c) 2014 TaccoTap. All rights reserved.

#import "SWNinePatchImageFactory.h"

@interface SWNinePatchImageFactory (Private)
+ (UIImage*)createResizableImageFromNinePatchImage:(UIImage*)ninePatchImage;
+ (UIEdgeInsets) getNinePatchInsets: (UIImage *) ninePatchImage;
@end

@implementation SWNinePatchImageFactory

+ (UIEdgeInsets) getNinePatchInsets: (UIImage *) ninePatchImage {
    UIEdgeInsets insets = UIEdgeInsetsMake(NSNotFound, NSNotFound, NSNotFound, NSNotFound);
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(ninePatchImage.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    const int width = ninePatchImage.size.width * ninePatchImage.scale;
    const int height = ninePatchImage.size.height * ninePatchImage.scale;
    NSUInteger bytesPerPixel = 4;
    { // top bottom
        float top = NSNotFound;
        float bottom = NSNotFound;
        for (int i = 0; i < height; i++) {
            
            NSUInteger topPixel = ((width * i) + 0) * bytesPerPixel;
            NSUInteger bottomPixel = ((width * (height - i)) + 0) * bytesPerPixel;
            UInt8 alphaTop = data[topPixel + 3];
            UInt8 alphaBottom = data[bottomPixel + 3];
            
            if (top == NSNotFound && alphaTop != 0) {
                top = i;
            }
            if (bottom == NSNotFound && alphaBottom != 0) {
                bottom = height - i;
            }
            if (bottom != NSNotFound && top != NSNotFound) {
                break;
            }
        }
        
        insets.top = MAX(top, 0);
        insets.bottom = MAX((height - bottom - 1), 0);
    }
    { // left right
        float left = NSNotFound;
        float right = NSNotFound;
        for (int i = 0; i < width; i++) {
            
            NSUInteger leftPixel = ((i) + 0) * bytesPerPixel;
            NSUInteger rightPixel = (((width - i)) + 0) * bytesPerPixel;
            UInt8 alphaLeft = data[leftPixel + 3];
            UInt8 alphaRight = data[rightPixel + 3];
            
            if (left == NSNotFound && alphaLeft != 0) {
                left = i;
            }
            if (right == NSNotFound && alphaRight != 0) {
                right = width - i;
            }
            if (right != NSNotFound && left != NSNotFound) {
                break;
            }
        }
        
        insets.left = MAX(left, 0);
        insets.right = MAX((width - right - 1), 0);
    }
    CFRelease(pixelData);
    
    insets.top /= ninePatchImage.scale;
    insets.bottom /= ninePatchImage.scale;
    insets.left /= ninePatchImage.scale;
    insets.right /= ninePatchImage.scale;
    
    NSAssert(insets.top != NSNotFound, @"The 9-patch PNG format is not support insets.top not found.");
    NSAssert(insets.bottom != NSNotFound, @"The 9-patch PNG format is not support insets.bottom not found.");
    NSAssert(insets.left != NSNotFound, @"The 9-patch PNG format is not support insets.left not found.");
    NSAssert(insets.right != NSNotFound, @"The 9-patch PNG format is not support insets.right not found.");
    
    return insets;
}

+ (UIImage*)createResizableNinePatchImageNamed:(NSString*)name
{
    NSAssert([name hasSuffix:@".9"], @"The image name is not ended with .9");
    
    NSString* fixedImageFilename = [NSString stringWithFormat:@"%@%@", name, @".png"];
    UIImage* oriImage = [UIImage imageNamed:fixedImageFilename];
    
    NSAssert(oriImage != nil, @"The input image is incorrect: ");
    
    NSString* fixed2xImageFilename = [NSString stringWithFormat:@"%@%@", [name substringWithRange:NSMakeRange(0, name.length - 2)], @"@2x.9.png"];
    UIImage* ori2xImage = [UIImage imageNamed:fixed2xImageFilename];
    if (ori2xImage != nil) {
        oriImage = ori2xImage;
        NSLog(@"NinePatchImageFactory[Info]: Using 2X image: %@", fixed2xImageFilename);
    } else {
        NSLog(@"NinePatchImageFactory[Info]: Using image: %@", fixedImageFilename);
    }
    
    return [self createResizableImageFromNinePatchImage:oriImage];
}

+ (UIImage*)createResizableNinePatchImage:(UIImage*)image
{
    return [self createResizableImageFromNinePatchImage:image];
}

+ (UIImage*)createResizableImageFromNinePatchImage:(UIImage*)ninePatchImage
{
    UIEdgeInsets insets = [self getNinePatchInsets: ninePatchImage];
    
    UIImage* cropImage = [ninePatchImage crop:CGRectMake(1, 1, ninePatchImage.size.width - 2, ninePatchImage.size.height - 2)];
    
    return [cropImage resizableImageWithCapInsets:insets];
}

@end
