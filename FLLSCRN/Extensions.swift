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
    
    var right : CGPoint { return CGPoint(x: self.center.x + self.bounds.width / 2, y: self.center.y) }
    var left  : CGPoint { return CGPoint(x: self.center.x - self.bounds.width / 2, y: self.center.y) }
}

extension UIColor {
    
    class func fllscrnGreen() -> UIColor {
        return UIColor.fllscrnGreen(alpha: 1.0)
    }
    
    class func fllscrnGreen(alpha: CGFloat) -> UIColor {
        return UIColor(red: 46.0/255.0, green: 204.0/255.0, blue: 113.0/255.0, alpha: alpha)
        // red: UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: alpha)
    }
    
    class func fllscrnPurple() -> UIColor {
        return UIColor.fllscrnPurple(alpha: 1.0)
    }
    
    class func fllscrnPurple(alpha: CGFloat) -> UIColor {
        return UIColor(red: 154.0/255.0, green: 18.0/255.0, blue: 79.0/255.0, alpha: alpha)
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
    
    class func fllscrnFontBold(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Avenir-Black", size: size)!
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

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
    var radiansToDegrees: Double { return Double(self) * 180 / .pi }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
