#import "UIBezierPath+Clipper.h"
#include "clipper.hpp"

using namespace ClipperLib;

@implementation UIBezierPath (Clipper)

static CGPoint cgPointWithIntPoint(IntPoint const &intPoint) {
    return CGPointMake(intPoint.X, intPoint.Y);
}

+ (UIBezierPath *)pathWithClippedPoints:(const NSArray *)points {

    Path subject;
    for (NSValue *pointValue in points) {
        CGPoint point = pointValue.CGPointValue;
        subject << IntPoint(point.x, point.y);
    }

    Clipper clipper;
    clipper.AddPath(subject, ptSubject, true);
    Paths solutions;
    clipper.Execute(ctUnion, solutions, pftNonZero, pftNonZero);

    UIBezierPath *path = [UIBezierPath bezierPath];
    for (size_t i = 0; i < solutions.size(); ++i) {
        Path& solution = solutions[i];
        if (solution.size() > 0) {
            [path moveToPoint:cgPointWithIntPoint(solution[0])];
            for (size_t j = 1; j < solution.size(); ++j) {
                [path addLineToPoint:cgPointWithIntPoint(solution[j])];
            }

            [path closePath];
        }
    }

    return path;
}

@end
