//
//  FLSCNImagePanScrollbarView.h
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/7/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLSCNImagePanScrollbarView : UIView

- (id)initWithFrame:(CGRect)frame edgeInsets:(UIEdgeInsets)edgeInsets;

- (void)updateWithScrollAmount:(CGFloat)scrollAmount forScrollableWidth:(CGFloat)scrollableWidth inScrollableArea:(CGFloat)scrollableArea;

-(void)updatePath:(BOOL)topLeft;

@end
