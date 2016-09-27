//
//  Extensions.swift
//  FLLSCRN
//
//  Created by Salmaan on 9/26/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView

extension UIView {
    func dg_center(usePresentationLayerIfPossible: Bool) -> CGPoint {
        
        if usePresentationLayerIfPossible, let presentationLayer = layer.presentation() {
            
            return presentationLayer.position
            
        }
        
        return center
    }
    
    var right : CGPoint { return CGPoint(x: self.center.x + self.bounds.width / 2, y: self.center.y)}
}

extension UIColor {
    
    class func fllscrnRed() -> UIColor {
        return UIColor.fllscrnRed(alpha: 1.0)
    }
    
    class func fllscrnRed(alpha: CGFloat) -> UIColor {
        return UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: alpha)
    }
    
    func colorCode() -> UInt {
        
        var red : CGFloat = 0, green : CGFloat = 0, blue : CGFloat = 0
        
        if self.getRed(&red, green: &green, blue: &blue, alpha: nil) {
            let redInt = UInt(red * 255 + 0.5)
            let greenInt = UInt(green * 255 + 0.5)
            let blueInt = UInt(blue * 255 + 0.5)
            
            return (redInt << 16) | (greenInt << 8) | blueInt
        }
        
        return 0
    }
}

extension UIFont {
    
    class func fllscrnFont(_ size : CGFloat) -> UIFont {
        return UIFont(name: "Avenir", size: size)!
    }
}

extension SCLAlertView {
    
    public func addTextField(title: String?=nil, identifier: String, keyboardType: UIKeyboardType)->UITextField {
        
        let textField = self.addTextField(title)
        
        textField.accessibilityIdentifier = identifier
        textField.keyboardType = keyboardType
        
        return textField
    }
}
