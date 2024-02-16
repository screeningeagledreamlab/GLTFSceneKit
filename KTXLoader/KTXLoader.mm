//
//  KTXLoader.m
//  GLTFSceneKit_iOS
//
//  Created by Jesse Armand on 29/11/23.
//  Copyright © 2023 DarkHorse. All rights reserved.
//

#import "KTXLoader.h"

#import <ktx.h>

@implementation KTXLoader {
    ktxTexture *texture;
    MTLPixelFormat pixelFormat;
}

+ (nullable id<MTLTexture>)createTextureFromData:(nonnull NSData *)data device:(id<MTLDevice>)device {
    return GLTFCreateTextureFromKTX2Data(data, device);
}

- (nullable instancetype)initWithData:(nonnull NSData *)data device:(id<MTLDevice>)device error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    ktx_size_t size = [data length];
    const ktx_uint8_t *bytes = (const ktx_uint8_t *)[data bytes];
    uint32_t flags = KTX_TEXTURE_CREATE_CHECK_GLTF_BASISU_BIT |
                     KTX_TEXTURE_CREATE_LOAD_IMAGE_DATA_BIT |
                     KTX_TEXTURE_CREATE_SKIP_KVDATA_BIT;

    ktxTexture2 *texture2 = NULL;
    ktxResult result = ktxTexture2_CreateFromMemory(bytes, size, flags, &texture2);
    if (result != KTX_SUCCESS) {
        *error = [NSError errorWithDomain:@"KTXLoader" code:result userInfo:nil];
    }

    if (ktxTexture2_NeedsTranscoding(texture2)) {
        BOOL deviceHasASTC = GLTFMetalDeviceSupportsASTC(device);
        BOOL deviceHasETC2 = GLTFMetalDeviceSupportsETC(device);
        BOOL deviceHasBC = GLTFMetalDeviceSupportsBC(device);

        khr_df_model_e colorModel = ktxTexture2_GetColorModel_e(texture2);

        ktx_transcode_fmt_e tf = KTX_TTF_NOSELECTION;
        if (colorModel == KHR_DF_MODEL_UASTC && deviceHasASTC) {
            tf = KTX_TTF_ASTC_4x4_RGBA;
        } else if (colorModel == KHR_DF_MODEL_ETC1S && deviceHasETC2) {
            tf = KTX_TTF_ETC;
        } else if (deviceHasASTC) {
            tf = KTX_TTF_ASTC_4x4_RGBA;
        } else if (deviceHasETC2) {
            tf = KTX_TTF_ETC2_RGBA;
        } else if (deviceHasBC) {
            tf = KTX_TTF_BC3_RGBA;
        }
        result = ktxTexture2_TranscodeBasis(texture2, tf, 0);

        if (result != KTX_SUCCESS) {
            *error = [NSError errorWithDomain:@"KTXLoader" code:result userInfo:nil];
        }

        texture = (ktxTexture *)texture2;
    }

    pixelFormat = GLTFMetalPixelFormatForVkFormat(texture2->vkFormat);

    return self;
}


- (id<MTLTexture>)loadTextureUsingDevice:(id<MTLDevice>)device {
    BOOL generateMipmaps = texture->generateMipmaps;
    NSUInteger levelCount = texture->numLevels;
    NSUInteger baseWidth = texture->baseWidth;
    NSUInteger baseHeight = texture->baseHeight;
    NSUInteger baseDepth = texture->baseDepth;
    NSUInteger maxMipLevelCount = floor(log2(MAX(baseWidth, baseHeight))) + 1;
    NSUInteger storedMipLevelCount = generateMipmaps ? maxMipLevelCount : levelCount;
    NSUInteger textureHeight = (texture->numDimensions > 1) ? baseHeight : 1;
    NSUInteger textureDepth = (texture->numDimensions > 2) ? baseDepth : 1;
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat
                                                                                          width:baseWidth
                                                                                         height:textureHeight
                                                                                      mipmapped:generateMipmaps];
    descriptor.depth = textureDepth;
    descriptor.usage = MTLTextureUsageShaderRead;
    descriptor.storageMode = MTLStorageModeShared;
#if TARGET_OS_OSX
    if (!device.hasUnifiedMemory) {
        descriptor.storageMode = MTLStorageModeManaged;
    }
#endif
    descriptor.arrayLength = 1;
    descriptor.mipmapLevelCount = storedMipLevelCount;
    
    id<MTLTexture> metalTexture = [device newTextureWithDescriptor:descriptor];

    KTX_error_code result;
    ktx_uint32_t layer = 0, faceSlice = 0;
    for (ktx_uint32_t level = 0; level < texture->numLevels; ++level) {
        ktx_size_t offset = 0;
        result = ktxTexture_GetImageOffset(texture, level, layer, faceSlice, &offset);
        ktx_uint8_t *imageBytes = ktxTexture_GetData(texture) + offset;
        ktx_uint32_t bytesPerRow = ktxTexture_GetRowPitch(texture, level);
        ktx_size_t bytesPerImage = ktxTexture_GetImageSize(texture, level);
        size_t levelWidth = MAX(1, (baseWidth >> level));
        size_t levelHeight = MAX(1, (baseHeight >> level));
        [metalTexture replaceRegion:MTLRegionMake2D(0, 0, levelWidth, levelHeight)
                   mipmapLevel:level
                         slice:faceSlice
                     withBytes:imageBytes
                   bytesPerRow:bytesPerRow
                 bytesPerImage:bytesPerImage];
    }

    ktxTexture_Destroy(texture);
    
    if (metalTexture == nil)
    {
        NSLog(@"Failed to create metal texture from ktxTexture");
        
        return nil;
    }
    return metalTexture;
}

@end

