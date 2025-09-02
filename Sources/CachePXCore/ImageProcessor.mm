#import "ImageProcessor.h"

#ifdef NO
#undef NO
#endif

#ifdef YES
#undef YES
#endif

#import <opencv2/opencv.hpp>

@implementation ImageProcessor

+ (nullable NSData *)resizeImageData:(NSData *)data
                               width:(int)targetWidth
                              height:(int)targetHeight
                             quality:(int)quality
{
    if (!data || data.length == 0) return nil;
    
    std::vector<uchar> buffer(data.length);
    memcpy(buffer.data(), data.bytes, data.length);
    
    cv::Mat input = cv::imdecode(buffer, cv::IMREAD_UNCHANGED);
    if (input.empty()) return nil;
    
    int originalWidth = input.cols;
    int originalHeight = input.rows;
    double scaleW = (double)targetWidth / originalWidth;
    double scaleH = (double)targetHeight / originalHeight;
    double scale = std::min(scaleW, scaleH);
    int newWidth = (int)(originalWidth * scale);
    int newHeight = (int)(originalHeight * scale);
    
    cv::Mat output;
    cv::resize(input, output, cv::Size(newWidth, newHeight), 0, 0, cv::INTER_AREA);
    
    NSString *ext = @".jpg";
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    if (data.length >= 4) {
        if (bytes[0] == 0xFF && bytes[1] == 0xD8) ext = @".jpg";
        else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) ext = @".png";
        else if (bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' && bytes[3] == 'F') ext = @".webp";
        else if (bytes[0] == 'B' && bytes[1] == 'M') ext = @".bmp";
    }
    
    std::vector<int> params;
    if ([ext isEqualToString:@".jpg"]) {
        params = {cv::IMWRITE_JPEG_QUALITY, std::min(std::max(quality, 0), 100)};
    } else if ([ext isEqualToString:@".png"]) {
        params = {cv::IMWRITE_PNG_COMPRESSION, std::min(std::max(quality / 10, 0), 9)};
    } else if ([ext isEqualToString:@".webp"]) {
        params = {cv::IMWRITE_WEBP_QUALITY, std::min(std::max(quality, 0), 100)};
    }
    
    std::vector<uchar> outBuf;
    if (!cv::imencode([ext UTF8String], output, outBuf, params)) {
        return nil;
    }
    
    return [NSData dataWithBytes:outBuf.data() length:outBuf.size()];
}

@end
