//
//  BezierGestureView.swift
//  FLLSCRN
//
//  Created by Salmaan on 9/28/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit

enum BezierGestureViewStyle : String {
    case video = "video"
    case photo = "photo"
}

let kCMinimumWidth   : CGFloat = 0.0
let kCMaxBaseWidth   : CGFloat = 10.0
let kCMaxWaveHeight  : CGFloat = 125.0

@objc protocol BezierGestureViewDelegate : class, UIGestureRecognizerDelegate {
    func gestureViewTarget(gesture: UIScreenEdgePanGestureRecognizer, baseWidth : CGFloat)
}

class BezierGestureView: UIView {

    weak var delegate   : BezierGestureViewDelegate?
    
    lazy var leftShapeLayer : CAShapeLayer  = CAShapeLayer()
    lazy var rightShapeLayer : CAShapeLayer = CAShapeLayer()
    
    lazy var l3LeftControlView = UIView()
    lazy var l2LeftControlView = UIView()
    lazy var l1LeftControlView = UIView()
    lazy var cLeftControlView  = UIView()
    lazy var r1LeftControlView = UIView()
    lazy var r2LeftControlView = UIView()
    lazy var r3LeftControlView = UIView()
    
    lazy var l3RightControlView = UIView()
    lazy var l2RightControlView = UIView()
    lazy var l1RightControlView = UIView()
    lazy var cRightControlView  = UIView()
    lazy var r1RightControlView = UIView()
    lazy var r2RightControlView = UIView()
    lazy var r3RightControlView = UIView()

    lazy var l3BottomControlView = UIView()
    lazy var l2BottomControlView = UIView()
    lazy var l1BottomControlView = UIView()
    lazy var cBottomControlView = UIView()
    lazy var c1BottomControlView = UIView()
    lazy var c2BottomControlView = UIView()
    lazy var c3BottomControlView = UIView()
    
    lazy var leftEdgeGesture : UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer()
    lazy var rightEdgeGesture : UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer()
    
    lazy var displayLink : CADisplayLink = CADisplayLink(target: self, selector: #selector(updateShapeLayer))

    lazy var videoDurationLabel : UILabel = UILabel()
    lazy var videoZoomLabel     : UILabel = UILabel()
    
    lazy var photoCountLabel    : UILabel = UILabel()
    lazy var photoZoomLabel     : UILabel = UILabel()
    
    var animating = false {
        didSet {
            self.isUserInteractionEnabled = !self.animating
            self.displayLink.isPaused = !self.animating
        }
    }
    
    var height          : CGFloat { return self.bounds.height - kCBottomBarHeight }
    var width           : CGFloat { return self.bounds.width }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureViews()
        setupGestureRecognizer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupGestureRecognizer() {
        
        leftEdgeGesture.accessibilityLabel = BezierGestureViewStyle.video.rawValue
        leftEdgeGesture.edges = .left
        leftEdgeGesture.delegate = self.delegate
        leftEdgeGesture.maximumNumberOfTouches = 2
        leftEdgeGesture.addTarget(self, action: #selector(leftEdgeGestureTarget))
        self.addGestureRecognizer(leftEdgeGesture)
        
        rightEdgeGesture.accessibilityLabel = BezierGestureViewStyle.photo.rawValue
        rightEdgeGesture.edges = .right
        rightEdgeGesture.delegate = self.delegate
        rightEdgeGesture.maximumNumberOfTouches = 2
        rightEdgeGesture.addTarget(self, action: #selector(rightEdgeGestureTarget))
        self.addGestureRecognizer(rightEdgeGesture)
    }
    
    func setupGestureViews() {
        //left
        self.leftShapeLayer.frame = CGRect(x: 0.0, y: 0.0,
                                           width: kCMinimumWidth,
                                           height: self.bounds.height)
        
        self.leftShapeLayer.fillColor = UIColor.fllscrnGreen().cgColor
        self.leftShapeLayer.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()]
        
        self.layer.addSublayer(self.leftShapeLayer)
        
        self.l3LeftControlView.frame  = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.l2LeftControlView.frame  = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.l1LeftControlView.frame  = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.cLeftControlView.frame   = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.r1LeftControlView.frame  = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.r2LeftControlView.frame  = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.r3LeftControlView.frame  = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.videoDurationLabel.frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 25.0)
        self.videoZoomLabel.frame     = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 25.0)
        
        self.videoDurationLabel.adjustsFontSizeToFitWidth = true
        self.videoDurationLabel.text = "0s"
        self.videoDurationLabel.textColor = UIColor.black
        self.videoDurationLabel.font = UIFont.fllscrnFont(20.0)
        self.videoDurationLabel.textAlignment = .right
        
        self.videoZoomLabel.adjustsFontSizeToFitWidth = true
        self.videoZoomLabel.text = "1.0x"
        self.videoZoomLabel.textColor = UIColor.black
        self.videoZoomLabel.font = UIFont.fllscrnFont(16.0)
        self.videoZoomLabel.textAlignment = .right
        
        self.addSubview(self.l3LeftControlView)
        self.addSubview(self.l2LeftControlView)
        self.addSubview(self.l1LeftControlView)
        self.addSubview(self.cLeftControlView)
        self.addSubview(self.r1LeftControlView)
        self.addSubview(self.r2LeftControlView)
        self.addSubview(self.r3LeftControlView)
        self.addSubview(self.videoDurationLabel)
        self.addSubview(self.videoZoomLabel)
        
        self.layoutControlPoints(baseWidth: kCMinimumWidth, waveWidth: 0.0, locationY: self.bounds.height / 2.0, edge: .left)
        self.updateShapeLayer(layer: .left)
        
        self.videoDurationLabel.center.x = kCMinimumWidth - self.videoDurationLabel.right.x
        self.videoZoomLabel.center.x = kCMinimumWidth - self.videoZoomLabel.right.x
        
        //right
        self.rightShapeLayer.frame = CGRect(x: width, y: 0.0,
                                            width: kCMinimumWidth,
                                            height: self.bounds.height)
        
        self.rightShapeLayer.fillColor = UIColor.fllscrnPurple().cgColor
        self.rightShapeLayer.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()]
        
