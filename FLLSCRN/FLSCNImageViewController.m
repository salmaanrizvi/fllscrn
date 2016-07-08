//
//  FLSCNImageViewController.m
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/7/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

#import "FLSCNImageViewController.h"
#import "FLSCNImagePanScrollbarView.h"
#import "FLLSCRN-Swift.h"

@interface FLSCNImageViewController ()

//Pan-based motion properties
@property (strong, nonatomic) IBOutlet UIImageView *imageOnScreen;
@property (strong, nonatomic) IBOutlet UIScrollView *imageScrollView;
@property (strong, nonatomic) CMMotionManager *motionManager;

//Scroll bars
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) FLSCNImagePanScrollbarView *scrollBarViewTop;
@property (nonatomic, strong) FLSCNImagePanScrollbarView *scrollBarViewBottom;
@property (nonatomic, strong) FLSCNImagePanScrollbarView *topLeftCornerBar;
@property (nonatomic, strong) FLSCNImagePanScrollbarView *bottomRightCornerBar;

// Accelerometer calculation properties
@property (nonatomic) CGFloat kAccelerometerFrequency;
@property (nonatomic) CGFloat zoomScaleMultiple;

@property (nonatomic) CGFloat minPitchAngle;
@property (nonatomic) CGFloat maxPitchAngle;

@end

//original values
//static CGFloat kMovementSmoothing = 1.6f;
//static CGFloat kAnimationDuration = 0.05f;
//static CGFloat kRotationMultiplier = 5.f;

static CGFloat pitchAngleCushion = 5.f;

@implementation FLSCNImageViewController

#pragma View Setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"Interactor in Image Picker: shouldFinish: %d hasStarted: %d", self.interactor.shouldFinish, self.interactor.hasStarted);
    
    self.maxPitchAngle = NAN;
    // Do any additional setup after loading the view.
    
    self.imageScrollView.frame = self.view.bounds;
    self.imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.imageScrollView.backgroundColor = [UIColor blackColor];
    self.imageScrollView.delegate = self;
    self.imageScrollView.scrollEnabled = NO;
    self.imageScrollView.alwaysBounceVertical = NO;
    self.imageScrollView.alwaysBounceHorizontal = YES;
    self.imageScrollView.maximumZoomScale = 2.f;
    //self.isMotionBasedPanEnabled = YES;
    //[self.imageScrollView.pinchGestureRecognizer addTarget:self action:@selector(pinchGestureRecognized:)];
    
    [self.view addSubview:self.imageScrollView];
    
    self.imageOnScreen = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageOnScreen.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.imageOnScreen.backgroundColor = [UIColor blackColor];
    self.imageOnScreen.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.imageScrollView addSubview:self.imageOnScreen];
    [self configureWithImage:self.imageForViewing];
    
    self.scrollBarViewBottom = [[FLSCNImagePanScrollbarView alloc] initWithFrame:self.view.bounds edgeInsets:UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f)];
    self.scrollBarViewBottom.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrollBarViewBottom.userInteractionEnabled = NO;
    [self.view addSubview:self.scrollBarViewBottom];
    
    self.scrollBarViewTop = [[FLSCNImagePanScrollbarView alloc] initWithFrame:self.view.bounds edgeInsets:UIEdgeInsetsMake(0.f, 0.f, self.view.bounds.size.height, 0.f)];
    self.scrollBarViewTop.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrollBarViewTop.userInteractionEnabled = NO;
    [self.view addSubview:self.scrollBarViewTop];
    
    self.topLeftCornerBar = [[FLSCNImagePanScrollbarView alloc] initWithFrame:self.view.bounds edgeInsets:UIEdgeInsetsMake(0.f, 0.f, self.view.bounds.size.height, 0.f)];
    self.topLeftCornerBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.topLeftCornerBar.userInteractionEnabled = NO;
    
    self.bottomRightCornerBar = [[FLSCNImagePanScrollbarView alloc] initWithFrame:self.view.bounds edgeInsets:UIEdgeInsetsMake(0.f, 0.f, self.view.bounds.size.height, 0.f)];
    self.bottomRightCornerBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.bottomRightCornerBar.userInteractionEnabled = NO;
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkUpdate:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    self.kAccelerometerFrequency = 150.0; //Hz
    
    UIPanGestureRecognizer *dismissGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissGesture:)];
    [self.view addGestureRecognizer:dismissGesture];

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initializeMotionManager];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.imageScrollView.contentOffset = CGPointMake((self.imageScrollView.contentSize.width / 2.f) - (CGRectGetWidth(self.imageScrollView.bounds)) / 2.f,
                                                     (self.imageScrollView.contentSize.height / 2.f) - (CGRectGetHeight(self.imageScrollView.bounds)) / 2.f);
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        
        if (isnan(self.maxPitchAngle)) {
            CMQuaternion quat = motion.attitude.quaternion;
                        
            self.maxPitchAngle = [self calculateRotationAngle:@"pitch" FromQuaternion:quat] * (180/ M_PI) - pitchAngleCushion;
            self.minPitchAngle = self.maxPitchAngle - 10;
            self.zoomScaleMultiple = (self.imageScrollView.maximumZoomScale - 1.) / (self.maxPitchAngle - self.minPitchAngle);
            
            NSLog(@"Max Angle: %lf", self.maxPitchAngle);
            NSLog(@"Min Angle: %lf", self.minPitchAngle);
        }
        
        [self calculateRotationBasedOnDeviceMotionRotationRate:motion];
        [self calculateZoomBasedOnDeviceMotionRotationRate:motion];
    }];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.motionManager stopDeviceMotionUpdates];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma Device Zoom Motion Calculation
