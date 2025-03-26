////  OpenCVWrapper.mm
////  codeWithNobody
////
////  Created by Devansh Bansal on 09/02/25.
//


#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"

@interface UIImage (OpenCVWrapper)
- (void)convertToMat: (cv::Mat *)pMat : (bool)alphaExists;
@end

@implementation UIImage (OpenCVWrapper)

- (void)convertToMat: (cv::Mat *)pMat : (bool)alphaExists {
    UIImageOrientation orientation = self.imageOrientation;
    NSLog(@"Image Orientation: %ld", (long)orientation);

    UIImageToMat(self, *pMat, alphaExists);

    switch (orientation) {
        case UIImageOrientationUp:
            NSLog(@"UIImageOrientationUp - No rotation applied");
            break;
        case UIImageOrientationDown:
            NSLog(@"UIImageOrientationDown - Rotating 180 degrees");
            cv::rotate(*pMat, *pMat, cv::ROTATE_180);
            break;
        case UIImageOrientationLeft:
            NSLog(@"UIImageOrientationLeft - Rotating 90 CCW");
            cv::rotate(*pMat, *pMat, cv::ROTATE_90_COUNTERCLOCKWISE);
            break;
        case UIImageOrientationRight:
            NSLog(@"UIImageOrientationRight - Rotating 90 CW");
            cv::rotate(*pMat, *pMat, cv::ROTATE_90_CLOCKWISE);
            break;
        default:
            NSLog(@"Unknown Orientation");
            break;
    }
}


@end
@implementation OpenCVWrapper

// perfect walaa   !!!!DO NOT DELETE!!!
+ (UIImage *)addWatermarkToImage:(UIImage *)image watermark:(UIImage *)watermarkImage {
    cv::Mat mat;
    [image convertToMat:&mat :false];

    cv::Mat watermarkMat;
    [watermarkImage convertToMat:&watermarkMat :true];

    // Convert watermark to BGRA if it's not already
    if (watermarkMat.channels() == 3) {
        cv::cvtColor(watermarkMat, watermarkMat, cv::COLOR_BGR2BGRA);
    }

    // Define scale factor
    float scaleFactor = 0.2f;
    int maxWidth = mat.cols * scaleFactor;
    
    // Maintain aspect ratio
    float aspectRatio = (float)watermarkMat.cols / (float)watermarkMat.rows;
    int newWidth = maxWidth;
    int newHeight = static_cast<int>(newWidth / aspectRatio);
    
    cv::resize(watermarkMat, watermarkMat, cv::Size(newWidth, newHeight));

    // Define bottom-right position
    int x = mat.cols - watermarkMat.cols - 20;
    int y = mat.rows - watermarkMat.rows - 20;

    // Ensure main image is BGRA
    if (mat.channels() == 3) {
        cv::cvtColor(mat, mat, cv::COLOR_BGR2BGRA);
    }

    // Get the ROI where the watermark will be placed
    cv::Rect roi(x, y, watermarkMat.cols, watermarkMat.rows);
    cv::Mat imageROI = mat(roi);

    // Extract the alpha channel from watermark
    std::vector<cv::Mat> watermarkChannels;
    cv::split(watermarkMat, watermarkChannels);
    cv::Mat alpha = watermarkChannels[3];

    // Normalize alpha channel (0-1 range)
    cv::Mat alphaFloat;
    alpha.convertTo(alphaFloat, CV_32F, 1.0 / 255);

    // Blend the watermark with the image ROI
    for (int c = 0; c < 3; ++c) { // Only blend BGR channels, ignore alpha
        imageROI.forEach<cv::Vec4b>([&](cv::Vec4b &pixel, const int * position) {
            int i = position[0], j = position[1];
            pixel[c] = cv::saturate_cast<uchar>(
                (1.0 - alphaFloat.at<float>(i, j)) * pixel[c] +
                (alphaFloat.at<float>(i, j)) * watermarkMat.at<cv::Vec4b>(i, j)[c]
            );
        });
    }

    return MatToUIImage(mat);
}


+ (UIImage *)cropImage:(UIImage *)image withRect:(CGRect)rect {
    cv::Mat mat;
    UIImageToMat(image, mat);

    // Convert CGRect to cv::Rect
    cv::Rect roi(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    // Ensure ROI is within bounds
    roi = roi & cv::Rect(0, 0, mat.cols, mat.rows);

    cv::Mat croppedMat = mat(roi).clone();

    return MatToUIImage(croppedMat);
}


+ (UIImage *)applyBlurToImage:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat:&mat :false];
    cv::GaussianBlur(mat, mat, cv::Size(15, 15), 0);
    return MatToUIImage(mat);
}


+ (UIImage *)applyBilateralFilterToImage:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat:&mat :false];

    // Convert 4-channel (RGBA) to 3-channel (RGB) if needed
    if (mat.type() == CV_8UC4) {
        cv::cvtColor(mat, mat, cv::COLOR_RGBA2RGB);
    }

    // Ensure the image is either CV_8UC1 (grayscale) or CV_8UC3 (RGB)
    if (mat.type() != CV_8UC1 && mat.type() != CV_8UC3) {
        NSLog(@"Unsupported image format for bilateral filter");
        return image;
    }

    // Apply bilateral filter
    cv::Mat filteredMat;
    cv::bilateralFilter(mat, filteredMat, 9, 75, 75);

    return MatToUIImage(filteredMat);
}

+ (UIImage *)applyEdgeDetectionToImage:(UIImage *)image {
    cv::Mat mat, edges;
    [image convertToMat:&mat :false];
    cv::Canny(mat, edges, 100, 200);
    cv::cvtColor(edges, mat, cv::COLOR_GRAY2BGR);
    return MatToUIImage(mat);
}

+ (UIImage *)convertToGrayscale:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat:&mat :false];
    cv::cvtColor(mat, mat, cv::COLOR_BGR2GRAY);
    return MatToUIImage(mat);
}

+ (UIImage *)applySharpenToImage:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat:&mat :false];
    cv::Mat kernel = (cv::Mat_<float>(3, 3) <<  0, -1,  0, -1,  5, -1,  0, -1,  0);
    cv::filter2D(mat, mat, -1, kernel);
    return MatToUIImage(mat);
}


// Helper function to convert cv::Mat to UIImage

UIImage* MatToUIImage(const cv::Mat& mat) {
    if (mat.empty()) return nil;

    cv::Mat convertedMat;
    if (mat.channels() == 4) {
        convertedMat = mat;  // Already BGRA, use directly
    } else {
        cv::cvtColor(mat, convertedMat, cv::COLOR_BGR2BGRA);
    }

    NSData *data = [NSData dataWithBytes: convertedMat.data length: convertedMat.elemSize() * convertedMat.total()];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef imageRef = CGImageCreate(
        convertedMat.cols, convertedMat.rows,
        8, 32, convertedMat.step[0],
        colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast,
        provider, NULL, false, kCGRenderingIntentDefault
    );

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return image;
}

@end

