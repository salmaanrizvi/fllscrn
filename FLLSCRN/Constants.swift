//
//  Constants.swift
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 9/14/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit
import FontAwesome_swift

class Constants {
    
    class func displayAlert(_ title: String, message: String) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
        return alert
        
    }
    
    class func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy, HH:mm:ss"
        return dateFormatter
    }
}

let recordButtonSize : CGFloat = 1/7.0 // 1/7 of the height of the device

let cameraRecordButtonImage = UIImage(named: "whitering-1")!
let flashOffIcon = UIImage(named: "Flash Off-50")!
let flashOnIcon = UIImage(named: "Flash On-50.png")!
let closeIcon = UIImage(named: "ic_close")!
let trashIcon = UIImage(named: "trash-2-xxl.png")!
let leftBackIcon = UIImage(named: "left back.png")!
let toggleCameraIcon = UIImage(named: "switch-camera-256")!

let faIconSize =  CGSize(width: 30.0, height: 30.0)
let tappedIconSize = CGSize(width: 45.0, height: 45.0)

let orangeTextIcon = UIImage(named: "Text Icon.png")!

let blackTextIcon = UIImage(named: "Black Text Icon.png")!

let blackTextIconSmall = UIImage(named: "Black Text Icon Small")!

let redGift = UIImage.fontAwesomeIconWithName(.Gift, textColor: UIColor.fllscrnRed(), size: faIconSize, backgroundColor: UIColor.white)

let redSend = UIImage.fontAwesomeIconWithName(.Send, textColor: UIColor.fllscrnRed(), size: faIconSize, backgroundColor: UIColor.white)
//UIImage(icon: FAType.FASend, size: faIconSize, textColor: UIColor.fllscrnRed(), backgroundColor: UIColor.whiteColor())

let redPlay = UIImage.fontAwesomeIconWithName(.Play, textColor: UIColor.fllscrnRed(), size: faIconSize, backgroundColor: UIColor.white)
//UIImage(icon: FAType.FAPlay, size: faIconSize, textColor: UIColor.fllscrnRed(), backgroundColor: UIColor.whiteColor())

let redPlayClearBackground = UIImage.fontAwesomeIconWithName(.Play, textColor: UIColor.fllscrnRed(), size: faIconSize, backgroundColor: UIColor.clear)
//UIImage(icon: FAType.FAPlay, size: faIconSize, textColor: UIColor.fllscrnRed(), backgroundColor: UIColor.clearColor())

let blackGift = UIImage.fontAwesomeIconWithName(.Gift, textColor: UIColor.black, size: faIconSize, backgroundColor: UIColor.white)
//UIImage(icon: FAType.FAGift, size: faIconSize, textColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())

let blackSend = UIImage.fontAwesomeIconWithName(.Send, textColor: UIColor.black, size: faIconSize, backgroundColor: UIColor.white)
//UIImage(icon: FAType.FASend, size: faIconSize, textColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())

let blackPlay = UIImage.fontAwesomeIconWithName(.Play, textColor: UIColor.black, size: faIconSize, backgroundColor: UIColor.white)
    //UIImage(icon: FAType.FAPlay, size: faIconSize, textColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())

let whiteGift = UIImage.fontAwesomeIconWithName(.Gift, textColor: UIColor.white, size: faIconSize, backgroundColor: UIColor.clear)
    //UIImage(icon: FAType.FAGift, size: faIconSize, textColor: UIColor.whiteColor(), backgroundColor: UIColor.clearColor())
