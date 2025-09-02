#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageProcessor : NSObject

+ (nullable NSData *)resizeImageData:(NSData *)data
                               width:(int)width
                              height:(int)height
                             quality:(int)quality;

@end

NS_ASSUME_NONNULL_END
