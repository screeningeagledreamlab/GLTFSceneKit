//
//  KTXLoader.h
//  KTXLoader
//
//  Created by Jesse Armand on 30/11/23.
//  Copyright © 2023 DarkHorse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import <KTXLoader/GLTFKTX2Support.h>

//! Project version number for KTXLoader.
FOUNDATION_EXPORT double KTXLoaderVersionNumber;

//! Project version string for KTXLoader.
FOUNDATION_EXPORT const unsigned char KTXLoaderVersionString[];

NS_ASSUME_NONNULL_BEGIN

@interface KTXLoader : NSObject

+ (nullable id<MTLTexture>)createTextureFromData:(nonnull NSData *)data device:(id<MTLDevice>)device;

- (nullable instancetype)initWithData:(NSData *)data device:(id<MTLDevice>)device error:(NSError **)error;

- (id<MTLTexture>)loadTextureUsingDevice:(id<MTLDevice>)device;

@end

NS_ASSUME_NONNULL_END