-(void)calculateZoomBasedOnDeviceMotionRotationRate:(CMDeviceMotion *)motion {
    
    CGFloat xRotationRate = motion.rotationRate.x;
    CGFloat yRotationRate = motion.rotationRate.y;
    CGFloat zRotationRate = motion.rotationRate.z;
    
    CGFloat pitch = [self calculateRotationAngle:@"pitch" FromQuaternion:motion.attitude.quaternion];
    CGFloat currentPitchInDegrees = pitch * (180. / M_PI);
    CGFloat zAccel = motion.userAcceleration.z;
    
    // if pitch is between min and max degrees for zooming
    if(fabs(xRotationRate) > fabs(yRotationRate) + fabs(zRotationRate) && currentPitchInDegrees > self.minPitchAngle && currentPitchInDegrees < self.maxPitchAngle) {
        
        [self.view addSubview:self.scrollBarViewTop];
        [self.view addSubview:self.scrollBarViewBottom];
        [self.topLeftCornerBar removeFromSuperview];
        [self.bottomRightCornerBar removeFromSuperview];
        
        CGFloat newZoomScale = (currentPitchInDegrees - self.minPitchAngle) * self.zoomScaleMultiple + 1;
        
        if(fabs(zAccel) > 1) {
            [UIView animateWithDuration:1/(4*fabs(zAccel)) delay:0.f options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear animations:^{
                self.imageScrollView.zoomScale = newZoomScale;
            } completion:nil];
        }
        else {
            [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear animations:^{
                self.imageScrollView.zoomScale = newZoomScale;
            } completion:nil];
        }
    }
    else if(currentPitchInDegrees < self.minPitchAngle) {
        
        [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear animations:^{
            self.imageScrollView.zoomScale = self.imageScrollView.minimumZoomScale;
            [self.topLeftCornerBar updatePath:YES];
            [self.bottomRightCornerBar updatePath:NO];
            [self.view addSubview:self.topLeftCornerBar];
            [self.view addSubview:self.bottomRightCornerBar];
            [self.scrollBarViewTop removeFromSuperview];
            [self.scrollBarViewBottom removeFromSuperview];
            
        } completion:nil];
    }
    else if (currentPitchInDegrees > self.maxPitchAngle) {
        [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear animations:^{
            self.imageScrollView.zoomScale = self.imageScrollView.maximumZoomScale;
        } completion:nil];
    }
    else {
        NSLog(@"This should never be called.");
    }
}

