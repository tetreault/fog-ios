#import <UIKit/UIKit.h>

@interface UIBezierPath (Clipper)
+ (UIBezierPath *)pathWithClippedPoints:(NSArray const *)points;
@end
