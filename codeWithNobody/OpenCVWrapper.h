#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (UIImage *)addWatermarkToImage:(UIImage *)image watermark:(UIImage *)watermarkImage;
+ (UIImage *)cropImage:(UIImage *)image withRect:(CGRect)rect;
+ (UIImage *)applyBlurToImage:(UIImage *)image;
+ (UIImage *)applyBilateralFilterToImage:(UIImage *)image;
+ (UIImage *)applyEdgeDetectionToImage:(UIImage *)image;
+ (UIImage *)convertToGrayscale:(UIImage *)image;
+ (UIImage *)applySharpenToImage:(UIImage *)image;



@end