#pragma Device Pan Motion Calculation
- (void)calculateRotationBasedOnDeviceMotionRotationRate:(CMDeviceMotion *)motion
{
    //    if (self.isMotionBasedPanEnabled)
    //    {
    CGFloat xRotationRate = motion.rotationRate.x;
    CGFloat yRotationRate = motion.rotationRate.y;
    CGFloat zRotationRate = motion.rotationRate.z;
    
    if (fabs(yRotationRate) > (fabs(xRotationRate) + fabs(zRotationRate)))
    {
        CGFloat invertedYRotationRate = yRotationRate * -1;
        
        CGFloat zoomScale = [self maximumZoomScaleForImage:self.imageOnScreen.image];
        CGFloat interpretedXOffset = self.imageScrollView.contentOffset.x + (invertedYRotationRate * zoomScale * self.kRotationMultiplier);
        
        CGPoint contentOffset = [self clampedContentOffsetForHorizontalOffset:interpretedXOffset];
        
        [UIView animateWithDuration:self.kMovementSmoothing
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self.imageScrollView setContentOffset:contentOffset animated:NO];
                         } completion:NULL];
    }
    //    }
}

- (CGPoint)clampedContentOffsetForHorizontalOffset:(CGFloat)horizontalOffset;
{
    CGFloat maximumXOffset = self.imageScrollView.contentSize.width - CGRectGetWidth(self.imageScrollView.bounds);
    CGFloat minimumXOffset = 0.f;
    
    CGFloat clampedXOffset = fmaxf(minimumXOffset, fmin(horizontalOffset, maximumXOffset));
    CGFloat centeredY = (self.imageScrollView.contentSize.height / 2.f) - (CGRectGetHeight(self.imageScrollView.bounds)) / 2.f;
    
    return CGPointMake(clampedXOffset, centeredY);
}


-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageOnScreen;
}

//- (void)pinchGestureRecognized:(id)sender
//{
//    self.isMotionBasedPanEnabled = NO;
//    self.imageScrollView.scrollEnabled = YES;
//}

- (void)configureWithImage:(UIImage *)image
{
    self.imageOnScreen.image = image;
    [self updateScrollViewZoomToMaximumForImage:image];
}

- (CGFloat)maximumZoomScaleForImage:(UIImage *)image
{
    return (CGRectGetHeight(self.imageScrollView.bounds) / CGRectGetWidth(self.imageScrollView.bounds)) * (image.size.width / image.size.height);
}

- (void)updateScrollViewZoomToMaximumForImage:(UIImage *)image
{
    CGFloat zoomScale = [self maximumZoomScaleForImage:image];
    
    NSLog(@"Zoom scale: %lf", zoomScale);
    
    self.imageScrollView.maximumZoomScale = zoomScale;
    self.imageScrollView.zoomScale = zoomScale;
}

-(void)initializeMotionManager {
    self.motionManager = [[CMMotionManager alloc] init];
    //[self.motionManager startDeviceMotionUpdates];
    //[self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
    self.motionManager.accelerometerUpdateInterval = 1/self.kAccelerometerFrequency;
    
    //    CMQuaternion quat = self.motionManager.deviceMotion.attitude.quaternion;
    //
    //    self.maxPitchAngle = [self calculateRotationAngle:@"pitch" FromQuaternion:quat] * (180/ M_PI);
    //    self.minPitchAngle = self.maxPitchAngle - 10;
    //
    //    NSLog(@"\nMax Angle / Initial Angle: %lf \nMin Angle: %lf", self.maxPitchAngle, self.minPitchAngle);
}

-(CGFloat)calculateRotationAngle:(NSString *)angle FromQuaternion:(CMQuaternion)quat  {
    
    // quat = [q0 q1 q2 q3] == [w x y z]
    
    if ([angle isEqualToString:@"roll"]) {
        // Roll (rotation around y axis) = arcsin(2*(q0*q2 - q3*q1))
        CGFloat roll = asin(2*(quat.w * quat.y - quat.z * quat.x));
        return roll;
    }
    else if([angle isEqualToString:@"pitch"]) {
        // Pitch (rotation around x axis) = atan2(2 * (q0 * q1 + q2 * q3), 1 - 2 * ((q1)^2 + (q2)^2))
        CGFloat pitch = atan2(2*(quat.w * quat.x + quat.y * quat.z), 1 - 2*(pow(quat.x, 2) + pow(quat.y, 2)));
        return pitch;
    }
    else if([angle isEqualToString:@"yaw"]) {
        // Yaw (rotation around z axis) = atan2(2 * (q0 * q3 + q1 * q2), 1 - 2 * ((q2)^2 + (q3)^2))
        CGFloat yaw = atan2(2* (quat.w * quat.y + quat.x * quat.z), 1 - 2 *(pow(quat.y, 2) + pow(quat.z, 2)));
        return yaw;
    }
    else {
        return nanf("nan");
    }
}

