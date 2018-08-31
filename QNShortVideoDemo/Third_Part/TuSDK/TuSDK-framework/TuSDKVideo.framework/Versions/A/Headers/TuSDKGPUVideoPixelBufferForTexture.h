//
//  TuSDKGPUVideoPixelBufferForTexture.h
//  TuSDKVideo
//
//  Created by sprint on 04/05/2018.
//  Copyright © 2018 TuSDK. All rights reserved.
//

#import <GPUImage/GPUImage.h>
#import "TuSDKVideoImport.h"
#import "TuSDKMovieInfo.h"
#import "TuSDKAssetVideoDecoder.h"
#import "TuSDKTextureCoordinateCropBuilder.h"

/**
 * PixelBuffer 上传到 GPU
 */
@interface TuSDKGPUVideoPixelBufferForTexture : GPUImageOutput <TuSDKSampleBufferInput>
{
    CGSize _outputSize;
}

/**
 * 输入的画面方向
 */
@property (nonatomic) GPUImageRotationMode inputRotation;

/**
 * 输出的画面方向
 */
@property (nonatomic) GPUImageRotationMode outputRotation;

/**
 * 输入的采样数据类型
 * 支持： kCVPixelFormatType_420YpCbCr8BiPlanarFullRange | kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange kCVPixelFormatType_32BGRA
 */
@property (nonatomic) OSType inputPixelFormatType;

/**
 期望输出的视频宽高
 */
@property (nonatomic) CGSize outputSize;

/**
 输入的视频宽高
 */
@property (nonatomic,readonly) CGSize inputSize;

/**
 * 设置材质坐标计算接口
 */
@property (nonatomic) TuSDKTextureCoordinateCropBuilder *textureCoordinateBuilder;

@end
