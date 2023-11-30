
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const GLTFMediaTypeKTX2;

extern MTLPixelFormat GLTFMetalPixelFormatForVkFormat(int vkformat);

extern id<MTLTexture> _Nullable GLTFCreateTextureFromKTX2Data(NSData *data, id<MTLDevice> device);

extern BOOL GLTFMetalDeviceSupportsETC(id<MTLDevice> device);

extern BOOL GLTFMetalDeviceSupportsASTC(id<MTLDevice> device);

extern BOOL GLTFMetalDeviceSupportsBC(id<MTLDevice> device);

NS_ASSUME_NONNULL_END