#pragma mark - CADisplayLink

- (void)displayLinkUpdate:(CADisplayLink *)displayLink
{
    CALayer *panningImageViewPresentationLayer = self.imageOnScreen.layer.presentationLayer;
    CALayer *panningScrollViewPresentationLayer = self.imageScrollView.layer.presentationLayer;
    
    CGFloat horizontalContentOffset = CGRectGetMinX(panningScrollViewPresentationLayer.bounds);
    
    CGFloat contentWidth = CGRectGetWidth(panningImageViewPresentationLayer.frame);
    CGFloat visibleWidth = CGRectGetWidth(self.imageScrollView.bounds);
    
    CGFloat clampedXOffsetAsPercentage = fmax(0.f, fmin(1.f, horizontalContentOffset / (contentWidth - visibleWidth)));
    
    CGFloat scrollBarWidthPercentage = visibleWidth / contentWidth;
    CGFloat scrollableAreaPercentage = 1.0 - scrollBarWidthPercentage;
    
    [self.scrollBarViewBottom updateWithScrollAmount:clampedXOffsetAsPercentage forScrollableWidth:scrollBarWidthPercentage inScrollableArea:scrollableAreaPercentage];
    
    [self.scrollBarViewTop updateWithScrollAmount:clampedXOffsetAsPercentage forScrollableWidth:scrollBarWidthPercentage inScrollableArea:scrollableAreaPercentage];
}

- (IBAction)handleDismissGesture:(UIPanGestureRecognizer *)sender {
    
    NSLog(@"Handle Dismiss Gesture Called.");
    
    CGFloat percentThreshold = 0.3;
    CGPoint translation = [sender translationInView:self.view];
    CGFloat verticalMovement = translation.y / self.view.bounds.size.height;
    CGFloat downwardMovement = fmaxf(verticalMovement, 0.f);
    CGFloat downwardMovementPercent = fminf(downwardMovement, 1.f);

    if (sender.state == UIGestureRecognizerStateBegan){
        NSLog(@"State Began");
        self.interactor.hasStarted = true;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (sender.state == UIGestureRecognizerStateChanged) {
        NSLog(@"State Changed");
        self.interactor.shouldFinish = downwardMovementPercent > percentThreshold;
        [self.interactor updateInteractiveTransition:downwardMovementPercent];
    }
    else if (sender.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"State Cancelled");
        self.interactor.hasStarted = false;
        [self.interactor cancelInteractiveTransition];
    }
    else if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"State Ended");
        self.interactor.hasStarted = false;
        self.interactor.shouldFinish
            ?  [self.interactor finishInteractiveTransition]
            : [self.interactor cancelInteractiveTransition];
    }

    
//    switch (sender.state) {
//        case UIGestureRecognizerStateBegan:
//            NSLog(@"State Began");
//            self.interactor.hasStarted = true;
//            [self dismissViewControllerAnimated:YES completion:nil];
//        
//        case UIGestureRecognizerStateChanged:
//            NSLog(@"State Changed");
//            self.interactor.shouldFinish = downwardMovementPercent > percentThreshold;
//            [self.interactor updateInteractiveTransition:downwardMovementPercent];
//        
//        case UIGestureRecognizerStateCancelled:
//            NSLog(@"State Cancelled");
//            self.interactor.hasStarted = false;
//            [self.interactor cancelInteractiveTransition];
//        
//        case UIGestureRecognizerStateEnded:
//            NSLog(@"State Ended");
//            self.interactor.hasStarted = false;
//            self.interactor.shouldFinish
//                ? [self.interactor finishInteractiveTransition]
//                : [self.interactor cancelInteractiveTransition];
//        
//        default:
//            break;
//    }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
