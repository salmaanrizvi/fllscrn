//
//  FLSCNImageViewController.h
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/7/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@class Interactor;

@interface FLSCNImageViewController : UIViewController<UIScrollViewDelegate, UIViewControllerTransitioningDelegate>

@property (strong,nonatomic) UIImage *imageForViewing;
@property (strong, nonatomic) NSURL *imageURL;

@property (nonatomic) CGFloat kMovementSmoothing;
@property (nonatomic) CGFloat kAnimationDuration;
@property (nonatomic) CGFloat kRotationMultiplier;

@property (nonatomic, strong) Interactor *interactor;

@end
