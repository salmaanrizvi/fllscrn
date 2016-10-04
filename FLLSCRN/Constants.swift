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

let redGift = UIImage.fontAwesomeIconWithName(.Gift, textColor: UIColor.fllscrnGreen(), size: faIconSize, backgroundColor: UIColor.white)

let redSend = UIImage.fontAwesomeIconWithName(.Send, textColor: UIColor.fllscrnGreen(), size: faIconSize, backgroundColor: UIColor.white)
//UIImage(icon: FAType.FASend, size: faIconSize, textColor: UIColor.fllscrnRed(), backgroundColor: UIColor.whiteColor())

let redPlay = UIImage.fontAwesomeIconWithName(.Play, textColor: UIColor.fllscrnGreen(), size: faIconSize, backgroundColor: UIColor.white)
//UIImage(icon: FAType.FAPlay, size: faIconSize, textColor: UIColor.fllscrnRed(), backgroundColor: UIColor.whiteColor())

let redPlayClearBackground = UIImage.fontAwesomeIconWithName(.Play, textColor: UIColor.fllscrnGreen(), size: faIconSize, backgroundColor: UIColor.clear)
//UIImage(icon: FAType.FAPlay, size: faIconSize, textColor: UIColor.fllscrnRed(), backgroundColor: UIColor.clearColor())

let blackGift = UIImage.fontAwesomeIconWithName(.Gift, textColor: UIColor.black, size: faIconSize, backgroundColor: UIColor.white)
//UIImage(icon: FAType.FAGift, size: faIconSize, textColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())

let blackSend = UIImage.fontAwesomeIconWithName(.Send, textColor: UIColor.black, size: faIconSize, backgroundColor: UIColor.white)
//UIImage(icon: FAType.FASend, size: faIconSize, textColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())

let blackPlay = UIImage.fontAwesomeIconWithName(.Play, textColor: UIColor.black, size: faIconSize, backgroundColor: UIColor.white)
    //UIImage(icon: FAType.FAPlay, size: faIconSize, textColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())

let whiteGift = UIImage.fontAwesomeIconWithName(.Gift, textColor: UIColor.white, size: faIconSize, backgroundColor: UIColor.clear)
    //UIImage(icon: FAType.FAGift, size: faIconSize, textColor: UIColor.whiteColor(), backgroundColor: UIColor.clearColor())

let whiteCamera = UIImage.fontAwesomeIconWithName(.CameraRetro, textColor: .white, size: faIconSize, backgroundColor: .clear)
let purpleCamera = UIImage.fontAwesomeIconWithName(.CameraRetro, textColor: .fllscrnPurple(), size: faIconSize, backgroundColor: .clear)

let whiteVideoCamera = UIImage.fontAwesomeIconWithName(.VideoCamera, textColor: .white, size: faIconSize, backgroundColor: .clear)
let greenVideoCamera = UIImage.fontAwesomeIconWithName(.VideoCamera, textColor: .fllscrnGreen(), size: faIconSize, backgroundColor: .clear)

