//
//  CameraFocusSquare.swift
//  ManestreamCamera
//
//  Created by Salmaan Rizvi on 7/22/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit
import Foundation

class CameraFocusSquare: UIView, CAAnimationDelegate {
    
    internal let kSelectionAnimation:String = "selectionAnimation"
    
    fileprivate var selectionBlink: CABasicAnimation?
    
    convenience init(touchPoint: CGPoint) {
        self.init()
        self.updatePoint(touchPoint)
        self.backgroundColor = UIColor.clear
        self.layer.borderWidth = 1.5
        self.layer.borderColor = UIColor.fllscrnRed().cgColor
        initBlink()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    fileprivate func initBlink() {
        
        // create the blink animation
        self.selectionBlink = CABasicAnimation(keyPath: "borderColor")
        self.selectionBlink!.toValue = (UIColor.clear.cgColor as AnyObject)
        self.selectionBlink!.repeatCount = 2
        
        // number of blinks
        self.selectionBlink!.duration = 0.5
        
        // this is duration per blink
        self.selectionBlink!.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Updates the location of the view based on the incoming touchPoint.
     */
    
    func updatePoint(_ touchPoint: CGPoint) {
        let squareWidth: CGFloat = 70
        let frame: CGRect = CGRect(x: touchPoint.x - squareWidth / 2, y: touchPoint.y - squareWidth / 2, width: squareWidth, height: squareWidth)
        self.frame = frame
    }
    
    /**
     This unhides the view and initiates the animation by adding it to the layer.
     */
    func animateFocusingAction() {
        
        if let blink = self.selectionBlink {
            // make the view visible
            self.alpha = 1.0
            self.isHidden = false
            // initiate the animation
            self.layer.add(blink, forKey: kSelectionAnimation)
        }
        
    }
    /**
     Hides the view after the animation stops. Since the animation is automatically removed, we don't need to do anything else here.
     */
    
    func animationDidStop(_ animation: CAAnimation, finished flag: Bool) {
        // hide the view
        self.alpha = 0.0
        self.isHidden = true
    }
}
