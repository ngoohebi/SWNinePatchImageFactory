//
//  SWNinePatchImageFactory.m
//  SWNinePatchImageFactory
//
//  Created by shiami on 7/10/14.
//  Copyright (c) 2014 TaccoTap. All rights reserved.

#import "SWNinePatchImageFactory.h"
#import <math.h>

@interface SWNinePatchImageFactory (Private)
+ (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy count:(int)count;
+ (UIImage*)createResizableImageFromNinePatchImage:(UIImage*)ninePatchImage;
@end

@implementation SWNinePatchImageFactory

+ (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy count:(int)count
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:count];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char* rawData = (unsigned char*)calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
    for (int ii = 0; ii < count; ++ii) {
        CGFloat red = (rawData[byteIndex] * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += 4;
        
        NSArray* aColor = [NSArray arrayWithObjects:[NSNumber numberWithFloat:red], [NSNumber numberWithFloat:green], [NSNumber numberWithFloat:blue], [NSNumber numberWithFloat:alpha], nil];
        [result addObject:aColor];
    }
    
    free(rawData);
    
    return result;
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
    float scl = ninePatchImage.scale;
    int w = ninePatchImage.size.width * scl;
    int h = ninePatchImage.size.height * scl;
    
    
    NSArray* rgbaImage = [self getRGBAsFromImage:ninePatchImage atX:0 andY:0 count:w*h];
    NSArray* topBarRgba = [rgbaImage subarrayWithRange:NSMakeRange(1, w - 2)];
    
    NSMutableArray* leftBarRgba = [NSMutableArray arrayWithCapacity:0];
    int count = [rgbaImage count];
    for (int i = 0; i < count; i += w) {
        [leftBarRgba addObject:rgbaImage[i]];
    }
    
    //int colori = 0;
    
    int top = -1, left = -1, bottom = -1, right = -1;
    count = [topBarRgba count];
    for (int i = 0; i <= count - 1; i++) {
        NSArray* aColor = topBarRgba[i];
        //        NSLog(@"topbar left color: %@,%@,%@,%@", aColor[0], aColor[1], aColor[2], aColor[3]);
        if ([aColor[3] floatValue] == 1) {
            left = i;
            break;
        }
    }
    NSAssert(left != -1, @"The 9-patch PNG format is not correct.");
    for (int i = count - 1; i >= 0; i--) {
        NSArray* aColor = topBarRgba[i];
        //        NSLog(@"topbar right color: %@,%@,%@,%@", aColor[0], aColor[1], aColor[2], aColor[3]);
        if ([aColor[3] floatValue] == 1) {
            right = i;
            break;
        }
    }
    NSAssert(right != -1, @"The 9-patch PNG format is not correct.");
    for (int i = left + 1; i <= right - 1; i++) {
        NSArray* aColor = topBarRgba[i];
        if ([aColor[3] floatValue] < 1) {
            NSAssert(NO, @"The 9-patch PNG format is not support.");
        }
    }
    count = [leftBarRgba count];
    for (int i = 0; i <= count - 1; i++) {
        NSArray* aColor = leftBarRgba[i];
        //        NSLog(@"leftbar top color: %@,%@,%@,%@", aColor[0], aColor[1], aColor[2], aColor[3]);
        if ([aColor[3] floatValue] == 1) {
            top = i;
            break;
        }
    }
    NSAssert(top != -1, @"The 9-patch PNG format is not correct.");
    for (int i = count - 1; i >= 0; i--) {
        NSArray* aColor = leftBarRgba[i];
        //        NSLog(@"leftbar bottom color: %@,%@,%@,%@", aColor[0], aColor[1], aColor[2], aColor[3]);
        if ([aColor[3] floatValue] == 1) {
            bottom = i;
            break;
        }
    }
    NSAssert(bottom != -1, @"The 9-patch PNG format is not correct.");
    for (int i = top + 1; i <= bottom - 1; i++) {
        NSArray* aColor = leftBarRgba[i];
        if ([aColor[3] floatValue] == 0) {
            NSAssert(NO, @"The 9-patch PNG format is not support.");
        }
    }
    
    UIImage* cropImage = [ninePatchImage crop:CGRectMake(1, 1, ninePatchImage.size.width - 2, ninePatchImage.size.height - 2)];
    return [cropImage resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right)];
}

@end
