//
//  CurvedSliderView.swift
//  FLLSCRN
//
//  Created by Salmaan on 10/13/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit

let kCSliderLineWidth : CGFloat = 2.5

class CurvedSliderView: UIView, UIGestureRecognizerDelegate {
    
    lazy var curvedLayer : CAShapeLayer = CAShapeLayer()
    lazy var sliderImage : UIImageView = UIImageView(image: sliderImg)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.curvedLayer.lineWidth = kCSliderLineWidth
        self.curvedLayer.strokeColor = UIColor.fllscrnGreen().cgColor
        self.curvedLayer.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(curvedLayer)
        
        self.createPath()
        self.createSlider()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createPath() {
        
        let width = self.frame.width
        let height = self.frame.height
        let center = CGPoint(x: 0, y: height / 2)
        
        let curvedPath = UIBezierPath(arcCenter: center, radius: width / 2, startAngle: CGFloat(270).degreesToRadians, endAngle: CGFloat(90).degreesToRadians, clockwise: true)
        curvedPath.close()
        
        curvedLayer.path = curvedPath.cgPath
    }
    
    func createSlider() {
        
        self.addSubview(self.sliderImage)
        
        let size = CGSize(width: self.frame.width / 7, height: self.frame.width / 7)
        let origin = CGPoint(x: 0 - size.width / 2 + 2*kCSliderLineWidth, y: 0 - size.height / 2)
        self.sliderImage.frame = CGRect(origin: origin, size: size)

        self.sliderImage.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer()
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        panGesture.addTarget(self, action: #selector(sliderTouched))
        self.sliderImage.addGestureRecognizer(panGesture)
    }
    
    func sliderTouched(panGesture : UIPanGestureRecognizer) {
        
        switch panGesture.state {
        case .began:
            print("Pan Gesture Began")
        case .changed:
            
            let translation = panGesture.translation(in: self)
            
            if self.curvedLayer.path!.contains(translation) {
                print("Translation: \(translation)")
                self.sliderImage.center = translation
            }
            
        default:
            print("Ended / Canceled / Failed / Possible.")
        }
        
    }
}