        self.layer.addSublayer(self.rightShapeLayer)
        
        self.l3RightControlView.frame = CGRect(x: width, y: 0.0, width: 3.0, height: 3.0)
        self.l2RightControlView.frame = CGRect(x: width, y: 0.0, width: 3.0, height: 3.0)
        self.l1RightControlView.frame = CGRect(x: width, y: 0.0, width: 3.0, height: 3.0)
        self.cRightControlView.frame  = CGRect(x: width, y: 0.0, width: 3.0, height: 3.0)
        self.r1RightControlView.frame = CGRect(x: width, y: 0.0, width: 3.0, height: 3.0)
        self.r2RightControlView.frame = CGRect(x: width, y: 0.0, width: 3.0, height: 3.0)
        self.r3RightControlView.frame = CGRect(x: width, y: 0.0, width: 3.0, height: 3.0)
        self.photoCountLabel.frame    = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 25.0)
        self.photoZoomLabel.frame     = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 25.0)
        
        self.photoCountLabel.adjustsFontSizeToFitWidth = true
        self.photoCountLabel.text = "0"
        self.photoCountLabel.textColor = UIColor.white
        self.photoCountLabel.font = UIFont.fllscrnFont(20.0)
        self.photoCountLabel.textAlignment = .left

        self.photoZoomLabel.adjustsFontSizeToFitWidth = true
        self.photoZoomLabel.text = "1.0x"
        self.photoZoomLabel.textColor = UIColor.white
        self.photoZoomLabel.font = UIFont.fllscrnFont(16.0)
        self.photoZoomLabel.textAlignment = .left
        
        self.addSubview(self.l3RightControlView)
        self.addSubview(self.l2RightControlView)
        self.addSubview(self.l1RightControlView)
        self.addSubview(self.cRightControlView)
        self.addSubview(self.r1RightControlView)
        self.addSubview(self.r2RightControlView)
        self.addSubview(self.r3RightControlView)
        self.addSubview(self.photoCountLabel)
        self.addSubview(self.photoZoomLabel)
        
        self.layoutControlPoints(baseWidth: kCMinimumWidth, waveWidth: 0.0, locationY: self.bounds.height / 2.0, edge: .right)
        self.updateShapeLayer(layer: .right)
        
        self.photoCountLabel.center.x = width + self.photoCountLabel.left.x
        self.photoZoomLabel.center.x = width + self.photoCountLabel.left.x

        self.displayLink.add(to: .main, forMode: .defaultRunLoopMode)
        displayLink.isPaused = true
    }
    
    fileprivate func currentPath(forEdge edge: UIRectEdge) -> CGPath {
        
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: edge == .left ? 0.0 : self.width, y: 0.0))
        
        if edge == .left {
            bezierPath.addLine(to: CGPoint(x: l3LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating).x, y: 0.0))
            
            bezierPath.addCurve(to: l1LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: l3LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: l2LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating))
            
            bezierPath.addCurve(to: r1LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: cLeftControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: r1LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating))
            
            bezierPath.addCurve(to: r3LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: r1LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: r2LeftControlView.dg_center(usePresentationLayerIfPossible: self.animating))
        }
        else {
            bezierPath.addLine(to: CGPoint(x: l3RightControlView.dg_center(usePresentationLayerIfPossible: self.animating).x, y: 0.0))
            
            bezierPath.addCurve(to: l1RightControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: l3RightControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: l2RightControlView.dg_center(usePresentationLayerIfPossible: self.animating))
            
            bezierPath.addCurve(to: r1RightControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: cRightControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: r1RightControlView.dg_center(usePresentationLayerIfPossible: self.animating))
            
            bezierPath.addCurve(to: r3RightControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: r1RightControlView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: r2RightControlView.dg_center(usePresentationLayerIfPossible: self.animating))
        }
        
        bezierPath.addLine(to: CGPoint(x: edge == .left ? 0.0 : self.width, y: height))
        
        bezierPath.close()
        
        return bezierPath.cgPath
    }
    
    func updateShapeLayer(layer: UIRectEdge) {
        if layer == .left {
            self.leftShapeLayer.path = self.currentPath(forEdge: .left)
            var rect = self.leftShapeLayer.path!.boundingBoxOfPath
            rect.origin.y += 45.0
            self.leftShapeLayer.bounds = rect
        }
        else if layer == .right {
            self.rightShapeLayer.path = self.currentPath(forEdge: .right)
            var rect = self.rightShapeLayer.path!.boundingBoxOfPath
            rect.origin.y += 45.0
            self.rightShapeLayer.bounds = rect
        }
        else {
            self.leftShapeLayer.path = self.currentPath(forEdge: .left)
            self.rightShapeLayer.path = self.currentPath(forEdge: .right)
        }
    }

    fileprivate func layoutControlPoints(baseWidth: CGFloat, waveWidth: CGFloat, locationY: CGFloat, edge : UIRectEdge) {
        
        let minTopY : CGFloat
        let maxBottomY : CGFloat
        let topPartWidth : CGFloat
        let bottomPartWidth : CGFloat
        
        let labelScaler = (0.5*height - locationY) / (0.5*height)
        
        let maxLabelY : CGFloat
        
        if edge == .left {
            
            minTopY = min((locationY - height / 2.0) * 0.28, 0.0)
            maxBottomY = height // max(height + (locationY - height / 2.0) * 0.28, height)
            
            topPartWidth = locationY - minTopY
            bottomPartWidth = maxBottomY - locationY
            
            maxLabelY = locationY <= height / 2
                      ? labelScaler * 55 + locationY
                      : min(height, labelScaler * 25 + locationY)
        }
        else { // right edge
            
            minTopY = min((locationY - height / 2.0) * 0.28, 0.0)
            maxBottomY = height
            
            topPartWidth = locationY - minTopY
            bottomPartWidth = maxBottomY - locationY
            
            maxLabelY = locationY <= height / 2
                      ? labelScaler * 55 + locationY
                      : min(height, labelScaler * 25 + locationY)
        }
        
        if edge == .left {
            
            self.l3LeftControlView.center = CGPoint(x: baseWidth, y: minTopY)
            self.l2LeftControlView.center = CGPoint(x: baseWidth, y: minTopY + topPartWidth * 0.44)
            self.l1LeftControlView.center = CGPoint(x: baseWidth + waveWidth * 0.64, y: minTopY + topPartWidth * 0.71)
            self.cLeftControlView.center  = CGPoint(x: baseWidth + waveWidth * 1.36, y: locationY)
            self.r1LeftControlView.center = CGPoint(x: baseWidth + waveWidth * 0.64, y: maxBottomY - bottomPartWidth * 0.71)
            self.r2LeftControlView.center = CGPoint(x: baseWidth, y: maxBottomY - (bottomPartWidth * 0.44))
            self.r3LeftControlView.center = CGPoint(x: baseWidth, y: maxBottomY)
            
            self.videoDurationLabel.center = CGPoint(x: baseWidth + waveWidth * 0.15, y: maxLabelY - self.videoDurationLabel.bounds.height)
            self.videoZoomLabel.center = CGPoint(x: self.videoDurationLabel.center.x, y: self.videoDurationLabel.center.y + self.videoZoomLabel.bounds.height)

        }
        else {
            
            self.l3RightControlView.center = CGPoint(x: width - baseWidth, y: minTopY)
            self.l2RightControlView.center = CGPoint(x: width - baseWidth, y: minTopY + topPartWidth * 0.44)
            self.l1RightControlView.center = CGPoint(x: width - (baseWidth + waveWidth * 0.64), y: minTopY + topPartWidth * 0.71)
            self.cRightControlView.center  = CGPoint(x: width - (baseWidth + waveWidth * 1.36), y: locationY)
            self.r1RightControlView.center = CGPoint(x: width - (baseWidth + waveWidth * 0.64), y: maxBottomY - bottomPartWidth * 0.71)
            self.r2RightControlView.center = CGPoint(x: width - baseWidth, y: maxBottomY - (bottomPartWidth * 0.44))
            self.r3RightControlView.center = CGPoint(x: width - baseWidth, y: maxBottomY)
            
            self.photoCountLabel.center = CGPoint(x: width - (baseWidth + waveWidth * 0.15), y: maxLabelY - self.photoCountLabel.bounds.height)
            self.photoZoomLabel.center = CGPoint(x: self.photoCountLabel.center.x, y: self.photoCountLabel.center.y + self.photoZoomLabel.bounds.height)
        }
    }
    
    func leftEdgeGestureTarget(gesture : UIScreenEdgePanGestureRecognizer) {
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            
            delegate?.gestureViewTarget(gesture: self.leftEdgeGesture, baseWidth: -1)
            
            self.animating = true
            
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: {
                
                self.l3LeftControlView.center.x = kCMinimumWidth
                self.l2LeftControlView.center.x = kCMinimumWidth
                self.l1LeftControlView.center.x = kCMinimumWidth
                self.cLeftControlView.center.x  = kCMinimumWidth
                self.r1LeftControlView.center.x = kCMinimumWidth
                self.r2LeftControlView.center.x = kCMinimumWidth
                self.r3LeftControlView.center.x = kCMinimumWidth
                self.videoDurationLabel.center.x = kCMinimumWidth - self.videoDurationLabel.right.x
                self.videoZoomLabel.center.x = kCMinimumWidth - self.videoZoomLabel.right.x
                
                }, completion: { (completed) in
                    
                    self.animating = false
                    self.leftShapeLayer.fillColor = UIColor.fllscrnGreen().cgColor
            })
        }
        else {
            
            let additionalHeight = max(gesture.translation(in: self).x, 0)
            let waveWidth = min(additionalHeight * 0.95, kCMaxWaveHeight)
            
            let baseWidth = min(kCMinimumWidth + additionalHeight - waveWidth, kCMaxBaseWidth)
            let locationY = gesture.location(in: gesture.view).y
            
            self.layoutControlPoints(baseWidth: baseWidth, waveWidth: waveWidth, locationY: locationY, edge: .left)
            self.updateShapeLayer(layer: .left)
            
            if baseWidth == kCMaxBaseWidth {
                self.leftShapeLayer.fillColor = UIColor.fllscrnGreen(alpha: 0.25).cgColor
            }
            
            delegate?.gestureViewTarget(gesture: self.leftEdgeGesture, baseWidth: baseWidth)
        }
    }
    
    func rightEdgeGestureTarget(gesture: UIScreenEdgePanGestureRecognizer) {
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            
            delegate?.gestureViewTarget(gesture: self.rightEdgeGesture, baseWidth: -1)
            
            self.animating = true
            
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: {
                
                self.l3RightControlView.center.x = self.width
                self.l2RightControlView.center.x = self.width
                self.l1RightControlView.center.x = self.width
                self.cRightControlView.center.x  = self.width
                self.r1RightControlView.center.x = self.width
                self.r2RightControlView.center.x = self.width
                self.r3RightControlView.center.x = self.width
                self.photoCountLabel.center.x = self.width + self.photoCountLabel.left.x
                self.photoZoomLabel.center.x = self.width + self.photoZoomLabel.left.x
                
                }, completion: { (completed) in
                    
                    self.animating = false
                    self.rightShapeLayer.fillColor = UIColor.fllscrnPurple().cgColor
            })
        }
        else {
            
            let additionalHeight = max(abs(gesture.translation(in: self).x), 0)
            let waveWidth = min(additionalHeight * 0.95, kCMaxWaveHeight)
                
            let baseWidth = min(kCMinimumWidth + additionalHeight - waveWidth, kCMaxBaseWidth)
            let locationY = gesture.location(in: gesture.view).y
            
            self.layoutControlPoints(baseWidth: baseWidth, waveWidth: waveWidth, locationY: locationY, edge: .right)
            self.updateShapeLayer(layer: .right)
            
            if baseWidth == kCMaxBaseWidth {
                self.rightShapeLayer.fillColor = UIColor.fllscrnPurple(alpha: 0.25).cgColor
            }
            else {
                self.rightShapeLayer.fillColor = UIColor.fllscrnPurple().cgColor
            }
            
            delegate?.gestureViewTarget(gesture: self.rightEdgeGesture, baseWidth: baseWidth)
        }
    }
}
