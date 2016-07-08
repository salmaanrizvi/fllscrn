//
//  FLSCNImagePanScrollbarView.m
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/7/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

#import "FLSCNImagePanScrollbarView.h"

@interface FLSCNImagePanScrollbarView()

@property (nonatomic, strong) CAShapeLayer *scrollBarLayer;
@property (nonatomic, strong) UIBezierPath *scrollBarPath;
@property (nonatomic) UIEdgeInsets edgeInsets;

@end

@implementation FLSCNImagePanScrollbarView

- (id)initWithFrame:(CGRect)frame edgeInsets:(UIEdgeInsets)edgeInsets;
{
    if (self = [super initWithFrame:frame])
    {
        _edgeInsets = edgeInsets;
        self.scrollBarPath = [UIBezierPath bezierPath];
        [self.scrollBarPath moveToPoint:CGPointMake(edgeInsets.left, CGRectGetHeight(self.bounds) - edgeInsets.bottom)];
        [self.scrollBarPath addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - edgeInsets.right, CGRectGetHeight(self.bounds) - edgeInsets.bottom)];
        
        // Creates a point for the path on the right
        
        //[scrollBarPath addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - edgeInsets.right, CGRectGetHeight(self.bounds) - self.bounds.size.height + 10)];
        
        CAShapeLayer *scrollBarBackgroundLayer = [CAShapeLayer layer];
        scrollBarBackgroundLayer.path = self.scrollBarPath.CGPath;
        scrollBarBackgroundLayer.lineWidth = 1.5f;
        scrollBarBackgroundLayer.strokeColor = [[[UIColor whiteColor] colorWithAlphaComponent:0.1] CGColor];
        scrollBarBackgroundLayer.fillColor = [[UIColor clearColor] CGColor];
        
        [self.layer addSublayer:scrollBarBackgroundLayer];
        
        self.scrollBarLayer = [CAShapeLayer layer];
        self.scrollBarLayer.path = self.scrollBarPath.CGPath;
        self.scrollBarLayer.lineWidth = 1.5f;
        self.scrollBarLayer.strokeColor = [[UIColor whiteColor] CGColor];
        self.scrollBarLayer.fillColor = [[UIColor clearColor] CGColor];
        self.scrollBarLayer.actions = @{@"strokeStart": [NSNull null], @"strokeEnd": [NSNull null]};
        
        [self.layer addSublayer:self.scrollBarLayer];
    }
    return self;
}

- (void)updateWithScrollAmount:(CGFloat)scrollAmount forScrollableWidth:(CGFloat)scrollableWidth inScrollableArea:(CGFloat)scrollableArea
{
    self.scrollBarLayer.strokeStart = scrollAmount * scrollableArea;
    self.scrollBarLayer.strokeEnd = (scrollAmount * scrollableArea) + scrollableWidth;
}


-(void) updatePath:(BOOL) topLeft {
    
    CGFloat percentOfScreenSize = 1/20.;
    
    if(topLeft) { // draw top left corner
        self.scrollBarPath = [UIBezierPath bezierPath];
        [self.scrollBarPath moveToPoint:CGPointMake(self.bounds.size.width*percentOfScreenSize, 0.f)];
        [self.scrollBarPath addLineToPoint:CGPointMake(0.f, 0.f)];
        [self.scrollBarPath moveToPoint:CGPointMake(0.f, self.bounds.size.height*percentOfScreenSize)];
        [self.scrollBarPath addLineToPoint:CGPointMake(0.f, 0.f)];
        self.scrollBarLayer.path = self.scrollBarPath.CGPath;
    }
    else { // draw bottom right corner
        self.scrollBarPath = [UIBezierPath bezierPath];
        [self.scrollBarPath moveToPoint:CGPointMake(self.bounds.size.width - self.bounds.size.width*percentOfScreenSize, self.bounds.size.height)];
        [self.scrollBarPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
        [self.scrollBarPath moveToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
        [self.scrollBarPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height - self.bounds.size.height*percentOfScreenSize)];
        self.scrollBarLayer.path = self.scrollBarPath.CGPath;
    }
}

@end