let formats : [NSNumber : String] =
    [ NSNumber(value: kCVPixelFormatType_1Monochrome.hashValue) : "kCVPixelFormatType_1Monochrome",
      NSNumber(value: kCVPixelFormatType_2Indexed.hashValue) : "kCVPixelFormatType_2Indexed",
      NSNumber(value: kCVPixelFormatType_4Indexed.hashValue) : "kCVPixelFormatType_4Indexed",
      NSNumber(value: kCVPixelFormatType_8Indexed.hashValue) : "kCVPixelFormatType_8Indexed",
      NSNumber(value: kCVPixelFormatType_1IndexedGray_WhiteIsZero.hashValue) : "kCVPixelFormatType_1IndexedGray_WhiteIsZero",
      NSNumber(value: kCVPixelFormatType_2IndexedGray_WhiteIsZero.hashValue) : "kCVPixelFormatType_2IndexedGray_WhiteIsZero",
      NSNumber(value: kCVPixelFormatType_4IndexedGray_WhiteIsZero.hashValue) : "kCVPixelFormatType_4IndexedGray_WhiteIsZero",
      NSNumber(value: kCVPixelFormatType_8IndexedGray_WhiteIsZero.hashValue) : "kCVPixelFormatType_8IndexedGray_WhiteIsZero",
      NSNumber(value: kCVPixelFormatType_16BE555.hashValue) : "kCVPixelFormatType_16BE555",
      NSNumber(value: kCVPixelFormatType_16LE555.hashValue) : "kCVPixelFormatType_16LE555",
      NSNumber(value: kCVPixelFormatType_16LE5551.hashValue) : "kCVPixelFormatType_16LE5551",
      NSNumber(value: kCVPixelFormatType_16BE565.hashValue) : "kCVPixelFormatType_16BE565",
      NSNumber(value: kCVPixelFormatType_16LE565.hashValue) : "kCVPixelFormatType_16LE565",
      NSNumber(value: kCVPixelFormatType_24RGB.hashValue) : "kCVPixelFormatType_24RGB",
      NSNumber(value: kCVPixelFormatType_24BGR.hashValue) : "kCVPixelFormatType_24BGR",
      NSNumber(value: kCVPixelFormatType_32ARGB.hashValue) : "kCVPixelFormatType_32ARGB",
      NSNumber(value: kCVPixelFormatType_32BGRA.hashValue) : "kCVPixelFormatType_32BGRA",
      NSNumber(value: kCVPixelFormatType_32ABGR.hashValue) : "kCVPixelFormatType_32ABGR",
      NSNumber(value: kCVPixelFormatType_32RGBA.hashValue) : "kCVPixelFormatType_32RGBA",
      NSNumber(value: kCVPixelFormatType_64ARGB.hashValue) : "kCVPixelFormatType_64ARGB",
      NSNumber(value: kCVPixelFormatType_48RGB.hashValue) : "kCVPixelFormatType_48RGB",
      NSNumber(value: kCVPixelFormatType_32AlphaGray.hashValue) : "kCVPixelFormatType_32AlphaGray",
      NSNumber(value: kCVPixelFormatType_16Gray.hashValue) : "kCVPixelFormatType_16Gray",
      NSNumber(value: kCVPixelFormatType_422YpCbCr8.hashValue) : "kCVPixelFormatType_422YpCbCr8",
      NSNumber(value: kCVPixelFormatType_4444YpCbCrA8.hashValue) : "kCVPixelFormatType_4444YpCbCrA8",
      NSNumber(value: kCVPixelFormatType_4444YpCbCrA8R.hashValue) : "kCVPixelFormatType_4444YpCbCrA8R",
      NSNumber(value: kCVPixelFormatType_444YpCbCr8.hashValue) : "kCVPixelFormatType_444YpCbCr8",
      NSNumber(value: kCVPixelFormatType_422YpCbCr16.hashValue) : "kCVPixelFormatType_422YpCbCr16",
      NSNumber(value: kCVPixelFormatType_422YpCbCr10.hashValue) : "kCVPixelFormatType_422YpCbCr10",
      NSNumber(value: kCVPixelFormatType_444YpCbCr10.hashValue) : "kCVPixelFormatType_444YpCbCr10",
      NSNumber(value: kCVPixelFormatType_420YpCbCr8Planar.hashValue) : "kCVPixelFormatType_420YpCbCr8Planar",
      NSNumber(value: kCVPixelFormatType_420YpCbCr8PlanarFullRange.hashValue) : "kCVPixelFormatType_420YpCbCr8PlanarFullRange",
      NSNumber(value: kCVPixelFormatType_422YpCbCr_4A_8BiPlanar.hashValue) : "kCVPixelFormatType_422YpCbCr_4A_8BiPlanar",
      NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange.hashValue) : "kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange",
      NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange.hashValue) : "kCVPixelFormatType_420YpCbCr8BiPlanarFullRange",
      NSNumber(value: kCVPixelFormatType_422YpCbCr8_yuvs.hashValue) : "kCVPixelFormatType_422YpCbCr8_yuvs",
      NSNumber(value: kCVPixelFormatType_422YpCbCr8FullRange.hashValue) : "kCVPixelFormatType_422YpCbCr8FullRange",
]

let labelWidthMultiple : CGFloat = 0.25
let widthMultiple : CGFloat = 1.0
let layoutPadding : CGFloat = 5.0
let cellsPerRow   : CGFloat = 3.0
